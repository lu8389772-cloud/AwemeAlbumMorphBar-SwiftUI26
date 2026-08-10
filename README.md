# AwemeLiquidBar 1.0.52l

Delivery-stability build based on the 1.0.52 series.

## This build changes only the unstable areas

- Restores the proven 1.0.52e profile-fullscreen right-side button recovery path after comment close.
- Separates right-column recovery from download-button logic.
- Uses one long-lived floating download button on the independent AlbumMorph overlay window.
- The download button no longer follows the avatar or any recycled feed cell. Its default position is screen-fixed and it can be dragged; the normalized position is persisted.
- The download button still presents the existing native `UIMenu` and current-item download/copy actions.
- Message and Friends unread badges use the same source-reading path.
- Empty unread containers no longer become a permanent red dot after the number clears.
- Mirrored badge visuals are reduced to 84% size; no plugin horizontal badge offset is applied.

Run `scripts/preflight.sh` before cloud compilation.
