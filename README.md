# AwemeLiquidBar 1.0.52r

## 1.0.52r targeted fixes

- Clean-screen avatar recovery no longer creates a replacement image/button. The existing `AWEHomeProfileGlassView` and its existing menu button stay in the live right stack; the menu button becomes the invisible recovery hit target while the real visual base/avatar are suppressed.
- First tap at the hidden-avatar position restores the original liquid avatar/base. Its normal full menu is restored too; while clean screen is active that same menu shows `退出清屏` in place of `一键清屏`, alongside the existing profile/download/copy actions.
- Clean screen no longer calls third-party `setRightAreaHidden:`/`setPureMode:animated:` while entering. Those can hide an ancestor of the avatar base and were the main reason the recovered avatar could become a clipped substitute or lose its menu.
- Status-bar hiding now has three bounded paths: the existing `prefersStatusBarHidden` hook, `setNeedsStatusBarAppearanceUpdate`, and runtime-only suppression of in-process status-bar hosts / legacy UIApplication selectors when available.
- AlbumMorph's own visibility state machine now resolves to visible fraction `0` whenever clean screen is active. Late bottom-bar recovery/layout callbacks therefore cannot bring the LiquidBar back during clean screen.
- Other-user profile **video** posts now get a longer bounded post-comment right-action protection window than image posts. Layout passes during that window reassert the current video right stack, including runtime `setRightAreaHidden:NO` when an external fullscreen tweak exposes that selector.
- Image-post comment behavior remains on the shorter existing recovery path because it was already stable.
- Keeps the 1.0.52q zero-count Messages badge fix, auth33, avatar download menu, and profile-comment safe-area restoration.

## Clean-screen behavior

1. Open the normal avatar menu and choose `一键清屏`.
2. Video/feed paging hierarchy is left intact. Top chrome, left text chrome, right-action children, progress/speed chrome, system status-bar hosts, native bar visual, and LiquidBar visible fraction are suppressed.
3. The real avatar menu button remains transparent and interactive at the exact avatar coordinates. No full-screen touch overlay is added, so vertical swiping stays owned by Douyin.
4. Tap the hidden-avatar position once: the original liquid avatar/base and native avatar branch are restored, while the rest of the interface stays suppressed.
5. Tap the restored avatar: the original full avatar menu appears. Its clean-screen item is now `退出清屏`.
6. Swipe to another item while clean screen is active: reveal state resets, and that item's real avatar menu button becomes the new invisible recovery target.

## Test first

- Other profile + external fullscreen + **video** post: open/close comments repeatedly and confirm the right action column does not disappear after dismissal.
- Repeat on an image post to confirm the already-stable image behavior is unchanged.
- Enter clean screen: both the system status bar and LiquidBar must disappear.
- Swipe 5–10 items in clean screen; paging must remain normal.
- Tap the hidden avatar location once: the avatar must look exactly like the normal liquid avatar, not a clipped replacement.
- Open that avatar's menu: normal profile/download/copy items must still exist and `退出清屏` must work.
- Clear Messages unread count to zero: no empty red circle should remain.
