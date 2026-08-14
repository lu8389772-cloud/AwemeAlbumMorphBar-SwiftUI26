# AwemeLiquidBar 1.0.56c16

Narrow follow-up to 1.0.56c15. It keeps the validated c8 playback lifecycle, c14/c15 article/avatar route fixes, and c10 true bottom-bar ownership release.

## 1.0.56c16 changes
- Adds authorization for `Wake54174`; authorization table now contains 38 unique accounts.
- The custom “显示液态底栏” ownership-release option remains restricted to the existing two compatibility accounts (`Hoeyc_0505` and `0416xxd`). `Wake54174` does not receive that option.
- Private-message forwarded works now use LiquidBar's semantic original tab identity. Douyin may report Messages as native selectedIndex 2 when Publish is omitted, so the previous hard-coded native index could leave fullscreen geometry and delayed right-stack recovery active inside IM media. Messages is now treated as semantic index 3 consistently.
- After closing comments, the plugin tracks only the known comment-input background containers and runs bounded post-dismiss transparency passes. This clears lingering opaque bottom surfaces/native tab backgrounds that otherwise could survive until the next feed item.
- No permanent timer, process-wide `UIView` hook, forced player control, or broad layout rewrite was added.

## Preserved
- Article Home-feed route correction.
- Avatar-editor route suppression.
- Search-result navigation isolation.
- Clean-screen hard no-show gate.
- Max-five bottom-bar entries and native Douyin Settings entry.
- Foreground/Friends playback lifecycle isolation.
