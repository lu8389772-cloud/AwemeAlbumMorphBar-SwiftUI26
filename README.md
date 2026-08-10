# AwemeLiquidBar 1.0.52t

## Scope
This build is intentionally narrow. It keeps the 1.0.52s clean-screen behavior that already worked, and changes only the two regressions confirmed by the 1.0.52s logs/screenshots.

### 1. Profile video: rebuild our glass from the live native buttons
The 1.0.52s interaction log showed that post-comment recovery was repeatedly selecting an `AWEElementStackView` with `buttons=0`, while another stack in the same transition still had native `AWEFeedVideoButton` descendants. The video-specific branch also never logged `RIGHT_FULLSCREEN_COMMENT_REACQUIRE`, so the image/video classifier was not reliably entering the intended path.

1.0.52t no longer guesses image vs video for this repair. When a comment panel closes on a profile-fullscreen route, it uses the exact `AWEPlayInteractionViewController` that opened comments, searches only inside that controller for the stack that actually owns the live native `AWEFeedVideoButton` controls, and rebuilds only our glass overlays from those controls.

The repair is bounded at 0/16/50/120/250/500/900/1500 ms. It does not change feed frames, native button frames, safe-area insets, or the tab-bar footprint. It also resets any stale press-stretch transform on our glass buttons.

### 2. Photo carousel: avatar menu no longer enters AWEElementStackView layout
The avatar `menuButton` introduced for the new menu was previously added directly to private `AWEElementStackView`. That is a risky layout participant: photo page changes can make the private stack reflow direct control subviews.

1.0.52t moves that transparent menu hit target into the native profile-picture host instead. The liquid glass plate remains where it was, but the menu control is no longer a direct child of `AWEElementStackView`. This is intended to remove the “open menu on image 1 -> switch to image 2 -> chrome/caption sinks to bottom” regression.

Clean-screen recovery still uses the same real avatar/menu target; the profile container path is kept alive while its visual children are suppressed.

## Preserved
- clean-screen status-bar and LiquidBar hiding;
- one-tap avatar recovery and full avatar menu;
- native download/copy actions;
- zero-count Messages badge fix and Friends badge;
- auth33;
- no independent floating download button.
