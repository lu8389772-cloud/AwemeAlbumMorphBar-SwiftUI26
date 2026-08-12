# AwemeLiquidBar 1.0.56c2

Performance-cleanup build based directly on the verified 1.0.56c1 chat-return rollback baseline.

Preserved: all 1.0.56c-stage features and the 1.0.56c1 chat-return rollback. Authorization data remains unchanged (36 digest entries).

Performance changes only:
- removes the process-wide `%hook UIView` used by fullscreen/clean-screen; player fullscreen correction now runs only from known player-controller layout callbacks and their local view trees;
- caches native top-category suppression targets, avoiding the old up-to-500-view BFS on every top-bar layout;
- removes clean-screen whole-window reapply scheduling from generic layout callbacks while retaining bounded rescans on reuse/model/index changes and exact per-control hooks;
- lowers steady Liquid Glass appearance polling from 4 Hz to 2 Hz and adds an event-driven refresh after feed index changes.

No authorization, chat-return, route, save-HUD, fullscreen preference, or settings behavior is intentionally changed.
