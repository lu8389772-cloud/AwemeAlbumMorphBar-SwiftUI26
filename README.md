# AwemeLiquidBar 1.0.40b

Based on 1.0.39. The home top-left 46 pt SwiftUI Liquid Glass button is the real UIKit menu source. A synchronous native `UIMenu` contains four `UIAction` rows: 直播、商城、关注、推荐. No empty deferred element is used.

The menu uses `showsMenuAsPrimaryAction` and large menu elements. Selecting a row performs a bounded search for the matching visible Douyin top-channel control and triggers its existing control/gesture/accessibility path.
