//
//  VerticalSlider.swift
//  Morepractice
//
//  Created by Fred Olivier on 17/09/2024.
//

import Foundation
// VerticalSlider.swift

import SwiftUI

struct VerticalSlider: View {
    @Binding var value: Double // Slider value between 0 and 1
    let thumbColor: Color
    let trackColor: Color
    let thumbOpacity: Double
    let hapticFeedback: Bool

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
                                if hapticFeedback {
                                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                                    impact.impactOccurred()
                                }
                                value = newValue
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
    }
}
