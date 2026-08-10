# AwemeLiquidBar 1.0.52i

## 1.0.52i stable floating download + badge direction fix

- The right-side download control is now a **true process-wide floating singleton hosted by the active normal app UIWindow**, not a child of a recycled feed cell.
- Its position is still derived from the actually visible profile avatar: X exactly matches the avatar center and Y keeps the established 8 pt edge gap.
- During the brief previous/current/next cell handoff, a 0.58 s owner-gap grace keeps the last valid button composited instead of writing `hidden/alpha` off then on. Hard routes such as comments/settings/search still hide immediately.
- Scheduled fullscreen compatibility recovery no longer hard-hides the button simply because one pass lands between two recycled feed cells.
- The current-aweme menu binding remains independent from visibility, so a temporary model lookup can show the pending menu without making the button disappear.
- Message unread-badge direction is corrected from device observation: the prior negative `badgePositionAdjustment` moved the badge visually right in the iOS 26 Liquid Glass tab layout. 1.0.52i uses positive offsets (normal +6 pt, selected +10 pt) to move it visually left, with the selected state farther inward from the capsule edge.
- Keeps auth30 and the opt-in `显示右侧下载按钮` switch.

### Downloader

The menu remains fully implemented inside AwemeLiquidBar; there is no runtime dependency on AwemeX or DYYY. Current actions are Save current video, Save current image / all images, Save audio, and Copy full caption.

### Authorization

Authorization remains the encrypted **29-entry** table. No accounts were added or removed.