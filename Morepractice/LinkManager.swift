//
//  LinkManager.swift
//  Morepractice
//
//  FaceTime–link edition • 2025-05-01
//  Updated: use max of both users’ cooldown settings
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import WebRTC
import AVFoundation
import CryptoKit          // replaces CommonCrypto
import SocketIO

// ────────────────────────────────────────────────────────── Helpers

extension RTCSdpType {
  init?(string: String) {
    switch string.lowercased() {
      case "offer":     self = .offer
      case "answer":    self = .answer
      case "pranswer":  self = .prAnswer
      case "rollback":  self = .rollback
      default:          return nil
    }
  }
}

extension Notification.Name {
  /// Posted when a new remote RTCVideoTrack arrives.
  static let didReceiveRemoteVideoTrack =
      Notification.Name("didReceiveRemoteVideoTrack")
}

private extension AVCaptureDevice.Format {
  /// Width in pixels for a given camera format.
  var pixelWidth: Int32 {
    CMVideoFormatDescriptionGetDimensions(formatDescription).width
  }
}

// ────────────────────────────────────────────────────────── Delegate

protocol LinkManagerDelegate: AnyObject {
  func didInitiateLink(sessionId: String)
  func didTerminateLink()
  func didReceiveMessage(_ message: String)
}

// ────────────────────────────────────────────────────────── LinkManager

final class LinkManager: NSObject {

  // MARK: Singleton
  static let shared = LinkManager()

  // MARK: Firebase
  private let db = Firestore.firestore()

  // MARK: Signaling (Socket.IO)
  private var manager: SocketManager!
  private var socket : SocketIOClient!

  // MARK: Identity
  private var currentUsername = "anonymous"
  private var targetUserId: String?
  public  var targetUsername: String? { targetUserId }

  // MARK: Session state
  private var sessionId: String?
  private var isCaller : Bool = false

  // MARK: WebRTC
  public var peerConnection:   RTCPeerConnection?
  public var rtcDataChannel:   RTCDataChannel?
  public var localVideoTrack:  RTCVideoTrack?
  public var remoteVideoTrack: RTCVideoTrack?
  private let peerConnectionFactory = RTCPeerConnectionFactory()
  private var videoCapturer:       RTCCameraVideoCapturer?

  // MARK: App references
  weak var delegate: LinkManagerDelegate?
  private weak var appViewModel : AppViewModel?
  private weak var authViewModel: AuthViewModel?

  private var linkingSettingsManager: LinkingSettingsManager {
    appViewModel?.linkingSettingsManager ?? LinkingSettingsManager()
  }

  // MARK: Eligibility timer
  private var eligibilityTimer: Timer?
  private var linkStartTime: Date?
  weak var remoteVideoView: UIView?

  // MARK: Init

  private override init() {
    super.init()
    RTCInitializeSSL()

    let url = URL(string: "https://webrtc.morepractice.co.uk:3001")!
    manager = SocketManager(
      socketURL: url,
      config: [
        .log(true), .compress,
        .reconnects(true), .reconnectAttempts(-1), .reconnectWait(5)
      ]
    )
    socket = manager.defaultSocket
    addSocketHandlers()
    socket.connect()
  }

  // MARK: – Injection

  func setAuthViewModel(_ vm: AuthViewModel) {
    authViewModel = vm
    fetchCurrentUsername { [weak self] name in
      guard let self = self else { return }
      self.currentUsername = name.trimmingCharacters(in: .whitespacesAndNewlines)
      if self.socket.status == .disconnected {
        self.socket.connect()
      } else {
        self.socket.emit("register", self.currentUsername)
      }
    }
  }

  func setAppViewModel(_ vm: AppViewModel) {
    appViewModel = vm
    eligibilityTimer?.invalidate()
    eligibilityTimer = Timer.scheduledTimer(
      withTimeInterval: linkingSettingsManager.linkInitiationInterval,
      repeats: true
    ) { [weak self] _ in
      self?.initiateLinkIfEligible()
    }
    initiateLinkIfEligible()
  }

  private func fetchCurrentUsername(completion: @escaping(String)->Void) {
    guard let u = Auth.auth().currentUser else {
      completion("anonymous"); return
    }
    db.collection("users")
      .whereField("uid", isEqualTo: u.uid)
      .getDocuments { snap, _ in
        let name = snap?.documents.first?.documentID ?? "anonymous"
        completion(name)
      }
  }

