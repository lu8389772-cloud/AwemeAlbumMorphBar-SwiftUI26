# AwemeLiquidBar 1.0.56c17 — Native Minimize Proxy Probe

Focused test build based directly on the validated **1.0.56c16 auth38** project.

## Only new runtime experiment

- Adds **原生滚动收缩（实验）** to the bottom-position card; enabled by default in this test build.
- Uses the public iOS 26+ `UITabBarController.tabBarMinimizeBehavior = .onScrollDown` path.
- Registers a transparent proxy collection view, already owned by the real LiquidBar `UITabBarController`, through `UIViewController.setContentScrollView(_:for: .bottom)`.
- Does **not** attach or reparent Douyin's real feed scroll view to the overlay controller. The existing Home/Friends feed pan recognizer is only observed; its vertical delta is mirrored into the transparent proxy.
- Does **not** install another pan recognizer and does not use the retired manual scale/translation collapse path.
- Disabling the switch restores `.never` and removes the source-pan target.

## Intentionally unchanged

All c16 authorization (38 users), custom two-account bottom-bar release, fullscreen/clean-screen, IM/comment routing, article/avatar fixes, badges, download/highest-quality playback, top group, top/right button materials and tint logic are unchanged.

The broader Liquid Glass material work (regular-vs-clear audit, shared glass containers, system transparency/tint adaptation, quieter top/right edges) is **not** mixed into this probe.
