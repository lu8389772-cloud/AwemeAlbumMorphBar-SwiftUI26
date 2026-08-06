# AwemeLiquidBar 1.0.41b

Based on the verified 1.0.41a system-button build. The successful top-left native menu morph and its four rows remain unchanged: 直播、商城、关注、推荐.

## Changes

- Top-left, top-search and right-side buttons keep real system `UIButtonConfiguration` Liquid Glass.
- Transparent mode remains `clearGlassButtonConfiguration`.
- Tint mode remains `glassButtonConfiguration`.
- Each independent button now keeps `overrideUserInterfaceStyle = .unspecified` and resolves against its own local video background instead of inheriting the bottom bar probe's Light/Dark branch.
- No custom material tint, fill or manual button alpha is introduced; Clear and Tinted modes remain restrained.
- The bottom-bar system tint probe is reduced from a visible 4×4 center point to a 1×1, 2%-opacity point parked under the covered left platter. This removes the small Liquid Glass dot that appeared in the center gap with two regular tabs.
- Fixed 46×46 pt controls, pixel-authored PNG sizing, icon colour modes and menu actions remain unchanged.
