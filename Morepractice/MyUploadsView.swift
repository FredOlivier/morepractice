import SwiftUI
import FirebaseFirestore

/// Represents a user upload document (single or pair), including its ratings.
struct UploadDoc: Identifiable {
    let id: String
    let urls: [String]
    let averageScore: Double
    let ratingCount: Int
    let ratings: [RatingEntry]

    struct RatingEntry: Identifiable {
        let id: String
        let url1: String
        let url2: String?      // nil for single
        let slider1: Int
        let slider2: Int?      // nil for single
        let timestamp: Date?
    }

    init(doc: DocumentSnapshot) {
        self.id = doc.documentID
        let data = doc.data() ?? [:]

        // Core fields
        let mediaURLs    = data["mediaURLs"] as? [String] ?? []
        self.urls        = mediaURLs
        self.averageScore = data["averageScore"] as? Double ?? 0.0
        self.ratingCount  = data["ratingCount"]  as? Int    ?? 0

        // Build RatingEntry array without capturing self
        let rawRatings = data["ratings"] as? [[String:Any]] ?? []
        var tmp: [RatingEntry] = []
        for (idx, entry) in rawRatings.enumerated() {
            // the “other” image URL stored when appending
            let u1 = entry["image1_url"] as? String ?? mediaURLs.first ?? ""
            let u2 = entry["image2_url"] as? String ?? (mediaURLs.count > 1 ? mediaURLs[1] : nil)
            let s1 = entry["slider1"]   as? Int    ?? 0
            let s2 = entry["slider2"]   as? Int
            let ts = (entry["ts"] as? Timestamp)?.dateValue()

            tmp.append(
                RatingEntry(
                    id: "\(idx)",
                    url1: u1,
                    url2: u2,
                    slider1: s1,
                    slider2: s2,
                    timestamp: ts
                )
            )
        }
        self.ratings = tmp
    }
}

struct MyUploadsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selection = 0   // 0 = singles, 1 = pairs
    @State private var singles: [UploadDoc] = []
    @State private var pairs:   [UploadDoc] = []
    private let db = Firestore.firestore()

    var body: some View {
        NavigationView {
            VStack {
                Picker("", selection: $selection) {
                    Text("Singles").tag(0)
                    Text("Pairs").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selection == 0 {
                    List(singles) { doc in
                        NavigationLink(
                          destination: UploadStatsView(doc: doc, isPair: false)
                        ) {
                            UploadRow(doc: doc, isPair: false)
                        }
                    }
                } else {
                    List(pairs) { doc in
                        NavigationLink(
                          destination: UploadStatsView(doc: doc, isPair: true)
                        ) {
                            UploadRow(doc: doc, isPair: true)
                        }
                    }
                }
            }
            .navigationTitle("My Uploads")
            .onAppear(perform: loadUploads)
        }
    }

    private func loadUploads() {
        guard let uid = authViewModel.currentUser?.uid else { return }
        let base = db.collection("user_upload").document(uid)

        base.collection("single_upload").getDocuments { snap, _ in
            if let docs = snap?.documents {
                self.singles = docs.map(UploadDoc.init)
            }
        }

        base.collection("pairs").getDocuments { snap, _ in
            if let docs = snap?.documents {
                self.pairs = docs.map(UploadDoc.init)
            }
        }
    }
}

/// Row view showing thumbnail(s) + summary stats
struct UploadRow: View {
    let doc: UploadDoc
    let isPair: Bool

    var body: some View {
        HStack {
            if isPair, doc.urls.count > 1 {
                ThumbnailView(url: doc.urls[0])
                ThumbnailView(url: doc.urls[1])
            } else {
                ThumbnailView(url: doc.urls.first ?? "")
            }

            VStack(alignment: .leading) {
                Text("Average: \(String(format: "%.1f", doc.averageScore))")
                Text("Ratings: \(doc.ratingCount)")
            }
            .padding(.leading, 8)

            Spacer()
        }
    }

    @ViewBuilder
    private func ThumbnailView(url: String) -> some View {
        AsyncImage(url: URL(string: url)) { img in
            img.resizable().scaledToFill()
        } placeholder: {
            Color.gray
        }
        .frame(width: isPair ? 80 : 90, height: isPair ? 80 : 90)
        .clipped()
    }
}

/// Detailed stats view for one upload
struct UploadStatsView: View {
    let doc: UploadDoc
    let isPair: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Top thumbnails
                if isPair, doc.urls.count > 1 {
                    HStack {
                        DetailThumbnail(url: doc.urls[0])
                        DetailThumbnail(url: doc.urls[1])
                    }
                } else if let url = doc.urls.first {
                    DetailThumbnail(url: url)
                }

                // Summary
                VStack(alignment: .leading, spacing: 4) {
                    Text("Average Score: \(String(format: "%.1f", doc.averageScore))")
                        .font(.headline)
                    Text("Total Ratings: \(doc.ratingCount)")
                        .font(.subheadline)
                }
                .padding(.horizontal)

                Divider()

                // List of individual ratings
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(doc.ratings) { entry in
                        RatingEntryView(entry: entry)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Upload Stats")
    }

    @ViewBuilder
    private func DetailThumbnail(url: String) -> some View {
        AsyncImage(url: URL(string: url)) { img in
            img.resizable().scaledToFit()
        } placeholder: {
            ProgressView()
        }
        .frame(maxWidth: .infinity)
        .cornerRadius(8)
        .shadow(radius: 4)
        .padding(.horizontal)
    }
}

/// View for a single rating entry, showing both images + respective scores
/// View for a single rating entry, showing both images + respective scores
struct RatingEntryView: View {
    let entry: UploadDoc.RatingEntry

    // track which URL to show full-screen
    @State private var showingImage = false
    @State private var imageToShow: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                // Left image + score
                VStack {
                    AsyncImage(url: URL(string: entry.url1)) { img in
                        img.resizable().scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.5)
                    }
                    .frame(width: 60, height: 60)
                    .clipped()
                    .cornerRadius(4)
                    // open sheet on tap
                    .onTapGesture {
                        imageToShow = entry.url1
                        showingImage = true
                    }

                    Text("Score: \(entry.slider1)")
                        .font(.caption)
                }

                // Right image + score (if any)
                if let u2 = entry.url2, let s2 = entry.slider2 {
                    VStack {
                        AsyncImage(url: URL(string: u2)) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.5)
                        }
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(4)
                        .onTapGesture {
                            imageToShow = u2
                            showingImage = true
                        }

                        Text("Score: \(s2)")
                            .font(.caption)
                    }
                }
            }

            if let date = entry.timestamp {
                Text(dateFormatted(date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Divider()
        }
        // full-screen sheet for whichever URL was tapped
        .sheet(isPresented: $showingImage) {
            ZStack {
                Color.black.ignoresSafeArea()
                AsyncImage(url: URL(string: imageToShow)) { img in
                    img.resizable().scaledToFit()
                } placeholder: {
                    ProgressView().tint(.white)
                }
                .padding()
            }
        }
    }

    private func dateFormatted(_ d: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .short
        return fmt.string(from: d)
    }
}
