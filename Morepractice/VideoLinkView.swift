// VideoLinkView.swift
//  Morepractice
//
//  Updated to remove undefined mirror/rtcVideoTrackLocal members
//

import SwiftUI
import WebRTC

struct VideoLinkView: View {
    // MARK: - Environment Objects
    @EnvironmentObject var appViewModel: AppViewModel

    // MARK: - Local & Remote Video Views
    @State private var localVideoView  = RTCMTLVideoView()
    @State private var remoteVideoView = RTCMTLVideoView()

    // Always mirror the local preview
    private let shouldMirrorLocal = true

    var body: some View {
        ZStack {
            // Remote video fills the background
            VideoRendererView(videoView: remoteVideoView, mirror: false)
                .ignoresSafeArea()

            // Local preview in the top-right corner
            VideoRendererView(videoView: localVideoView, mirror: shouldMirrorLocal)
                .frame(width: 120, height: 160)
                .cornerRadius(8)
                .shadow(radius: 4)
                .padding()
                .position(x: UIScreen.main.bounds.width - 80, y: 100)

            // Call controls at bottom
            VStack {
                Spacer()
                HStack(spacing: 40) {
                    // Hang up
                    Button(action: {
                        LinkManager.shared.terminateCurrentLink()
                    }) {
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 28))
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }

                    // “Extend” control message
                    Button(action: {
                        guard let channel = LinkManager.shared.rtcDataChannel,
                              channel.readyState == .open,
                              let data = try? JSONSerialization.data(
                                  withJSONObject: ["command":"extend","seconds":30]
                              )
                        else { return }
                        let buffer = RTCDataBuffer(data: data, isBinary: false)
                        _ = channel.sendData(buffer)
                    }) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 28))
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            guard let pc = LinkManager.shared.peerConnection else { return }

            // — Local preview —
            if let sender = pc.senders.first(where: { $0.track?.kind == kRTCMediaStreamTrackKindVideo }),
               let localTrack = sender.track as? RTCVideoTrack {
                localVideoView.videoContentMode = .scaleAspectFill
                localTrack.add(localVideoView)
            }

            // — Remote video —
            for transceiver in pc.transceivers where transceiver.mediaType == .video {
                if let remoteTrack = transceiver.receiver.track as? RTCVideoTrack {
                    remoteTrack.add(remoteVideoView)
                }
            }

            // ** Listen for any newly negotiated remote track **
            NotificationCenter.default.addObserver(
                forName: .didReceiveRemoteVideoTrack,
                object: nil,
                queue: .main
            ) { note in
                if let track = note.object as? RTCVideoTrack {
                    track.add(remoteVideoView)
                }
            }
        }
        .onDisappear {
            // Clean up observer
            NotificationCenter.default.removeObserver(self, name: .didReceiveRemoteVideoTrack, object: nil)

            guard let pc = LinkManager.shared.peerConnection else { return }

            // Detach local
            if let sender = pc.senders.first(where: { $0.track?.kind == kRTCMediaStreamTrackKindVideo }),
               let localTrack = sender.track as? RTCVideoTrack {
                localTrack.remove(localVideoView)
            }

            // Detach remote
            for transceiver in pc.transceivers where transceiver.mediaType == .video {
                if let remoteTrack = transceiver.receiver.track as? RTCVideoTrack {
                    remoteTrack.remove(remoteVideoView)
                }
            }
        }
    }
}

/// A SwiftUI wrapper around RTCMTLVideoView for rendering WebRTC streams.
struct VideoRendererView: UIViewRepresentable {
    let videoView: RTCMTLVideoView
    let mirror: Bool

    func makeUIView(context: Context) -> RTCMTLVideoView {
        videoView.videoContentMode = .scaleAspectFill
        return videoView
    }

    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        uiView.transform = mirror
            ? CGAffineTransform(scaleX: -1, y: 1)
            : .identity
    }
}
