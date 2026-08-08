# AwemeLiquidBar 1.0.49c

Incremental release based on 1.0.48a.

- Adds an independent **完全隐藏左上角按钮** switch. When enabled, both the plugin Liquid Glass menu button and Douyin's original left entrance are suppressed; top search remains independent.
- Preserves the 1.0.48a publish/share/forward/PNG/commerce stability restoration.
- Extends the encrypted authorization table from 26 to 28 entries. Account plaintext is not stored in the release gate.


## 1.0.49c fixes
- New native bottom bar now obeys Hide Bottom Titles directly in the Swift UITab model.
- Normal/selected icon artwork is explicitly swapped on selection, so separate icon overrides cannot be lost to UIKit selected-image caching.
- Fresh-install tap forwarding reacquires the original Douyin tab bar when its weak cache is not ready.
- Diagnostic export now records bottom-bar hit-testing, selected index, overlay state and forwarding route.


## 1.0.49c regression cleanup

- Comment panels no longer trigger three competing pre-dismiss right-column recoveries. The right action stack is rebound only after the final sensitive comment controller exits, using three bounded passes (0/100/280 ms).
- Diagnostic export records RIGHT_HOST_BEFORE_COMMENT and RIGHT_REBIND_PASS so profile-feed cell replacement can be confirmed without a continuous sampler.
- Bottom-bar icon customization is now one icon per destination. Selected/unselected artwork choices were removed; selection is represented by foreground/accent state only.
