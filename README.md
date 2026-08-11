# AwemeLiquidBar 1.0.52x

Rebuilt directly from the **1.0.52o** project. This build intentionally does not carry the later p-w clean-screen/layout experiments.

## Scope

- Only rebuilds the right-side action recovery after closing comments.
- Removes the old captured-stack pinning that could keep an obsolete `AWEElementStackView` alive.
- Lets Douyin / the external fullscreen tweak replace the native right-action stack normally.
- During a short 2.6 s post-comment window, actual `AWEFeedVideoButton` lifecycle/layout callbacks are the source of truth. When the native buttons exist again, the plugin rebinds/recreates the 46 pt glass slots on that exact current stack.
- Resets stale press/stretch transforms on repaired glass buttons.
- Adds bounded fallback passes only for cases where the native button does not emit a useful lifecycle callback.
- Leaves the 1.0.52o bottom bar, avatar menu, badges, download menu, Friends handling and auth33 otherwise unchanged.

## Diagnostic markers

`RIGHT_NATIVE_REPAIR_ARM`, `RIGHT_NATIVE_REPAIR`, and `RIGHT_NATIVE_REPAIR_PASS` are written to the interaction log.
