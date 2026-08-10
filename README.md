# AwemeLiquidBar 1.0.52a

## Stable downloader / Friends / fullscreen compatibility

This build is based on **1.0.51c**. The encrypted **auth29** table and the proven top-category centering fix are unchanged.

### Main changes

- Replaced the per-feed-cell download buttons with **one process-wide Liquid Glass download button**. It is anchored to the currently visible right-action stack, so recycled/offscreen cells cannot leave duplicates floating over comments or profile pages.
- The download button is hidden while comments, settings, search, share/publish, commerce sheets, or a normal user-profile page owns the screen. A real playable profile-video fullscreen remains eligible.
- Native menu installation now follows the same proven order as the top-left native menu: configure the `UIButton`, then assign `UIMenu`, then set `showsMenuAsPrimaryAction = YES`.
- Downloading is intentionally **reliability-first** in this build. Video saving first tries `video.h264URL.originURLList`, then simple play/download URL fallbacks. Image saving uses `albumImages`, `currentImageIndex`, and `urlList`, preferring a URL whose path does not end in `.image`.
- Image posts expose **Save current image / Save all images**; video posts expose **Save current video**. Audio save and full-caption copy remain available when applicable.
- Fresh installs no longer default to “prefer highest playback quality”, avoiding private player-quality probing unless the user explicitly enables it.
- Friends initial entry now preserves the native tab-bar layout footprint before the first Friends content layout, while the original bar remains visually suppressed. This targets the one remaining first-entry caption-under-bar case.
- Current-right-stack selection now scores actual screen visibility instead of blindly preferring the pre-comment cached stack.
- Added compatibility recovery for another tweak's “profile video opens fullscreen” mode: if that transition hides the active right stack, two bounded recovery passes restore/rebind our right-side glass instead of using a timer/display link.
- Added diagnostics: `DOWNLOAD_BUTTON_HIT`, `DOWNLOAD_MENU_READY`, `DOWNLOAD_ACTION`, `DOWNLOAD_VIDEO_HTTP`, `DOWNLOAD_IMAGE_HTTP`, `RIGHT_FULLSCREEN_RECOVERY`, and `RIGHT_FULLSCREEN_VISIBILITY_GUARD`.

### DYYY reference

The reliable media-field fallbacks were independently implemented after reviewing the public MIT-licensed DYYY project: its long-press downloader uses Douyin's `h264URL.originURLList` for video and `albumImages/currentImageIndex/urlList` for image posts. AwemeLiquidBar has **no runtime dependency on DYYY or AwemeX**.

### Authorization

Authorization remains the encrypted **29-entry** table. No accounts were added or removed in this build.
