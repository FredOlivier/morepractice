// ScoreDetailView.swift

import SwiftUI

struct ScoreDetailView: View {
    var score: Score

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                // First Image
                AsyncImage(url: URL(string: score.image1URL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                    } else if phase.error != nil {
                        // Error placeholder
                        Color.red
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                    } else {
                        // Placeholder while loading
                        ProgressView()
                            .frame(width: 150, height: 150)
                    }
                }

                // Second Image
                AsyncImage(url: URL(string: score.image2URL)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                    } else if phase.error != nil {
                        // Error placeholder
                        Color.red
                            .frame(width: 150, height: 150)
                            .clipShape(Circle())
                    } else {
                        // Placeholder while loading
                        ProgressView()
                            .frame(width: 150, height: 150)
                    }
                }
            }

            Text("Relational Score: \(String(format: "%.2f", score.relationalScore))")
                .font(.title2)
                .padding()

            VStack(alignment: .leading, spacing: 10) {
                Text("Slider 1: \(String(format: "%.2f", score.slider1))")
                Text("Slider 2: \(String(format: "%.2f", score.slider2))")
            }
            .font(.headline)
            .padding()

            Text("Date: \(score.date, formatter: dateFormatter)")
                .font(.subheadline)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
    }

    // Date formatter for displaying dates
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }
}

struct MyHeartView_Previews: PreviewProvider {
    static var previews: some View {
        MyHeartView(scoreManager: ScoreManager(authViewModel: AuthViewModel()))
    }
}
