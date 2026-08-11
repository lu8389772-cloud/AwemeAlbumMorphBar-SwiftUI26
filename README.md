# AwemeLiquidBar 1.0.52z

Built from the clean 1.0.52o auth34 line through the minimal 1.0.52y right-action fix.

1.0.52z changes only the delayed `AWECommentInputViewController` lifecycle handling:

- the helper is treated as a bookkeeping-only controller, not a visible route;
- its `viewDidAppear` does not schedule fullscreen/right/bar recovery;
- its `viewWillDisappear` does not prewarm or restart the bar visibility driver;
- its `viewDidDisappear` may unregister sensitive-route bookkeeping, but cannot schedule AlbumMorph route recovery, transition recovery, home-chrome recovery, or a new right-action rebind generation;
- visible comment-panel dismissal remains the only comment-close event that can schedule right-action rebind.

Auth table remains auth34. No clean-screen, footprint-guard, Context Menu, or later experimental layout code is included.
