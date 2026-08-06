# AwemeLiquidBar 1.0.43d

Focused stability rollback based on 1.0.43c.

## Changes

- Upward-swipe bottom-bar collapse is fully disabled and removed from settings. No compact transform is allowed to run.
- Right-side like/comment/favorite/share glass overlays are visual-only again. Douyin's original controls receive all touches, restoring reliable interaction.
- The successful 54 pt Liquid Glass backplate behind the profile avatar is retained.
- No custom gray/white CALayer border is added. The remaining optical edge is UIKit's native Liquid Glass highlight.
- The system tint probe is restored to a full-rendered 4 x 4 view at full opacity and moved to the physical bottom-left rounded screen corner. It is no longer scaled to sub-pixel size.
- Multiline chat input detection now searches nested composer hierarchies and reapplies a fixed 22 pt radius from `IESIMGrowingTextView` layout/bounds changes.
- Dynamic top-left menu routing, hidden top labels/underline, custom bottom-bar icons, accent color and iOS 27 force-dark behavior are retained.
