import SwiftUI

// MARK: - Color Palette

/// Defines the color scheme for the application.
struct ColorPalette {
    let primary: Color
    let onPrimary: Color
    let primaryContainer: Color
    let onPrimaryContainer: Color
    let secondary: Color
    let onSecondary: Color
    let secondaryContainer: Color
    let onSecondaryContainer: Color
    let tertiary: Color
    let onTertiary: Color
    let tertiaryContainer: Color
    let onTertiaryContainer: Color
    let error: Color
    let errorContainer: Color
    let onError: Color
    let onErrorContainer: Color
    let background: Color
    let onBackground: Color
    let surface: Color
    let onSurface: Color
    let surfaceVariant: Color
    let onSurfaceVariant: Color
    let outline: Color
    let inverseOnSurface: Color
    let inverseSurface: Color
    let inversePrimary: Color

    // MARK: - Light Color Scheme
    static let lightPalette = ColorPalette(
        primary: Color(red: 0.0, green: 0.47, blue: 0.84), // md_theme_light_primary
        onPrimary: Color(red: 1.0, green: 1.0, blue: 1.0), // md_theme_light_onPrimary
        primaryContainer: Color(red: 0.76, green: 0.89, blue: 1.0), // md_theme_light_primaryContainer
        onPrimaryContainer: Color(red: 0.0, green: 0.19, blue: 0.31), // md_theme_light_onPrimaryContainer
        secondary: Color(red: 0.33, green: 0.69, blue: 0.33), // md_theme_light_secondary
        onSecondary: Color(red: 1.0, green: 1.0, blue: 1.0), // md_theme_light_onSecondary
        secondaryContainer: Color(red: 0.84, green: 0.97, blue: 0.84), // md_theme_light_secondaryContainer
        onSecondaryContainer: Color(red: 0.0, green: 0.21, blue: 0.0), // md_theme_light_onSecondaryContainer
        tertiary: Color(red: 0.5, green: 0.25, blue: 0.75), // md_theme_light_tertiary
        onTertiary: Color(red: 1.0, green: 1.0, blue: 1.0), // md_theme_light_onTertiary
        tertiaryContainer: Color(red: 0.9, green: 0.8, blue: 1.0), // md_theme_light_tertiaryContainer
        onTertiaryContainer: Color(red: 0.2, green: 0.0, blue: 0.3), // md_theme_light_onTertiaryContainer
        error: Color(red: 0.73, green: 0.13, blue: 0.13), // md_theme_light_error
        errorContainer: Color(red: 1.0, green: 0.89, blue: 0.89), // md_theme_light_errorContainer
        onError: Color(red: 1.0, green: 1.0, blue: 1.0), // md_theme_light_onError
        onErrorContainer: Color(red: 0.25, green: 0.0, blue: 0.0), // md_theme_light_onErrorContainer
        background: Color(red: 0.98, green: 0.98, blue: 0.98), // md_theme_light_background
        onBackground: Color(red: 0.11, green: 0.11, blue: 0.11), // md_theme_light_onBackground
        surface: Color(red: 0.98, green: 0.98, blue: 0.98), // md_theme_light_surface
        onSurface: Color(red: 0.11, green: 0.11, blue: 0.11), // md_theme_light_onSurface
        surfaceVariant: Color(red: 0.9, green: 0.9, blue: 0.9), // md_theme_light_surfaceVariant
        onSurfaceVariant: Color(red: 0.28, green: 0.28, blue: 0.28), // md_theme_light_onSurfaceVariant
        outline: Color(red: 0.45, green: 0.45, blue: 0.45), // md_theme_light_outline
        inverseOnSurface: Color(red: 0.94, green: 0.94, blue: 0.94), // md_theme_light_inverseOnSurface
        inverseSurface: Color(red: 0.2, green: 0.2, blue: 0.2), // md_theme_light_inverseSurface
        inversePrimary: Color(red: 0.6, green: 0.78, blue: 0.95) // md_theme_light_inversePrimary
    )

