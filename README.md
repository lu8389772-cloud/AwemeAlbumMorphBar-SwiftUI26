# AwemeLiquidBar 1.0.51a

## 1.0.51a native downloader + quality handling

This release removes the runtime dependency on AwemeX download actions. The right-side download button now resolves the current visible Douyin `awemeModel` from the live feed cell (`awelistkit_cellContext -> model`) and performs download/copy work inside AwemeLiquidBar.

Native menu actions:
- Save current video with smart high-quality stream selection.
- Save all images from an album post.
- Download the post audio and open the system export/share sheet.
- Copy the complete post description.

Smart video selection uses Douyin's own `bitrateModels_origin` / `bitrateModels` list. It keeps the top resolution tier, prefers the top frame-rate tier, prefers HEVC/H.265 when available, then chooses a compressed bitrate that remains within the upper quality band instead of blindly selecting the largest H.264 stream.

A new **Prefer highest-quality playback** switch is enabled by default. It tries Douyin's existing private quality-switching interfaces (`switchStreamBitrate:type:completionHandler:` first, `setResolutionWithIndex:isManual:beginChange:completion:` as fallback) and only invokes them when the runtime method signature is compatible.

The download menu source button is now attached directly to the app window rather than the scrolling feed hierarchy. This prevents UIKit from scrolling the feed to keep the UIMenu source visible when the menu is opened.

Friends-feed bottom-bar persistence now uses a latched Friends-root state. Douyin can hide or temporarily detach its native tab bar after the current Friends batch is exhausted without causing the resident LiquidBar to disappear. Route suppression still wins on profile/search/comment/share/publish/etc.

Top category centering, auth29, cross-version bottom routing, message badge mirroring, profile-only settings gesture option, and the existing iOS 26/27 glass behavior are retained.

## Authorization

Authorization remains the encrypted **auth29** table. No authorization entries were added or removed in 1.0.51a.
