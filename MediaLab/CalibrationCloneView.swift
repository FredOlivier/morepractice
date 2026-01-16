//
//  CalibrationCloneView.swift
//  MediaLab
//
//  Created by Fred Olivier on 16/01/2026.
//

import SwiftUI
import MediaKit
import UIKit

struct CalibrationCloneView: View {
    @StateObject private var viewModel = CalibrationViewModel()
    @State private var layoutMode: CalibrationLayoutMode = .sideBySide

    var body: some View {
        ZStack {
            layoutContent
                .ignoresSafeArea()

            headerControls
        }
        .onAppear {
            viewModel.loadNextPair()
        }
    }

    private var layoutContent: some View {
        Group {
            switch layoutMode {
            case .sideBySide:
                HStack(spacing: 0) {
                    mediaPane(for: .a, usePreviewFocalPoint: false)
                    mediaPane(for: .b, usePreviewFocalPoint: false)
                }
            case .stacked:
                VStack(spacing: 0) {
                    mediaPane(for: .a, usePreviewFocalPoint: false)
                    mediaPane(for: .b, usePreviewFocalPoint: false)
                }
            case .preview:
                mediaPane(for: viewModel.previewSlot, usePreviewFocalPoint: true)
            }
        }
        .background(Color.black)
    }

    @ViewBuilder
    private func mediaPane(for slot: CalibrationSlot, usePreviewFocalPoint: Bool) -> some View {
        let content = viewModel.content(for: slot)
        let focalPoint: Binding<CGPoint>
        switch slot {
        case .a:
            focalPoint = usePreviewFocalPoint
                ? $viewModel.previewFocalPointA
                : Binding(
                    get: { viewModel.recipeA.focalPoint },
                    set: { viewModel.recipeA.focalPoint = $0 }
                )
        case .b:
            focalPoint = usePreviewFocalPoint
                ? $viewModel.previewFocalPointB
                : Binding(
                    get: { viewModel.recipeB.focalPoint },
                    set: { viewModel.recipeB.focalPoint = $0 }
                )
        }
        switch slot {
        case .a:
            CalibrationImagePane(
                content: content,
                recipe: $viewModel.recipeA,
                focalPoint: focalPoint,
                presetSelection: $viewModel.presetSelectionA,
                saveState: viewModel.saveState(for: .a),
                onPreset: { viewModel.applyPreset($0, for: .a) },
                onConfirm: { viewModel.saveRecipe(for: .a) }
            )
        case .b:
            CalibrationImagePane(
                content: content,
                recipe: $viewModel.recipeB,
                focalPoint: focalPoint,
                presetSelection: $viewModel.presetSelectionB,
                saveState: viewModel.saveState(for: .b),
                onPreset: { viewModel.applyPreset($0, for: .b) },
                onConfirm: { viewModel.saveRecipe(for: .b) }
            )
        }
    }

    private var headerControls: some View {
        VStack(spacing: 8) {
            HStack {
                Picker("Layout", selection: $layoutMode) {
                    ForEach(CalibrationLayoutMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if layoutMode == .preview {
                    Picker("Preview", selection: $viewModel.previewSlot) {
                        Text("A").tag(CalibrationSlot.a)
                        Text("B").tag(CalibrationSlot.b)
                    }
                    .pickerStyle(.segmented)
                }

                Button("Next Pair") {
                    viewModel.loadNextPair()
                }
                .buttonStyle(.bordered)
            }
            .padding(12)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if let status = viewModel.statusMessage {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
            }
        }
        .padding(.top, 12)
        .padding(.horizontal, 12)
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

enum CalibrationLayoutMode: CaseIterable {
    case sideBySide
    case stacked
    case preview

    var title: String {
        switch self {
        case .sideBySide: return "Side-by-side"
        case .stacked: return "Stacked"
        case .preview: return "Preview"
        }
    }
}

enum CalibrationSlot {
    case a
    case b
}

struct CalibrationContent: Equatable {
    let id: String?
    let image: UIImage?
    let label: String
}

private struct CalibrationImagePane: View {
    let content: CalibrationContent
    @Binding var recipe: MediaPresentationRecipe
    @Binding var focalPoint: CGPoint
    @Binding var presetSelection: CalibrationPresetSelection
    let saveState: CalibrationSaveState
    let onPreset: (CalibrationPresetSelection) -> Void
    let onConfirm: () -> Void

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black

                if let image = content.image {
                    CalibratedImageView(
                        image: image,
                        containerSize: proxy.size,
                        recipe: recipe,
                        focalPoint: focalPoint
                    )
                } else {
                    ProgressView()
                        .tint(.white)
                }

                CalibrationGestureLayer(
                    size: proxy.size,
                    recipe: $recipe,
                    focalPoint: $focalPoint
                )

                calibrationOverlay
                    .zIndex(1)
            }
        }
        .clipped()
        .contentShape(Rectangle())
    }

    private var calibrationOverlay: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                ForEach(CalibrationPresetSelection.allCases, id: \.self) { preset in
                    Button(preset.title) {
                        onPreset(preset)
                    }
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .foregroundStyle(.white)
                    .background(presetSelection == preset ? Color.white.opacity(0.12) : Color.black.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                Color.white.opacity(presetSelection == preset ? 0.6 : 0.3),
                                lineWidth: 1
                            )
                    )
                }
            }

            HStack(spacing: 8) {
                Text("Zoom")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Slider(
                    value: Binding(
                        get: { recipe.zoom },
                        set: { recipe.zoom = MediaPresentationMath.clamped(
                            MediaPresentationRecipe(
                                version: recipe.version,
                                mode: recipe.mode,
                                zoom: $0,
                                focalPoint: recipe.focalPoint,
                                fullBleed: recipe.fullBleed,
                                calibrationPreset: recipe.calibrationPreset
                            )
                        ).zoom }
                    ),
                    in: MediaPresentationMath.zoomRange
                )
            }

            HStack(spacing: 12) {
                Button("Confirm") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)

                Text(saveState.message)
                    .font(.caption)
                    .foregroundStyle(saveState.isError ? .red : .green)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.horizontal, 8)
        .padding(.bottom, 12)
    }
}

