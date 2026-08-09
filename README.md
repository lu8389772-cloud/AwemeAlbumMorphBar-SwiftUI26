# AwemeLiquidBar 1.0.51c

## Stability / regression repair

This build is based on 1.0.51a and keeps auth29 and the top-category centering fix.

Key changes:

- Native download menu actions now capture the exact current aweme model when the menu is built. UIMenu presentation can temporarily reparent/reuse the feed stack, so resolving the model again at action time could return nil in 1.0.51a.
- Download menu/model parsing is cached by aweme identity and icon generation instead of rebuilding on every right-stack refresh.
- Highest-playback probing is coalesced to one bounded attempt per model/stack. Failed private-selector lookup is cached too, so unsupported Douyin versions no longer retry hundreds of times.
- HEIGHT_SYNC_FIXED now writes/applies only when the overlay frame or user offset actually changes.
- Right/search/profile visual glass press feedback now uses an elastic scale/stretch spring rather than only toggling highlighted state.
- Fixed the commerce route matcher false positive: the substring `ecom` inside `recommend` made `AWERecommendToFriend...` controllers look like commerce sheets. That incorrectly suppressed LiquidBar at the end of Friends batches.
- Friends native tab-bar hide requests are blocked at the root feed while the original bar remains visually suppressed. This preserves the native bottom layout footprint so captions/recommendation UI do not fall underneath the custom bar.
- Added download HTTP diagnostics and a normal mobile User-Agent.

Authorization remains the encrypted **auth29** table. No accounts were added or removed.
