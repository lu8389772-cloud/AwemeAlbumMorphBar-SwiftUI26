# AwemeLiquidBar 1.0.55a

Stable no-fullscreen consolidation based directly on 1.0.52o auth36.

## Kept
- Existing LiquidBar/top/right glass behavior from 1.0.52o.
- Avatar single-tap menu with profile/download/audio/copy actions.
- auth36 authorization table.
- Friends + Messages native badge mirroring and the existing ~10% badge visual reduction.

## Fixed
- Messages unread count 0 now clears the badge instead of leaving an empty red circle.
- Added one-tap clean screen as a display-only state. It hides UI by layer opacity only and restores the same live views on exit; it does not change frame, center, safe-area, tab-bar footprint, or superview relationships.
- Clean-screen exit is always available from the same invisible avatar hit area; no replacement/cropped avatar is created.

## Explicitly out of scope
- Third-party fullscreen compatibility.
- Profile-video right-action recovery for external fullscreen tweaks.
- Fullscreen-triggered bottom/83pt layout compensation.
- All experimental code from 1.0.52x through 1.0.54d.

Test this build with external fullscreen tweaks disabled if you want baseline behavior.