    // MARK: - Dark Color Scheme
    static let darkPalette = ColorPalette(
        primary: Color(red: 0.6, green: 0.78, blue: 0.95), // md_theme_dark_primary
        onPrimary: Color(red: 0.0, green: 0.32, blue: 0.53), // md_theme_dark_onPrimary
        primaryContainer: Color(red: 0.0, green: 0.47, blue: 0.84), // md_theme_dark_primaryContainer
        onPrimaryContainer: Color(red: 0.76, green: 0.89, blue: 1.0), // md_theme_dark_onPrimaryContainer
        secondary: Color(red: 0.7, green: 0.89, blue: 0.7), // md_theme_dark_secondary
        onSecondary: Color(red: 0.0, green: 0.37, blue: 0.0), // md_theme_dark_onSecondary
        secondaryContainer: Color(red: 0.33, green: 0.69, blue: 0.33), // md_theme_dark_secondaryContainer
        onSecondaryContainer: Color(red: 0.84, green: 0.97, blue: 0.84), // md_theme_dark_onSecondaryContainer
        tertiary: Color(red: 0.8, green: 0.6, blue: 0.9), // md_theme_dark_tertiary
        onTertiary: Color(red: 0.3, green: 0.0, blue: 0.45), // md_theme_dark_onTertiary
        tertiaryContainer: Color(red: 0.5, green: 0.25, blue: 0.75), // md_theme_dark_tertiaryContainer
        onTertiaryContainer: Color(red: 0.9, green: 0.8, blue: 1.0), // md_theme_dark_onTertiaryContainer
        error: Color(red: 1.0, green: 0.6, blue: 0.6), // md_theme_dark_error
        errorContainer: Color(red: 0.73, green: 0.13, blue: 0.13), // md_theme_dark_errorContainer
        onError: Color(red: 0.4, green: 0.0, blue: 0.0), // md_theme_dark_onError
        onErrorContainer: Color(red: 1.0, green: 0.89, blue: 0.89), // md_theme_dark_onErrorContainer
        background: Color(red: 0.11, green: 0.11, blue: 0.11), // md_theme_dark_background
        onBackground: Color(red: 0.98, green: 0.98, blue: 0.98), // md_theme_dark_onBackground
        surface: Color(red: 0.11, green: 0.11, blue: 0.11), // md_theme_dark_surface
        onSurface: Color(red: 0.98, green: 0.98, blue: 0.98), // md_theme_dark_onSurface
        surfaceVariant: Color(red: 0.28, green: 0.28, blue: 0.28), // md_theme_dark_surfaceVariant
        onSurfaceVariant: Color(red: 0.9, green: 0.9, blue: 0.9), // md_theme_dark_onSurfaceVariant
        outline: Color(red: 0.6, green: 0.6, blue: 0.6), // md_theme_dark_outline
        inverseOnSurface: Color(red: 0.11, green: 0.11, blue: 0.11), // md_theme_dark_inverseOnSurface
        inverseSurface: Color(red: 0.98, green: 0.98, blue: 0.98), // md_theme_dark_inverseSurface
        inversePrimary: Color(red: 0.0, green: 0.47, blue: 0.84) // md_theme_dark_inversePrimary
    )
}

// MARK: - Typography

/// Defines the typography for the application.
struct Typography {
    let displayLarge: Font
    let displayMedium: Font
    let displaySmall: Font
    let headlineLarge: Font
    let headlineMedium: Font
    let headlineSmall: Font
    let titleLarge: Font
    let titleMedium: Font
    let titleSmall: Font
    let bodyLarge: Font
    let bodyMedium: Font
    let bodySmall: Font
    let labelLarge: Font
    let labelMedium: Font
    let labelSmall: Font

