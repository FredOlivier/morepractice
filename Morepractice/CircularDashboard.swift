//  CircularDashboard.swift
//  Morepractice
//
//  2025‑04‑22 – UI facelift:
//  • Uses Apple‑style rounded semibold system font for all captions
//  • Outer buttons are slightly larger (200 × 200 → nicer balance)
//  • No behavioural changes or navigation tweaks
//
//  2025‑05‑01 – Animated borders (toggle via SettingsManager.animatedBordersEnabled)
//  • Center (Explore): rainbow angular gradient rotating slowly
//  • Outer buttons: color‑family gradient rotating slowly
//

import SwiftUI

/// Arranges five circular buttons (“Me”, “Connections”, “Upload”, “Modes”,
/// “Explore”) in a scroll‑wheel layout.
struct CircularDashboard: View {

    // ---------------------------------------------------------------------
    // MARK: Environment
    // ---------------------------------------------------------------------
    @Environment(\.colorScheme)                   var colorScheme
    @EnvironmentObject var authViewModel:         AuthViewModel
    @EnvironmentObject var scoreManager:          ScoreManager
    @EnvironmentObject var mediaManager:          MediaManager
    @EnvironmentObject var appViewModel:          AppViewModel
    @EnvironmentObject var settingsManager:       SettingsManager
    @EnvironmentObject var linkingSettingsManager:LinkingSettingsManager

    // ---------------------------------------------------------------------
    // MARK: Constants
    // ---------------------------------------------------------------------
    private let buttons: [DashboardButton] = [
        .init(label: "Me",          systemImage: "person.circle.fill"),
        .init(label: "Connections", systemImage: "person.3.fill"),
        .init(label: "Upload",      systemImage: "square.and.arrow.up.fill"),
        .init(label: "Modes",       systemImage: "slider.horizontal.3"),
        .init(label: "Explore",     systemImage: "magnifyingglass.circle.fill")
    ]

    /// Rounded, bold font applied to every caption
    private let dashboardLabelFont =
        Font.system(size: 16, weight: .semibold, design: .rounded)

    /// Diameter for the four outer buttons (Explore keeps its original 220 pt)
    private let outerButtonDiameter: CGFloat = 200     // <‑‑ was 180

    // ---------------------------------------------------------------------
    // MARK: Background state
    // ---------------------------------------------------------------------
    @State private var backgroundGradients: [GradientWithBrightness] = []
    @State private var exploreGradientColors: [Color] = [
        CircularDashboard.randomColor(), CircularDashboard.randomColor()
    ]

    // ---------------------------------------------------------------------
    // MARK: Animation state (borders)
    // ---------------------------------------------------------------------
    @State private var borderPhase: Double = 0

    // ---------------------------------------------------------------------
    // MARK: Body
    // ---------------------------------------------------------------------
    var body: some View {
        GeometryReader { geo in
            ZStack {
                //---------------------------------------------------------
                // 1) pastel gradient blobs
                //---------------------------------------------------------
                ForEach(backgroundGradients) { g in
                    Circle()
                        .fill(g.gradient)
                        .frame(width: max(geo.size.width,  geo.size.height) * 1.5,
                               height:max(geo.size.width,  geo.size.height) * 1.5)
                        .offset(x: .random(in: -50...50),
                                y: .random(in: -50...50))
                        .blur(radius: 20)
                }

                //---------------------------------------------------------
                // 2) faint grey backdrop
                //---------------------------------------------------------
                Circle()
                    .fill(colorScheme == .dark
                          ? Color.white.opacity(0.05)
                          : Color.black.opacity(0.05))
                    .frame(width: max(geo.size.width, geo.size.height) * 1.2,
                           height:max(geo.size.width, geo.size.height) * 1.2)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                //---------------------------------------------------------
                // 3) Title
                //---------------------------------------------------------
                VStack {
                    Text("iMore")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.primary)
                        .padding(.top, 95)
                    Spacer()
                }

                //---------------------------------------------------------
                // 4) Centre “Explore”
                //---------------------------------------------------------
                dashboardButton(buttons[4], isCenter: true)
                    .frame(width: 220, height: 220)
                    .overlay(centerAnimatedBorder)
                    .zIndex(1)

                //---------------------------------------------------------
                // 5) Outer four
                //---------------------------------------------------------
                ForEach(0..<4) { idx in
                    let b = buttons[idx]
                    dashboardButton(b, isCenter: false)
                        .frame(width: outerButtonDiameter,
                               height: outerButtonDiameter)
                        .overlay(outerAnimatedBorder(for: idx))
                        .offset(x: offsetX(for: idx, in: geo),
                                y: offsetY(for: idx, in: geo))
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            // inject rounded font into entire hierarchy
            .environment(\.font, dashboardLabelFont)
            .onAppear {
                backgroundGradients = (0..<3).map { _ in
                    CircularDashboard.randomGradientWithBrightness()
                }.sorted { $0.brightness < $1.brightness }
                startOrStopBorderAnimation()
            }
            .onChange(of: settingsManager.animatedBordersEnabled) { _ in
                startOrStopBorderAnimation()
            }
        }
    }

    // Start/stop the continuous border animation based on settings
    private func startOrStopBorderAnimation() {
        if settingsManager.animatedBordersEnabled {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                // animate phase across 0...1 (rotation uses degrees)
                borderPhase = 1
            }
        } else {
            // snap back to 0 and remove implicit animation
            withAnimation(.none) {
                borderPhase = 0
            }
        }
    }

