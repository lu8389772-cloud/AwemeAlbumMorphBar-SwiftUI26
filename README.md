# AwemeLiquidBar 1.0.56c8

Focused stability follow-up based directly on the 1.0.56c2 performance-cleanup build.

Preserved:
- all 1.0.56c-stage UI/fullscreen/clean-screen/save-HUD behavior;
- the 1.0.56c1 chat-return rollback scope;
- the 1.0.56c2 performance cleanup;
- the existing 36-entry authorization table.

New fixes in 1.0.56c8:
- adds a DYYY-style native Douyin settings shortcut: both current sidebar Settings layout variants are hooked narrowly, a `LiquidBar` button is attached beside the native `设置` entry, and it opens the existing LiquidBar settings sheet without depending on the two-finger gesture or bottom-bar layout;
- enforces a hard maximum of five visible bottom entries; once five are enabled, the remaining switch is disabled/greyed so UIKit never enters its broken sixth-tab More path;
- profile-only two-finger settings gesture now fails open when the `我` entry is disabled, preventing a configuration lockout;
- highest-quality playback no longer replaces Douyin's adaptive bitrate set with one model and no longer rewrites `playURL` / force-switches a live private player. It preserves every native bitrate model, biases higher bitrate first, and gives native playback a 2-second foreground-resume grace window;
- Friends unread badge now requires a positive numeric unread count, so a stale native empty badge shell at count 0 no longer becomes a permanent red dot.

No settings-drawer/chat-return/progress-bar experiments from 1.0.56d+ are reintroduced.

- 1.0.56c8 injects a LiquidBar row into Douyin’s real Settings page through AWESettingsViewModel, matching DYKiller’s model-level approach.


## 1.0.56c8
Playback lifecycle isolation: stop forcing Friends native-tab layout during player activation and make foreground restoration overlay-only. No forced play/pause calls.
