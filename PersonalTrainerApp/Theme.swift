import SwiftUI

// MARK: - Sigma Training Design System
// Earthy, modern aesthetic with consistent tokens across all views.

enum Theme {

    // MARK: - Categorical Colors (content domain — never use for chrome)

    /// Strength category — warm terracotta. Also brand/app tint.
    static let accent = Color(red: 0.78, green: 0.49, blue: 0.36)          // #C67C5B

    /// Cardio category — deep forest green. Pushed away from sage so it
    /// reads distinctly from the success checkmark color.
    static let cardio = Color(red: 0.31, green: 0.55, blue: 0.40)          // #4F8C66

    /// Warm-up category — golden saffron. Yellower/more saturated so it
    /// no longer blurs against the terracotta accent.
    static let warmup = Color(red: 0.91, green: 0.65, blue: 0.21)          // #E8A636

    /// Cool-down category — deeper teal. Pushed away from gray so it reads
    /// as a clear category color, not a muted UI color.
    static let cooldown = Color(red: 0.20, green: 0.55, blue: 0.62)        // #338C9E

    // MARK: - Functional Colors (UI semantics — never use as a category)

    /// Primary action chrome. Currently aliased to `accent` for brand
    /// consistency, but kept as a separate token so action buttons can
    /// diverge from the Strength category without a sweep.
    static let primaryAction = accent

    /// Data emphasis — volume totals, chart series, numeric highlights.
    /// The only cool color in the palette; reserve for data, not state.
    static let dataHighlight = Color(red: 0.45, green: 0.55, blue: 0.65)   // #738CA6

    /// Timer active-state indicator (countdown text while running).
    /// Same hue as dataHighlight today, but a distinct token so the timer
    /// can evolve without touching chart code.
    static let timerActive = dataHighlight

    /// Completion checkmarks (logged today). Vivid green, distinct from cardio.
    static let success = Color(red: 0.20, green: 0.66, blue: 0.33)         // #33A854

    /// Destructive action chrome. Use sparingly — most destructive buttons
    /// use SwiftUI's `role: .destructive` which already gets system red.
    static let destructive = Color.red

    /// Subtle text/icons on earthy backgrounds — chevrons, dividers.
    static let muted = Color(red: 0.60, green: 0.56, blue: 0.52)           // #998F85

    /// Unchecked / inactive state
    static let inactive = Color.gray.opacity(0.3)
    
    // MARK: - Gradients
    
    /// Primary section header gradient (strength)
    static let accentGradient = LinearGradient(
        colors: [accent, Color(red: 0.65, green: 0.40, blue: 0.30)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Card stroke overlay
    static let cardStroke = LinearGradient(
        colors: [Color.white.opacity(0.12), Color.clear],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    /// Cardio section stroke
    static let cardioStroke = LinearGradient(
        colors: [cardio.opacity(0.3), cooldown.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Surface & Materials
    
    /// Standard card background (use on all card-like surfaces)
    static let cardBackground: Material = .ultraThinMaterial
    
    /// Elevated card background for inner items (history sets, daily logs)
    static let innerCardBackground = Color(.secondarySystemGroupedBackground)
    
    // MARK: - Corner Radii
    
    /// Outer cards (muscle group cards, cardio card, calendar container)
    static let cardRadius: CGFloat = 16
    
    /// Inner elements (history items, log cells, chart containers, duration capsules)
    static let innerRadius: CGFloat = 12
    
    // MARK: - Spacing
    
    /// Between major sections on a screen
    static let sectionSpacing: CGFloat = 24
    
    /// Within a section (between cards/rows)
    static let itemSpacing: CGFloat = 12
    
    /// Inside cards (content padding)
    static let cardPadding: CGFloat = 16
    
    /// Small gap between label and subtitle
    static let labelSpacing: CGFloat = 4
    
    // MARK: - Reusable View Modifiers
}

// MARK: - Card Style Modifier

struct ThemeCard: ViewModifier {
    var radius: CGFloat = Theme.cardRadius
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(Theme.cardStroke, lineWidth: 1)
            )
    }
}

extension View {
    /// Applies the standard earthy card style (material background + subtle stroke)
    func themeCard(radius: CGFloat = Theme.cardRadius) -> some View {
        modifier(ThemeCard(radius: radius))
    }
}

// MARK: - EmptyStateView

/// Reusable empty-state for sections with no content yet.
/// Icon + title + optional subtitle + optional capsule action.
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    var subtitle: String? = nil
    var actionLabel: String? = nil
    var actionTint: Color = Theme.accent
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title)
                .foregroundStyle(.secondary)

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(actionTint.opacity(0.2)))
                    .foregroundStyle(actionTint)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}