    // ---------------------------------------------------------------------
    // MARK: Geometry helpers
    // ---------------------------------------------------------------------
    private func offsetX(for idx: Int, in geo: GeometryProxy) -> CGFloat {
        let angle = angleForButton(idx)
        let radius = min(geo.size.width, geo.size.height) * 0.4
        return CGFloat(cos(angle) * radius)
    }

    private func offsetY(for idx: Int, in geo: GeometryProxy) -> CGFloat {
        let angle = angleForButton(idx)
        let radius = min(geo.size.width, geo.size.height) * 0.4
        return CGFloat(sin(angle) * radius)
    }

    private func angleForButton(_ idx: Int) -> Double {
        switch idx {
        case 0: return  45.0.degreesToRadians   // top‑left
        case 1: return 135.0.degreesToRadians   // bottom‑left
        case 2: return 225.0.degreesToRadians   // bottom‑right
        case 3: return 315.0.degreesToRadians   // top‑right
        default: return 0
        }
    }

    // ---------------------------------------------------------------------
    // MARK: Animated border overlays
    // ---------------------------------------------------------------------
    // Center: full rainbow angular gradient that rotates
    private var centerAnimatedBorder: some View {
        Group {
            if settingsManager.animatedBordersEnabled {
                Circle()
                    .strokeBorder(rainbowGradient, lineWidth: 8)
                    .rotationEffect(.degrees(borderPhase * 360))
                    .opacity(colorScheme == .dark ? 0.9 : 0.85)
            } else {
                Circle()
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.25 : 0.2), lineWidth: 6)
            }
        }
    }

    // Outer: color-family gradient per index; rotates
    private func outerAnimatedBorder(for idx: Int) -> some View {
        Group {
            if settingsManager.animatedBordersEnabled {
                Circle()
                    .strokeBorder(colorFamilyGradient(for: idx), lineWidth: 6)
                    .rotationEffect(.degrees(borderPhase * 360))
                    .opacity(colorScheme == .dark ? 0.85 : 0.8)
            } else {
                Circle()
                    .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.18 : 0.15), lineWidth: 5)
            }
        }
    }

    // Build a rainbow AngularGradient
    private var rainbowGradient: AngularGradient {
        let colors: [Color] = [
            .red, .orange, .yellow, .green, .mint, .teal, .cyan, .blue, .indigo, .purple, .pink, .red
        ]
        return AngularGradient(gradient: Gradient(colors: colors),
                               center: .center)
    }

    // Build a color-family AngularGradient for an outer button:
    // Each index maps to a base color; we vary saturation/brightness slightly.
    private func colorFamilyGradient(for idx: Int) -> AngularGradient {
        let base: UIColor
        switch idx {
        case 0: base = UIColor.systemRed
        case 1: base = UIColor.systemYellow
        case 2: base = UIColor.systemBlue
        case 3: base = UIColor.systemGreen
        default: base = UIColor.systemGray
        }

        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        base.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

        // Build a small band of related colors by tweaking s/b
        func clamp(_ v: CGFloat) -> CGFloat { max(0, min(1, v)) }
        let s1 = clamp(s * 0.85)
        let s2 = clamp(s * 1.05)
        let b1 = clamp(b * 0.80)
        let b2 = clamp(b * 1.05)

        let c1 = Color(UIColor(hue: h, saturation: s1, brightness: b2, alpha: a))
        let c2 = Color(UIColor(hue: h, saturation: s2, brightness: b1, alpha: a))
        let c3 = Color(UIColor(hue: h, saturation: s,  brightness: b,  alpha: a))

        return AngularGradient(gradient: Gradient(colors: [c1, c3, c2, c1]),
                               center: .center)
    }

    // ---------------------------------------------------------------------
    // MARK: Button Factory
    // ---------------------------------------------------------------------
    private func dashboardButton(_ b: DashboardButton,
                                 isCenter: Bool) -> some View {
        Group {
            switch b.label {

            // --------------- Me ---------------
            case "Me":
                NavigationLink {
                    MeView()
                        .environmentObject(authViewModel)
                        .environmentObject(scoreManager)
                        .environmentObject(mediaManager)
                        .environmentObject(appViewModel)
                        .environmentObject(linkingSettingsManager)
                        .environmentObject(settingsManager)
                } label: {
                    styledCircle(b, isCenter, fill: .red.opacity(0.6))
                }

            // ----------- Connections ----------
            case "Connections":
                NavigationLink {
                    ConnectionsView()
                        .environmentObject(authViewModel)
                        .environmentObject(scoreManager)
                        .environmentObject(mediaManager)
                        .environmentObject(appViewModel)
                        .environmentObject(settingsManager)
                        .environmentObject(linkingSettingsManager)
                } label: {
                    styledCircle(b, isCenter, fill: .yellow.opacity(0.8))
                }

            // --------------- Upload -----------
            case "Upload":
                NavigationLink {
                    UploadOptionsView()
                        .environmentObject(authViewModel)
                        .environmentObject(settingsManager)
                        .environmentObject(appViewModel)
                        .environmentObject(linkingSettingsManager)
                } label: {
                    styledCircle(b, isCenter, fill: .blue.opacity(0.8))
                }

            // --------------- Modes ------------
            case "Modes":
                NavigationLink {
                    ModesView()
                        .environmentObject(authViewModel)
                        .environmentObject(scoreManager)
                        .environmentObject(mediaManager)
                        .environmentObject(appViewModel)
                        .environmentObject(settingsManager)
                        .environmentObject(linkingSettingsManager)
                } label: {
                    styledCircle(b, isCenter, fill: .green.opacity(0.8))
                }

            // -------------- Explore -----------
            case "Explore":
                NavigationLink {
                    MediaInteractionView()
                        .environmentObject(authViewModel)
                        .environmentObject(scoreManager)
                        .environmentObject(mediaManager)
                        .environmentObject(appViewModel)
                        .environmentObject(settingsManager)
                        .environmentObject(linkingSettingsManager)
                } label: {
                    ZStack {
                        Circle().fill(
                            LinearGradient(gradient: Gradient(colors: exploreGradientColors),
                                           startPoint: .topLeading,
                                           endPoint: .bottomTrailing)
                        )
                        iconAndCaption(for: b, isCenter: true, color: .white)
                    }
                }

            // ------------- fallback ----------
            default:
                Button { handleButtonTap(b) } label: {
                    styledCircle(b, isCenter, fill: Color.gray.opacity(0.5))
                }
            }
        }
        .accessibilityLabel(b.label)
        .accessibilityHint("Open \(b.label) section")
    }

    // styled circle with icon + caption
    private func styledCircle(_ b: DashboardButton,
                              _ isCenter: Bool,
                              fill: Color) -> some View {
        ZStack { Circle().fill(fill)
            iconAndCaption(for: b, isCenter: isCenter, color: .white)
        }
    }

    private func iconAndCaption(for b: DashboardButton,
                                isCenter: Bool,
                                color: Color) -> some View {
        ZStack(alignment: .top) {
            Image(systemName: b.systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: isCenter ? 50 : 44,
                       height:isCenter ? 50 : 44)
                .foregroundColor(color)

            if !isCenter {
                Text(b.label)
                    .foregroundColor(.primary)
                    .padding(.top, 90)   // adjusted for bigger circle
            }
        }
    }

    // Dummy tap‑handler placeholder
    private func handleButtonTap(_ b: DashboardButton) {
        print("\(b.label) tapped – not yet wired.")
    }
}

