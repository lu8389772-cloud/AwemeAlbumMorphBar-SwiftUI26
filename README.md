# AwemeLiquidBar 1.0.52y

Rebuilt directly from **1.0.52o auth34**. No p–x experimental UI/layout changes are inherited.

## Scope

This release changes only profile-video post-comment right-action recovery.

The 1.0.52x interaction log proved that visible comment-panel dismissal restored the
right action stack (`native=4`, `glass=4`), then roughly two seconds later
`AWECommentInputViewController` exited and incorrectly started a second recovery
cycle with the captured stack already detached (`window=0`, all repair passes 0).

1.0.52y:
- never lets the delayed input-only helper create a second right-action generation;
- skips its late profile-route recovery during the bounded ignore window;
- keeps the valid on-screen profile-video right stack protected through that teardown;
- updates protection to the actually restored on-screen stack if Douyin swaps it;
- preserves auth34 and all 1.0.52o UI/layout behavior.
