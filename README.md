# AwemeLiquidBar 1.0.52k

Focused rollback/stability build based on 1.0.52j.

- Messages unread badge: exact rollback to the original mirror implementation from before 1.0.52d. No plugin-defined `badgePositionAdjustment` is applied in any state.
- Download button host: moved out of Douyin's feed/root content into the independent resident AlbumMorph overlay, so presenting the UIMenu cannot scroll/re-layout the video feed and drop the caption to the physical bottom.
- Download geometry: uses only the plugin's 54 pt profile-glass plate as the anchor. No UIImageView/native-profile/profile fallback switching, eliminating the second downward step after the avatar settles.
- Download visibility: while a playable feed remains active, transient owner/avatar gaps keep the last valid button visible indefinitely. Only explicit blocked routes/settings/disabled state hide it.
- Position changes are applied without UIView/CoreAnimation animation.
- auth30 and the rest of 1.0.52j behavior are retained.
