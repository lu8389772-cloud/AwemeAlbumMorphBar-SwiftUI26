# AwemeLiquidBar 1.0.50b

Consolidated compatibility/interaction update based on 1.0.49e. The encrypted authorization table remains **29 entries**.

## Changes

- **Cross-version bottom-tab forwarding**: keeps the proven target/action path first, then adds compatible tap-gesture discovery and conservative controller index-route fallback for Douyin builds that return `TAB_FORWARD ... no-route`.
- **External AwemeX bridge (soft dependency)**: when `AwemeX.dylib` is loaded and exposes supported runtime selectors, a native 46 pt Liquid Glass menu button is placed above the right-side avatar. The menu can bridge `saveCurrentVideo`, `saveImages`, `saveAudio`, `copyCompleteText`, and optionally `tcShowDownloadOptions`. If the external plugin is absent or no selector is available, the button stays hidden and AwemeLiquidBar remains independent.
- **Two-finger settings gesture guard**: adds `双指长按仅在‘我’页面触发`; default is ON to avoid collisions with immersive/relax-video gestures. Turning it OFF restores global behavior.
- **Friends-feed bottom-bar persistence**: on a real Friends second tab (not Shop), Douyin's content-driven hidden flag no longer removes the resident LiquidBar; route-level hiding for profile/search/share/comments/publish/commerce is still respected.
- **Native glass press feedback**: search, right-side actions, avatar and the external bridge menu forward the real touch owner's press state into the visual system glass button, restoring UIKit highlight/deformation without stealing the original action.
- **Messages unread badge**: optional `显示消息未读角标` switch (default OFF). The original message badge value/dot is mirrored onto the Messages `UITab`, so it follows custom item ordering automatically.
- Keeps the 1.0.48 publish/share/PNG/commerce stability fixes, single-artwork bottom-icon model, and existing right-side comment recovery diagnostics.

## External bridge notes

The bridge does **not** copy or reimplement the other plugin's downloader. It performs runtime capability detection and sends the action only to a currently live object that responds to the corresponding selector. Direct selector availability is statically detectable, but the exact live target still requires device validation with that plugin/version installed. Diagnostic mode records `BRIDGE_PLUGIN_FOUND` and `BRIDGE_ACTION`.

## Authorization

Authorization remains the existing encrypted **auth29** table; no authorization entries were added or removed in 1.0.50b.
## 1.0.50b top category centering fix

The Telegram-style top category group is now always centered on the physical top-bar/container midpoint. When the left action, right search action, or both are hidden, the layout reserves symmetric side clearance so 1–4 visible category titles no longer drift horizontally. This is a geometry-only change on top of 1.0.50a; auth29 and the 1.0.50a feature set are retained.
