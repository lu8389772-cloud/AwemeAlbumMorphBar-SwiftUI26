# AwemeLiquidBar 1.0.52b

## Download anchor / profile-fullscreen comment recovery / Friends first layout

This build is based on **1.0.52a**. The encrypted **auth29** table and the proven top-category centering fix are unchanged.

### Main changes

- Fixes the 1.0.52a download-button disappearance. The singleton download button no longer attaches directly to the overlay `UIWindow` (whose direct frame can be transient/zero in the current resident-overlay architecture). It now attaches to the Album Morph controller/root view, which owns the stable 440×screen-height coordinate space used by the visible LiquidBar.
- Download placement now prefers the current avatar glass/native profile anchor; if that avatar is temporarily rebuilding, it falls back to the current visible right-action stack instead of hiding the button.
- The menu remains our own `UIButton + UIMenu + UIAction` implementation. Video uses Douyin `h264URL.originURLList` first; image posts use `albumImages/currentImageIndex/urlList`; audio and caption-copy remain native to this plugin.
- For the known conflict with another tweak's “open another user's profile video fullscreen” feature, comment dismissal now opens a **2.4-second bounded protection window**. During that window, a second late `hidden=YES`, `alpha=0`, or `removeFromSuperview` request against the captured current right stack is rejected after the visible comment panel is gone. Outside that short window, normal paging/reuse behavior is untouched.
- Profile-fullscreen comment recovery gets a few additional bounded passes through 2.25 seconds. There is still no continuous timer/display-link for this recovery.
- Friends first-entry layout is primed at the actual `AFDContainer/AWEFamiliar` controller `viewWillAppear` boundary, before its first content layout, rather than waiting for a later tab-bar callback.
- Interaction logging for `ALBUM_MORPH_OVERLAY` is state-deduplicated, reducing diagnostic-file churn while testing.

### DYYY reference

The media-field fallback matches the public DYYY implementation pattern: video from `h264URL.originURLList`, image posts from `albumImages/currentImageIndex/urlList`, and music from `music.playURL.originURLList`. AwemeLiquidBar has **no runtime dependency** on DYYY or AwemeX.

### Authorization

Authorization remains the encrypted **29-entry** table. No accounts were added or removed in this build.
