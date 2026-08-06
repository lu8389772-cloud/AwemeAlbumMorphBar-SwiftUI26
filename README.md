# AwemeLiquidBar 1.0.46c

Changes from 1.0.46b:

- Fixes the plugin top-category titles being hidden by the native-category suppression pass.
- Keeps plugin labels fully opaque and above the selected pill.
- Category taps now forward directly to the captured original Douyin tab owner, with title lookup only as fallback.
- Edge taps and horizontal swipes animate the visible labels out and the next window in instead of replacing text abruptly.
- Freezes top/right Liquid Glass style while comments or other full-screen routes cover the feed, preventing a light comment sheet from recoloring and flashing home controls on dismissal.
- Stops restarting the recovery display link from routine layout/frame callbacks.
- Reduces steady right-stack scans and glass-probe polling to 4 Hz while keeping delayed lifecycle repair passes.
- Top category group still supports 1–4 visible items; one-item mode hides the selected pill.

The GitHub workflow builds and uploads `AwemeLiquidBar-1.0.46c-Xcode27-rootless`.
