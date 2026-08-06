# AwemeLiquidBar 1.0.45a

## 1.0.45a changes

- Replaces the two-overlapping-glass top category implementation with one horizontally scrollable native `UISegmentedControl` hosted on one system Liquid Glass platter. The selected capsule is now owned by the system segmented control.
- Keeps the album-morph overlay `UIWindow` resident and transparent; route changes only toggle the tab bar content and hit testing. This follows the older stable project's warm/resident-bar principle and avoids exposing a fresh white window frame.
- Adds a bounded 4–12 Hz recovery sampler that runs only for 1.45 seconds after a top/feed transition. Right action and avatar slots are judged in their local stack coordinates so partial paging or dragging them offscreen no longer permanently hides them.
- Preserves explicit white/black/accent/custom icon colors across UIKit configuration updates. Explicit colors outrank automatic selected-state colors.
- Uses an absolute, synchronized bottom-bar vertical offset with a wider -24…80 pt range and reapplies it on every native controller layout.
- Removes the composer cutout mask and invasive text-frame shift. The actual painted input background receives a continuous radius up to 22 pt and is refreshed on frame, content-size and text changes.
- The optional left-button menu morph remains available as a separate switch; the segmented category group remains the default.

## Build

```sh
make clean
make package -j1
```

The default workflow builds a rootless package with Xcode 27 and uploads `AwemeLiquidBar-1.0.45a-Xcode27-rootless`.
