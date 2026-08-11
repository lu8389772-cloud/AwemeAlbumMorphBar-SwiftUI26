# AwemeLiquidBar 1.0.52o

This build is rebuilt from the **1.0.52c stable baseline**, not from 1.0.52m.

## 1.0.52o scope

- Retains the 1.0.52c profile-fullscreen/comment right-action recovery path.
- Retires the independent floating download button. No right-action/profile geometry can position a separate download control.
- A single tap on the plugin-owned avatar glass base now opens a native menu. `进入主页` and the current-item download/copy actions are in that menu.
- Adds `头像菜单显示下载功能`; it only changes menu contents and cannot alter layout.
- Restores native `badgeValue` rendering for Messages and mirrors the same path to Friends. Shop promotional badges are not mirrored as Friends unread counts.
- Native badge visuals receive a bounded 0.90 scale after UIKit lays them out.
- Uses a 36-entry local opaque authorization digest table; no plaintext account identifiers are stored.