  // MARK: Debug

  func sendTestPing(to target: String) {
    socket.emit("signal", [
      "type":"testPing",
      "from":currentUsername,
      "to":target,
      "sessionId":sessionId ?? ""
    ])
  }

  // ─────────────────────────────────────────────────────── Link start

  func initiateLinkIfEligible() {
    guard let vm = appViewModel, vm.linkingMode,
          sessionId == nil else { return }

    LinkEligibilityManager.shared.fetchEligibleUsers(
      for: currentUsername,
      eligibilityModes: linkingSettingsManager.selectedEligibilityModes
    ) { [weak self] pool in
      guard let self = self, let target = pool.first else { return }

      // check existing cooldown
      let cdRef = self.db
        .collection("users").document(self.currentUsername)
        .collection("cooldowns").document(target)
      cdRef.getDocument { docSnap, _ in
        if let ts = docSnap?.data()?["nextAvailableTime"] as? Timestamp,
           ts.dateValue() > Date() {
          // still cooling down
          return
        }
        self.beginCallerFlow(to: target)
      }
    }
  }

  private func beginCallerFlow(to target: String) {
    isCaller     = true
    sessionId    = UUID().uuidString
    targetUserId = target
    linkStartTime = Date()

    let sid      = sessionId!
    let me       = currentUsername.trimmingCharacters(in: .whitespacesAndNewlines)
    let them     = target.trimmingCharacters(in: .whitespacesAndNewlines)

    // fetch both users' cooldown settings and apply max
    let localCd = linkingSettingsManager.cooldownDuration
    let remoteSettingsRef = db
      .collection("users").document(them)
      .collection("settings").document("linkingSettings")
    remoteSettingsRef.getDocument { [weak self] doc, _ in
      guard let self = self else { return }
      let remoteCd = doc?.data()?["cooldownDuration"] as? Double ?? 60.0
      let cd       = max(localCd, remoteCd)
      let next     = Date().addingTimeInterval(cd)

      // emit link signal
      self.socket.emit("signal", [
        "type":"createLink","from":me,"to":them,"sessionId":sid
      ])

      // start WebRTC
      self.createPeerConnection()
      self.createAndSendOffer()

      // write cooldown for both directions
      let cdData: [String:Any] = ["nextAvailableTime": Timestamp(date: next)]
      let batch = self.db.batch()
      let refA = self.db.collection("users").document(me)
                    .collection("cooldowns").document(them)
      let refB = self.db.collection("users").document(them)
                    .collection("cooldowns").document(me)
      batch.setData(cdData, forDocument: refA, merge: true)
      batch.setData(cdData, forDocument: refB, merge: true)
      batch.commit()
    }
  }

  // MARK: PeerConnection setup

  private func createPeerConnection() {
    let cfg = RTCConfiguration()
    cfg.sdpSemantics = .unifiedPlan
    cfg.iceServers   = buildIceServers()

    peerConnection = peerConnectionFactory.peerConnection(
      with: cfg,
      constraints: RTCMediaConstraints(
        mandatoryConstraints: nil,
        optionalConstraints: nil
      ),
      delegate: self
    )
    addLocalMedia()
  }

  private func buildIceServers() -> [RTCIceServer] {
    let creds = generateTurnCreds(secret: turnSecret, ttl:3600)
    return [
      RTCIceServer(urlStrings:["stun:webrtc.morepractice.co.uk:3478"]),
      RTCIceServer(
        urlStrings:["turn:webrtc.morepractice.co.uk:3478?transport=udp"],
        username:creds.username,
        credential:creds.credential
      ),
      RTCIceServer(
        urlStrings:["turns:webrtc.morepractice.co.uk:5349?transport=tcp"],
        username:creds.username,
        credential:creds.credential
      )
    ]
  }

  private func addLocalMedia() {
    let source = peerConnectionFactory.videoSource()
    videoCapturer = RTCCameraVideoCapturer(delegate: source)
    localVideoTrack = peerConnectionFactory.videoTrack(with: source, trackId: "v0")
    if let t = localVideoTrack {
      peerConnection?.add(t, streamIds: ["stream"])
    }
    if let sender = peerConnection?.senders.first(where: {
         $0.track?.kind == kRTCMediaStreamTrackKindVideo
       }) {
      var params = sender.parameters
      for e in params.encodings {
        e.maxBitrateBps = 300_000
        e.maxFramerate   = 15
      }
      sender.parameters = params
    }
    startCamera()
  }

