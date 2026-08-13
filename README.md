# AwemeLiquidBar 1.0.56c15

Stable follow-up based on 1.0.56c12, keeping the validated 1.0.56c10 playback lifecycle and bottom-bar release behavior.

## Preserved from c12
- Article-style Home feed cards no longer permanently lose LiquidBar after the card ends.
- IM/shared-work media routes suppress LiquidBar where the chat composer/media viewer owns the bottom area.
- Search result navigation is isolated from LiquidBar fullscreen feed geometry.
- Fullscreen feed sizing does not rewrite the scroll container while tracking/dragging/decelerating.
- Single-visible-category top label follows the real selected category instead of defaulting to the first label.
- “显示液态底栏” remains a true ownership-release mode for the two compatibility accounts only.
- Foreground/Friends playback lifecycle isolation from 1.0.56c8 remains unchanged.

## 1.0.56c15 corrections
- Authorization table is corrected to 37 unique users. `Hoeyc_0505` was already in the original table and is no longer duplicated; `0416xxd` remains authorized.
- The bottom-bar ownership-release option is still visible/usable only for `Hoeyc_0505` and `0416xxd`; all other authorized users are forced to the normal LiquidBar-on path and do not see that setting.
- Clean screen now has a source-level hard no-show gate. Route/lifecycle/pause/selection callbacks may keep bookkeeping state, but cannot reveal the LiquidBar overlay, tab bar, or search proxy while clean screen is active.
- No new timers, polling loops, process-wide UIView hooks, forced play/pause calls, or chat-return experiments are introduced.

## Build
Use the existing Xcode 27 / Theos GitHub Actions workflow. The phone-side upload flow does not need to run the Python preflight script.
