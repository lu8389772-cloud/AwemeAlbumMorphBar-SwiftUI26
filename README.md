# AwemeLiquidBar 1.0.42a

Consolidated iOS 26 material, menu and efficiency update based on the stable 1.0.41c branch.

## Main changes

- The iOS 26 default for the custom top-left, top-search and right-side controls is now the verified 1.0.41a **system-adaptive** Liquid Glass path. It follows the system Clear/Tinted preference and the probe-resolved light/dark branch.
- **Pure transparent material** is now a separate opt-in switch. It uses native `clearGlassButtonConfiguration`, with a gray translucent perimeter over the two top buttons and a lighter perimeter on the right action column to suppress the harsh white rim.
- The existing iOS 27 force-dark preference key and stored ON/OFF state are unchanged and remain independent of the new iOS 26 default.
- In transparent mode, automatic SF Symbol foreground follows Douyin's local original icon tint; explicit white/black/accent/custom colour modes still take priority.
- New-bottom-bar icon editing keeps independent normal and selected SF Symbol choices, but removes per-icon colour controls. Unselected colour is system-owned and selected colour is the global accent.
- The top-left four-item menu retains 直播 / 商城 / 关注 / 推荐 and the native source-to-menu morph. The forced large row size was removed so UIKit uses its more compact automatic menu width. Redundant top category titles remain hidden.
- Rendering work is reduced by caching unchanged button configurations and image colour samples, limiting probe sampling and continuous stack scans to 8 Hz, pausing the probe off-screen, and coalescing delayed refreshes.

The 4 x 4 bottom material probe remains fully rendered beneath the left platter so the system-adaptive bottom bar stays reliable without exposing the center dot.