private struct CalibrationGestureLayer: View {
    let size: CGSize
    @Binding var recipe: MediaPresentationRecipe
    @Binding var focalPoint: CGPoint
    @State private var pinchStartZoom: CGFloat?

    var body: some View {
        ZStack {
            CrosshairView()
                .position(
                    x: size.width * focalPoint.x,
                    y: size.height * focalPoint.y
                )
        }
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .gesture(magnificationGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let x = min(max(0, value.location.x), size.width)
                let y = min(max(0, value.location.y), size.height)
                focalPoint = CGPoint(
                    x: size.width > 0 ? x / size.width : 0.5,
                    y: size.height > 0 ? y / size.height : 0.5
                )
                focalPoint = clampedFocalPoint(focalPoint)
            }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                if pinchStartZoom == nil {
                    pinchStartZoom = recipe.zoom
                }
                let baseZoom = pinchStartZoom ?? recipe.zoom
                let nextZoom = baseZoom * value
                recipe.zoom = MediaPresentationMath.clamped(
                    MediaPresentationRecipe(
                        version: recipe.version,
                        mode: recipe.mode,
                        zoom: nextZoom,
                        focalPoint: recipe.focalPoint,
                        fullBleed: recipe.fullBleed,
                        calibrationPreset: recipe.calibrationPreset
                    )
                ).zoom
            }
            .onEnded { _ in
                pinchStartZoom = nil
            }
    }

    private func clampedFocalPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), 1),
            y: min(max(point.y, 0), 1)
        )
    }
}

private struct CalibratedImageView: View {
    let image: UIImage
    let containerSize: CGSize
    let recipe: MediaPresentationRecipe
    let focalPoint: CGPoint

    var body: some View {
        let clamped = MediaPresentationMath.clamped(recipe)
        let clampedFocalPoint = CGPoint(
            x: min(max(focalPoint.x, 0), 1),
            y: min(max(focalPoint.y, 0), 1)
        )
        let scaledSize = MediaPresentationMath.scaledSize(
            contentSize: image.size,
            containerSize: containerSize,
            mode: clamped.mode,
            zoom: clamped.zoom
        )
        let offset = MediaPresentationMath.offset(
            containerSize: containerSize,
            scaledContentSize: scaledSize,
            focalPoint: clampedFocalPoint
        )

        Image(uiImage: image)
            .resizable()
            .frame(width: scaledSize.width, height: scaledSize.height)
            .offset(offset)
            .frame(width: containerSize.width, height: containerSize.height)
            .clipped()
    }
}

private struct CrosshairView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.9), lineWidth: 1)
                .frame(width: 18, height: 18)
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 1, height: 26)
            Rectangle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 26, height: 1)
        }
        .shadow(radius: 2)
    }
}

enum CalibrationPresetSelection: CaseIterable, Hashable {
    case portrait
    case landscape
    case safe

    var title: String {
        switch self {
        case .portrait: return "Portrait preset"
        case .landscape: return "Landscape preset"
        case .safe: return "Safe (fit)"
        }
    }

}
