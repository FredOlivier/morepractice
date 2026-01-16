//
//  CalibrationViewModel.swift
//  MediaLab
//
//  Created by Fred Olivier on 16/01/2026.
//

import Foundation
import FirebaseFirestore
import MediaKit
import UIKit
internal import Combine

final class CalibrationViewModel: ObservableObject {
    @Published private(set) var mediaA: MediaDoc?
    @Published private(set) var mediaB: MediaDoc?
    @Published private(set) var imageA: UIImage?
    @Published private(set) var imageB: UIImage?
    @Published var recipeA: MediaPresentationRecipe = CalibrationViewModel.defaultRecipe
    @Published var recipeB: MediaPresentationRecipe = CalibrationViewModel.defaultRecipe
    @Published var previewFocalPointA: CGPoint = CGPoint(x: 0.5, y: 0.5)
    @Published var previewFocalPointB: CGPoint = CGPoint(x: 0.5, y: 0.5)
    @Published var presetSelectionA: CalibrationPresetSelection = .safe
    @Published var presetSelectionB: CalibrationPresetSelection = .safe
    @Published var previewSlot: CalibrationSlot = .a
    @Published var statusMessage: String?
    @Published private(set) var saveStateA: CalibrationSaveState = .idle
    @Published private(set) var saveStateB: CalibrationSaveState = .idle

    private let db = Firestore.firestore()
    private var seenThisSession = Set<String>()
    private static let defaultRecipe = MediaPresentationRecipe(
        mode: .fit,
        zoom: 1,
        focalPoint: CGPoint(x: 0.5, y: 0.5),
        fullBleed: true
    )

