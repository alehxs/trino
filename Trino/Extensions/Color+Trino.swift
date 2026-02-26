import SwiftUI

extension Color {
    /// Legacy alias — kept so existing call-sites compile while we migrate.
    static let trinoOrange = Color(red: 1.0, green: 107 / 255.0, blue: 53 / 255.0)
}

// MARK: - AppTheme

enum AppTheme: String, CaseIterable {
    case orange, green, teal

    var accent: Color {
        switch self {
        case .orange: return Color(red: 1.0,  green: 107/255.0, blue: 53/255.0)
        case .green:  return Color(red: 0.20, green: 0.75,      blue: 0.45)
        case .teal:   return Color(red: 0.17, green: 0.72,      blue: 0.68)
        }
    }

    /// Light intensity (1 / 3 completions)
    var intensity1: Color {
        switch self {
        case .orange: return Color(red: 1.0, green: 180/255, blue: 150/255)
        default:      return accent.opacity(0.30)
        }
    }

    /// Mid intensity (2 / 3 completions)
    var intensity2: Color {
        switch self {
        case .orange: return Color(red: 1.0, green: 140/255, blue: 90/255)
        default:      return accent.opacity(0.60)
        }
    }

    /// Full intensity (3 / 3 completions) — same as accent
    var intensity3: Color { accent }

    var displayName: String { rawValue.capitalized }
}
