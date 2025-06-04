import SwiftUI
import WebRTC

/// A UIViewRepresentable wrapper around WebRTC’s Metal-based video view.
struct RTCMTLVideoViewWrapper: UIViewRepresentable {
  let track: RTCVideoTrack?

  func makeCoordinator() -> Coordinator { Coordinator() }

  func makeUIView(context: Context) -> RTCMTLVideoView {
    let metalView = RTCMTLVideoView(frame: .zero)
    metalView.videoContentMode = .scaleAspectFill
    context.coordinator.view  = metalView
    context.coordinator.track = track
    if let t = track {
      t.add(metalView)
    }
    return metalView
  }

  func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
    // Swap renderer if track changed
    if context.coordinator.track !== track {
      if let oldT = context.coordinator.track,
         let oldV = context.coordinator.view {
        oldT.remove(oldV)
      }
      if let newT = track {
        newT.add(uiView)
      }
      context.coordinator.track = track
      context.coordinator.view  = uiView
    }
  }

  class Coordinator {
    var track: RTCVideoTrack?
    var view:  RTCMTLVideoView?
  }
}

/// Full‐screen video chat with timer, “Add Time” button, and proper camera orientation.
struct VideoChatView: View {
  @EnvironmentObject private var appViewModel: AppViewModel
  @EnvironmentObject private var linkingSettingsManager: LinkingSettingsManager

  // State for tracks
  @State private var localTrack:  RTCVideoTrack?
  @State private var remoteTrack: RTCVideoTrack?
  @State private var remainingTime: Int = 0

  // Publisher for remote track arrival
  private let remoteTrackPublisher = NotificationCenter
    .default
    .publisher(for: .didReceiveRemoteVideoTrack)

  // Ticker for countdown
  private let ticker = Timer
    .publish(every: 1, on: .main, in: .common)
    .autoconnect()

  var body: some View {
    ZStack {
      // Remote feed fills the background
      RTCMTLVideoViewWrapper(track: remoteTrack)
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)

      // Local preview top-right, un‐mirrored
      VStack {
        HStack {
          Spacer()
          RTCMTLVideoViewWrapper(track: localTrack)
            .scaleEffect(x: -1, y: 1)
            .frame(width: 120, height: 160)
            .cornerRadius(8)
            .padding(12)
        }
        Spacer()
      }

      // Bottom-right: Timer, Add Time, Hang-up
      VStack {
        Spacer()
        HStack {
          Spacer()
          VStack(spacing: 12) {
            Text(timerText(from: remainingTime))
              .font(.system(size: 18, weight: .semibold, design: .monospaced))
              .padding(6)
              .background(Color.black.opacity(0.5))
              .foregroundColor(.white)
              .cornerRadius(6)

            Button("Add \(linkingSettingsManager.extensionDuration)s") {
              extendTime()
            }
            .font(.callout).bold()
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color.blue.opacity(0.7))
            .foregroundColor(.white)
            .cornerRadius(6)

            Button(action: endCall) {
              Image(systemName: "phone.down.circle.fill")
                .resizable()
                .frame(width: 64, height: 64)
                .foregroundColor(.red)
            }
          }
          .padding(16)
        }
      }
    }
    .onAppear {
      // Grab existing tracks
      let lm = LinkManager.shared
      localTrack  = lm.localVideoTrack
      remoteTrack = lm.remoteVideoTrack
      // Start countdown
      remainingTime = Int(linkingSettingsManager.chatDuration)
    }
    // Update remote when new track arrives
    .onReceive(remoteTrackPublisher) { notif in
      if let newTrack = notif.object as? RTCVideoTrack {
        remoteTrack = newTrack
      }
    }
    // Countdown ticker
    .onReceive(ticker) { _ in
      if remainingTime <= 0 {
        endCall()
      } else {
        remainingTime -= 1
      }
    }
  }

  // MARK: Helpers

  private func extendTime() {
    remainingTime += linkingSettingsManager.extensionDuration
    LinkManager.shared.sendControl([
      "type": "extendTimer",
      "added": linkingSettingsManager.extensionDuration
    ])
  }

  private func endCall() {
    LinkManager.shared.terminateCurrentLink()
    appViewModel.isChatChannelOpen = false
  }

  private func timerText(from seconds: Int) -> String {
    String(format: "%02d:%02d", seconds / 60, seconds % 60)
  }
}
