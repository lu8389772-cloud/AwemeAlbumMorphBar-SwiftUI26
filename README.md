# AwemeLiquidBar 1.0.52h
## 1.0.52h avatar-bound download fix

- Right-side download visibility now follows the actually visible profile avatar.
- Download X is exactly the avatar center; vertical spacing is derived from the avatar/glass diameter plus an 8 pt edge gap.
- Transient right-stack geometry rejection no longer hides a button while the avatar is still visible.
- Geometry-only layout keeps the singleton download control synchronized even on feeds where no action-slot cache has been created yet.


## 1.0.52h additions

- Fixes the Xcode 27 badge compile error by applying `badgePositionAdjustment` through `UITabBarItemStateAppearance` rather than `UITabBarItem`.
- Adds a `显示右侧下载按钮` switch. It is opt-in by default; turning it off immediately hides the singleton download control.
- Authorization table expanded from 29 to 30 encrypted entries; no plaintext account identifier is stored.

## 1.0.52h
- Stabilizes the singleton download button across preloaded/recycled feed cells: only the selected current right-action stack owns and moves it.
- Uses the right-action stack top edge as the download-button anchor instead of transient avatar views.
- Keeps a pending download menu/button visible while the current aweme model is briefly unavailable during paging.
- Improves current-stack scoring using the enclosing feed/player host to avoid previous/next cell ownership oscillation.
- Moves the Messages unread badge 6 pt inward so it stays comfortably inside the selected glass capsule.
- Friends caption behavior is intentionally unchanged in this build.


## Download visibility / transition throttle / Friends caption reserve

This build is based on **1.0.52b**. The encrypted **auth30** table, top-category centering, and the profile-fullscreen right-stack recovery are retained.

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