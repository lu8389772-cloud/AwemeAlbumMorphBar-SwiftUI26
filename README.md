# AwemeLiquidBar 1.0.53b

Rebuilt from the **1.0.52o auth34** line. This build does not inherit the 1.0.53a UIWindow avatar-menu anchor or the old profile-video "pin the pre-comment stack" protection.

## Focus of 1.0.53b

- **Profile video / comments:** the post-comment repair now follows the *currently live* right-side `AWEElementStackView`. It scans all foreground app windows (not only normal-level windows), tracks newly laid-out right stacks directly, and can bind the four Liquid Glass action bases from exact `AWEFeedVideoButton` instances or conservative accessibility/geometry fallback owners. Old pre-comment stacks are never pinned.
- **Avatar menu:** single tap remains the interaction. The menu button is nested inside the native profile host instead of being a global UIWindow hit target or a direct child of `AWEElementStackView`. No long-press-only interaction is used.
- **Photo paging / 83-pt drop:** nested/recycled feed, player, interaction, photo/gallery controllers no longer drive AlbumMorph's *global* bar route-recovery/prewarm state. Their own page lifecycle can continue without moving the global 83-pt bottom-bar state.
- **Clean screen:** uses the real profile/avatar hierarchy. No fake avatar, snapshot avatar, or reparented avatar is created. The existing transparent menu hit area stays on the real profile path so the original Liquid Glass avatar can be revealed and the same full single-tap menu can be used to exit clean screen.
- Keeps auth34, zero-unread badge cleanup, and menu-based download/copy functions.

## New diagnostics

- `RIGHT_FLEX_ARM`
- `RIGHT_FLEX_RESCAN`
- `RIGHT_FLEX_REPAIR`
- `NESTED_FEED_BAR_RECOVERY_SKIPPED`
