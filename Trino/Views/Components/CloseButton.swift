import SwiftUI

/// Wraps iOS 26's native Button(role: .close) — no SF Symbol, system-rendered appearance.
/// Usage: CloseButton { dismiss() }
struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        Button(role: .close, action: action)
    }
}
