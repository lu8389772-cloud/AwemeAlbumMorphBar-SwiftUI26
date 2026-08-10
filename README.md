# AwemeLiquidBar 1.0.52s

## Targeted fixes

### 1. Clean-screen avatar recovery
1.0.52r preserved the real avatar menu button, but the parent `AWEElementStackView` was still forced to `hidden/alpha=0` and interaction-disabled by its own hooks. That made the recovery button impossible to tap.

1.0.52s keeps the **right-stack root itself visible and interactive** during clean screen and suppresses only its visual children. The existing transparent avatar `menuButton` remains the recovery hit target. First tap restores the original liquid avatar/base; tapping it then opens the original full avatar menu with `退出清屏` replacing `一键清屏`.

On clean-screen exit the current stack is refreshed through `AWERefreshProfileAvatarGlass`, including one deferred refresh after menu dismissal, so the original liquid avatar/menu binding is restored instead of drawing any replacement control.

### 2. Video comment close vs image comment close
The stable image path normally keeps the same right-side stack. Video posts may tear down and rebuild their `AWEElementStackView` after the comment sheet closes.

Earlier builds tried to protect the *old* video stack by blocking `removeFromSuperview`, `hidden`, and `alpha=0`. 1.0.52s stops doing that for definite video works. The old video stack is allowed to leave normally, and bounded post-comment passes preferentially reacquire a **different/new current stack** before falling back to the captured one.

Image posts retain their existing stable behavior.

### 3. Photo-carousel regression removal
1.0.52r treated a temporarily missing aweme model as video and ran a long 6.6-second video layout guard plus external `setRightAreaHidden:NO` writes. Photo carousels can transiently lose that model binding when moving between images.

1.0.52s:
- no longer classifies a nil/transient model as video;
- removes the per-layout video guard;
- removes external `setRightAreaHidden:NO` writes;
- keeps video recovery bounded to post-comment lifecycle passes only.

This is specifically intended to stop the image-page chrome/caption area from being pushed toward the bottom when changing from the first image to the second while the avatar menu is open.

## Preserved
- clean-screen LiquidBar/status-bar suppression paths;
- avatar profile/download/copy menu;
- zero-count Messages badge fix;
- Friends badge behavior;
- profile comment safe-area restore;
- auth33.
