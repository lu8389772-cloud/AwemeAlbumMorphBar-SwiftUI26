# AwemeLiquidBar 1.0.46a

## Changes

- Replaces the failed segmented-control top bar with the Xiaohongshu/Telegram structure: one system Liquid Glass platter, one soft selected tint pill, plain title buttons, and at most four channels visible at once.
- Accounts with more than four channels reveal the remaining channels by swiping the group left or right, or by selecting an edge item.
- The top group is the automatic fallback for the left-button native menu morph. A working menu hides the group; disabling the menu or failing to install it brings the group back.
- Ports the verified 1.0.10b bottom-bar lifecycle to the current Swift native bar: the real glass tree remains resident and a left-to-right mask follows interactive return progress instead of hiding, fading, moving, or rebuilding the bar.
- Removes the delayed multi-retry route recovery that caused disappear/reappear cycles and uses one next-run-loop reconciliation.
- Keeps the 4×4 system tint resolver fully rendered in the physical bottom-left rounded screen corner while pausing only its low-frequency sampler, preventing a temporary white material branch on return.
- Resets the unstable chat-input experiment to off by default. With it off, the plugin does not alter the composer background, left action, text frame, or masks.

## Build

The GitHub workflow builds a rootless package with Xcode 27 and uploads `AwemeLiquidBar-1.0.46a-Xcode27-rootless`.
