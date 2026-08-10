# AwemeLiquidBar 1.0.52m

Focused stability build based on the supplied 1.0.52d project. Auth29 and unrelated LiquidBar behavior are retained.

## Changes

- Download button is now a true screen-space singleton. The current right-action stack is used only to resolve the current aweme model; it no longer controls the button's X/Y position.
- Download position is fixed from the feed UIWindow bounds. Recycled cells, avatar rebuilds, right-stack hidden/alpha changes and stack transforms cannot move it.
- Preloaded/previous/next stacks are forbidden from stealing or hiding the download singleton. Brief model gaps keep the existing button/menu instead of blinking it out.
- The existing “显示下载按钮” switch only gates visibility; it never participates in geometry.
- Friends fullscreen mode now reserves the complete custom-bar height when the external tweak removes the native tab-bar footprint. `AWEFeedTableViewController` reasserts this after layout and once on the next run-loop turn.
- Friends and Messages use plugin-owned unread badges instead of scaling UIKit private badge views. Numeric badges are fixed at 16 pt high; dot badges are 8 pt. Both use the same layout code.
- The top-bar layout performs a bounded cleanup pass for leaked native “直播” pills, including the pink Follow live badge created after the original category suppression pass.

## Unchanged

- Native current-item download actions and UIMenu.
- Profile-fullscreen right-action recovery.
- Bottom-bar routing, top category group, icon configuration, authorization table, and other existing settings.
