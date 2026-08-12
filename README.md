# AwemeLiquidBar 1.0.56g

## 1.0.56g focused fix

Settings drawer now follows the *actual horizontal displacement* of Douyin's native `AWENormalModeTabBar`. The custom LiquidBar is shifted by the same X amount, so when the underlying page is pushed left the **right-hand slice** of the bar remains visible exactly like the native bar. The Swift controller composes this route X offset with the user's independent vertical offset; it does not overwrite height/vertical settings. Interactive chat return keeps the existing `transitionCoordinator.percentComplete` mask and forces route X to zero while interactive.

## Previous 1.0.56f notes

Based directly on the verified **1.0.56b** build. The validated fullscreen geometry (profile/detail 0.5 + live-prestream 0.3.1) is intentionally unchanged.

## Changes in 1.0.56g

- Clean-screen status-bar hiding is strengthened for current Douyin hosting/controller subclasses: active controller classes receive a reversible runtime `prefersStatusBarHidden` wrapper while clean mode is active, plus a top status-bar-view visual fallback when such views are reachable in-process.
- The Messages root page is no longer classified as a chat-detail route merely because it uses `AWEIMMessageBaseViewController`/`messagebase`; actual IM input/detail/session controllers still suppress LiquidBar, preserving proportional chat swipe-back reveal.
- Save feedback is rebuilt as a centered native adaptive glass HUD. Loading uses a spinner, success/failure use SF Symbols, dynamic label colors and system glass/blur material, with spring entrance and compact fade-out.
- The avatar quick menu now labels the primary save action by media type: `保存图片` for image posts and `保存视频` for videos.
- Fullscreen setting is renamed to `全屏播放`; the third-party fullscreen explanatory hint is removed.
- Top-left menu morph now suppresses both native category visuals and the plugin category group during the same first layout pass, reducing cold-launch category flash.
- Highest-bitrate playback logic from 1.0.56b is preserved. Comment clean-screen protection is preserved.

## Build

Use the existing Xcode 27 / iOS 27 cloud workflow for the full project. The scripts do not install or restart Douyin.