    func loadNextPair() {
        statusMessage = "Loading media..."
        fetchNeedsReviewCandidates { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let docs) where docs.count >= 2:
                self.selectPair(from: docs)
            default:
                self.fetchFallbackCandidates { fallback in
                    self.selectPair(from: fallback)
                }
            }
        }
    }

    func content(for slot: CalibrationSlot) -> CalibrationContent {
        switch slot {
        case .a:
            return CalibrationContent(
                id: mediaA?.id,
                image: imageA,
                label: "A"
            )
        case .b:
            return CalibrationContent(
                id: mediaB?.id,
                image: imageB,
                label: "B"
            )
        }
    }

    func saveState(for slot: CalibrationSlot) -> CalibrationSaveState {
        switch slot {
        case .a: return saveStateA
        case .b: return saveStateB
        }
    }

    func applyPreset(_ preset: CalibrationPresetSelection, for slot: CalibrationSlot) {
        var updated = CalibrationViewModel.defaultRecipe
        switch preset {
        case .portrait:
            updated.mode = .fill
            updated.zoom = 1.2
            updated.focalPoint = CGPoint(x: 0.5, y: 0.35)
            updated.calibrationPreset = .portrait
        case .landscape:
            updated.mode = .fill
            updated.zoom = 1.1
            updated.focalPoint = CGPoint(x: 0.5, y: 0.5)
            updated.calibrationPreset = .landscape
        case .safe:
            updated.mode = .fit
            updated.zoom = 1.0
            updated.focalPoint = CGPoint(x: 0.5, y: 0.5)
            updated.calibrationPreset = nil
        }

        updated.fullBleed = true
        switch slot {
        case .a:
            recipeA = updated
            presetSelectionA = preset
        case .b:
            recipeB = updated
            presetSelectionB = preset
        }
    }

    func saveRecipe(for slot: CalibrationSlot) {
        let media: MediaDoc?
        let recipe: MediaPresentationRecipe
        let previewFocalPoint: CGPoint
        switch slot {
        case .a:
            media = mediaA
            recipe = recipeA
            previewFocalPoint = previewFocalPointA
        case .b:
            media = mediaB
            recipe = recipeB
            previewFocalPoint = previewFocalPointB
        }

        guard let media else { return }
        let clamped = MediaPresentationMath.clamped(recipe)
        let clampedPreviewFocal = Self.clampedFocalPoint(previewFocalPoint)
        let payload: [String: Any] = [
            "presentation_v1": [
                "version": 1,
                "mode": clamped.mode.rawValue,
                "zoom": clamped.zoom,
                "focalPoint": [
                    "x": clamped.focalPoint.x,
                    "y": clamped.focalPoint.y
                ],
                "previewFocalPoint": [
                    "x": clampedPreviewFocal.x,
                    "y": clampedPreviewFocal.y
                ],
                "fullBleed": true,
                "preset": clamped.calibrationPreset?.rawValue ?? "unknown",
                "updatedAt": FieldValue.serverTimestamp()
            ]
        ]

        updateSaveState(.saving, for: slot)
        db.collection("media").document(media.id).setData(payload, merge: true) { [weak self] error in
            guard let self else { return }
            if let error {
                self.updateSaveState(.error("Error: \(error.localizedDescription)"), for: slot)
            } else {
                self.updateSaveState(.saved, for: slot)
            }
        }
    }

    private func updateSaveState(_ state: CalibrationSaveState, for slot: CalibrationSlot) {
        switch slot {
        case .a: saveStateA = state
        case .b: saveStateB = state
        }
    }

    private func fetchNeedsReviewCandidates(completion: @escaping (Result<[MediaDoc], Error>) -> Void) {
        let baseQuery = db.collection("media")
            .whereField("presentation_v1.needsReview", isEqualTo: true)
            .whereField("url", isGreaterThan: "")
            .limit(to: 50)

        baseQuery.getDocuments { snapshot, error in
            if let error {
                completion(.failure(error))
                return
            }
            let docs = (snapshot?.documents ?? []).compactMap(Self.parseMediaDoc)
            completion(.success(docs))
        }
    }

    private func fetchFallbackCandidates(completion: @escaping ([MediaDoc]) -> Void) {
        let queryWithUrl = db.collection("media")
            .whereField("url", isGreaterThan: "")
            .limit(to: 50)

        queryWithUrl.getDocuments { snapshot, error in
            if let _ = error {
                let fallback = self.db.collection("media").limit(to: 50)
                fallback.getDocuments { snap, _ in
                    let docs = (snap?.documents ?? []).compactMap(Self.parseMediaDoc)
                    completion(docs.filter { !$0.url.isEmpty })
                }
                return
            }

            let docs = (snapshot?.documents ?? []).compactMap(Self.parseMediaDoc)
            completion(docs)
        }
    }

    private func selectPair(from docs: [MediaDoc]) {
        let prioritized = docs.sorted { lhs, rhs in
            (lhs.recipe == nil) && (rhs.recipe != nil)
        }
        let unseen = prioritized.filter { !seenThisSession.contains($0.id) }
        guard unseen.count >= 2, let pair = pickPair(from: unseen) else {
            statusMessage = "No new media available this session."
            return
        }

        seenThisSession.insert(pair.0.id)
        seenThisSession.insert(pair.1.id)
        mediaA = pair.0
        mediaB = pair.1
        recipeA = pair.0.recipe ?? Self.defaultRecipe
        recipeB = pair.1.recipe ?? Self.defaultRecipe
        previewFocalPointA = pair.0.previewFocalPoint ?? recipeA.focalPoint
        previewFocalPointB = pair.1.previewFocalPoint ?? recipeB.focalPoint
        presetSelectionA = presetSelection(from: recipeA)
        presetSelectionB = presetSelection(from: recipeB)
        statusMessage = nil
        saveStateA = .idle
        saveStateB = .idle

        loadImage(for: pair.0, slot: .a)
        loadImage(for: pair.1, slot: .b)
    }

    private func pickPair(from docs: [MediaDoc]) -> (MediaDoc, MediaDoc)? {
        guard docs.count >= 2 else { return nil }
        var candidates = docs.shuffled()
        let first = candidates.removeFirst()
        guard let second = candidates.first(where: { $0.id != first.id }) else {
            return nil
        }
        return (first, second)
    }

    private func loadImage(for doc: MediaDoc, slot: CalibrationSlot) {
        guard let url = URL(string: doc.url) else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = MediaImageLoader.normalizedImage(from: data) else { return }
                await MainActor.run {
                    switch slot {
                    case .a: self.imageA = image
                    case .b: self.imageB = image
                    }
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = "Failed to load image."
                }
            }
        }
    }

    private static func parseMediaDoc(_ doc: QueryDocumentSnapshot) -> MediaDoc? {
        guard let url = doc.data()["url"] as? String else { return nil }
        let presentation = doc.data()["presentation_v1"] as? [String: Any]
        let recipe = parseRecipe(from: presentation)
        let previewFocalPoint = parseFocalPoint(from: presentation, key: "previewFocalPoint")
        return MediaDoc(
            id: doc.documentID,
            url: url,
            recipe: recipe,
            previewFocalPoint: previewFocalPoint
        )
    }

    private static func parseRecipe(from map: [String: Any]?) -> MediaPresentationRecipe? {
        guard let map else { return nil }
        let modeRaw = map["mode"] as? String ?? MediaPresentationMode.fit.rawValue
        let mode = MediaPresentationMode(rawValue: modeRaw) ?? .fit
        let zoom = map["zoom"] as? CGFloat ?? CGFloat(map["zoom"] as? Double ?? 1.0)
        let focalPoint = parseFocalPoint(from: map, key: "focalPoint") ?? CGPoint(x: 0.5, y: 0.5)
        let fullBleed = map["fullBleed"] as? Bool ?? true
        let version = map["version"] as? Int ?? 1
        let presetRaw = map["preset"] as? String
        let preset = presetRaw.flatMap { CalibrationPreset(rawValue: $0) }

        return MediaPresentationRecipe(
            version: version,
            mode: mode,
            zoom: zoom,
            focalPoint: focalPoint,
            fullBleed: fullBleed,
            calibrationPreset: preset
        )
    }

    private static func parseFocalPoint(from map: [String: Any]?, key: String) -> CGPoint? {
        guard let map, let focal = map[key] as? [String: Any] else { return nil }
        let focalX = focal["x"] as? CGFloat ?? CGFloat(focal["x"] as? Double ?? 0.5)
        let focalY = focal["y"] as? CGFloat ?? CGFloat(focal["y"] as? Double ?? 0.5)
        return CGPoint(x: focalX, y: focalY)
    }

    private static func clampedFocalPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), 1),
            y: min(max(point.y, 0), 1)
        )
    }

    private func presetSelection(from recipe: MediaPresentationRecipe) -> CalibrationPresetSelection {
        switch recipe.calibrationPreset {
        case .portrait: return .portrait
        case .landscape: return .landscape
        case .none: return .safe
        }
    }
}

struct MediaDoc: Equatable {
    let id: String
    let url: String
    let recipe: MediaPresentationRecipe?
    let previewFocalPoint: CGPoint?
}

enum CalibrationSaveState: Equatable {
    case idle
    case saving
    case saved
    case error(String)

    var message: String {
        switch self {
        case .idle:
            return ""
        case .saving:
            return "Saving..."
        case .saved:
            return "Saved ✅"
        case .error(let message):
            return message
        }
    }

    var isError: Bool {
        if case .error = self { return true }
        return false
    }
}
