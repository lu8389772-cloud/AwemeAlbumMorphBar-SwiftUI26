# AwemeLiquidBar 1.0.52v

This build deliberately returns the avatar/menu hierarchy to the verified 1.0.52o implementation and adds clean screen as an isolated state, rather than redesigning avatar interaction.

## What is deliberately unchanged from 1.0.52o

- Single tap on the liquid avatar base opens the original plugin menu.
- `menuButton` remains the same sibling of `AWEHomeProfileGlassView` inside the existing `AWEElementStackView`.
- The avatar slot/menu button are not reparented into the native profile host, UIWindow, or a context-menu interaction.
- No long-press avatar interaction is installed.
- Normal-mode avatar frame/center/layout code is the 1.0.52o code path.

## Clean screen

- Adds `一键清屏` / `退出清屏` as one UIAction inside the existing single-tap avatar menu.
- Clean screen hides feed chrome, top bar, original/plugin bottom bars and the status bar without changing video geometry.
- The original avatar/menu remains in its original hierarchy but is visually suppressed while clean screen is active.
- A separate transparent UIWindow-level hit target is placed only over the vanished avatar position. It is never inserted into Douyin's private stack/profile hierarchy.
- Tapping that hot zone restores only the original avatar/liquid base and its original single-tap menu; all other chrome stays hidden.
- The full menu then contains `退出清屏`.

## Other retained fixes

- auth33 authorization table.
- Native avatar download/copy menu.
- Zero-count Messages badge guard: unread 0 does not leave an empty red circle.
- Existing 1.0.52o profile/comment recovery behavior is otherwise untouched in this rebuild.
