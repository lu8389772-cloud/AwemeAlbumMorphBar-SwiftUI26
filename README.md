# AwemeLiquidBar 1.0.47d

- Native indicator-driven top selection pill: follows Douyin paging continuously instead of starting a spring after page selection.
- Single lightweight window-shift animation for hidden categories; removes the two-phase fade/translate rebuild.
- Removes the continuous recovery CADisplayLink and cuts delayed rescans to three bounded passes.
- Freezes top/right button material while the home feed is covered, preventing route-transition recolour flashes.
- Explicit white/black/accent/custom icon colours are re-applied to UIButtonConfiguration after every material update.
- Search remains independent of the top-category/menu switch.


## 1.0.47d
- 顶部分组标题固定白色。
- 选中胶囊跟随同步降为短时 30 Hz，并增加亚像素去重，降低发热。
- 授权摘要表扩展为 26 项，并增加第二级摘要标签预筛选。
