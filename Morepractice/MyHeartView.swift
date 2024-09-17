
// MyHeartView.swift

import SwiftUI

struct MyHeartView: View {
    @ObservedObject var scoreManager: ScoreManager
    @State private var selectedScore: Score?
    @State private var showingDetailView = false

    var body: some View {
        VStack {
            if scoreManager.scores.isEmpty {
                Text("No scores recorded yet.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(scoreManager.scores) { score in
                    HStack {
                        // Display first image
                        AsyncImage(url: URL(string: score.image1URL)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else if phase.error != nil {
                                // Error placeholder
                                Color.red
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else {
                                // Placeholder while loading
                                ProgressView()
                                    .frame(width: 50, height: 50)
                            }
                        }

                        // Display second image
                        AsyncImage(url: URL(string: score.image2URL)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else if phase.error != nil {
                                // Error placeholder
                                Color.red
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } else {
                                // Placeholder while loading
                                ProgressView()
                                    .frame(width: 50, height: 50)
                            }
                        }

                        VStack(alignment: .leading) {
                            Text("Relational Score: \(String(format: "%.2f", score.relationalScore))")
                                .font(.headline)
                            Text("Slider1: \(String(format: "%.2f", score.slider1)) | Slider2: \(String(format: "%.2f", score.slider2))")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text("Date: \(score.date, formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 8)
                    }
                    .onTapGesture {
                        self.selectedScore = score
                        self.showingDetailView = true
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
        .navigationTitle("MyHeart")
        .sheet(isPresented: $showingDetailView) {
            if let selectedScore = selectedScore {
                ScoreDetailView(score: selectedScore)
            }
        }
    }

    // Date formatter for displaying dates
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}
