import SwiftUI

struct TemporaryChatView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @EnvironmentObject var linkingSettingsManager: LinkingSettingsManager  // Needs this from environment
    @State private var newMessage: String = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            // 1) Chat ScrollView
            ScrollView {
                ForEach(appViewModel.messages, id: \.self) { msg in
                    Text(msg)
                        .padding(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()

            // 2) Input field and send button
            HStack {
                TextField("Type a message...", text: $newMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Send") {
                    appViewModel.sendChatMessage(newMessage)
                    newMessage = ""
                }
                .padding(.horizontal)
                .disabled(!appViewModel.isChatChannelOpen || newMessage.isEmpty)
            }
            .padding()

            // 3) End/Close Chat Button
            Button("End Chat") {
                LinkManager.shared.terminateCurrentLink()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .padding(.top, 8)

            Spacer()
        }
        .navigationTitle("Temporary Chat")
        .onAppear {
            print("TemporaryChatView: onAppear. Chat started.")
            // Schedule auto-termination using the adjustable chatDuration value.
            DispatchQueue.main.asyncAfter(deadline: .now() + linkingSettingsManager.chatDuration) {
                if appViewModel.isInTemporaryChat {
                    LinkManager.shared.terminateCurrentLink()
                    // Optionally dismiss the view if desired:
                    // dismiss()
                }
            }
        }
    }
}

// MARK: - Preview Correction
struct TemporaryChatView_Previews: PreviewProvider {
    static var previews: some View {
        // 1. Create AppViewModel using the correct no-argument init
        let appVM = AppViewModel()
        // 2. Create the separate LinkingSettingsManager needed by the view
        let linkingMgr = LinkingSettingsManager()

        // 3. Inject both into the environment for the preview
        TemporaryChatView()
            .environmentObject(appVM)         // Provide AppViewModel instance
            .environmentObject(linkingMgr)  // Provide LinkingSettingsManager instance
    }
}