    static let defaultTypography = Typography(
        displayLarge: .largeTitle,
        displayMedium: .title,
        displaySmall: .title2,
        headlineLarge: .title3,
        headlineMedium: .headline,
        headlineSmall: .subheadline,
        titleLarge: .title,
        titleMedium: .title2,
        titleSmall: .title3,
        bodyLarge: .body,
        bodyMedium: .callout,
        bodySmall: .footnote,
        labelLarge: .caption,
        labelMedium: .caption2,
        labelSmall: .system(size: 10)
    )
}

// MARK: - Shapes

/// Defines the shapes for the application.
struct Shapes {
    let extraSmall: RoundedRectangle
    let small: RoundedRectangle
    let medium: RoundedRectangle
    let large: RoundedRectangle
    let extraLarge: RoundedRectangle

    static let defaultShapes = Shapes(
        extraSmall: RoundedRectangle(cornerRadius: 4),
        small: RoundedRectangle(cornerRadius: 8),
        medium: RoundedRectangle(cornerRadius: 12),
        large: RoundedRectangle(cornerRadius: 16),
        extraLarge: RoundedRectangle(cornerRadius: 28)
    )
}

// MARK: - Theme

/// Combines ColorPalette, Typography, and Shapes into a single theme.
struct Theme {
    let colors: ColorPalette
    let typography: Typography
    let shapes: Shapes
}

// MARK: - Environment Key for Theme

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = Theme(
        colors: .lightPalette, // Default to light palette if not explicitly set
        typography: .defaultTypography,
        shapes: .defaultShapes
    )
}

extension EnvironmentValues {
    var appTheme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - View Modifier to Apply Theme

struct MyApplicationThemeModifier: ViewModifier {
    var useDarkTheme: Bool
    // dynamicColor is ignored as it's Android-specific and set to false in original

    func body(content: Content) -> some View {
        let selectedPalette = useDarkTheme ? ColorPalette.darkPalette : ColorPalette.lightPalette
        let theme = Theme(
            colors: selectedPalette,
            typography: Typography.defaultTypography,
            shapes: Shapes.defaultShapes
        )

        content
            .environment(\.appTheme, theme)
            // Apply the color scheme explicitly based on useDarkTheme
            .preferredColorScheme(useDarkTheme ? .dark : .light)
    }
}

extension View {
    /// Applies the custom application theme to the view hierarchy.
    ///
    /// - Parameters:
    ///   - useDarkTheme: If `true`, the dark color scheme is used. If `false`, the light color scheme is used.
    ///                   Defaults to `true` as per the original Kotlin code.
    ///   - dynamicColor: This parameter is ignored in SwiftUI as it's Android-specific and
    ///                   was set to `false` in the original Kotlin code, disabling dynamic colors.
    /// - Returns: A view with the application theme applied.
    func myApplicationTheme(useDarkTheme: Bool = true, dynamicColor: Bool = false) -> some View {
        self.modifier(MyApplicationThemeModifier(useDarkTheme: useDarkTheme))
    }
}

// Example Usage (for demonstration, not part of the required output)
/*
struct ContentView: View {
    @Environment(\.appTheme) var theme

    var body: some View {
        VStack {
            Text("Hello, SwiftUI!")
                .font(theme.typography.headlineLarge)
                .foregroundColor(theme.colors.onBackground)
                .padding()
                .background(theme.colors.background)
                .cornerRadius(theme.shapes.medium.cornerRadius)

            Button("Primary Action") {
                // Action
            }
            .font(theme.typography.labelLarge)
            .foregroundColor(theme.colors.onPrimary)
            .padding()
            .background(theme.colors.primary)
            .cornerRadius(theme.shapes.small.cornerRadius)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.colors.background.ignoresSafeArea())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .myApplicationTheme(useDarkTheme: false)
                .previewDisplayName("Light Theme")

            ContentView()
                .myApplicationTheme(useDarkTheme: true)
                .previewDisplayName("Dark Theme")
        }
    }
}
*/