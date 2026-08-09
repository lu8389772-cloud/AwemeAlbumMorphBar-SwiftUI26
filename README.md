# AwemeLiquidBar 1.0.49e

> Authorization-only update: adds one encrypted authorization entry (29 total). Functional behavior is unchanged from 1.0.49d.

Incremental release based on 1.0.49c.

- Adds an independent **完全隐藏左上角按钮** switch. When enabled, both the plugin Liquid Glass menu button and Douyin's original left entrance are suppressed; top search remains independent.
- Preserves the 1.0.48a publish/share/forward/PNG/commerce stability restoration.
- Extends the encrypted authorization table from 26 to 28 entries. Account plaintext is not stored in the release gate.


## 1.0.49e fixes
- New native bottom bar now obeys Hide Bottom Titles directly in the Swift UITab model.
- Normal/selected icon artwork is explicitly swapped on selection, so separate icon overrides cannot be lost to UIKit selected-image caching.
- Fresh-install tap forwarding reacquires the original Douyin tab bar when its weak cache is not ready.
- Diagnostic export now records bottom-bar hit-testing, selected index, overlay state and forwarding route.


## 1.0.49e regression cleanup

- Fixes the remaining profile-video comment-close disappearance. Douyin keeps `AWECommentInputViewController` alive for several seconds after the visible comment panel is gone; right-side recovery now fires when the last visible comment panel exits instead of waiting for that input helper.
- Keeps a weak reference to the live right action stack before the comment transition and searches all foreground normal-level app windows as a fallback, avoiding temporary key/input-window mismatches.
- After the panel is gone, the visible right-column `AWEElementStackView` is restored and rebound with six bounded passes (0/80/200/450/800/1200 ms); no continuous polling is added.
- Diagnostic export records captured target, cross-window stack count and each restore result.
- Bottom-bar icon customization remains one icon per destination. Selected/unselected artwork choices are removed; selection is represented by foreground/accent state only.
