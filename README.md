# AwemeLiquidBar 1.0.53d

Built from 1.0.53b with three targeted fixes verified from the 1.0.53b logs:

1. UIKit `_UIContextMenuActionsOnlyViewController` is now globally layout-transparent. Opening the avatar UIMenu must not drive AlbumMorph to fraction 0 or shift a photo page by the 83-pt bottom-bar height.
2. Clean-screen exit explicitly rebuilds the avatar UIMenu state and performs bounded top/right chrome restoration. The menu must return to “一键清屏” after exit.
3. Visible right action stacks self-heal on their own layout only when the four glass slots are actually unhealthy; no permanent timer and no old-stack pinning.

Auth34 and zero-unread badge behavior are preserved.
