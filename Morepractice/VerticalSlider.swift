// VerticalSlider.swift

import SwiftUI

struct VerticalSlider: View {
    @Binding var value: Double // Slider value between 0 and 1
    let thumbColor: Color
    let trackColor: Color
    let thumbOpacity: Double

    @EnvironmentObject var settingsManager: SettingsManager // Injected
    @EnvironmentObject var soundManager: SoundManager // Injected

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let yPosition = height * (1 - CGFloat(value))

            ZStack(alignment: .top) {
                // Slider Track
                Rectangle()
                    .fill(trackColor)
                    .opacity(0.3) // Adjusted opacity for more transparency
                    .frame(width: 40)
                    .cornerRadius(10)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { drag in
                                let newValue = min(max(0, 1 - Double(drag.location.y / height)), 1)
                                value = newValue

                                // Haptic Feedback on Slider Change
                            //    if settingsManager.hapticFeedbackEnabled {
                         //           let generator = UIImpactFeedbackGenerator(style: .heavy)
                       //             generator.prepare()
                         //           generator.impactOccurred(intensity: CGFloat(signOf: CGFloat(Float(settingsManager.hapticStrength)), magnitudeOf: 1.0)) // Clamp to 1.0
                     //           }
                            }
                    )

                // Slider Thumb
                Rectangle()
                    .fill(thumbColor)
                    .opacity(thumbOpacity)
                    .frame(width: 40, height: 30)
                    .cornerRadius(5)
                    .offset(y: yPosition - 15) // Adjust for thumb height
            }
        }
        .onAppear {
            // Play booting up sound if enabled
//            if settingsManager.soundEnabled {
 //               soundManager.playSound(named: "bootup")
//            }
        }
    }
}

struct VerticalSlider_Previews: PreviewProvider {
    static var previews: some View {
        let settingsMgr = SettingsManager()
        let soundMgr = SoundManager.shared

        VerticalSlider(value: .constant(0.5), thumbColor: .blue, trackColor: .gray, thumbOpacity: 0.5)
            .environmentObject(settingsMgr)
            .environmentObject(soundMgr)
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.black)
    }
}
