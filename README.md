# AwemeLiquidBar 1.0.49b

Incremental release based on 1.0.48a.

- Adds an independent **完全隐藏左上角按钮** switch. When enabled, both the plugin Liquid Glass menu button and Douyin's original left entrance are suppressed; top search remains independent.
- Preserves the 1.0.48a publish/share/forward/PNG/commerce stability restoration.
- Extends the encrypted authorization table from 26 to 28 entries. Account plaintext is not stored in the release gate.


## 1.0.49b fixes
- New native bottom bar now obeys Hide Bottom Titles directly in the Swift UITab model.
- Normal/selected icon artwork is explicitly swapped on selection, so separate icon overrides cannot be lost to UIKit selected-image caching.
- Fresh-install tap forwarding reacquires the original Douyin tab bar when its weak cache is not ready.
- Diagnostic export now records bottom-bar hit-testing, selected index, overlay state and forwarding route.
