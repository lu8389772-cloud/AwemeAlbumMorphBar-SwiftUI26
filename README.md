# AwemeLiquidBar 1.0.41a

Based on the verified 1.0.40b four-item menu build. The top-left menu animation and its four rows remain unchanged: 直播、商城、关注、推荐.

Top-left, top-search and right-side replacement controls now use real system `UIButtonConfiguration` Liquid Glass surfaces instead of explicit SwiftUI `glassEffect(.clear/.regular)` surfaces.

- Transparent mode: `clearGlassButtonConfiguration`
- Tint mode: `glassButtonConfiguration`
- No custom glass tint, background fill or manual opacity
- Fixed 46 × 46 pt control frame
- Mirrors the light/dark style resolved for the native bottom `UITabBar`
- Keeps original-colour PNG sizing and existing icon colour modes

This is intended to let UIKit honor the same system glass appearance, contrast and transparency behavior as the native bottom bar while keeping both variants restrained.
