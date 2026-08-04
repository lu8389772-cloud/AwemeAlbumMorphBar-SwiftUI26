# AwemeLiquidBar 1.0.37

## Selectable glass material

- Top-left menu, fallback top Search, and the four right-side action buttons now share one setting: **顶部与右侧按钮色调模式**.
- The setting is available on both iOS 26 and iOS 27.
- Default is OFF on both systems, retaining the current pure Clear Glass material.
- When enabled, those controls use SwiftUI regular Liquid Glass (`.buttonStyle(.glass)`), restoring the stronger system-tinted material and allowing Automatic SF Symbol foreground resolution to be handled by that material.
- The switch does not affect the independent bottom bar, bottom Search, the iOS 27 bottom-bar force-dark option, or imported PNG colours.

## Retained behavior

- Clear mode continues to use `.buttonStyle(.glass(.clear))`.
- Automatic, White, Black, Accent, and Custom colour modes remain independent for SF Symbols.
- Selected Like remains pink and selected Favorite remains yellow in Automatic mode.
- Imported PNG files remain original-colour images and preserve their actual logical size and aspect ratio. They are never enlarged; only images exceeding the doubled ceiling are reduced proportionally.
- Top and bottom Search remain mutually exclusive.
- The replacement bottom bar mirrors the original Douyin bottom-bar visibility.
- Authorization, layout controls, route suppression, and iOS 27 bottom-bar force-dark mode remain unchanged.
