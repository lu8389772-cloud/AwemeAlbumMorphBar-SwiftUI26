# AwemeLiquidBar 1.0.43b

Consolidated interaction, dynamic routing and performance update based on 1.0.42a.

## Main changes

- Clear-glass automatic SF Symbol colour no longer reads Douyin's permanently white artwork. A low-rate, per-control local backdrop sampler switches the icon between black and white with hysteresis. Explicit white, black, accent and custom colours still have higher priority.
- The custom gray perimeter is removed completely. UIKit owns the Liquid Glass body and its source-to-menu deformation without a rigid circular overlay.
- Right-side like, comment, favorite and share replacements are real interactive glass UIButtons again. Their native press response and elastic deformation remain active, while completed taps are forwarded to Douyin's original controls.
- The top-left menu reads the currently available top channel items at runtime, preserves their current order and labels (including account-specific local channels), excludes externally hidden items, and falls back to 直播 / 商城 / 关注 / 推荐 only when scanning fails.
- Top category text remains pixel-hidden for routing, and the exact `AWEFeedMultiTabSelectedContainerView` underline is suppressed after its own layout so the selected marker cannot reappear.
- The profile avatar receives a 54 pt system Liquid Glass backplate using the same adaptive/clear material choice as the right action column, without a custom outline.
- Upward-swipe collapse is re-enabled through a simultaneous source-window pan bridge. Native private minimization selectors are tried first; the fallback computes travel from the live tab-bar height on every layout, so adjusted height and vertical offset do not produce stale coordinates.
- The 4 x 4 system-material probe remains only while the Album Morph bottom bar is actually visible. It is hidden and its 4–8 Hz display link is paused on chat and other non-bottom-bar pages.
- Multiline chat input capsules grow vertically while keeping the single-line 22 pt continuous corner radius instead of turning the whole field into an oversized pill.

The local contrast sampler processes at most one visible clear-glass button per low-rate tick. Dynamic menu reconstruction is signature-cached, and existing bounded scans remain coalesced.
