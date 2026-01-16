//
//  Color+Hex.swift
//  Morepractice
//
//  Created by Fred Olivier on 25/10/2025.
//

import Foundation
import SwiftUI

public extension Color {
  /// Initialize from `#RRGGBB` or `#RRGGBBAA` (case-insensitive, leading `#` optional).
  init?(hex: String) {
    var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if s.hasPrefix("#") { s.removeFirst() }
    guard s.count == 6 || s.count == 8 else { return nil }

    var v: UInt64 = 0
    guard Scanner(string: s).scanHexInt64(&v) else { return nil }

    let r, g, b, a: Double
    if s.count == 8 {
      r = Double((v & 0xFF000000) >> 24) / 255.0
      g = Double((v & 0x00FF0000) >> 16) / 255.0
      b = Double((v & 0x0000FF00) >> 8)  / 255.0
      a = Double( v & 0x000000FF)       / 255.0
    } else {
      r = Double((v & 0xFF0000) >> 16) / 255.0
      g = Double((v & 0x00FF00) >> 8)  / 255.0
      b = Double( v & 0x0000FF)        / 255.0
      a = 1.0
    }

    self = Color(red: r, green: g, blue: b, opacity: a)
  }

  /// Convert to `#RRGGBBAA` when possible (UIKit-backed platforms).
  func toHexRGBA() -> String? {
    #if canImport(UIKit)
    let ui = UIColor(self)
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
    let rr = Int(round(r * 255))
    let gg = Int(round(g * 255))
    let bb = Int(round(b * 255))
    let aa = Int(round(a * 255))
    return String(format: "#%02X%02X%02X%02X", rr, gg, bb, aa)
    #else
    return nil
    #endif
  }
}
