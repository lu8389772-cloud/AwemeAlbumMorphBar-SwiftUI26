# AwemeLiquidBar 1.0.52w

1.0.52w targets the common cause behind several apparently unrelated “content falls to the physical bottom” regressions.

## Root cause addressed

Album Morph is rendered in an independent UIWindow. Douyin still relies on its original AWENormalModeTabBar / tab-bar wrapper as the native layout footprint. The old code protected that invisible footprint only on Friends. On Home/Profile/photo paging/comment return, Douyin could transiently hide, move, transform, or collapse the original bar while the replacement LiquidBar remained visible. A subsequent private layout pass then expanded feed/interactions into the 83-pt bottom-bar area.

## 1.0.52w changes

- Generalizes the existing Friends-only native footprint protection to all normal main-tab routes while Album Morph is supposed to be visible.
- Keeps the original AWENormalModeTabBar visually suppressed, noninteractive, but not hidden and not moved out of its stable bottom geometry.
- Blocks transient off-screen/zero-size frame, center, bounds and transform writes only while the replacement bar owns the bottom area.
- Real bar-suppressing routes (comments, search, user-detail, commerce, publish, settings and clean screen) remain allowed to hide/move the native bar normally.
- Adds a low-cost AWEPlayInteractionViewController footprint verifier. It does nothing while the content view ends at or above the replacement bar. If content extends behind the visible 83-pt bar, it asks the native host to restore its original footprint and logs the before/after geometry.
- Keeps the single-tap avatar menu and isolated clean-screen architecture from 1.0.52v unchanged.
- Keeps auth33 and zero-unread badge handling unchanged.

Useful probe records:
- `BOTTOM_FOOTPRINT_HIDE_BLOCKED`
- `BOTTOM_FOOTPRINT_FRAME_BLOCK`
- `BOTTOM_FOOTPRINT_CENTER_BLOCK`
- `BOTTOM_FOOTPRINT_TRANSFORM_BLOCK`
- `BOTTOM_FOOTPRINT_ANOMALY`
- `BOTTOM_FOOTPRINT_AFTER`
