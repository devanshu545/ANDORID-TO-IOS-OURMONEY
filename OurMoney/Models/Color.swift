import SwiftUI

extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0
        )
    }
}

// Minimal Sophisticated Dark Theme (Graphite & Slate with subtle Teal)
let md_theme_dark_primary = Color(hex: 0xFF80CBC4) // Soft Teal
let md_theme_dark_onPrimary = Color(hex: 0xFF003732)
let md_theme_dark_primaryContainer = Color(hex: 0xFF005049)
let md_theme_dark_onPrimaryContainer = Color(hex: 0xFF9CF7EE)

let md_theme_dark_secondary = Color(hex: 0xFFB0BEC5) // Slate Gray
let md_theme_dark_onSecondary = Color(hex: 0xFF1B2A32)
let md_theme_dark_secondaryContainer = Color(hex: 0xFF324048)
let md_theme_dark_onSecondaryContainer = Color(hex: 0xFFCCDBE2)

let md_theme_dark_tertiary = Color(hex: 0xFFBCAAA4) // Warm Gray / Taupe
let md_theme_dark_onTertiary = Color(hex: 0xFF271914)
let md_theme_dark_tertiaryContainer = Color(hex: 0xFF3E2D27)
let md_theme_dark_onTertiaryContainer = Color(hex: 0xFFD8C5BE)

let md_theme_dark_error = Color(hex: 0xFFFFB4AB)
let md_theme_dark_errorContainer = Color(hex: 0xFF93000A)
let md_theme_dark_onError = Color(hex: 0xFF690005)
let md_theme_dark_onErrorContainer = Color(hex: 0xFFFFDAD6)

let md_theme_dark_background = Color(hex: 0xFF121212) // Material Dark Background
let md_theme_dark_onBackground = Color(hex: 0xFFE3E2E6)
let md_theme_dark_surface = Color(hex: 0xFF1A1C1E) // Slightly elevated dark
let md_theme_dark_onSurface = Color(hex: 0xFFE3E2E6)
let md_theme_dark_surfaceVariant = Color(hex: 0xFF2F3033) // Card backgrounds
let md_theme_dark_onSurfaceVariant = Color(hex: 0xFFC4C6D0)
let md_theme_dark_outline = Color(hex: 0xFF8E9099)

let md_theme_dark_inverseOnSurface = Color(hex: 0xFF1A1C1E)
let md_theme_dark_inverseSurface = Color(hex: 0xFFE3E2E6)
let md_theme_dark_inversePrimary = Color(hex: 0xFF006A60)

// Light theme fallback (Clean slate)
let md_theme_light_primary = Color(hex: 0xFF006A60)
let md_theme_light_onPrimary = Color(hex: 0xFFFFFFFF)
let md_theme_light_primaryContainer = Color(hex: 0xFF9CF7EE)
let md_theme_light_onPrimaryContainer = Color(hex: 0xFF00201C)

let md_theme_light_secondary = Color(hex: 0xFF4A626A)
let md_theme_light_onSecondary = Color(hex: 0xFFFFFFFF)
let md_theme_light_secondaryContainer = Color(hex: 0xFFCCDBE2)
let md_theme_light_onSecondaryContainer = Color(hex: 0xFF051F26)

let md_theme_light_tertiary = Color(hex: 0xFF55443E)
let md_theme_light_onTertiary = Color(hex: 0xFFFFFFFF)
let md_theme_light_tertiaryContainer = Color(hex: 0xFFD8C5BE)
let md_theme_light_onTertiaryContainer = Color(hex: 0xFF130602)

let md_theme_light_error = Color(hex: 0xFFBA1A1A)
let md_theme_light_errorContainer = Color(hex: 0xFFFFDAD6)
let md_theme_light_onError = Color(hex: 0xFFFFFFFF)
let md_theme_light_onErrorContainer = Color(hex: 0xFF410002)

let md_theme_light_background = Color(hex: 0xFFFBFDFA)
let md_theme_light_onBackground = Color(hex: 0xFF191C1B)
let md_theme_light_surface = Color(hex: 0xFFFBFDFA)
let md_theme_light_onSurface = Color(hex: 0xFF191C1B)
let md_theme_light_surfaceVariant = Color(hex: 0xFFDBE5E0)
let md_theme_light_onSurfaceVariant = Color(hex: 0xFF3F4947)
let md_theme_light_outline = Color(hex: 0xFF6F7977)

let md_theme_light_inverseOnSurface = Color(hex: 0xFFEFF1EE)
let md_theme_light_inverseSurface = Color(hex: 0xFF2E3130)
let md_theme_light_inversePrimary = Color(hex: 0xFF53DBC9)