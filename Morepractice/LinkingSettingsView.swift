//
//  LinkingSettingsView.swift
//  Morepractice
//
//  Created by Fred Olivier on 11/04/2025.
//

import SwiftUI

struct LinkingSettingsView: View {
    @EnvironmentObject var linkingSettingsManager: LinkingSettingsManager

    var body: some View {
        Form {
            Section(header: Text("Linking Interval")) {
                HStack {
                    Text("Link Initiation Interval")
                    Spacer()
                    Text("\(linkingSettingsManager.linkInitiationInterval, specifier: "%.0f") sec")
                }
                Slider(value: $linkingSettingsManager.linkInitiationInterval, in: 5...60, step: 1)
                    .accentColor(.blue)
            }
            
            Section(header: Text("Chat Duration")) {
                HStack {
                    Text("Chat Duration")
                    Spacer()
                    Text("\(linkingSettingsManager.chatDuration, specifier: "%.0f") sec")
                }
                Slider(value: $linkingSettingsManager.chatDuration, in: 30...300, step: 1)
                    .accentColor(.green)
            }
            
            Section(header: Text("Eligibility Modes")) {
                // Toggle for Basic Eligibility
                Toggle("Basic Eligibility", isOn: Binding(
                    get: { linkingSettingsManager.selectedEligibilityModes.contains(.basic) },
                    set: { newValue in
                        if newValue {
                            linkingSettingsManager.selectedEligibilityModes.insert(.basic)
                        } else {
                            linkingSettingsManager.selectedEligibilityModes.remove(.basic)
                        }
                    }
                ))
                Section(header: Text("Cooldown")) {
                    Picker("Mode", selection:$linkingSettingsManager.cooldownMode) {
                        ForEach(LinkingSettingsManager.CooldownMode.allCases){ Text($0.rawValue.capitalized).tag($0) }
                    }
                    if linkingSettingsManager.cooldownMode == .time {
                        Stepper("Seconds: \(Int(linkingSettingsManager.cooldownTime))",
                                value:$linkingSettingsManager.cooldownTime,
                                in:60...432000, step:60)
                    } else if linkingSettingsManager.cooldownMode == .interaction {
                        Stepper("Links before repeat: \(linkingSettingsManager.cooldownInteractions)",
                                value:$linkingSettingsManager.cooldownInteractions, in:1...10)
                    }
                }
                Section(header: Text("Who can link")) {
                    Picker("Pool", selection:$linkingSettingsManager.socialPool){
                        Text("Everyone").tag(LinkingSettingsManager.SocialPool.everyone)
                        Text("Friends").tag(LinkingSettingsManager.SocialPool.friends)
                        Text("Mutual friends").tag(LinkingSettingsManager.SocialPool.mutualFriends)
                    }.pickerStyle(.segmented)
                }

                
                // Toggle for Tag-based Eligibility
                Toggle("Tag-based Eligibility", isOn: Binding(
                    get: { linkingSettingsManager.selectedEligibilityModes.contains(.tags) },
                    set: { newValue in
                        if newValue {
                            linkingSettingsManager.selectedEligibilityModes.insert(.tags)
                        } else {
                            linkingSettingsManager.selectedEligibilityModes.remove(.tags)
                        }
                    }
                ))
            }
        }
        .navigationTitle("Linking Settings")
    }
}

struct LinkingSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        LinkingSettingsView()
            .environmentObject(LinkingSettingsManager())
    }
}
