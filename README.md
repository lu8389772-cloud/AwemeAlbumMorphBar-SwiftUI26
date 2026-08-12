# AwemeLiquidBar 1.0.56b

Based directly on the verified **1.0.56a compilefix1** build. The validated internal-fullscreen geometry is intentionally unchanged.

## Changes in 1.0.56b

- Clean screen now uses exact feed/UI runtime classes instead of broad UILabel/UIImageView/UIControl heuristics. This clears the current item immediately while protecting comment-panel UI.
- Clean screen requests real status-bar hiding on feed, detail, full-page/image, hot-spot, pure-mode and live roots, and restores the original status-bar decision on exit.
- Progress containers and story/page progress controls re-hide themselves when late layout/alpha updates recreate them.
- Highest-quality playback now constrains AWEVideoModel to the highest advertised AWEVideoBSModel bitrate early, while retaining the existing player-side switch as a fallback.
- Settings/privacy/account-security routes suppress the independent LiquidBar window. Chat detail detection now includes IESIMInputViewController and additional conversation-detail names so interactive swipe-back can use the existing percent-complete reveal path again.
- When left-top menu morph is enabled, the top category group is suppressed from the first layout pass, removing the cold-launch flash.

## Preserved

- Internal fullscreen uses the already validated profile/detail 0.5 behavior and live-prestream 0.3.1 behavior.
- Existing proportional interactive return masking is not rewritten; route detection is expanded so the same mechanism can activate on chat/settings routes.
- No permanent clean-screen polling timer is added.

## Build

Use the existing Xcode 27 / iOS 27 cloud workflow for the full project. The scripts do not install or restart Douyin.
