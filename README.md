# AwemeLiquidBar 1.0.53a

This build is a clean rebuild from **1.0.52o auth34**. It intentionally does not inherit the later 1.0.52p–1.0.52z experimental profile-stack, footprint, long-press, or clean-screen implementations.

## 1.0.53a scope

### Profile-video right actions
- Deletes the profile-only "keep the old AWEElementStackView alive" protection path.
- Profile video now uses the same native lifecycle repair strategy as Home: live `AWEFeedVideoButton` instances identify their real current `AWEElementStackView`, then the existing 46 pt Liquid Glass slots are recreated/rebound there.
- After a visible comment panel closes, only bounded rescans of *currently live native buttons* run. No captured old Stack is pinned, forced visible, or moved.
- Delayed `AWECommentInputViewController` helpers are recovery-transparent and cannot start a second route/right-action recovery.

### Photo paging + avatar menu
- Keeps the avatar interaction as **single tap**, not long press.
- The real avatar and its Liquid Glass visual remain in Douyin's native right stack.
- The menu presentation hit target is a transparent `UIWindow` child aligned over the real avatar. It is not a child of `AWEElementStackView`, so opening the menu cannot participate in Douyin's private photo-page stack layout.
- The full menu remains: `进入主页`, clean screen, save current item/all images/audio, and copy text.

### One-tap clean screen
- `一键清屏` is only a menu action; it does not reparent or recreate the real avatar.
- Hides status bar, top/left/right chrome, original bottom bar, and AlbumMorph LiquidBar while leaving the video/photo content and vertical feed swipe path intact.
- The window-level transparent avatar anchor remains at the real avatar position while clean screen is active.
- First tap at that position restores only the **real native avatar + real Liquid Glass avatar base**. Other chrome remains hidden.
- A subsequent single tap opens the same full menu, where the action becomes `退出清屏`.
- Exiting restores the suppressed views rather than replacing the avatar with a copied/temporary view.

### Preserved fixes
- Authorization table remains **auth34**, including the added `L1u7lnG` digest; no plaintext account identifier is stored.
- Messages unread badge is removed when its parsed count is 0; Friends badge mirroring remains supported.
- Independent floating download button remains retired; download/copy actions live in the avatar menu.
