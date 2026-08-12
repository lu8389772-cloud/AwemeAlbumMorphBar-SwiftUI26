# AwemeLiquidBar 1.0.56c1

This build is the **1.0.56c feature stage**, with only the later chat-return visibility experiment rolled back to the pre-experiment behavior.

## Preserved from 1.0.56c

- Internal fullscreen implementation and validated profile/live geometry.
- Clean-screen v2, including status-bar hiding and comment-area protection.
- Highest-bitrate / quality preference work.
- Centered adaptive Liquid Glass save HUD and media-type save menu wording.
- Fullscreen setting name `全屏播放` without the third-party compatibility hint.
- Cold-start top-category suppression improvements.
- 1.0.56c settings-route handling and all unrelated LiquidBar features.

## Rolled back

The chat-return experiment is not kept in this build. The sensitive chat-route classifier, overlay fraction suppression, and transition-completion ordering are restored to the 1.0.56a behavior. This build intentionally makes **no new attempt to repair chat swipe-back animation**.

The purpose is to recover the Messages-page bottom-bar lifecycle without discarding the rest of the 1.0.56c work.
