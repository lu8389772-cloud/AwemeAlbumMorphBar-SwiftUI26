# AwemeLiquidBar 1.0.47a

- Native indicator-driven top selection pill: follows Douyin paging continuously instead of starting a spring after page selection.
- Single lightweight window-shift animation for hidden categories; removes the two-phase fade/translate rebuild.
- Removes the continuous recovery CADisplayLink and cuts delayed rescans to three bounded passes.
- Freezes top/right button material while the home feed is covered, preventing route-transition recolour flashes.
- Explicit white/black/accent/custom icon colours are re-applied to UIButtonConfiguration after every material update.
- Search remains independent of the top-category/menu switch.