// ---------------------------------------------------------------------
// MARK: - Support Types / Helpers
// ---------------------------------------------------------------------
struct GradientWithBrightness: Identifiable {
    let id = UUID()
    let gradient: LinearGradient
    let brightness: Double
}

struct DashboardButton: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let systemImage: String
}

// ----------  random pastel generator ----------
extension CircularDashboard {
    static func randomGradientWithBrightness() -> GradientWithBrightness {
        var c1 = Color.randomPastel(), c2 = Color.randomPastel()
        if c1.brightness > c2.brightness { swap(&c1, &c2) }

        return GradientWithBrightness(
            gradient: LinearGradient(
                gradient: Gradient(colors: [c1, c2]),
                startPoint: .random(), endPoint: .random()),
            brightness: c1.brightness
        )
    }
    static func randomColor() -> Color { .randomPastel() }
}

extension Color {
    static func randomPastel() -> Color {
        Color(hue: .random(in: 0...1),
              saturation: .random(in: 0.25...0.55),
              brightness: .random(in: 0.7...0.9))
    }
    /// Extract perceived brightness [0‑1]
    var brightness: Double {
        var b: CGFloat = 0
        UIColor(self).getHue(nil, saturation:nil, brightness:&b, alpha:nil)
        return Double(b)
    }
}

extension UnitPoint {
    static func random() -> UnitPoint {
        .init(x: .random(in: 0...1), y: .random(in: 0...1))
    }
}

extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
}

// ---------------------------------------------------------------------
// MARK: - Preview
// ---------------------------------------------------------------------
struct CircularDashboard_Previews: PreviewProvider {
    static var previews: some View {
        let appVM      = AppViewModel()
        let settings   = SettingsManager()
        let linkingMgr = LinkingSettingsManager()

        CircularDashboard()
            .environmentObject(appVM.authViewModel)
            .environmentObject(appVM.scoreManager)
            .environmentObject(appVM.mediaManager)
            .environmentObject(appVM)
            .environmentObject(settings)
            .environmentObject(linkingMgr)
    }
}
