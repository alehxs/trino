import UIKit

@MainActor
enum AppIconService {

    /// Switches the home-screen icon to match the given theme.
    /// - Orange maps to the primary icon (nil name).
    /// - No-ops if the icon is already correct or alternate icons aren't supported.
    static func apply(theme: AppTheme) {
        guard UIApplication.shared.supportsAlternateIcons else { return }

        let targetName: String? = switch theme {
        case .orange: nil
        case .green:  "AppIconGreen"
        case .teal:   "AppIconTeal"
        }

        guard UIApplication.shared.alternateIconName != targetName else { return }

        // Completion runs on an arbitrary queue — do not access @MainActor state here.
        UIApplication.shared.setAlternateIconName(targetName) { error in
            if let error {
                print("[AppIconService] Failed to set icon: \(error.localizedDescription)")
            }
        }
    }
}
