# AwemeLiquidBar 1.0.39

## True 46 pt top/right glass controls

- Top-left menu, fallback top Search, and all four right-side action controls use an explicit **46 × 46 pt** SwiftUI glass body.
- The resting shape is `Capsule()` in a square frame, so it is a true circle at rest and can become a pill/oval when the frame is stretched.
- The implementation no longer uses the padded `GlassButtonStyle` shell whose private interaction view measured 56 × 46 pt.
- Clear Glass remains the default. The existing **顶部与右侧按钮色调模式** switch changes the same 46 pt body to regular/tinted glass.
- The glass is configured with `.interactive()`; the existing Douyin controls still own business taps and routing.

## PNG pixel sizing

Imported PNG files are interpreted as @3x artwork from their actual source pixels:

- 30 × 30 px → about 10 × 10 pt
- 60 × 60 px → about 20 × 20 pt
- 90 × 90 px → about 30 × 30 pt
- 100 × 100 px → about 33.3 × 33.3 pt

Small images are never enlarged. If either edge exceeds 100 px, the image is reduced proportionally. Original colour, aspect ratio, alpha, and transparent canvas are preserved.

## Retained behavior

- Automatic, White, Black, Accent, and Custom modes remain independent for SF Symbols.
- Selected Like remains pink and selected Favorite remains yellow in Automatic mode.
- Top and bottom Search remain mutually exclusive.
- The replacement bottom bar mirrors the original Douyin bottom-bar visibility.
- Authorization, settings, layout controls, route suppression, and iOS 27 bottom-bar force-dark remain unchanged.
