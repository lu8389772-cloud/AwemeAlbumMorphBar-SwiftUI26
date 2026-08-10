# AwemeLiquidBar 1.0.52c

## Download visibility / transition throttle / Friends caption reserve

This build is based on **1.0.52b**. The encrypted **auth29** table, top-category centering, and the profile-fullscreen right-stack recovery are retained.

### Main changes

- The singleton download control is no longer hosted by the independent AlbumMorph bottom-bar window/controller. It is reparented to the **current visible feed cell's interaction hierarchy**, so it is composited with the same video cell as the avatar/right-action column and naturally follows paging.
- Download placement still prefers the current avatar glass/native profile anchor, but the current stack itself is now accepted as the source instead of depending on a second global stack lookup that could select a preloaded/offscreen cell.
- Download route suppression is less brittle: stale sensitive-controller registrations cannot hide the button when a real playable feed is already visible.
- Adds a deduplicated `DOWNLOAD_SLOT` probe line with the resolved stack, host, frame, and visible/offscreen state.
- Fixes a large transition churn source: `AWEBeginReturnPrewarm` now actually obeys `AWEControllerShouldBeginReturnPrewarm`. Ordinary nested feed-controller `viewWillDisappear` callbacks no longer drive the resident bar 0→1 hundreds of times.
- Friends feed `AWEFeedTableViewController` receives a bottom safe-area reserve equal to the custom tab-bar height minus the system home-indicator inset. This is applied before the first Friends layout and restored when leaving the feed.
- Settings dismissal primes the invisible native tab-bar footprint before the transition snapshot, preventing the Home caption from briefly falling to the physical bottom when Settings closes.
- Profile-fullscreen comment recovery from 1.0.52b is unchanged because it was confirmed effective on-device.

### Downloader

The menu remains fully implemented inside AwemeLiquidBar; there is no runtime dependency on AwemeX or DYYY. Current actions are Save current video, Save current image / all images, Save audio, and Copy full caption.

### Authorization

Authorization remains the encrypted **29-entry** table. No accounts were added or removed.
