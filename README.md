# AwemeLiquidBar 1.0.52q

## 1.0.52q targeted fixes

- Removes all static `.class` references to the private `AWEPlayInteractionViewController`; runtime checks now resolve it with `NSClassFromString`, preventing `_OBJC_CLASS_$_AWEPlayInteractionViewController` linker failures.
- Messages badge now mirrors only a strictly positive numeric unread count. A surviving empty native badge container or a literal `0` clears our badge instead of drawing an empty red circle.
- Friends badge behavior is unchanged, so compact red-dot reminders remain supported there.

This build continues from **1.0.52o/auth33** and keeps the independent floating download button retired.

## 1.0.52q scope

- Adds `一键清屏` to the plugin-owned avatar menu.
- Clean screen preserves Douyin's feed hierarchy, video renderer and vertical paging; it never rewrites the feed/video frame and does not place a full-screen interception view over the video.
- It first uses any compatible runtime pure-mode selectors that exist, then independently suppresses known top/right/left/text/icon/control chrome, the plugin bottom-bar overlay, the original bottom-bar visual, and the system status bar. It deliberately does **not** blank the whole `AWEPlayInteractionViewController`, because some Douyin builds keep the renderer or paging gesture there.
- The avatar is hidden too. A transparent 42–54 pt recovery hit target remains at the live avatar position. The first tap reveals only the avatar; the rest of the interface stays hidden. Tapping the revealed avatar opens a one-item `退出清屏` menu.
- When paging to another video during clean screen, the revealed avatar resets to hidden and the recovery hit target follows the new video's avatar position.
- If the runtime exposes Douyin/DYYY-style pure-mode selectors (`setRightAreaHidden:`, `setLeftAreaHidden:`, `setBottomAreaHidden:`, `setTabBarHiddenForPureMode:`, `setTimesHiddenForPureMode:`, `setPureMode:animated:`), 1.0.52q uses them opportunistically in addition to its own suppression path. It does not require the reference plugin to be installed.
- Strengthens other-profile fullscreen right-action recovery. Recovery no longer depends only on a narrow playable-controller class-name match, and it can locate an on-screen right stack even if a fullscreen tweak hides its wrapper.
- Restores known right-area wrapper views when they actually own the selected `AWEElementStackView`; feed/player roots are never force-unhidden.
- For profile-fullscreen comment dismissal, skips the unnecessary AlbumMorph bottom-bar reinstall/re-align path and restores the pre-comment `additionalSafeAreaInsets` of the live interaction controller over bounded passes. This targets the nickname/caption dropping to the screen edge after comments close.
- Keeps auth33 unchanged.

## Test first

1. Open a video from another user's profile with the external fullscreen tweak enabled. Enter/exit comments several times. The right action column should survive and nickname/caption should not fall to the bottom edge.
2. Open the avatar menu and choose `一键清屏`. Only the video should remain; the system status bar and LiquidBar should disappear.
3. Swipe through 5–10 videos. Vertical paging should remain normal and no UI should reappear.
4. Tap the invisible former-avatar position. Only the avatar should appear. Tap the avatar and choose `退出清屏`; all normal UI should recover.
5. Repeat on Home and Friends. If one specific element survives clean screen, capture its FLEX class hierarchy; the core clean-screen mechanism does not need FLEX unless an outlier lives outside the known interaction/top/bottom containers.
