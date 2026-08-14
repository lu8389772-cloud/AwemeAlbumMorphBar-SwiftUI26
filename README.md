# AwemeLiquidBar 1.0.56c18 — Direct Native Minimize Probe

Focused A/B test based on the validated **1.0.56c16 auth38** feature set, carrying forward only the c17 diagnostics.

## Only new runtime experiment

- Keeps **原生滚动收缩（实验）** enabled by default for this probe.
- Uses the public iOS 26+ `UITabBarController.tabBarMinimizeBehavior = .onScrollDown` path.
- Removes c17's synthetic proxy-offset mirroring.
- The active Home/Friends child controller now calls `setContentScrollView(realAWEFeedTableView, for: .bottom)` with Douyin's actual finger-driven feed scroll view.
- The real `AWEFeedTableView` stays in Douyin's hierarchy/window; it is never reparented, resized, or given a second recognizer.
- Its existing pan recognizer gets only a begin/end logging target. No content offset, frame, scale, or transform is changed.
- Turning the experiment OFF restores `.never` and unregisters the direct source.
- The retired manual whole-window collapse recognizer remains hard-disabled.

## Why this build exists

c17 proved Home/Friends gesture detection and proxy offset mirroring were correct while the visible tab-bar frame never moved. c18 changes one architectural variable: UIKit observes the **real user-driven feed scroll view** instead of a programmatically scrolled proxy.

## Intentionally unchanged

Authorization (38 unique users), the two-account bottom-bar release option, fullscreen/clean-screen, IM/comment routing, article/avatar fixes, badges, download/highest-quality playback, top group, and top/right glass material logic are unchanged.

The broader Liquid Glass material/adaptive-tint work is not mixed into this probe.