  private func startCamera() {
    guard let cap = videoCapturer,
          let cam = RTCCameraVideoCapturer.captureDevices()
                     .first(where: { $0.position == .front })
    else { return }

    let fmts = RTCCameraVideoCapturer.supportedFormats(for: cam)
      .filter {
        CMFormatDescriptionGetMediaSubType($0.formatDescription)
        == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
      }
    guard let best = fmts.max(by: { $0.pixelWidth < $1.pixelWidth }) else { return }
    let fps = Int(best.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 24)
    cap.startCapture(with: cam, format: best, fps: fps)
  }

  // MARK: Offer / Answer

  private func createAndSendOffer() {
    peerConnection?.offer(
      for: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
    ) { [weak self] offer, err in
      guard let self = self, let off = offer else { return }
      self.peerConnection?.setLocalDescription(off) { _ in
        self.socket.emit("signal", [
          "type":"offer","from":self.currentUsername,
          "to":self.targetUserId ?? "","sessionId":self.sessionId ?? "",
          "offer":["type":"offer","sdp":off.sdp]
        ])
      }
    }
  }

  private func sendAnswer() {
    peerConnection?.answer(
      for: RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
    ) { [weak self] answer, err in
      guard let self = self, let ans = answer else { return }
      self.peerConnection?.setLocalDescription(ans) { _ in
        self.socket.emit("signal", [
          "type":"answer","from":self.currentUsername,
          "to":self.targetUserId ?? "","sessionId":self.sessionId ?? "",
          "answer":["type":"answer","sdp":ans.sdp]
        ])
        self.delegate?.didInitiateLink(sessionId: self.sessionId!)
      }
    }
  }

  // MARK: TURN creds via CryptoKit

  private let turnSecret = "uYaVrN0qn3(r)CY7#&RL&r&rj]T4Y"
  private func generateTurnCreds(secret: String, ttl: TimeInterval)
    -> (username: String, credential: String)
  {
    let exp  = Int(Date().timeIntervalSince1970) + Int(ttl)
    let user = "\(exp)"
    let key  = SymmetricKey(data: secret.data(using: .utf8)!)
    let sig  = HMAC<Insecure.SHA1>.authenticationCode(
      for: user.data(using: .utf8)!, using: key
    )
    return (user, Data(sig).base64EncodedString())
  }

  // MARK: Control / extend

  func sendControl(_ obj: [String:Any]) {
    guard let ch = rtcDataChannel, ch.readyState == .open,
          let data = try? JSONSerialization.data(withJSONObject: obj)
    else { return }
    ch.sendData(RTCDataBuffer(data: data, isBinary: false))
  }

  // MARK: Terminate

  func terminateCurrentLink() {
    guard let sid = sessionId else { return }
    socket.emit("signal", [
      "type":"terminateLink","from":currentUsername,
      "to":targetUserId ?? "","sessionId":sid
    ])
    cleanup()
  }

  private func cleanup() {
    peerConnection?.close()
    peerConnection       = nil
    rtcDataChannel       = nil
    videoCapturer?.stopCapture()
    videoCapturer        = nil
    localVideoTrack      = nil
    remoteVideoTrack     = nil
    sessionId            = nil
    targetUserId         = nil
    delegate?.didTerminateLink()
  }
}

// ───────────────────────────────────────────────────────── Socket.IO

private extension LinkManager {
  func addSocketHandlers() {
    socket.on(clientEvent: .connect) { [weak self] _, _ in
      guard let self = self else { return }
      self.socket.emit("register", self.currentUsername)
    }
    socket.on("signal") { [weak self] data, _ in
      guard let p = data.first as? [String:Any],
            let type = p["type"] as? String,
            let self = self
      else { return }
      switch type {
        case "offer":        self.handleOffer(p)
        case "answer":       self.handleAnswer(p)
        case "iceCandidate": self.handleIceCandidate(p)
        case "terminateLink":self.cleanup()
        default:             break
      }
    }
  }
}

// ───────────────────────────────────────────────────────── Handlers

