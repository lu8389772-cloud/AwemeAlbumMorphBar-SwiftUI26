# AwemeLiquidBar 1.0.56a

This project is based directly on the verified **1.0.55a stable baseline** and adds two focused changes.

## 1. Internal fullscreen playback

- Fullscreen is now owned by AwemeLiquidBar itself; disable DYYY/AwemeX or other external fullscreen tweaks while testing.
- The internal fullscreen switch defaults to **ON** and is available in LiquidBar settings.
- Feed/player media expands behind the bottom area without forcing profile/detail interaction overlays to the bottom.
- Profile/detail video geometry follows the validated standalone 0.5 behavior.
- Live pre-stream layout follows the validated 0.3.1 behavior, including the AWEElementStackView tab-bar compensation and IESLiveStackView -20 pt compensation.
- Bottom tab backgrounds used by Douyin are cleared while fullscreen is active.
- No cumulative author-profile image offset is included.

## 2. Clean screen v2

The avatar menu still provides **一键清屏 / 退出清屏**. The implementation remains display-only (no feed geometry ownership), but persistence is stronger:

- hides the original/custom bottom bars;
- hides top chrome, right-side action visuals, captions/anchors/tags;
- explicitly hides the native landscape fullscreen-entry control, danmaku containers/buttons, video/chapter progress UI, story/image page indicators and related folio controls;
- reapplies suppression when feed cells are reused, aweme index/model changes, or layouts rebuild after a swipe;
- uses short event-driven reapply passes instead of a permanent polling timer;
- keeps the invisible avatar hit target available so clean screen can be exited from the same menu.

## Build

The full project contains SwiftUI/iOS 26+ Liquid Glass code. Use the same modern SDK/Xcode environment that successfully builds the existing AwemeLiquidBar project. The included GitHub workflow targets Xcode 27/iOS 27.

Local Theos packaging is still available when the local SDK/toolchain is sufficiently new:

```sh
make clean
make package -j1
```

The build scripts do **not** install or restart Douyin.
