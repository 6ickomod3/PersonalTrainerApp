import SwiftUI

// MARK: - Sigma Training Design System
// Earthy, modern aesthetic with consistent tokens across all views.

enum Theme {
    
    // MARK: - Core Palette (Earthy Tones)
    
    /// Primary accent — warm terracotta for strength/exercises
    static let accent = Color(red: 0.78, green: 0.49, blue: 0.36)          // #C67C5B
    
    /// Secondary accent — sage green for cardio/success
    static let secondary = Color(red: 0.48, green: 0.62, blue: 0.49)       // #7A9E7E
    
    /// Warm-up tint — amber clay
    static let warmup = Color(red: 0.83, green: 0.57, blue: 0.37)          // #D4915E
    
    /// Cool-down tint — dusty teal
    static let cooldown = Color(red: 0.42, green: 0.62, blue: 0.64)        // #6B9EA3
    
    /// Cardio tint — olive sage
    static let cardio = Color(red: 0.56, green: 0.66, blue: 0.47)          // #8FA878

    /// Chart/volume highlight — muted slate blue
    static let highlight = Color(red: 0.45, green: 0.55, blue: 0.65)       // #738CA6
    
    /// Subtle text/icons on earthy backgrounds
    static let muted = Color(red: 0.60, green: 0.56, blue: 0.52)           // #998F85
    
    // MARK: - Semantic Colors
    
    /// Completion checkmarks
    static let success = secondary
    
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
