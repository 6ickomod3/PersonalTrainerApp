import SwiftUI

enum Theme {
    static let accent = Color(red: 0.78, green: 0.49, blue: 0.36)
    static let primaryAction = accent
    static let dataHighlight = Color(red: 0.45, green: 0.55, blue: 0.65)
    static let timerActive = dataHighlight
    static let success = Color(red: 0.20, green: 0.66, blue: 0.33)
    static let innerCardBackground = Color(.secondarySystemGroupedBackground)
    static let cardRadius: CGFloat = 16
    static let innerRadius: CGFloat = 12
    static let sectionSpacing: CGFloat = 24
    static let itemSpacing: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let cardStroke = LinearGradient(
        colors: [Color.white.opacity(0.12), Color.clear],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct ThemeCard: ViewModifier {
    var radius: CGFloat = Theme.cardRadius

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).stroke(Theme.cardStroke, lineWidth: 1))
    }
}

extension View {
    func themeCard(radius: CGFloat = Theme.cardRadius) -> some View {
        modifier(ThemeCard(radius: radius))
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    var subtitle: String? = nil
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage).font(.title).foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(title).font(.headline).multilineTextAlignment(.center)
            if let subtitle {
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .buttonStyle(.borderedProminent)
                    .frame(minHeight: 44)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
}
