//
//  UploadButtonView.swift
//  Morepractice
//
//  Created by Fred Olivier on 13/04/2025.
//

import Foundation
import SwiftUI

struct UploadButtonView: View {
    let title: String
    let iconName: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.white)
            Text(title)
                .foregroundColor(.white)
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding()
        .background(Color.blue.opacity(0.4))
        .cornerRadius(20)
    }
}

struct UploadButtonView_Previews: PreviewProvider {
    static var previews: some View {
        UploadButtonView(title: "Upload Pair", iconName: "square.split.2x1.fill")
    }
}