private extension LinkManager {
  func handleOffer(_ p: [String:Any]) {
    guard sessionId == nil else { return }
    isCaller     = false
    sessionId    = p["sessionId"] as? String
    targetUserId = p["from"] as? String
    createPeerConnection()
    if let o = p["offer"] as? [String:Any],
       let sdp = o["sdp"]  as? String,
       let tp  = RTCSdpType(string: o["type"] as? String ?? "")
    {
      let desc = RTCSessionDescription(type:tp, sdp:sdp)
      peerConnection?.setRemoteDescription(desc) { [weak self] _ in
        self?.sendAnswer()
      }
    }
  }

  func handleAnswer(_ p: [String:Any]) {
    guard p["sessionId"] as? String == sessionId else { return }
    if let a = p["answer"] as? [String:Any],
       let sdp = a["sdp"]  as? String,
       let tp  = RTCSdpType(string: a["type"] as? String ?? "")
    {
      let desc = RTCSessionDescription(type:tp, sdp:sdp)
      peerConnection?.setRemoteDescription(desc) { _ in }
      delegate?.didInitiateLink(sessionId: sessionId!)
    }
  }

  func handleIceCandidate(_ p: [String:Any]) {
    guard p["sessionId"] as? String == sessionId,
          let cand = p["candidate"] as? [String:Any],
          let sdp  = cand["sdp"]            as? String,
          let idx  = cand["sdpMLineIndex"] as? Int32
    else { return }
    let mid = cand["sdpMid"] as? String
    let c   = RTCIceCandidate(sdp:sdp, sdpMLineIndex:idx, sdpMid:mid)
    peerConnection?.add(c)
  }
}

// ───────────────────────────────────────────────────────── Delegates

extension LinkManager: RTCDataChannelDelegate, RTCPeerConnectionDelegate {

  // Data-channel opened
  func dataChannelDidChangeState(_ dc: RTCDataChannel) {
    rtcDataChannel = dc
    if dc.readyState == .open {
      DispatchQueue.main.async {
        self.appViewModel?.isChatChannelOpen = true
      }
    }
  }

  // Data received
  func dataChannel(_ dc: RTCDataChannel,
      didReceiveMessageWith buffer: RTCDataBuffer) {
    guard !buffer.isBinary,
          let msg = String(data:buffer.data,encoding:.utf8)
    else { return }
    delegate?.didReceiveMessage(msg)
  }

  // Plan-B: old stream
  func peerConnection(_ pc: RTCPeerConnection,
                      didAdd stream: RTCMediaStream) {
    if let t = stream.videoTracks.first {
      remoteVideoTrack = t
      NotificationCenter.default.post(
        name: .didReceiveRemoteVideoTrack, object: t)
    }
  }

  // Unified-Plan: new receiver
  func peerConnection(_ pc: RTCPeerConnection,
                      didAdd rtpReceiver: RTCRtpReceiver,
                      streams: [RTCMediaStream]) {
      guard rtpReceiver.track?.kind == kRTCMediaStreamTrackKindVideo,
          let vt = rtpReceiver.track as? RTCVideoTrack
    else { return }
    remoteVideoTrack = vt
    NotificationCenter.default.post(
      name: .didReceiveRemoteVideoTrack, object: vt)
  }

  // ICE candidate generated
  func peerConnection(_ pc: RTCPeerConnection,
                      didGenerate candidate: RTCIceCandidate) {
    guard let sid = sessionId else { return }
    socket.emit("signal", [
      "type":"iceCandidate","from":currentUsername,
      "to":targetUserId ?? "","sessionId":sid,
      "candidate":[
        "sdp":candidate.sdp,
        "sdpMLineIndex":candidate.sdpMLineIndex,
        "sdpMid":candidate.sdpMid ?? ""
      ]
    ])
  }

  // Other delegate stubs:
  func peerConnection(_ pc: RTCPeerConnection,
                      didChange newState: RTCSignalingState) {}
  func peerConnectionShouldNegotiate(_ pc: RTCPeerConnection) {}
  func peerConnection(_ pc: RTCPeerConnection,
                      didChange newState: RTCIceConnectionState) {}
  func peerConnection(_ pc: RTCPeerConnection,
                      didChange newState: RTCIceGatheringState) {}
  func peerConnection(_ pc: RTCPeerConnection,
                      didRemove stream: RTCMediaStream) {}
  func peerConnection(_ pc: RTCPeerConnection,
                      didRemove candidates: [RTCIceCandidate]) {}
  func peerConnection(_ pc: RTCPeerConnection,
                      didOpen dataChannel: RTCDataChannel) {
    rtcDataChannel = dataChannel
    dataChannel.delegate = self
  }
}
