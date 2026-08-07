# AwemeLiquidBar 1.0.48a

Stability-restore release based on 1.0.47d (26-account encrypted authorization retained).

## Restored regressions
- Publish/creation route: restores hard suspension of the independent AlbumMorph overlay window while the publish flow is presented, preventing the overlay from trapping dismissal/touches.
- Share/forward/system sheets: hard-suspends the overlay for share, forward, transpond, send-panel, activity and document routes so lower controls are never covered by LiquidBar.
- Imported PNG sizing: restores the established @3x pixel contract (30 px → 10 pt, 100 px → 33.33 pt) with a 100 px longest-edge cap before images enter UIButtonConfiguration.
- Commerce/group-buy isolation: presented commerce controllers matching group-buy/POI/e-commerce/product/order/cart/purchase routes suppress the plugin bar; diagnostic mode records presented controller classes to investigate device-only commerce bugs.

## Performance
- Development probe file I/O is now disabled unless Interaction Diagnostics is explicitly enabled. This removes continuous probe-log file churn during normal use.

## Retained
- 26-item encrypted authorization table; no plaintext account identifiers.
- Current Telegram-style top switcher, cached Liquid Glass buttons, avatar glass, adaptive material behavior and iOS 27 force-dark preference.
- Experimental bottom-bar collapse remains disabled.
