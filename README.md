# AwemeLiquidBar 1.0.53f

This build is a focused follow-up to 1.0.53d based on the 1.0.53d probe/interaction logs.

1. Clean screen is now a hard global chrome gate.
   - The real `AWEFeedTopBarContainer` is explicitly suppressed because it lives outside `AWEPlayInteractionViewController`.
   - Top/right/home-chrome refreshers return immediately while clean screen is active, so `TOP_BIND` / `RIGHT_FLEX_REPAIR` can no longer recreate visible chrome behind the clean-screen state.
   - Status bar, native tab bar and AlbumMorph overlay remain suppressed until exit.

2. Avatar UIMenu freezes horizontal photo paging while it is presented.
   - A single tap still opens the normal menu.
   - Only horizontal scroll views with content wider than their viewport are temporarily disabled.
   - They are restored when the system context-menu controller disappears.
   - This deliberately prevents the “menu open -> swipe to next photo -> interaction stack moves down exactly 83 pt” sequence captured in 1.0.53d.

3. Post-comment right glass is sticky only during the bounded repair window.
   - A transient native-button tree with 0/partial owners no longer hides the last valid four glass slots.
   - Health checking now requires live local native owner/source bindings and on-screen slot geometry, so stale slots are still re-bound when replacement native buttons appear.
   - No old `AWEElementStackView` is pinned and no permanent timer is introduced.

Auth34, zero-unread badge behavior, download menu and existing single-tap avatar menu behavior are preserved.
