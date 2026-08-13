#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Photos/Photos.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <math.h>
#include <mach-o/dyld.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

/*
 AwemeLiquidBar 1.0.56c13 — fullscreen + clean/status fixes + adaptive glass save HUD + native badges + auth37 + visual-only bottom-bar toggle

 Fullscreen/clean consolidation release:
 - starts from the verified 1.0.55a stable baseline; unrelated layout experiments remain excluded;
 - integrates the independently validated 0.5.1 fullscreen geometry as an internal, switchable module;
 - preserves the validated media-vs-overlay separation on profile/detail videos and the validated 0.3.1 live-prestream compensation;
 - clean screen remains display-only (opacity/interaction only) but now explicitly covers bottom bar, danmaku, landscape-entry, video progress, image/page progress and chapter progress;
 - clean state is reapplied on feed reuse/index transitions so sliding to the next video/image cannot resurrect native chrome;
 - clean screen still exits from the same invisible avatar-menu hit target, with no replacement avatar or hierarchy reparenting;
 - external DYYY/AwemeX fullscreen should be disabled when the internal fullscreen mode is enabled.

 Regression restore release:
 - restores the proven hard-suspend path for publish and share/forward sheets so
   the independent AlbumMorph UIWindow cannot intercept dismissal or lower-page
   controls while those destinations are presented;
 - restores imported PNG pixel semantics at @3x (with the established 100 px
   longest-edge cap) before images enter UIKit UIButtonConfiguration;
 - keeps transient commerce/group-buy sheets outside plugin bottom-bar ownership
   and records their controller classes only when diagnostics are enabled;
 - preserves the current top switcher, cached glass buttons, avatar glass,
   authorization table and low-frequency adaptive-material behavior.

 This release keeps the 1.0.49e route fixes and adds conservative compatibility paths:
 - cross-version bottom-tab forwarding when Douyin changes its private button gesture;
 - a native current-item downloader that reads Douyin's live aweme/video models directly;
 - native Liquid Glass press feedback restoration for visual-only top/right controls;
 - an optional profile-only two-finger settings gesture guard;
 - Friends-feed bottom-bar persistence and a sortable Messages unread badge mirror;
 - reliability-first video/image saving plus opt-in (not default) highest-playback probing.
*/

@interface AWENormalModeTabBar : UIView
@end

@interface AWENormalModeTabBarController : UIViewController
- (NSArray *)buttons;
@end

@interface AWESearchViewController : UIViewController
@end

/* Minimal declarations for Douyin's native Settings model. DYKiller injects
   its entry through these runtime classes instead of the sidebar view tree. */
@interface AWESettingItemModel : NSObject
@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *detail;
@property(nonatomic, assign) NSInteger type;
@property(nonatomic, assign) NSInteger cellType;
@property(nonatomic, assign) NSInteger colorStyle;
@property(nonatomic, assign) BOOL isEnable;
@property(nonatomic, copy) NSString *svgIconImageName;
@property(nonatomic, copy) void (^cellTappedBlock)(void);
@end

@interface AWESettingSectionModel : NSObject
@property(nonatomic, copy) NSString *sectionHeaderTitle;
@property(nonatomic, assign) CGFloat sectionHeaderHeight;
@property(nonatomic, assign) NSInteger type;
@property(nonatomic, copy) NSArray *itemArray;
@end

@interface AWESettingsViewModel : NSObject
@property(nonatomic, copy) NSArray *sectionDataArray;
@property(nonatomic, weak) id controllerDelegate;
@end

@interface AWEIMOptimizeAudioInputTouchView : UIView
@end

@interface AWEFeedVideoButton : UIView
@end

@interface AWEHPTopBarCTAItemView : UIView
@end

@interface AWELeftSideBarEntranceView : UIView
@end

@interface AWEHPSearchBubbleEntranceView : UIView
@end

@interface AWEHPDiscoverFeedEntranceView : UIView
@end

@interface AWEAlbumMorphOverlayWindow : UIWindow
@property(nonatomic, weak) UITabBar *managedTabBar;
@property(nonatomic, strong) UIView *searchTouchProxy;
@property(nonatomic, assign) BOOL contentVisible;
@end

@protocol AWEAlbumMorphActionSink;

extern void *AWEAlbumMorphCreateController(void);
void AWEAlbumMorphRegisterContentScrollView(UIViewController *controller,
                                             UIScrollView *scrollView);
int32_t AWEAlbumMorphRequestNativeMinimized(UIViewController *controller,
                                             int32_t minimizedValue,
                                             int32_t animatedValue);

@interface AWEPhotosExactGlassButtonHostView : UIView
- (void)updateWithImage:(UIImage *)image
              pointSize:(CGFloat)pointSize
            controlSize:(CGFloat)controlSize
        foregroundColor:(nullable UIColor *)foregroundColor
 preserveOriginalImage:(BOOL)preserveOriginalImage
           tintedGlass:(BOOL)tintedGlass;
@end

@interface AWEAlbumMorphTabController : UITabBarController
@property(nonatomic, weak) id actionSink;
- (void)configureSecondTabAsShop:(BOOL)shop;
- (void)configureVisibleItemIdentifiers:(NSArray<NSString *> *)identifiers;
- (void)updateMessageBadgeValue:(nullable NSString *)value;
- (void)updateSecondBadgeValue:(nullable NSString *)value;
- (void)reloadConfiguredImages;
- (void)updateAccentColor:(UIColor *)color;
- (void)setForcedDark:(BOOL)forced;
- (void)setResolvedInterfaceStyleRaw:(NSInteger)rawValue;
- (void)setMorphBarVisible:(BOOL)visible animated:(BOOL)animated;
- (void)setVisibleFraction:(CGFloat)fraction animated:(BOOL)animated;
- (void)setVerticalOffset:(CGFloat)offset;
- (void)syncSelectedOriginalIndex:(NSInteger)index;
- (NSInteger)currentOriginalIndex;
- (void)mirrorSourceScrollOffset:(CGFloat)offset;
- (void)bindSourceScrollView:(UIScrollView *)scrollView;
- (void)setCompactMode:(BOOL)compact animated:(BOOL)animated;
@end

@interface AWEPlayInteractionViewController : UIViewController
@property(nonatomic, strong) NSString *referString;
@property(nonatomic, assign) BOOL isCommentVCShowing;
- (void)performCommentAction;
- (void)onVideoPlayerViewDoubleClicked:(id)sender;
@end

/*
 1.0.40b: these helpers are used by the bottom-search configuration saver
 before the main forward-declaration block later in the file. Keep their
 static prototypes here so Clang never creates implicit int declarations.
*/
static UIWindow *AWEActiveMainWindow(void);
static UIView *AWEFindViewByExactRuntimeClass(UIView *root,
                                              NSString *className,
                                              NSUInteger depth);
static void AWEScheduleTopActionContainerRefresh(UIView *container);
static void AWEStartHomeChromeRecoverySampler(void);
static void AWESchedulePostCommentRightRebind(NSString *reason);
static NSString *AWECurrentRightActionStackSummary(void);
static UIView *AWEFindCurrentRightActionStackAcrossWindows(void);
static BOOL AWEAnyVisibleCommentPanelForRightRecovery(void);
static BOOL AWEFrameLooksLikeCurrentRightActionStack(UIView *stack);
static BOOL AWEClassNameLooksLikePlayableFeedController(NSString *className);
static BOOL AWECurrentRouteHasPlayableFeedController(void);
static BOOL AWEForceRestoreRightActionStackAfterComment(UIView *stack);
static UIMenu *AWEAvatarBaseMenuForStack(UIView *stack, UIView *profileHost);
static void AWEStableEnterCleanScreenFromStack(UIView *stack);
static void AWEStableExitCleanScreen(void);
static void AWEStableApplyCleanScreenGlobal(void);
static void AWEScheduleCleanScreenReapply(NSString *reason);
static void AWEStableCleanEnforceBottomBarSuppression(void);
static void AWEInternalFSLayoutInteractionController(UIViewController *vc);
static void AWEInternalFSHandleElementStackLayout(UIView *stack);
static void AWEInternalFSTabBarUpdate(UIView *tabBar);
static BOOL AWECustomBottomBarReleaseAllowed(void);

static char kAWENativeBarKey;
static char kAWEDelegateKey;
static char kAWEApplyingKey;
static char kAWEOriginalHiddenKey;
static char kAWEOriginalChildHiddenStateKey;
static char kAWEOriginalChildAlphaStateKey;
static char kAWEControllerKey;
static char kAWELastFrameKey;
static char kAWELastVisibleFrameKey;
static char kAWEColdStartBackplateKey;
static char kAWETransitionPrewarmTokenKey;
static char kAWESettingsGestureKey;
static char kAWELogSignatureKey;
static char kAWEWanStylingKey;
static char kAWEComposerProbeCountKey;
static char kAWEComposerProbeLastSignatureKey;
static char kAWEInputControllerProbeCountKey;
static char kAWEChatCapsuleMaskKey;
static char kAWEChatOriginalRadiusKey;
static char kAWEChatOriginalMasksKey;
static char kAWEChatOriginalClipsKey;
static char kAWEChatTextBaseFrameKey;
static char kAWEChatTextAppliedFrameKey;
static char kAWEChatPlaceholderBaseFrameKey;
static char kAWEChatPlaceholderAppliedFrameKey;
static char kAWEVisibilityMaskKey;
static char kAWEVisibilityCoordinatorRegistrationKey;
static char kAWEStableCleanMarkerKey;
static char kAWEStableCleanOriginalOpacityKey;
static char kAWEStableCleanOriginalInteractionKey;
static char kAWEFSLiveElementBaseTransformKey;
static char kAWEFSLiveIESBaseTransformKey;
static char kAWEFSCommentDirectBackgroundKey;
static char kAWEHomeActionGlassKey;
static char kAWEHomeActionProxyKey;
static char kAWEHomeActionProxyTargetKey;
static char kAWEHomeActionOriginalImageViewKey;
static char kAWEHomeActionSymbolOverlayKey;
static char kAWEHomeActionSourceOwnerKey;
static char kAWEHomeActionSourceHiddenKey;
static char kAWEHomeActionSourceAlphaKey;
static char kAWEHomeActionKindKey;
static char kAWEHomeActionRetryGenerationKey;
static char kAWEHomeActionStackSlotsKey;
static char kAWEHomeActionStackRetryGenerationKey;
static char kAWEHomeActionStackApplyingKey;
static char kAWEHomeActionStackRefreshPendingKey;
static char kAWEHomeActionStackLastLayoutRefreshKey;
static char kAWEGlassPressFeedbackRecognizerKey;
static char kAWEGlassPressFeedbackTargetKey;
static char kAWEExternalBridgeMenuSlotKey;
static char kAWEExternalBridgeMenuButtonKey;
static char kAWEExternalBridgeMenuModelIdentityKey;
static char kAWEExternalBridgeMenuConfigGenerationKey;
static char kAWETopActionRefreshPendingKey;
static char kAWEImageAverageColorCacheKey;
static char kAWEAdaptiveGlassConfigurationSignatureKey;
static char kAWEAdaptiveGlassTransparentKey;
static char kAWEAdaptiveGlassStrongEdgeKey;
static char kAWEAdaptiveGlassAutomaticContrastKey;
static char kAWEAdaptiveGlassForegroundLightKey;
static char kAWEAdaptiveGlassLastSampleTimeKey;
static char kAWEAdaptiveGlassExplicitForegroundKey;
static char kAWEAdaptiveGlassBaseImageKey;
static char kAWEAdaptiveGlassUpdateHandlerInstalledKey;
static char kAWEAdaptiveGlassAppliedForegroundSignatureKey;
static char kAWEHomeGlassTintViewKey;
static char kAWETopActionRetryGenerationKey;
static char kAWETopMenuMorphInstalledKey;
static char kAWETopMenuMorphForwardingKey;
static char kAWETopMenuSignatureKey;
static char kAWETopCategoryHiddenMarkerKey;
static char kAWETopCategoryOriginalLayerOpacityKey;
static char kAWETopCategoryIndicatorMarkerKey;
static char kAWETopCategoryIndicatorOriginalAlphaKey;
static char kAWETopCategoryIndicatorOriginalHiddenKey;
static char kAWETopCategoryIndicatorOriginalLayerOpacityKey;
/* 1.0.56c13: cache the already-identified native top-category views so the
   500-node BFS does not run on every AWEFeedTopBarContainer layout pass. */
static char kAWETopCategorySuppressionCacheKey;
static char kAWETopCategorySuppressionCacheDirtyKey;
static char kAWETopCategorySuppressionCacheSubviewCountKey;
static char kAWETopMenuSlotKey;
static char kAWETopSearchSlotKey;
static char kAWETopSourceHiddenKey;
static char kAWETopSourceAlphaKey;
static char kAWETopSourceSlotKey;
static char kAWETopOwnerLayerOpacityKey;
static char kAWETopOwnerInteractionKey;
static char kAWETopOwnerSlotKey;
static char kAWETopMenuForcedHiddenKey;
static char kAWETabBarSymbolSignatureKey;
static char kAWEIconPresetNameKey;
static char kAWETopTelegramHostKey;
static char kAWETopTelegramGlassKey;
static char kAWETopTelegramScrollKey;
static char kAWETopTelegramPillKey;
static char kAWETopTelegramButtonsKey;
static char kAWETopTelegramTargetKey;
static char kAWETopTelegramSelectedIndexKey;
static char kAWETopTelegramTitlesSignatureKey;
static char kAWETopTelegramSourceOpacityKey;
static char kAWETopTelegramHiddenSourcesKey;
static char kAWETopLiquidGroupViewKey;
static char kAWETopLiquidGroupRefreshKey;
static char kAWEComposerRefreshPendingKey;
static char kAWEChatResolvedFillKey;
static char kAWEAlbumMorphOriginalOpacityKey;
static char kAWEAlbumMorphOriginalInteractionKey;
static char kAWEProfileGlassSlotKey;
static char kAWEProfileOriginalBackgroundKey;
static char kAWEProfileOriginalBorderWidthKey;
static char kAWEProfileOriginalBorderColorKey;
static char kAWEProfileVisualMarkerKey;
static char kAWEAlbumMorphCollapseGestureKey;
static char kAWEFriendsOriginalAdditionalSafeAreaInsetsKey;

typedef NS_ENUM(NSInteger, AWEHomeDiagnosticForegroundMode) {
    AWEHomeDiagnosticForegroundModeAutomatic = 0,
    AWEHomeDiagnosticForegroundModeForceWhite = 1,
    AWEHomeDiagnosticForegroundModeForceBlack = 2
};

static BOOL gAWEHomeDiagnosticEnabled = NO;
static NSUInteger gAWEHomeDiagnosticGeneration = 0;
static AWEHomeDiagnosticForegroundMode gAWEHomeDiagnosticForegroundMode =
    AWEHomeDiagnosticForegroundModeAutomatic;

static BOOL gAWESettingsVisible = NO;
static char kAWELiquidSettingsNativePushKey;
static BOOL gAWESecondTabRoleLoaded = NO;
static BOOL gAWESecondTabIsShop = NO;

/*
 The feed/right-side views remain in a LIGHT trait even when UIKit renders a
 dark glass material over a dark video. Therefore labelColor cannot be used as
 the source of truth. Track the foreground chosen by Douyin's own visible PNG
 and apply the same explicit white/black color to our Symbols.
*/
static BOOL gAWEHomeAdaptiveForegroundValid = NO;
static BOOL gAWEHomeAdaptiveForegroundIsLight = YES;

static dispatch_queue_t AWEHomeDiagnosticLogQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create(
            "com.xyy.awemeliquidbar.home-button-diagnostic",
            DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

static NSString *AWEHomeDiagnosticLogPath(void) {
    static NSString *path;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(
            NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documents = paths.firstObject;
        path = [[documents stringByAppendingPathComponent:
            @"AwemeLiquidBar_022h1.0.1_home_buttons.log"] copy];
    });
    return path;
}

static NSString *AWEHomeDiagnosticLoadedImagePath(void) {
    uint32_t count = _dyld_image_count();
    for (uint32_t index = 0; index < count; index++) {
        const char *name = _dyld_get_image_name(index);
        if (!name) continue;
        NSString *path = [NSString stringWithUTF8String:name];
        NSString *lower = path.lowercaseString;
        if ([lower containsString:@"awemeliquidbarhomenativebuttons"] ||
            [lower containsString:@"awemeliquidbar"]) {
            return path;
        }
    }
    return @"<image-not-found>";
}

static void AWEHomeDiagnosticWrite(BOOL force, NSString *format, ...) { (void)force; (void)format; }

static NSString *AWEHomeDiagnosticModeName(void) {
    switch (gAWEHomeDiagnosticForegroundMode) {
        case AWEHomeDiagnosticForegroundModeForceWhite: return @"FORCE_WHITE";
        case AWEHomeDiagnosticForegroundModeForceBlack: return @"FORCE_BLACK";
        default: return @"AUTOMATIC";
    }
}

static NSString *AWEHomeDiagnosticStyleName(UIUserInterfaceStyle style) {
    switch (style) {
        case UIUserInterfaceStyleLight: return @"LIGHT";
        case UIUserInterfaceStyleDark: return @"DARK";
        default: return @"UNSPECIFIED";
    }
}

static NSString * const kAWEAccentHexDefaultsKey = @"AwemeLiquidBarAccentHex";
static NSString * const kAWEAccentHistoryDefaultsKey =
    @"AwemeLiquidBarAccentHistory";
static NSString * const kAWEChatCapsuleEnabledDefaultsKey =
    @"AwemeLiquidBarChatCapsuleEnabled1.0.46";
static NSString * const kAWEChatSeparateLeftDefaultsKey =
    @"AwemeLiquidBarChatSeparateLeft1.0.46";
static NSString * const kAWELowerHalfDoubleTapCommentDefaultsKey =
    @"AwemeLiquidBarLowerHalfDoubleTapComment";
static NSString * const kAWEVerticalOffsetDefaultsKey =
    @"AwemeLiquidBarVerticalOffset";
static NSString * const kAWEAlbumMorphCollapseEnabledDefaultsKey =
    @"AwemeLiquidBarAlbumMorphCollapseEnabledV2";
static NSString * const kAWEDoubleTapLikeFractionDefaultsKey =
    @"AwemeLiquidBarDoubleTapLikeFraction";
static NSString * const kAWEWanToWDefaultsKey =
    @"AwemeLiquidBarWanToW";
static NSString * const kAWEHomeCustomPNGModeDefaultsKey =
    @"AwemeLiquidBarHomeCustomPNGMode";
static NSString * const kAWETopGlassEnabledDefaultsKey =
    @"AwemeLiquidBarTopGlassEnabled";
static NSString * const kAWEHideTopLeftButtonDefaultsKey =
    @"AwemeLiquidBarHideTopLeftButtonV1";
static NSString * const kAWEHomeTransparentGlassDefaultsKey =
    @"AwemeLiquidBarHomeTransparentGlassV1";
static NSString * const kAWETopTelegramSwitcherEnabledDefaultsKey =
    @"AwemeLiquidBarTopTelegramSwitcherEnabled1.0.1";
static NSString * const kAWETopTelegramVisibleCountDefaultsKey =
    @"AwemeLiquidBarTopTelegramVisibleCount1.0.1";
static NSString * const kAWETopMenuMorphEnabledDefaultsKey =
    @"AwemeLiquidBarTopMenuMorphEnabled1.0.1";
static NSString * const kAWESymbolOverridesDefaultsKey =
    @"AwemeLiquidBarSymbolOverridesV1";
static NSString * const kAWESymbolColorModesDefaultsKey =
    @"AwemeLiquidBarSymbolColorModesV1";
static NSString * const kAWESymbolCustomColorsDefaultsKey =
    @"AwemeLiquidBarSymbolCustomColorsV1";
static NSString * const kAWESecondTabShopDefaultsKey =
    @"AwemeLiquidBarSecondTabShopV1";
static NSString * const kAWEInteractionDiagnosticEnabledDefaultsKey =
    @"AwemeLiquidBarInteractionDiagnosticEnabledV1";
static NSString * const kAWEHomeForceDarkGlassDefaultsKey =
    @"AwemeLiquidBarHomeForceDarkGlassV1";
static NSString * const kAWEHideBottomTitlesDefaultsKey =
    @"AwemeLiquidBarHideBottomTitlesV1";
static NSString * const kAWEBottomBarDisplayEnabledDefaultsKey =
    @"AwemeLiquidBarBottomBarDisplayEnabledV1";
static NSString * const kAWESettingsGestureMineOnlyDefaultsKey =
    @"AwemeLiquidBarSettingsGestureMineOnlyV1";
static NSString * const kAWEMessageBadgeEnabledDefaultsKey =
    @"AwemeLiquidBarMessageBadgeEnabledV1";
static NSString * const kAWEAvatarMenuDownloadEnabledDefaultsKey =
    @"AwemeLiquidBarAvatarMenuDownloadEnabledV1";
static NSString * const kAWEPreferHighestPlaybackDefaultsKey =
    @"AwemeLiquidBarPreferHighestPlaybackV1";
static NSString * const kAWEAlbumMorphStyleDefaultsKey =
    @"AwemeLiquidBarAlbumMorphStyleV1";
static NSString * const kAWEInternalFullscreenDefaultsKey =
    @"AwemeLiquidBarInternalFullscreenV1";
static NSString * const kAWEAlbumMorphItemOrderDefaultsKey =
    @"AwemeLiquidBarAlbumMorphItemOrderV1";
static NSString * const kAWEAlbumMorphEnabledItemsDefaultsKey =
    @"AwemeLiquidBarAlbumMorphEnabledItemsV1";

static __weak AWENormalModeTabBar *gAWELastTabBar = nil;
static __weak AWENormalModeTabBarController *gAWELastController = nil;
static NSUInteger gAWERecoveryGeneration = 0;
static BOOL gAWETransitionDiagnosticsEnabled = NO;
static BOOL gAWESearchPageVisible = NO;
static AWEAlbumMorphTabController *gAWEAlbumMorphController = nil;
static UIWindow *gAWEAlbumMorphOverlayWindow = nil;
static UIVisualEffectView *gAWEAlbumMorphTintProbe = nil;
static CADisplayLink *gAWEAlbumMorphTintDisplayLink = nil;
static id gAWEAlbumMorphTintDisplayLinkTarget = nil;
static __weak UIWindow *gAWEAlbumMorphTintProbeWindow = nil;
static UIUserInterfaceStyle gAWEAlbumMorphLastMirroredStyle = UIUserInterfaceStyleUnspecified;
static UIUserInterfaceStyle gAWEAlbumMorphLastAppliedStyle = UIUserInterfaceStyleUnspecified;
static UIUserInterfaceStyle gAWEHomeChromeLastStableStyle = UIUserInterfaceStyleUnspecified;
static UIUserInterfaceStyle gAWEHomeChromePendingStyle = UIUserInterfaceStyleUnspecified;
static NSUInteger gAWEHomeChromeStyleGeneration = 0;
static NSHashTable<UIButton *> *gAWEAdaptiveGlassButtons = nil;
static NSUInteger gAWEAdaptiveContrastRoundRobinIndex = 0;
static NSUInteger gAWEConfiguredIconGeneration = 1;
static id gAWEAlbumMorphCoordinator = nil;
static BOOL gAWEAlbumMorphVisible = NO;
static BOOL gAWEAlbumMorphCompact = NO;
static __weak UIWindow *gAWEAlbumMorphCollapseGestureWindow = nil;
static UIPanGestureRecognizer *gAWEAlbumMorphCollapseGesture = nil;
static id gAWEAlbumMorphCollapseGestureDelegate = nil;
static __weak UIView *gAWEAlbumMorphSuppressedOriginalBar = nil;
static UIGestureRecognizer *gAWEAlbumMorphSearchGesture = nil;
static __weak UIView *gAWEAlbumMorphSearchGestureOriginalView = nil;
static UIView *gAWEAlbumMorphSearchTouchProxy = nil;
static NSUInteger gAWEAlbumMorphRouteRecoveryGeneration = 0;
static CFTimeInterval gAWEAlbumMorphPublishLaunchSuppressionUntil = 0.0;
static __weak UIViewController *gAWEAlbumMorphPublishSourceController = nil;
static CGRect gAWEAlbumMorphLastAlignedFrame = {{0.0, 0.0}, {0.0, 0.0}};
static __weak UIWindow *gAWEAlbumMorphLastAlignedSourceWindow = nil;
static CFTimeInterval gAWESensitiveEntrySuppressionUntil = 0.0;
static NSHashTable *gAWESensitiveVisibleControllers = nil;
static NSHashTable<UIView *> *gAWEVisibleMessagingComposers = nil;
static __weak UIView *gAWEHomeFeedTopContainer = nil;
static NSHashTable *gAWECommerceProductDetailMarkers = nil;
static CFTimeInterval gAWECommerceSuppressionUntil = 0.0;
static BOOL gAWECommentRightRebindPending = NO;
static NSUInteger gAWECommentRightRebindGeneration = 0;
static NSString *gAWECommentRightHostBefore = nil;
static __weak UIView *gAWECommentRightStackBefore = nil;
static BOOL gAWEFriendsTabLatched = NO;
static NSString *gAWEDownloadSlotProbeSignature = nil;

/* 1.0.55a clean screen is deliberately display-only. It never owns layout. */
static BOOL gAWEStableCleanScreenEnabled = NO;
static __weak UIView *gAWEStableCleanScreenStack = nil;
static NSHashTable<UIView *> *gAWEStableCleanSuppressedViews = nil;
static NSUInteger gAWEStableCleanReapplyGeneration = 0;
static CFTimeInterval gAWEStableCleanLastReapplyTime = 0.0;

/* Internal fullscreen uses the measured Douyin tab-bar footprint from the
   validated standalone 0.5.1 geometry. Keep these independent of LiquidBar's
   visual bar height: they represent the native layout footprint only. */
static const CGFloat kAWEFSInvalidHeight = -1.0;
static CGFloat gAWEFSOriginalTabBarHeight = kAWEFSInvalidHeight;
static CGFloat gAWEFSCurrentTabBarHeight = kAWEFSInvalidHeight;


#pragma mark - iOS 26/27 global glass style and adaptive foreground

static NSInteger AWEOperatingSystemMajorVersion(void) {
    return NSProcessInfo.processInfo.operatingSystemVersion.majorVersion;
}

static BOOL AWEIsIOS27OrLater(void) {
    return AWEOperatingSystemMajorVersion() >= 27;
}

static BOOL AWEHomeForceDarkGlassEnabled(void) {
    /* Keep the historical preference key for upgrade compatibility, but the
       switch now applies only to the independent bottom-bar hierarchy. On
       iOS 27 the default is ON because the system backdrop probe is not stable
       inside Douyin's overlay window; iOS 26 keeps adaptive mode by default. */
    id stored = [NSUserDefaults.standardUserDefaults
        objectForKey:kAWEHomeForceDarkGlassDefaultsKey];
    if ([stored isKindOfClass:NSNumber.class]) {
        return [(NSNumber *)stored boolValue];
    }
    return AWEIsIOS27OrLater();
}

static BOOL AWEHideBottomTitlesEnabled(void) {
    return [NSUserDefaults.standardUserDefaults
        boolForKey:kAWEHideBottomTitlesDefaultsKey];
}

static BOOL AWEBottomBarDisplayEnabled(void) {
    /* 1.0.56c13: true bottom-bar ownership release is a two-account
       compatibility entitlement. Everyone else is forced to the normal
       LiquidBar-on path even if an old defaults value was left as OFF. */
    if (!AWECustomBottomBarReleaseAllowed()) return YES;
    id stored = [NSUserDefaults.standardUserDefaults
        objectForKey:kAWEBottomBarDisplayEnabledDefaultsKey];
    return [stored isKindOfClass:NSNumber.class] ? [(NSNumber *)stored boolValue] : YES;
}

static BOOL AWEInternalFullscreenEnabled(void) {
    id stored = [NSUserDefaults.standardUserDefaults
        objectForKey:kAWEInternalFullscreenDefaultsKey];
    return [stored isKindOfClass:NSNumber.class] ? [(NSNumber *)stored boolValue] : YES;
}

static BOOL AWESettingsGestureMineOnlyEnabled(void) {
    id stored = [NSUserDefaults.standardUserDefaults
        objectForKey:kAWESettingsGestureMineOnlyDefaultsKey];
    /* Keep the historical global gesture as the compatibility default. The
       profile-only guard is opt-in so a tab-identification mismatch can never
       lock a user out of the settings page after an update. */
    return [stored isKindOfClass:NSNumber.class] ? [(NSNumber *)stored boolValue] : NO;
}

static BOOL AWEMessageBadgeEnabled(void) {
    return [NSUserDefaults.standardUserDefaults
        boolForKey:kAWEMessageBadgeEnabledDefaultsKey];
}

static BOOL AWEAvatarMenuDownloadEnabled(void) {
    id stored = [NSUserDefaults.standardUserDefaults
        objectForKey:kAWEAvatarMenuDownloadEnabledDefaultsKey];
    return [stored isKindOfClass:NSNumber.class] ? [(NSNumber *)stored boolValue] : YES;
}

static BOOL AWEPreferHighestPlaybackEnabled(void) {
    id stored = [NSUserDefaults.standardUserDefaults
        objectForKey:kAWEPreferHighestPlaybackDefaultsKey];
    /* 1.0.55a: do not opt fresh installs into continuous player quality
       intervention. Users who explicitly enabled the switch keep their value. */
    return [stored isKindOfClass:NSNumber.class] ? [(NSNumber *)stored boolValue] : NO;
}

/* Swift native-tab bridge. Keep the exported ABI integer-based so the
   Objective-C++/Swift boundary does not depend on Bool ABI details. */
int32_t AWEAlbumMorphHideTitlesEnabled(void) {
    return AWEHideBottomTitlesEnabled() ? 1 : 0;
}

static BOOL AWEAlbumMorphCollapseEnabled(void) {
    /* 1.0.48a retires the experimental collapse path completely.  Keep the
       historical preference key only so old installs do not crash while
       loading settings; no gesture or compact transform is allowed to run. */
    return NO;
}

static BOOL AWESecondTabIsShop(void);
static BOOL AWEInstallOrUpdateAlbumMorphBar(UIView *originalBar,
                                             BOOL forceVisible);

static BOOL AWEAlbumMorphStyleEnabled(void) {
    /* The legacy replacement bar has been retired. The native customizable
       tab controller is now the only plugin bottom-bar implementation. */
    return YES;
}


static NSArray<NSString *> *AWEAlbumMorphAllItemIdentifiers(void) {
    return @[@"home", @"second", @"publish", @"messages", @"profile", @"search"];
}

static NSArray<NSString *> *AWEAlbumMorphDefaultVisibleItemIdentifiers(void) {
    return @[@"home", @"second", @"messages", @"profile", @"search"];
}

static BOOL AWEAlbumMorphItemIsSelectablePage(NSString *identifier) {
    return [@[@"home", @"second", @"messages", @"profile"]
        containsObject:identifier ?: @""];
}

static NSArray<NSString *> *AWEStoredAlbumMorphItemOrder(void) {
    NSArray *stored = [NSUserDefaults.standardUserDefaults
        arrayForKey:kAWEAlbumMorphItemOrderDefaultsKey];
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    NSSet<NSString *> *allowed = [NSSet setWithArray:AWEAlbumMorphAllItemIdentifiers()];
    for (id value in stored) {
        if (![value isKindOfClass:NSString.class] || ![allowed containsObject:value] ||
            [result containsObject:value]) continue;
        [result addObject:value];
    }
    for (NSString *identifier in AWEAlbumMorphAllItemIdentifiers()) {
        if (![result containsObject:identifier]) [result addObject:identifier];
    }
    return result;
}

static NSSet<NSString *> *AWEStoredAlbumMorphEnabledItemIdentifiers(void) {
    NSArray *stored = [NSUserDefaults.standardUserDefaults
        arrayForKey:kAWEAlbumMorphEnabledItemsDefaultsKey];
    NSArray<NSString *> *candidate = stored.count
        ? stored : AWEAlbumMorphDefaultVisibleItemIdentifiers();
    NSSet<NSString *> *allowed = [NSSet setWithArray:AWEAlbumMorphAllItemIdentifiers()];
    NSMutableSet<NSString *> *result = [NSMutableSet set];
    for (id value in candidate) {
        if (![value isKindOfClass:NSString.class] || ![allowed containsObject:value] ||
            [result containsObject:value]) continue;
        if (result.count >= 5) break;
        [result addObject:value];
    }
    NSUInteger selectableCount = 0;
    for (NSString *identifier in result) {
        if (AWEAlbumMorphItemIsSelectablePage(identifier)) selectableCount++;
    }
    if (selectableCount < 2) {
        return [NSSet setWithArray:AWEAlbumMorphDefaultVisibleItemIdentifiers()];
    }
    return result;
}

static NSArray<NSString *> *AWEAlbumMorphVisibleItemIdentifiers(void) {
    NSSet<NSString *> *enabled = AWEStoredAlbumMorphEnabledItemIdentifiers();
    NSMutableArray<NSString *> *visible = [NSMutableArray array];
    for (NSString *identifier in AWEStoredAlbumMorphItemOrder()) {
        if ([enabled containsObject:identifier] && ![identifier isEqualToString:@"search"]) {
            [visible addObject:identifier];
        }
    }
    if ([enabled containsObject:@"search"]) [visible addObject:@"search"];
    return visible;
}

static void AWESaveAlbumMorphItemConfiguration(NSArray<NSString *> *order,
                                                NSSet<NSString *> *enabled) {
    NSMutableArray<NSString *> *cleanOrder = [NSMutableArray array];
    NSSet<NSString *> *allowed = [NSSet setWithArray:AWEAlbumMorphAllItemIdentifiers()];
    for (id value in order) {
        if (![value isKindOfClass:NSString.class] || ![allowed containsObject:value] ||
            [cleanOrder containsObject:value]) continue;
        [cleanOrder addObject:value];
    }
    for (NSString *identifier in AWEAlbumMorphAllItemIdentifiers()) {
        if (![cleanOrder containsObject:identifier]) [cleanOrder addObject:identifier];
    }

    NSMutableArray<NSString *> *cleanEnabled = [NSMutableArray array];
    for (NSString *identifier in cleanOrder) {
        if (![enabled containsObject:identifier]) continue;
        if (cleanEnabled.count >= 5) break;
        [cleanEnabled addObject:identifier];
    }
    [NSUserDefaults.standardUserDefaults setObject:cleanOrder
        forKey:kAWEAlbumMorphItemOrderDefaultsKey];
    [NSUserDefaults.standardUserDefaults setObject:cleanEnabled
        forKey:kAWEAlbumMorphEnabledItemsDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];

    if (gAWEAlbumMorphController) {
        [gAWEAlbumMorphController
            configureVisibleItemIdentifiers:AWEAlbumMorphVisibleItemIdentifiers()];
    }
    if (AWEAlbumMorphStyleEnabled() && gAWELastTabBar) {
        AWEInstallOrUpdateAlbumMorphBar((UIView *)gAWELastTabBar, NO);
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = AWEActiveMainWindow();
        UIView *top = window ? AWEFindViewByExactRuntimeClass(
            window, @"AWEFeedTopBarContainer", 0) : nil;
        if (top) AWEScheduleTopActionContainerRefresh(top);
    });
}

static NSString *AWEAlbumMorphItemTitle(NSString *identifier) {
    if ([identifier isEqualToString:@"home"]) return @"首页";
    if ([identifier isEqualToString:@"second"]) return AWESecondTabIsShop() ? @"商城" : @"朋友";
    if ([identifier isEqualToString:@"publish"]) return @"发布";
    if ([identifier isEqualToString:@"messages"]) return @"消息";
    if ([identifier isEqualToString:@"profile"]) return @"我";
    if ([identifier isEqualToString:@"search"]) return @"搜索";
    return identifier ?: @"";
}

static NSString *AWEAlbumMorphItemDetail(NSString *identifier) {
    if ([identifier isEqualToString:@"publish"]) return @"即时打开原生发布入口，不停留选中";
    if ([identifier isEqualToString:@"search"]) return @"固定为右侧独立系统搜索圆钮";
    return @"映射到抖音原生页面";
}

static NSString *AWEAlbumMorphItemSymbol(NSString *identifier) {
    if ([identifier isEqualToString:@"home"]) return @"photo.on.rectangle.angled";
    if ([identifier isEqualToString:@"second"]) return AWESecondTabIsShop()
        ? @"storefront.fill" : @"hands.and.sparkles.fill";
    if ([identifier isEqualToString:@"publish"]) return @"plus";
    if ([identifier isEqualToString:@"messages"]) return @"message.fill";
    if ([identifier isEqualToString:@"profile"]) return @"person.crop.circle.fill";
    if ([identifier isEqualToString:@"search"]) return @"magnifyingglass";
    return @"circle";
}

static NSInteger AWECurrentOriginalMainTabIndex(void) {
    AWENormalModeTabBarController *controller = gAWELastController;
    if (controller) {
        for (NSString *key in @[@"selectedIndex", @"currentSelectedIndex", @"currentIndex"]) {
            @try {
                id value = [controller valueForKey:key];
                if ([value respondsToSelector:@selector(integerValue)]) {
                    NSInteger index = [value integerValue];
                    if (index >= 0 && index <= 4) return index;
                }
            } @catch (__unused NSException *exception) {}
        }

        NSArray *buttons = nil;
        @try { buttons = [controller buttons]; }
        @catch (__unused NSException *exception) { buttons = nil; }
        for (NSUInteger index = 0; index < MIN(buttons.count, (NSUInteger)5); index++) {
            id button = buttons[index];
            if ([button isKindOfClass:UIControl.class] && ((UIControl *)button).selected) {
                return (NSInteger)index;
            }
            @try {
                id selected = [button valueForKey:@"selected"];
                if ([selected respondsToSelector:@selector(boolValue)] && [selected boolValue]) {
                    return (NSInteger)index;
                }
            } @catch (__unused NSException *exception) {}
        }
    }

    if (gAWELastTabBar) {
        UITabBar *nativeBar = objc_getAssociatedObject(
            (UIView *)gAWELastTabBar, &kAWENativeBarKey);
        if (nativeBar.selectedItem) return nativeBar.selectedItem.tag;
    }
    return NSNotFound;
}


static NSInteger AWECurrentMainTabIndex(void) {
    if (AWEAlbumMorphStyleEnabled() && gAWEAlbumMorphController) {
        NSInteger index = [gAWEAlbumMorphController currentOriginalIndex];
        if (index != NSNotFound) return index;
    }
    return AWECurrentOriginalMainTabIndex();
}

static BOOL AWEHomeTabSelectedForNativeBar(UITabBar *nativeBar) {
    if (nativeBar.selectedItem) return nativeBar.selectedItem.tag == 0;
    return AWECurrentMainTabIndex() == 0;
}

/* 0.0.20a diagnostic state. These strings only de-duplicate log output;
   they do not participate in bar visibility or geometry. */
static NSString *gAWEProbeLastHierarchySignature = nil;
static NSString *gAWEProbeLastDecisionSignature = nil;
static NSString *gAWETransitionSurfaceLastSignature = nil;

/*
 0.0.20a visibility state:
 - steady pages follow Douyin's own AWENormalModeTabBar hidden/alpha signal;
 - the custom UITabBar stays warm at its final geometry;
 - a zero-width layer mask replaces the old off-screen parking state;
 - interactive pop reveals/hides the bar from the left using the real
   transition coordinator percentComplete.
*/
typedef NS_ENUM(NSInteger, AWEBarTransitionMaskMode) {
    AWEBarTransitionMaskModeNone = 0,
    AWEBarTransitionMaskModeReveal = 1,
    AWEBarTransitionMaskModeHide = 2
};

static BOOL gAWEBarStableStateInitialized = NO;
static BOOL gAWEBarStableVisible = YES;
static CGFloat gAWEBarLastVisibleFraction = -1.0;
static AWEBarTransitionMaskMode gAWEBarTransitionMaskMode =
    AWEBarTransitionMaskModeNone;
static BOOL gAWEBarTransitionFromVisible = YES;
static __weak id<UIViewControllerTransitionCoordinator>
    gAWEBarVisibilityCoordinator = nil;

/*
 Real-bar warmup state. The staged UITabBar is the same object later adopted by
 AWENormalModeTabBar; it is not a disposable substitute effect view.
*/
static UITabBar *gAWEStagedNativeBar = nil;
static UIView *gAWEStagedNativeBarHost = nil;
static NSUInteger gAWEActualBarWarmupGeneration = 0;
static NSUInteger gAWETransitionPrewarmGeneration = 0;
static CFTimeInterval gAWETransitionPrewarmUntil = 0.0;
static CFTimeInterval gAWEReturnRevealGraceUntil = 0.0;
static BOOL gAWEColdStartBackplateEverInstalled = NO;
static BOOL gAWEColdStartBackplateRetired = NO;

/*
 0.0.21d keeps the verified 0.0.21b cold-launch material bootstrap, but fixes its release order. This never replaces the native
 UITabBar visual provider. It only gives the real platter/lens a dark trait
 before their first visible frame, then removes that temporary override.
*/
static BOOL gAWENativeDarkBootstrapActive = NO;
static BOOL gAWENativeDarkBootstrapReleaseScheduled = NO;
static CFTimeInterval gAWENativeDarkBootstrapBeganAt = 0.0;

static UIViewController *AWETopViewControllerFrom(UIViewController *controller);
static UIWindow *AWEActiveMainWindow(void);
static UIView *AWEFindViewByExactRuntimeClass(UIView *root,
                                              NSString *className,
                                              NSUInteger depth);
static void AWEScheduleTopActionContainerRefresh(UIView *container);
static void AWEStartHomeChromeRecoverySampler(void);
static void AWEAttachNativeBarWithForce(UIView *tabBar, BOOL forceVisible);
static void AWEScheduleTransitionRecovery(void);
static void AWEProbeLogExpandedSnapshot(NSString *event,
                                        UIViewController *controller,
                                        BOOL force);
static void AWEProbeStartSampling(NSString *reason,
                                  UIViewController *controller);
static void AWETransitionSurfaceProbeStart(NSString *reason);
static void AWEStartBarVisibilityDriver(void);
static void AWEUpdateNativeBarVisibility(UIView *originalBar,
                                         UITabBar *nativeBar,
                                         NSString *reason);
static void AWEApplyNativeDarkBootstrap(UITabBar *nativeBar);
static void AWEScheduleNativeDarkBootstrapRelease(UITabBar *nativeBar);
static void AWEApplyHomeOnlyGlassStyleToNativeBar(UITabBar *nativeBar);
static void AWEApplyHomeOnlyGlassStyleToExistingSurfaces(void);
static UIVisualEffect *AWECreateHomeAdaptiveGlassEffect(void);
static void AWERefreshAllConfiguredIcons(void);
static AWENormalModeTabBar *AWEPrepareBarForController(id controller,
                                                       BOOL forceVisible);
static BOOL AWEAlbumMorphStyleEnabled(void);
static BOOL AWEInstallOrUpdateAlbumMorphBar(UIView *originalBar, BOOL forceVisible);
static void AWEUninstallAlbumMorphBar(void);
static void AWEApplyAlbumMorphResolvedAppearance(UIWindow *sourceWindow, NSInteger originalIndex);
static void AWEApplyAlbumMorphVisibleFraction(CGFloat fraction, NSString *reason, BOOL animated);
static void AWEUpdateAlbumMorphVisibility(UIView *originalBar, NSString *reason);
static void AWEApplyAlbumMorphOriginalSuppression(UIView *originalBar,
                                                    BOOL suppress);
static void AWEForceAlbumMorphRouteRecovery(NSString *reason);
static void AWEAlbumMorphProbeWrite(NSString *format, ...);
static void AWERestoreAlbumMorphSearchGesture(void);
static void AWEHideAlbumMorphTintProbe(void);



#pragma mark - Low-frequency interaction diagnostics

static CFTimeInterval gAWELastBottomHitDiagnosticTime = 0.0;

static BOOL AWEInteractionDiagnosticsEnabled(void) {
    return [NSUserDefaults.standardUserDefaults
        boolForKey:kAWEInteractionDiagnosticEnabledDefaultsKey];
}

static dispatch_queue_t AWEInteractionDiagnosticQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create(
            "com.xyy.awemeliquidbar.interaction-diagnostic",
            DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

static NSString *AWEInteractionDiagnosticPath(void) {
    static NSString *path;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *documents = NSSearchPathForDirectoriesInDomains(
            NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        path = [[documents stringByAppendingPathComponent:
            @"AwemeLiquidBar_1.0.56c13_interaction.log"] copy];
    });
    return path;
}

static void AWEInteractionDiagnosticClear(void) {
    NSString *path = AWEInteractionDiagnosticPath();
    dispatch_async(AWEInteractionDiagnosticQueue(), ^{
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    });
}

static void AWEInteractionDiagnosticWrite(NSString *format, ...) {
    if (!AWEInteractionDiagnosticsEnabled() || format.length == 0) return;
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    if (!message) return;

    NSString *path = AWEInteractionDiagnosticPath();
    dispatch_async(AWEInteractionDiagnosticQueue(), ^{
        NSFileManager *fm = NSFileManager.defaultManager;
        NSDictionary *attributes = [fm attributesOfItemAtPath:path error:nil];
        unsigned long long size = [attributes fileSize];
        if (size > 768 * 1024) {
            [fm removeItemAtPath:path error:nil];
        }
        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
        NSString *line = [NSString stringWithFormat:@"[%@] %@\n",
            [formatter stringFromDate:NSDate.date], message];
        NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
        if (![fm fileExistsAtPath:path]) {
            [data writeToFile:path atomically:YES];
        } else {
            NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
            @try {
                [handle seekToEndOfFile];
                [handle writeData:data];
                [handle closeFile];
            } @catch (__unused NSException *exception) {
                [handle closeFile];
            }
        }
    });
}

#pragma mark - 1.0.40b bounded route / scroll probe

static dispatch_queue_t AWEAlbumMorphProbeQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create(
            "com.xyy.awemeliquidbar.album-morph-probe",
            DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

static NSString *AWEAlbumMorphProbePath(void) {
    static NSString *path;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *documents = NSSearchPathForDirectoriesInDomains(
            NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
        path = [[documents stringByAppendingPathComponent:
            @"AwemeLiquidBar_1.0.56c13_probe.log"] copy];
    });
    return path;
}

static void AWEAlbumMorphProbeClear(void) {
    NSString *path = AWEAlbumMorphProbePath();
    dispatch_async(AWEAlbumMorphProbeQueue(), ^{
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    });
}

static void AWEAlbumMorphProbeWrite(NSString *format, ...) {
    /* Probe I/O is diagnostic-only. Earlier development builds wrote this log
       continuously even when the user had diagnostics disabled, which adds
       unnecessary file churn during feed/page transitions. */
    if (!AWEInteractionDiagnosticsEnabled() || format.length == 0) return;
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    if (!message) return;

    NSString *path = AWEAlbumMorphProbePath();
    dispatch_async(AWEAlbumMorphProbeQueue(), ^{
        NSFileManager *fm = NSFileManager.defaultManager;
        unsigned long long size = [[fm attributesOfItemAtPath:path error:nil] fileSize];
        if (size > 1024 * 1024) [fm removeItemAtPath:path error:nil];

        NSDateFormatter *formatter = [NSDateFormatter new];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
        NSString *line = [NSString stringWithFormat:@"[%@] %@\n",
            [formatter stringFromDate:NSDate.date], message];
        NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
        if (![fm fileExistsAtPath:path]) {
            [data writeToFile:path atomically:YES];
            return;
        }
        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
        @try {
            [handle seekToEndOfFile];
            [handle writeData:data];
            [handle closeFile];
        } @catch (__unused NSException *exception) {
            [handle closeFile];
        }
    });
}

void AWEAlbumMorphProbeLog(const char *utf8Message) {
    if (!utf8Message) return;
    NSString *message = [NSString stringWithUTF8String:utf8Message];
    if (message.length > 0) AWEAlbumMorphProbeWrite(@"SWIFT %@", message);
}

static NSString *AWEInteractionObjectSummary(id object) {
    if (!object) return @"nil";
    if ([object isKindOfClass:UIView.class]) {
        UIView *view = object;
        CGRect frame = view.window
            ? [view convertRect:view.bounds toView:view.window]
            : CGRectZero;
        return [NSString stringWithFormat:@"%@/%p window=%d hidden=%d alpha=%.3f frame=%@",
            NSStringFromClass(view.class), view, view.window != nil,
            view.hidden, view.alpha, NSStringFromCGRect(frame)];
    }
    return [NSString stringWithFormat:@"%@/%p", NSStringFromClass([object class]), object];
}

#pragma mark - Local account authorization gate

/*
 The release gate deliberately stores no plaintext account identifiers.
 Allowed identifiers are normalized, salted, SHA-256 hashed, and compared
 against split XOR tables. A device-bound proof is cached after a successful
 silent read from the current account's profile page.
*/

typedef struct {
    uint8_t data[64];
    uint32_t dataLength;
    uint64_t bitLength;
    uint32_t state[8];
} AWEHashContext;

static const uint32_t kAWEHashRoundConstants[64] = {
    0x428A2F98,0x71374491,0xB5C0FBCF,0xE9B5DBA5,0x3956C25B,0x59F111F1,0x923F82A4,0xAB1C5ED5,
    0xD807AA98,0x12835B01,0x243185BE,0x550C7DC3,0x72BE5D74,0x80DEB1FE,0x9BDC06A7,0xC19BF174,
    0xE49B69C1,0xEFBE4786,0x0FC19DC6,0x240CA1CC,0x2DE92C6F,0x4A7484AA,0x5CB0A9DC,0x76F988DA,
    0x983E5152,0xA831C66D,0xB00327C8,0xBF597FC7,0xC6E00BF3,0xD5A79147,0x06CA6351,0x14292967,
    0x27B70A85,0x2E1B2138,0x4D2C6DFC,0x53380D13,0x650A7354,0x766A0ABB,0x81C2C92E,0x92722C85,
    0xA2BFE8A1,0xA81A664B,0xC24B8B70,0xC76C51A3,0xD192E819,0xD6990624,0xF40E3585,0x106AA070,
    0x19A4C116,0x1E376C08,0x2748774C,0x34B0BCB5,0x391C0CB3,0x4ED8AA4A,0x5B9CCA4F,0x682E6FF3,
    0x748F82EE,0x78A5636F,0x84C87814,0x8CC70208,0x90BEFFFA,0xA4506CEB,0xBEF9A3F7,0xC67178F2
};

#define AWE_ROR32(v,n) (((v) >> (n)) | ((v) << (32 - (n))))
#define AWE_CH(x,y,z) (((x) & (y)) ^ (~(x) & (z)))
#define AWE_MAJ(x,y,z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define AWE_EP0(x) (AWE_ROR32((x),2) ^ AWE_ROR32((x),13) ^ AWE_ROR32((x),22))
#define AWE_EP1(x) (AWE_ROR32((x),6) ^ AWE_ROR32((x),11) ^ AWE_ROR32((x),25))
#define AWE_SIG0(x) (AWE_ROR32((x),7) ^ AWE_ROR32((x),18) ^ ((x) >> 3))
#define AWE_SIG1(x) (AWE_ROR32((x),17) ^ AWE_ROR32((x),19) ^ ((x) >> 10))

static void AWEHashTransform(AWEHashContext *context, const uint8_t block[64]) {
    uint32_t words[64];
    for (NSUInteger index = 0; index < 16; index++) {
        NSUInteger offset = index * 4;
        words[index] = ((uint32_t)block[offset] << 24) |
                       ((uint32_t)block[offset + 1] << 16) |
                       ((uint32_t)block[offset + 2] << 8) |
                       ((uint32_t)block[offset + 3]);
    }
    for (NSUInteger index = 16; index < 64; index++) {
        words[index] = AWE_SIG1(words[index - 2]) + words[index - 7] +
                       AWE_SIG0(words[index - 15]) + words[index - 16];
    }
    uint32_t a=context->state[0], b=context->state[1], c=context->state[2], d=context->state[3];
    uint32_t e=context->state[4], f=context->state[5], g=context->state[6], h=context->state[7];
    for (NSUInteger index = 0; index < 64; index++) {
        uint32_t t1 = h + AWE_EP1(e) + AWE_CH(e,f,g) +
                      kAWEHashRoundConstants[index] + words[index];
        uint32_t t2 = AWE_EP0(a) + AWE_MAJ(a,b,c);
        h=g; g=f; f=e; e=d+t1; d=c; c=b; b=a; a=t1+t2;
    }
    context->state[0]+=a; context->state[1]+=b; context->state[2]+=c; context->state[3]+=d;
    context->state[4]+=e; context->state[5]+=f; context->state[6]+=g; context->state[7]+=h;
}

static void AWEHashInit(AWEHashContext *context) {
    memset(context, 0, sizeof(*context));
    context->state[0]=0x6A09E667; context->state[1]=0xBB67AE85;
    context->state[2]=0x3C6EF372; context->state[3]=0xA54FF53A;
    context->state[4]=0x510E527F; context->state[5]=0x9B05688C;
    context->state[6]=0x1F83D9AB; context->state[7]=0x5BE0CD19;
}

static void AWEHashUpdate(AWEHashContext *context, const uint8_t *bytes, size_t length) {
    if (!context || (!bytes && length > 0)) return;
    for (size_t index = 0; index < length; index++) {
        context->data[context->dataLength++] = bytes[index];
        if (context->dataLength == 64) {
            AWEHashTransform(context, context->data);
            context->bitLength += 512;
            context->dataLength = 0;
        }
    }
}

static void AWEHashFinal(AWEHashContext *context, uint8_t output[32]) {
    uint32_t index = context->dataLength;
    context->data[index++] = 0x80;
    if (index > 56) {
        while (index < 64) context->data[index++] = 0;
        AWEHashTransform(context, context->data);
        index = 0;
    }
    while (index < 56) context->data[index++] = 0;
    context->bitLength += (uint64_t)context->dataLength * 8;
    for (NSUInteger byteIndex = 0; byteIndex < 8; byteIndex++) {
        context->data[63 - byteIndex] = (uint8_t)(context->bitLength >> (byteIndex * 8));
    }
    AWEHashTransform(context, context->data);
    for (NSUInteger word = 0; word < 8; word++) {
        output[word * 4]     = (uint8_t)(context->state[word] >> 24);
        output[word * 4 + 1] = (uint8_t)(context->state[word] >> 16);
        output[word * 4 + 2] = (uint8_t)(context->state[word] >> 8);
        output[word * 4 + 3] = (uint8_t)context->state[word];
    }
}

static NSData *AWEHashData(NSData *data) {
    uint8_t digest[32];
    AWEHashContext context;
    AWEHashInit(&context);
    AWEHashUpdate(&context, data.bytes, data.length);
    AWEHashFinal(&context, digest);
    return [NSData dataWithBytes:digest length:sizeof(digest)];
}

static NSString *AWEStringFromXor(const uint8_t *bytes, size_t length, uint8_t key) {
    if (!bytes || length == 0) return @"";
    NSMutableData *data = [NSMutableData dataWithLength:length];
    uint8_t *output = data.mutableBytes;
    for (size_t index = 0; index < length; index++) output[index] = bytes[index] ^ key;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
}

static NSString *AWEAuthorizationHashPrefix(void) {
    static const uint8_t bytes[] = { 0x7D,0x70,0x7E,0x06,0x06,0x7D,0x69,0x68,0x74,0x06,0x06,0x0E,0x0C,0x0E,0x0A,0x06,0x06 };
    return AWEStringFromXor(bytes, sizeof(bytes), 0x3C);
}

static NSString *AWEAuthorizationHashSuffix(void) {
    static const uint8_t bytes[] = { 0x39,0x39,0x5B,0x5A,0x7A,0x39,0x39,0x44,0x6F,0x62,0x70,0x70,0x39,0x39,0x32,0x3B };
    return AWEStringFromXor(bytes, sizeof(bytes), 0x03);
}

static NSString *AWEAuthorizationTokenPrefix(void) {
    static const uint8_t bytes[] = { 0xEE,0xE3,0xED,0x95,0x95,0xFB,0xE0,0xE4,0xEA,0xE1,0x95,0x95,0x9E,0x81,0x9F,0x81,0x9E,0x95,0x95 };
    return AWEStringFromXor(bytes, sizeof(bytes), 0xAF);
}

static NSString *AWEAuthorizationTokenSuffix(void) {
    static const uint8_t bytes[] = { 0x43,0x43,0x21,0x20,0x00,0x43,0x43,0x3D,0x1C,0x0F,0x10,0x1A,0x1C,0x3B,0x16,0x0C,0x17,0x1D };
    return AWEStringFromXor(bytes, sizeof(bytes), 0x79);
}

static NSString *AWEAuthorizationDefaultsKey(NSUInteger kind) {
    switch (kind) {
        case 0: { static const uint8_t b[]={0xFA,0xF7,0xF9,0x95,0xDA,0x95,0xDF,0x95,0x8A,0x8B,0x8A}; return AWEStringFromXor(b,sizeof(b),0xBB); }
        case 1: { static const uint8_t b[]={0x8A,0x87,0x89,0xE5,0xAA,0xE5,0xBF,0xE5,0xFA,0xFB,0xFA}; return AWEStringFromXor(b,sizeof(b),0xCB); }
        case 2: { static const uint8_t b[]={0x8B,0x86,0x88,0xE4,0xAB,0xE4,0xB9,0xE4,0xFB,0xFA,0xFB}; return AWEStringFromXor(b,sizeof(b),0xCA); }
        default: { static const uint8_t b[]={0x1F,0x12,0x1C,0x70,0x33,0x3F,0x2D,0x2A,0x3B,0x2C,0x70,0x6F,0x6E,0x6F}; return AWEStringFromXor(b,sizeof(b),0x5E); }
    }
}

static NSString *AWEAuthorizationNotificationName(void) {
    static const uint8_t b[]={0xC7,0xCA,0xC4,0xA8,0xE7,0xF3,0xF2,0xEE,0xA8,0xE5,0xEE,0xE7,0xE8,0xE1,0xE3,0xE2,0xA8,0xB7,0xB6,0xB7};
    return AWEStringFromXor(b,sizeof(b),0x86);
}

typedef struct {
    uint8_t mask[32];
    uint8_t value[32];
} AWEAuthorizationDigestPair;

static const AWEAuthorizationDigestPair kAWEAuthorizationDigests[37] = {
    { { 0x59, 0x82, 0x56, 0x11, 0xCC, 0x1E, 0x58, 0xA8, 0xEF, 0xB6, 0x24, 0x7E, 0x97, 0xB8, 0x64, 0x73, 0xCE, 0x8F, 0x7D, 0x23, 0x21, 0xF4, 0xC3, 0xC9, 0x75, 0xD5, 0xCA, 0xF8, 0xE3, 0x16, 0xB1, 0x32 }, { 0x9F, 0x0C, 0xED, 0xA5, 0xCB, 0x5B, 0x84, 0x63, 0xD4, 0x38, 0xC3, 0x54, 0x7D, 0x04, 0x85, 0xBD, 0x81, 0x67, 0xEC, 0xF0, 0x4D, 0xE2, 0x02, 0x72, 0xDC, 0x96, 0xFF, 0xE4, 0x3D, 0x52, 0x81, 0xB2 } },
    { { 0x3F, 0x40, 0x8A, 0x7D, 0x84, 0xB4, 0xFA, 0x3E, 0x5E, 0x8B, 0x01, 0xB5, 0x24, 0xF8, 0xBD, 0xDD, 0x2A, 0xB5, 0xA0, 0xEB, 0xC5, 0xAA, 0x72, 0xCC, 0x16, 0x88, 0x8F, 0xC9, 0x67, 0xCB, 0xCC, 0x73 }, { 0xDE, 0x19, 0x74, 0x29, 0x81, 0xA3, 0x4B, 0xB7, 0x6A, 0xD2, 0x31, 0xA1, 0x70, 0xF0, 0x66, 0xA7, 0xA4, 0xFD, 0x73, 0x60, 0x1A, 0x65, 0xD2, 0x57, 0xCD, 0x90, 0x06, 0x85, 0xD9, 0xCA, 0xDD, 0x34 } },
    { { 0x91, 0xDF, 0x80, 0xC6, 0x2F, 0x47, 0x04, 0xEE, 0x32, 0x74, 0xC6, 0x3B, 0x38, 0xF5, 0x47, 0xF2, 0x01, 0x89, 0xE2, 0x8C, 0x36, 0xC3, 0xE2, 0xE8, 0xA4, 0x62, 0xA2, 0x8E, 0xDC, 0x76, 0xE7, 0xC0 }, { 0x58, 0xFD, 0x08, 0x53, 0xC3, 0x95, 0x41, 0x39, 0x18, 0xBA, 0x8D, 0x20, 0xD0, 0x9D, 0x7B, 0xBD, 0x0A, 0xFF, 0x31, 0xF9, 0x8B, 0xBE, 0x4E, 0xFD, 0xFA, 0x2C, 0x84, 0x7F, 0x07, 0x15, 0x5C, 0x4A } },
    { { 0x9A, 0x39, 0xA9, 0x30, 0x33, 0x0A, 0x27, 0xF0, 0xB3, 0x94, 0xB3, 0x30, 0x4B, 0x3A, 0xB4, 0xCA, 0xAA, 0x16, 0xA6, 0x38, 0x58, 0x03, 0x6E, 0x18, 0xB9, 0x3A, 0xE7, 0x55, 0xAA, 0xC0, 0x84, 0x77 }, { 0xD9, 0xF2, 0x0C, 0xFF, 0x8C, 0x68, 0xBC, 0xB0, 0x48, 0xC2, 0x7D, 0x73, 0xB3, 0x8A, 0x4A, 0x04, 0x10, 0x1F, 0x7D, 0xA3, 0x1B, 0x9F, 0x8E, 0x36, 0x98, 0xA2, 0xEE, 0xF1, 0x23, 0xC3, 0x04, 0xB9 } },
    { { 0x2F, 0x52, 0x96, 0xDA, 0x3E, 0x75, 0x2F, 0xA7, 0x1C, 0x1C, 0xAA, 0xC8, 0x1A, 0xA5, 0xA5, 0x79, 0x2C, 0xCB, 0x94, 0x62, 0xD0, 0x28, 0x9B, 0xFC, 0x6B, 0x43, 0xA5, 0x5A, 0xFC, 0x92, 0xFF, 0x73 }, { 0x71, 0x70, 0x32, 0xCC, 0x45, 0x46, 0x78, 0xF7, 0x4D, 0x4C, 0x27, 0x61, 0xB2, 0x30, 0x4E, 0x97, 0xE4, 0x95, 0x3B, 0x97, 0xE3, 0x13, 0x41, 0x15, 0xAE, 0xE5, 0xCD, 0xBA, 0x6C, 0xC4, 0xE8, 0x14 } },
    { { 0xD0, 0xBE, 0xB8, 0x56, 0x38, 0xA5, 0x44, 0x4B, 0x56, 0x6D, 0xEA, 0x62, 0x6A, 0x4C, 0x2F, 0x2A, 0xB5, 0xCC, 0x67, 0xDD, 0x3D, 0x00, 0x25, 0xB1, 0x54, 0xF0, 0x43, 0x86, 0xD1, 0xD7, 0x85, 0xA8 }, { 0x07, 0xDD, 0xEE, 0x5E, 0xEF, 0xAE, 0xFB, 0x7F, 0xA5, 0xA1, 0xEA, 0x69, 0xC1, 0x48, 0xBF, 0xC6, 0x4E, 0x1C, 0xDD, 0xBC, 0xF3, 0xC2, 0x47, 0x70, 0x0B, 0x82, 0xF7, 0x29, 0x28, 0x2F, 0x34, 0xFA } },
    { { 0xB2, 0xC6, 0x06, 0x0C, 0x9B, 0x00, 0x23, 0x40, 0x3E, 0xE2, 0x1F, 0x01, 0x6C, 0x1B, 0xF0, 0x3A, 0x49, 0x14, 0x47, 0xAB, 0xD6, 0x6F, 0x0A, 0x00, 0xCE, 0xC2, 0xB2, 0x60, 0x9E, 0xFD, 0x61, 0x46 }, { 0xEB, 0x0D, 0x0F, 0x14, 0x24, 0x49, 0x61, 0x50, 0x4B, 0x9A, 0xC7, 0x5C, 0xF9, 0x65, 0x7A, 0x75, 0x5E, 0x88, 0x16, 0xD3, 0xBC, 0xB6, 0xBE, 0x96, 0xD0, 0xDD, 0xC5, 0x10, 0x4F, 0xBC, 0xE9, 0xBA } },
    { { 0xD2, 0x88, 0x7F, 0x78, 0xD5, 0x01, 0x3A, 0x43, 0xC8, 0xC3, 0x2A, 0xD0, 0xFF, 0x2D, 0xAA, 0x2D, 0xC4, 0x13, 0xD9, 0x3B, 0xEF, 0xB4, 0x65, 0xCD, 0xB7, 0xF3, 0x42, 0x98, 0x1D, 0xB3, 0xBC, 0x7C }, { 0xBD, 0x10, 0xD1, 0x2A, 0xC0, 0xF4, 0xCE, 0x3C, 0xB8, 0xB4, 0x07, 0x24, 0xBC, 0xCA, 0xA3, 0x76, 0xC9, 0x02, 0x11, 0x2E, 0x67, 0x62, 0x49, 0x3E, 0x2C, 0x45, 0xDD, 0x30, 0x9A, 0x0E, 0xCC, 0x2A } },
    { { 0xAE, 0x3A, 0xB3, 0x2A, 0x1A, 0xB7, 0x2E, 0xF1, 0x31, 0xA1, 0xCA, 0xD3, 0x51, 0xF7, 0x63, 0x5A, 0xF8, 0xBA, 0x8D, 0x13, 0x52, 0x3B, 0xCE, 0x06, 0xC8, 0x5B, 0xC0, 0x96, 0xFF, 0x03, 0xC8, 0xEC }, { 0xBD, 0x69, 0x21, 0xE7, 0xB6, 0x3D, 0x7D, 0x88, 0xD8, 0x78, 0x6C, 0x54, 0xF7, 0xA4, 0xA5, 0x99, 0xF9, 0xB6, 0x38, 0x46, 0x75, 0xAE, 0x5E, 0x36, 0x30, 0x4A, 0x53, 0x71, 0x80, 0x59, 0xA2, 0x67 } },
    { { 0x16, 0x0E, 0x67, 0xC3, 0x5B, 0x38, 0x84, 0x26, 0x43, 0x24, 0xAF, 0xD1, 0xCD, 0x0F, 0xE0, 0xC0, 0x65, 0xD2, 0x03, 0x3C, 0x38, 0x38, 0x45, 0x07, 0x8D, 0xDA, 0x4D, 0xFE, 0xE8, 0x64, 0x35, 0x9D }, { 0x86, 0xE5, 0x3A, 0xB2, 0xDC, 0x82, 0xB2, 0xB8, 0x35, 0x20, 0x65, 0x7B, 0x61, 0x29, 0x0F, 0xCA, 0x57, 0x9A, 0x90, 0x29, 0x59, 0x79, 0x5F, 0xE1, 0xAB, 0xB7, 0x33, 0x70, 0x37, 0xDA, 0x31, 0xA8 } },
    { { 0xC9, 0x70, 0xCC, 0x49, 0x9A, 0x11, 0x01, 0xB7, 0xA4, 0xE8, 0xC7, 0xFA, 0x93, 0x32, 0x43, 0xF9, 0x9A, 0xC1, 0x8F, 0xCA, 0x2B, 0x9C, 0xC9, 0x4B, 0x60, 0x70, 0x42, 0x40, 0xA2, 0x5E, 0xC9, 0x11 }, { 0x7C, 0x96, 0xAE, 0x86, 0x7B, 0xC7, 0xB5, 0x18, 0xB6, 0x1C, 0xF4, 0x8E, 0x3D, 0x7B, 0x3C, 0xBD, 0x6D, 0xDB, 0xFE, 0x95, 0x3A, 0x4C, 0x3D, 0x5B, 0xC4, 0x8C, 0xC2, 0xBF, 0x41, 0x50, 0xDD, 0x76 } },
    { { 0x62, 0x17, 0x40, 0xBE, 0x72, 0x4F, 0x57, 0x0E, 0xF2, 0xBF, 0x21, 0xF3, 0xBD, 0xC4, 0x91, 0x7A, 0x3B, 0x7D, 0x0B, 0x26, 0x12, 0x1F, 0xA1, 0xC5, 0x2A, 0xBE, 0x81, 0x02, 0xAA, 0xA9, 0x04, 0x05 }, { 0xF1, 0x83, 0x3D, 0xF6, 0x0F, 0x2D, 0x2C, 0x52, 0x72, 0xFC, 0x79, 0xFB, 0x27, 0x94, 0x4E, 0xD5, 0x11, 0x05, 0xC6, 0x2C, 0x0D, 0xED, 0xD3, 0xC1, 0x28, 0xED, 0xC5, 0xC3, 0x27, 0xA9, 0x39, 0x81 } },
    { { 0xF6, 0x17, 0xF1, 0xDC, 0x44, 0xE8, 0xB6, 0x44, 0x70, 0x78, 0x03, 0x19, 0x25, 0x58, 0xBE, 0xCF, 0x77, 0x10, 0xC4, 0x21, 0xD3, 0xA4, 0x21, 0x2A, 0x89, 0x1B, 0xA1, 0xA7, 0xE2, 0x32, 0x67, 0xC4 }, { 0x7A, 0xA8, 0xBD, 0x0A, 0xB4, 0xFF, 0xBF, 0xA5, 0x58, 0xE3, 0x48, 0xDE, 0x25, 0x1F, 0xE8, 0x89, 0xF7, 0xDB, 0x80, 0x8D, 0x23, 0x00, 0x45, 0x69, 0x2B, 0x81, 0xF7, 0x80, 0x68, 0xCF, 0xDD, 0xC8 } },
    { { 0xE9, 0xA3, 0xAE, 0xF1, 0x36, 0x6D, 0x66, 0x86, 0xCE, 0x5A, 0xFB, 0xEF, 0x3B, 0xAA, 0x20, 0x00, 0xFE, 0x04, 0xC3, 0x79, 0xAE, 0x18, 0x36, 0x04, 0x49, 0xC4, 0x4A, 0xE5, 0x89, 0x7B, 0x4A, 0x01 }, { 0xB5, 0x2B, 0x78, 0x27, 0x36, 0x11, 0xB2, 0xED, 0x7C, 0x9F, 0xEB, 0x10, 0x5F, 0x42, 0x16, 0x92, 0x6E, 0x20, 0x5B, 0x35, 0xF5, 0x54, 0x42, 0xED, 0x86, 0x34, 0xE9, 0x80, 0xDF, 0x4B, 0xB4, 0xD1 } },
    { { 0x2D, 0xDD, 0x30, 0x46, 0xE8, 0xE7, 0x6D, 0x5A, 0xA9, 0x10, 0x22, 0x39, 0x0A, 0xEB, 0x96, 0x9E, 0xC2, 0x8B, 0x9D, 0xA7, 0x21, 0x72, 0xA0, 0xBF, 0x5D, 0x1A, 0x77, 0xB7, 0x68, 0x45, 0x7C, 0xE4 }, { 0xD7, 0xAE, 0xBC, 0x56, 0x25, 0x0D, 0x09, 0x6F, 0x18, 0x87, 0xCC, 0x76, 0xC6, 0xBE, 0xB3, 0x2A, 0xA5, 0xB3, 0x19, 0xD4, 0x8B, 0xE6, 0x0A, 0xBC, 0x23, 0x2A, 0x47, 0xD2, 0x29, 0x1F, 0x29, 0x97 } },
    { { 0x2E, 0x43, 0x0F, 0x1B, 0x61, 0xE7, 0xB9, 0x40, 0xD9, 0x2E, 0xD3, 0xB8, 0xC9, 0x70, 0x73, 0x09, 0x9D, 0xB9, 0x23, 0x1F, 0xAE, 0x7D, 0xCD, 0x17, 0xF0, 0xE9, 0x96, 0x29, 0x00, 0x01, 0x0A, 0x5E }, { 0x83, 0x67, 0x9E, 0xBC, 0x74, 0xA1, 0x3B, 0x07, 0x60, 0x85, 0xAB, 0xA2, 0xD3, 0xE7, 0xFB, 0x8F, 0xD0, 0x1F, 0xAA, 0x20, 0x2B, 0x63, 0xB2, 0xFF, 0x70, 0xF5, 0x0F, 0x89, 0xF8, 0xE4, 0x2E, 0x7C } },
    { { 0x16, 0x77, 0xDE, 0xDC, 0x26, 0xFC, 0x5B, 0x90, 0x0C, 0x2C, 0xA4, 0x20, 0x32, 0x5E, 0xF8, 0x0F, 0xCD, 0x5F, 0x51, 0x3B, 0xDE, 0xE7, 0x98, 0x57, 0x42, 0x0F, 0x60, 0xBC, 0x78, 0x46, 0x08, 0xB7 }, { 0xDD, 0x41, 0x40, 0x80, 0xBE, 0xD0, 0xA4, 0xA9, 0x5E, 0x3B, 0xDD, 0xE1, 0xCF, 0x7C, 0x60, 0x06, 0x44, 0x26, 0xDD, 0x05, 0x7D, 0x1F, 0xDC, 0x02, 0x5A, 0x29, 0xE9, 0x35, 0xD0, 0x97, 0x2A, 0x49 } },
    { { 0x76, 0x48, 0x59, 0x0E, 0x41, 0x67, 0x94, 0x79, 0x00, 0x77, 0xD9, 0xC3, 0xBC, 0xBD, 0xA6, 0x9E, 0x9C, 0x18, 0xDC, 0x62, 0x15, 0x7A, 0x80, 0x8D, 0x7B, 0x78, 0xB4, 0x58, 0xFF, 0xA2, 0x93, 0xB5 }, { 0xFD, 0xA2, 0xD0, 0x43, 0x9E, 0x6E, 0xA2, 0xB5, 0x1F, 0x6B, 0x05, 0x8B, 0x2D, 0xA5, 0x56, 0xFD, 0x46, 0xFC, 0x3C, 0x15, 0x50, 0x21, 0x6A, 0x54, 0xDC, 0xE5, 0xFA, 0xEC, 0x01, 0xD9, 0x4B, 0x8B } },
    { { 0x50, 0x84, 0x34, 0x3A, 0xC2, 0x16, 0xE2, 0xF3, 0xAC, 0xA3, 0x72, 0x54, 0x1F, 0xDC, 0x43, 0x4E, 0xEE, 0xEF, 0x51, 0x47, 0x8E, 0x1A, 0x0E, 0x04, 0x27, 0x56, 0xB5, 0x4D, 0xC9, 0x12, 0xCD, 0x67 }, { 0x7D, 0x33, 0xDB, 0xF4, 0x61, 0x4C, 0x1E, 0x6C, 0xFF, 0x1D, 0xD4, 0xFF, 0xAD, 0x72, 0xA4, 0x76, 0xCF, 0x9D, 0xE2, 0xE5, 0xC8, 0x42, 0x77, 0x60, 0xD7, 0xE6, 0x28, 0x0E, 0xC5, 0xAD, 0xC1, 0x46 } },
    { { 0x9A, 0x72, 0x0B, 0xD0, 0x8F, 0x81, 0x9D, 0x49, 0x58, 0xC8, 0xFF, 0xD9, 0x57, 0x59, 0x6E, 0x69, 0xE8, 0x53, 0x53, 0xB6, 0xE7, 0x33, 0x92, 0x95, 0x2A, 0x12, 0x26, 0x56, 0xE8, 0xCC, 0xDF, 0xEC }, { 0x7D, 0x96, 0xA5, 0x37, 0x91, 0x85, 0xF9, 0x8B, 0xD4, 0x3E, 0x00, 0xC1, 0xD0, 0x60, 0x4A, 0x00, 0x67, 0xF6, 0x0C, 0x22, 0xBD, 0xB2, 0x47, 0x20, 0x8A, 0xD6, 0x72, 0xFC, 0x5F, 0x7B, 0xE3, 0x79 } },
    { { 0x6D, 0x54, 0x34, 0xD3, 0x42, 0x11, 0xAD, 0x5D, 0xCE, 0x98, 0x00, 0x4A, 0xC7, 0x55, 0x7E, 0x9F, 0x9D, 0xD9, 0xCD, 0x23, 0x87, 0xB9, 0xE7, 0xB3, 0xD8, 0x2C, 0x98, 0xEF, 0x65, 0x07, 0xF6, 0xB8 }, { 0xB5, 0x9B, 0xE7, 0xC9, 0x07, 0x49, 0xF8, 0x2B, 0xFC, 0x8F, 0x0F, 0xD8, 0x4C, 0x31, 0xD0, 0x53, 0xBE, 0xC4, 0x4B, 0x00, 0x2D, 0x69, 0x3B, 0xC5, 0x8B, 0x86, 0xDE, 0x1F, 0xAB, 0x06, 0x44, 0x71 } },
    { { 0x51, 0xDE, 0x0F, 0x73, 0x21, 0xA2, 0xF9, 0xB3, 0xB3, 0xC3, 0xD6, 0xC1, 0x25, 0x55, 0x65, 0xCE, 0x2A, 0x52, 0x04, 0x03, 0x22, 0x22, 0x1D, 0x9D, 0x9D, 0xCC, 0xEF, 0x4B, 0x11, 0xDE, 0x94, 0x38 }, { 0xF4, 0x41, 0x50, 0x82, 0x05, 0xCE, 0xB9, 0x86, 0xBA, 0x95, 0xDB, 0x9F, 0x8B, 0x34, 0xF9, 0x15, 0x56, 0xDE, 0xA2, 0x1A, 0x4A, 0x32, 0xA3, 0x23, 0x88, 0x2C, 0x63, 0xD2, 0x4C, 0xB1, 0xEE, 0x5E } },
    { { 0xFB, 0xBD, 0x7B, 0xE8, 0x0A, 0x68, 0xE9, 0xCF, 0x67, 0x87, 0x3D, 0xAD, 0xCD, 0x2F, 0x17, 0x4D, 0xCB, 0x7F, 0xB7, 0x60, 0x65, 0xC6, 0xBF, 0x34, 0xE1, 0x0B, 0x10, 0x34, 0x7F, 0x24, 0x13, 0x72 }, { 0xA4, 0xE7, 0x1F, 0x54, 0x44, 0xFD, 0xEB, 0x6B, 0x0B, 0xBF, 0x04, 0x3D, 0xD7, 0x65, 0x10, 0x0A, 0x25, 0xCB, 0x1E, 0x24, 0x8D, 0xE5, 0xE3, 0x5A, 0xB3, 0xA8, 0x4D, 0x4B, 0xD3, 0x1F, 0x37, 0x66 } },
    { { 0x4B, 0xE8, 0xCB, 0xC5, 0x90, 0x87, 0xFB, 0xBA, 0xA5, 0x66, 0xFF, 0x3E, 0x09, 0x6F, 0xA8, 0x57, 0x8D, 0xBB, 0x1A, 0x1C, 0x32, 0x91, 0x46, 0x4C, 0x0A, 0x8F, 0xF2, 0xB1, 0x9A, 0x22, 0x1F, 0x82 }, { 0xB6, 0x73, 0x3B, 0xE9, 0x03, 0x4D, 0x50, 0x0E, 0xF4, 0x64, 0x15, 0x4D, 0x35, 0x01, 0xC8, 0x9F, 0x95, 0x3F, 0x66, 0x2B, 0xE0, 0x5B, 0x65, 0x51, 0x2A, 0x4C, 0x2A, 0x28, 0x52, 0xBF, 0xBE, 0x86 } },
    { { 0x58, 0xA4, 0xE6, 0x5B, 0xFC, 0xD9, 0xAC, 0x0B, 0xBC, 0x47, 0x52, 0x36, 0xD0, 0x6A, 0x81, 0x66, 0x6A, 0x56, 0x55, 0xA1, 0x6C, 0xFD, 0x37, 0xB2, 0xD3, 0x95, 0xE7, 0xB0, 0xE8, 0xE8, 0xA7, 0x52 }, { 0x6D, 0x67, 0x4F, 0x6E, 0x32, 0xA9, 0x8B, 0xAE, 0x6D, 0x31, 0xD9, 0xE9, 0x93, 0x11, 0xDC, 0x6D, 0xCA, 0x48, 0x64, 0xB4, 0xD0, 0xD3, 0xD4, 0x1E, 0x25, 0x3C, 0xE6, 0x01, 0x91, 0xDE, 0xB6, 0xA8 } },
    { { 0x07, 0x62, 0x9A, 0xCA, 0xD0, 0x9C, 0x9D, 0x8E, 0xCB, 0xB4, 0x12, 0x9E, 0xF4, 0x27, 0x26, 0x73, 0x2A, 0x1D, 0xA1, 0x47, 0xBB, 0x01, 0x6F, 0x53, 0x7A, 0x42, 0x55, 0x49, 0x36, 0x47, 0x7E, 0x17 }, { 0x9E, 0x54, 0xCC, 0xDE, 0x32, 0x9B, 0xF5, 0x47, 0xBF, 0xFD, 0xB2, 0x93, 0x05, 0xA2, 0xBD, 0xF4, 0x47, 0x72, 0xD3, 0x4A, 0x9E, 0xFD, 0x22, 0x7F, 0x10, 0x88, 0x0D, 0x83, 0x07, 0x34, 0x0B, 0x0F } },
    { { 0xE9, 0x64, 0x37, 0x23, 0x78, 0x31, 0xEA, 0x77, 0x80, 0x5E, 0x43, 0x1B, 0xC4, 0x54, 0xEC, 0x9A, 0xA2, 0x07, 0x04, 0xFE, 0xC0, 0xD8, 0xB8, 0x69, 0x56, 0x49, 0x12, 0x13, 0xC4, 0x24, 0xFA, 0xEB }, { 0x99, 0x2C, 0xD6, 0x20, 0xF3, 0xDD, 0x0A, 0x42, 0x95, 0x2C, 0xFA, 0x66, 0x8B, 0xA4, 0x94, 0xD4, 0x22, 0xD6, 0xE4, 0x31, 0x79, 0x7D, 0xC9, 0x73, 0x18, 0xB6, 0x0A, 0xB2, 0x97, 0xCC, 0x8E, 0x10 } },
    { { 0x4D, 0xD0, 0x84, 0x0C, 0x7D, 0xB5, 0x27, 0xBD, 0x70, 0x1E, 0xCF, 0x08, 0xC3, 0x23, 0xEB, 0x69, 0xA6, 0xDB, 0xA2, 0xD3, 0x2C, 0x7B, 0x35, 0xF6, 0x5F, 0x33, 0x88, 0x12, 0x3F, 0xDB, 0xD4, 0xA7 }, { 0x3A, 0xCD, 0x79, 0xA9, 0x16, 0x9D, 0xF9, 0x9F, 0xF0, 0xEC, 0xE0, 0x68, 0xDD, 0x06, 0x63, 0xA7, 0xA5, 0x8A, 0x1B, 0xD4, 0x1D, 0x8C, 0xD0, 0xFE, 0x01, 0x32, 0xAD, 0x3C, 0x12, 0x08, 0xAA, 0x86 } },
    { { 0xBB, 0x40, 0xC0, 0xD1, 0xDD, 0xCC, 0x65, 0xB2, 0x2C, 0xFA, 0x11, 0x1B, 0xBF, 0xFE, 0x6E, 0x34, 0xD3, 0x71, 0x6F, 0x5D, 0xF4, 0x43, 0x7C, 0x2E, 0xEF, 0xC8, 0xBC, 0xBA, 0x93, 0xBD, 0x6F, 0x93 }, { 0x5F, 0xE5, 0x97, 0x9A, 0xFE, 0xEA, 0x1D, 0x02, 0x3B, 0xCC, 0x6A, 0x96, 0x62, 0x15, 0x02, 0x2A, 0x4D, 0xEB, 0x87, 0x6C, 0x76, 0x02, 0xFB, 0x9C, 0x44, 0x9E, 0x36, 0xBF, 0xE2, 0x41, 0x93, 0x59 } },
    { { 0x4B, 0x1E, 0xB1, 0x95, 0xC4, 0x66, 0x6C, 0x6F, 0x51, 0xAB, 0x01, 0xAA, 0x80, 0x39, 0xB6, 0xF2, 0xA3, 0x98, 0xD3, 0xF2, 0x86, 0x13, 0xA3, 0x34, 0x0A, 0xD8, 0x16, 0xBC, 0xF1, 0x3C, 0x02, 0xFB }, { 0xC6, 0x41, 0xA6, 0xCD, 0x97, 0xC2, 0x1F, 0xC8, 0xA2, 0xBC, 0xC8, 0xB6, 0x80, 0xBD, 0x5A, 0x0A, 0xDA, 0x98, 0x11, 0xAB, 0x8F, 0x3B, 0x1E, 0x3C, 0x1F, 0xE0, 0xE9, 0xFB, 0xFF, 0x6B, 0xF0, 0xE9 } },
    { { 0x85, 0xD4, 0x62, 0x31, 0xD7, 0xE0, 0x24, 0x76, 0x52, 0xAF, 0x7D, 0x2D, 0xEB, 0x8F, 0xCE, 0x20, 0x87, 0xEE, 0x9A, 0x4C, 0xD3, 0x3A, 0x41, 0xB9, 0x47, 0xB4, 0x17, 0x63, 0xF6, 0xC9, 0xB6, 0xC8 }, { 0xDB, 0xE3, 0xBB, 0x84, 0x5C, 0xEE, 0xAB, 0xF8, 0x53, 0x2A, 0xEA, 0x1B, 0x75, 0xD3, 0xBD, 0xD2, 0x94, 0xFA, 0xFE, 0x08, 0x13, 0xE9, 0x4E, 0x7B, 0xB3, 0x80, 0x70, 0x0A, 0x1D, 0x71, 0x8B, 0xBA } },
    { { 0xA2, 0xCD, 0x6C, 0x26, 0x49, 0x3E, 0xF7, 0x4C, 0x92, 0xCF, 0xB8, 0x43, 0xA6, 0x21, 0x75, 0x3C, 0xB7, 0x90, 0xD0, 0xFD, 0xA5, 0xB0, 0xBE, 0x03, 0x26, 0xC0, 0xBD, 0xC1, 0x99, 0xAD, 0xFA, 0xE9 }, { 0xA3, 0x31, 0xD8, 0x56, 0x38, 0x42, 0x08, 0x77, 0x9B, 0xD3, 0xCB, 0x99, 0xB2, 0x6B, 0x77, 0x4B, 0xD2, 0x75, 0x0B, 0xDD, 0x4D, 0x83, 0xEB, 0xFF, 0x93, 0x5A, 0x64, 0x80, 0xA2, 0x69, 0x05, 0x83 } },
    { { 0xCF, 0xDD, 0x88, 0xC7, 0xD8, 0x25, 0xA7, 0xA4, 0x49, 0x3A, 0xCA, 0x20, 0x95, 0xF3, 0xA2, 0x80, 0x0B, 0x6E, 0x35, 0x65, 0x78, 0x54, 0x33, 0x8D, 0x6B, 0xAC, 0x05, 0x23, 0x96, 0x3B, 0x8B, 0xE0 }, { 0x2C, 0x4F, 0x76, 0x91, 0x45, 0x8E, 0x3D, 0x6C, 0x74, 0x9C, 0xD1, 0x13, 0xA9, 0x74, 0x69, 0xB8, 0x3E, 0x92, 0xEE, 0x5F, 0xA0, 0x71, 0x78, 0x6C, 0xBF, 0x04, 0xAE, 0x53, 0xCE, 0x1C, 0x2B, 0x5C } },
    { { 0x4C, 0xE1, 0xEC, 0xEC, 0x0C, 0x66, 0xC3, 0xB6, 0x2F, 0x5E, 0x19, 0x5C, 0xE0, 0xB2, 0xFB, 0xD1, 0x16, 0x98, 0x2D, 0x41, 0x0E, 0x6D, 0xD0, 0x02, 0x64, 0x84, 0x1F, 0x80, 0xFC, 0x0A, 0xFA, 0x2F }, { 0xBC, 0x9D, 0x3D, 0x48, 0x98, 0x6D, 0xE9, 0x00, 0x6D, 0x85, 0xCE, 0xA2, 0xA5, 0xCA, 0x38, 0xD8, 0x73, 0x1D, 0x5D, 0x7B, 0x69, 0x5D, 0xF9, 0xC3, 0x71, 0x40, 0xBE, 0xD0, 0x10, 0xBE, 0x18, 0x19 } },
    { { 0x44, 0x6E, 0xAD, 0xA7, 0xD0, 0x92, 0xA1, 0xD1, 0x26, 0x83, 0x0D, 0xBD, 0xB0, 0x95, 0xC2, 0x5A, 0x22, 0xE6, 0x5B, 0x88, 0x72, 0x75, 0x40, 0xF2, 0x83, 0xB7, 0xAF, 0x14, 0x6B, 0x14, 0xBD, 0x86 }, { 0x6B, 0x1A, 0x29, 0x50, 0x1D, 0x93, 0x3A, 0xBD, 0xAA, 0x09, 0x65, 0x85, 0x8E, 0x20, 0x6C, 0x64, 0x49, 0x1D, 0x5D, 0x34, 0xBB, 0x04, 0x93, 0xF9, 0x0C, 0x32, 0x42, 0x56, 0x51, 0xE9, 0x54, 0x16 } },
    { { 0x06, 0x0B, 0xDC, 0x86, 0x77, 0x92, 0xAA, 0xDB, 0x48, 0xD6, 0x13, 0x11, 0x4B, 0x6C, 0x25, 0x1D, 0x4F, 0xC6, 0xA5, 0xE8, 0x2D, 0x84, 0xD8, 0x9E, 0x9C, 0x85, 0x03, 0xFD, 0xCE, 0x87, 0x7D, 0x14 }, { 0x11, 0xAD, 0x66, 0xF2, 0x1E, 0xB1, 0xFA, 0xBA, 0x32, 0x60, 0x5D, 0x9C, 0x1E, 0xB1, 0x41, 0xB1, 0xDD, 0x92, 0x5D, 0x73, 0x4D, 0x00, 0xE6, 0x90, 0xC9, 0xF7, 0xD1, 0xD6, 0xFF, 0xF0, 0x42, 0x56 } },

    { { 0x9F, 0x67, 0x6D, 0xD3, 0xB5, 0x1B, 0x1B, 0x2A, 0x8C, 0x89, 0xFB, 0x22, 0x4C, 0x21, 0x04, 0xBC, 0xE0, 0xC3, 0x82, 0xA3, 0xDE, 0x1E, 0x96, 0xC9, 0xD9, 0x44, 0x86, 0xAD, 0x15, 0xEB, 0x19, 0xFB }, { 0xCF, 0x3D, 0x10, 0xAC, 0xB6, 0xB6, 0x44, 0xEF, 0x7F, 0x0F, 0x49, 0xDE, 0x7F, 0xFF, 0x20, 0xE8, 0x6B, 0x6D, 0x06, 0x59, 0x5E, 0xC2, 0x73, 0x39, 0xA5, 0x0B, 0x64, 0x61, 0x81, 0x91, 0xDB, 0x5C } },
};


#define AWE_AUTHORIZATION_DIGEST_COUNT \
    (sizeof(kAWEAuthorizationDigests) / sizeof(kAWEAuthorizationDigests[0]))

static uint32_t AWEAuthorizationDigestTag(const uint8_t *bytes) {
    if (!bytes) return 0;
    uint32_t tag = 0xA73C5D91u;
    for (NSUInteger index = 0; index < 32; index++) {
        tag ^= ((uint32_t)bytes[index] + 0x9Du + (uint32_t)index * 17u);
        tag = (tag << 7) | (tag >> 25);
        tag *= 0x45D9F3Bu;
    }
    return tag ^ 0xC17A4E6Du;
}

static const uint32_t kAWEAuthorizationDigestTags[AWE_AUTHORIZATION_DIGEST_COUNT] = {
    0x3C8B2C6Fu, 0xCBE3B362u, 0x3B20BEC5u, 0x8C61DCC5u, 0x23F73B69u, 0xEC3F7C89u,
    0x3206638Au, 0x11ECCCDEu, 0x3871B57Bu, 0x10504AC4u, 0x7CA8DAD5u, 0xB3285104u,
    0x7A88FD21u, 0xDE48FE8Eu, 0x86E6A2D1u, 0x7488562Au, 0xDFB83DEDu, 0xDD279AE8u,
    0xB6FE03A6u, 0xBFB4B3DDu, 0xA64F8628u, 0xC9867052u, 0x0D573228u, 0xA3489318u,
    0x14EEEEC3u, 0x99555471u, 0xB2F28823u, 0xBCBCDE59u, 0x2C934A14u, 0x7D879147u,
    0x52083C3Fu, 0xD22A2870u, 0x155CC3CAu, 0x0C57AB18u, 0xC47E6571u, 0xB2B37631u,
    0x4B0A02CEu
};

static BOOL AWEConstantTimeEqual(const uint8_t *left, const uint8_t *right, size_t length) {
    uint8_t difference = 0;
    for (size_t index = 0; index < length; index++) difference |= left[index] ^ right[index];
    return difference == 0;
}

static NSString *AWENormalizedAccountIdentifier(NSString *text) {
    if (![text isKindOfClass:NSString.class] || text.length == 0) return @"";
    NSString *value = [[text precomposedStringWithCompatibilityMapping]
        stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    while ([value hasPrefix:@"@"]) value = [value substringFromIndex:1];
    NSMutableString *result = [NSMutableString stringWithCapacity:value.length];
    NSCharacterSet *whitespace = NSCharacterSet.whitespaceAndNewlineCharacterSet;
    for (NSUInteger index = 0; index < value.length; index++) {
        unichar character = [value characterAtIndex:index];
        if ([whitespace characterIsMember:character] ||
            character == 0x200B || character == 0x200C ||
            character == 0x200D || character == 0xFEFF) continue;
        [result appendFormat:@"%C", character];
    }
    while ([result hasSuffix:@":"] || [result hasSuffix:@"："] ||
           [result hasSuffix:@"·"] || [result hasSuffix:@"|"]) {
        [result deleteCharactersInRange:NSMakeRange(result.length - 1, 1)];
    }
    return result.lowercaseString;
}

static NSData *AWEAuthorizationDigestForIdentifier(NSString *identifier) {
    NSString *normalized = AWENormalizedAccountIdentifier(identifier);
    if (normalized.length == 0) return nil;
    NSString *payload = [NSString stringWithFormat:@"%@%@%@",
        AWEAuthorizationHashPrefix(), normalized, AWEAuthorizationHashSuffix()];
    return AWEHashData([payload dataUsingEncoding:NSUTF8StringEncoding]);
}

static BOOL AWEAuthorizationDigestAllowed(NSData *digest) {
    if (digest.length != 32) return NO;
    const uint8_t *candidate = digest.bytes;
    const uint32_t candidateTag = AWEAuthorizationDigestTag(candidate);
    uint8_t expected[32];
    for (NSUInteger entry = 0; entry < AWE_AUTHORIZATION_DIGEST_COUNT; entry++) {
        if ((candidateTag ^ kAWEAuthorizationDigestTags[entry]) != 0) continue;
        for (NSUInteger index = 0; index < 32; index++) {
            expected[index] = kAWEAuthorizationDigests[entry].mask[index] ^
                              kAWEAuthorizationDigests[entry].value[index];
        }
        if (AWEConstantTimeEqual(candidate, expected, 32)) {
            memset(expected, 0, sizeof(expected));
            return YES;
        }
    }
    memset(expected, 0, sizeof(expected));
    return NO;
}

static NSString *AWEHexStringFromData(NSData *data) {
    if (data.length == 0) return @"";
    const uint8_t *bytes = data.bytes;
    NSMutableString *result = [NSMutableString stringWithCapacity:data.length * 2];
    for (NSUInteger index = 0; index < data.length; index++) [result appendFormat:@"%02x", bytes[index]];
    return result;
}

static NSData *AWEDataFromHexString(NSString *hex) {
    if (![hex isKindOfClass:NSString.class] || hex.length == 0 || hex.length % 2 != 0) return nil;
    NSMutableData *data = [NSMutableData dataWithCapacity:hex.length / 2];
    for (NSUInteger index = 0; index < hex.length; index += 2) {
        unsigned int value = 0;
        NSString *pair = [hex substringWithRange:NSMakeRange(index, 2)];
        NSScanner *scanner = [NSScanner scannerWithString:pair];
        if (![scanner scanHexInt:&value]) return nil;
        uint8_t byte = (uint8_t)value;
        [data appendBytes:&byte length:1];
    }
    return data;
}

static NSString *AWEAuthorizationInstallSalt(void) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *key = AWEAuthorizationDefaultsKey(2);
    NSString *salt = [defaults stringForKey:key];
    if (salt.length == 32) return salt;
    uint8_t randomBytes[16];
    arc4random_buf(randomBytes, sizeof(randomBytes));
    salt = AWEHexStringFromData([NSData dataWithBytes:randomBytes length:sizeof(randomBytes)]);
    [defaults setObject:salt forKey:key];
    return salt;
}

static NSString *AWEAuthorizationDeviceIdentifier(void) {
    NSString *value = UIDevice.currentDevice.identifierForVendor.UUIDString;
    if (value.length == 0) value = NSBundle.mainBundle.bundleIdentifier;
    return value.lowercaseString ?: @"";
}

static NSString *AWEAuthorizationProofForDigestHex(NSString *digestHex) {
    if (digestHex.length != 64) return @"";
    NSString *payload = [NSString stringWithFormat:@"%@%@|%@|%@%@",
        AWEAuthorizationTokenPrefix(), digestHex,
        AWEAuthorizationDeviceIdentifier(), AWEAuthorizationInstallSalt(),
        AWEAuthorizationTokenSuffix()];
    return AWEHexStringFromData(AWEHashData([payload dataUsingEncoding:NSUTF8StringEncoding]));
}

static BOOL gAWEAuthorizationCacheLoaded = NO;
static BOOL gAWEAuthorizationCacheValid = NO;

static BOOL AWEAuthorizationValid(void) {
    if (gAWEAuthorizationCacheLoaded) return gAWEAuthorizationCacheValid;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    NSString *digestHex = [defaults stringForKey:AWEAuthorizationDefaultsKey(0)];
    NSString *proof = [defaults stringForKey:AWEAuthorizationDefaultsKey(1)];
    NSData *digest = AWEDataFromHexString(digestHex);
    BOOL allowed = AWEAuthorizationDigestAllowed(digest);
    NSString *expected = allowed ? AWEAuthorizationProofForDigestHex(digestHex) : @"";
    gAWEAuthorizationCacheValid = allowed && proof.length == 64 &&
        [proof isEqualToString:expected];
    gAWEAuthorizationCacheLoaded = YES;
    return gAWEAuthorizationCacheValid;
}

static BOOL AWECustomBottomBarReleaseAllowed(void) {
    /* Do not embed the two account names. Compare the already-authorized
       account digest against two independently masked 32-byte digests. */
    if (!AWEAuthorizationValid()) return NO;
    NSString *digestHex = [NSUserDefaults.standardUserDefaults
        stringForKey:AWEAuthorizationDefaultsKey(0)];
    NSData *digest = AWEDataFromHexString(digestHex);
    if (digest.length != 32) return NO;
    const uint8_t *candidate = digest.bytes;

    static const AWEAuthorizationDigestPair allowed[2] = {
        { { 0x9E, 0x20, 0x2C, 0x15, 0xAE, 0x68, 0x78, 0x7C, 0xE8, 0x3A, 0x93, 0xEB, 0xBC, 0xA4, 0x9A, 0xF7, 0x12, 0x3B, 0xD6, 0x12, 0x48, 0x12, 0x2B, 0x9E, 0x7E, 0x9A, 0xBD, 0x96, 0xC3, 0xE7, 0xC0, 0x64 }, { 0xCE, 0x7A, 0x51, 0x6A, 0xAD, 0xC5, 0x27, 0xB9, 0x1B, 0xBC, 0x21, 0x17, 0x8F, 0x7A, 0xBE, 0xA3, 0x99, 0x95, 0x52, 0xE8, 0xC8, 0xCE, 0xCE, 0x6E, 0x02, 0xD5, 0x5F, 0x5A, 0x57, 0x9D, 0x02, 0xC3 } },
        { { 0xBD, 0x8E, 0x50, 0xB9, 0x76, 0x28, 0xBA, 0xC2, 0x5A, 0x2C, 0x6C, 0xAC, 0x97, 0x64, 0x99, 0xD8, 0x31, 0xBA, 0x34, 0x09, 0xEC, 0xA0, 0x57, 0xA8, 0x92, 0x67, 0x0A, 0x96, 0x64, 0x16, 0x81, 0x83 }, { 0x18, 0x11, 0x0F, 0x48, 0x52, 0x44, 0xFA, 0xF7, 0x53, 0x7A, 0x61, 0xF2, 0x39, 0x05, 0x05, 0x03, 0x4D, 0x36, 0x92, 0x10, 0x84, 0xB0, 0xE9, 0x16, 0x87, 0x87, 0x86, 0x0F, 0x39, 0x79, 0xFB, 0xE5 } },
    };

    uint8_t expected[32];
    for (NSUInteger entry = 0; entry < 2; entry++) {
        for (NSUInteger index = 0; index < 32; index++) {
            expected[index] = allowed[entry].mask[index] ^ allowed[entry].value[index];
        }
        if (AWEConstantTimeEqual(candidate, expected, 32)) {
            memset(expected, 0, sizeof(expected));
            return YES;
        }
    }
    memset(expected, 0, sizeof(expected));
    return NO;
}

static BOOL AWEMasterEnabledStored(void) {
    return [NSUserDefaults.standardUserDefaults
        boolForKey:AWEAuthorizationDefaultsKey(3)];
}

static BOOL AWEPluginFeaturesEnabled(void) {
    return AWEAuthorizationValid() && AWEMasterEnabledStored();
}

static void AWEPostAuthorizationChanged(void) {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:AWEAuthorizationNotificationName() object:nil];
}

static void AWEBindAuthorizationDigest(NSData *digest) {
    if (!AWEAuthorizationDigestAllowed(digest)) return;
    NSString *digestHex = AWEHexStringFromData(digest);
    NSString *proof = AWEAuthorizationProofForDigestHex(digestHex);
    if (digestHex.length != 64 || proof.length != 64) return;
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:digestHex forKey:AWEAuthorizationDefaultsKey(0)];
    [defaults setObject:proof forKey:AWEAuthorizationDefaultsKey(1)];
    [defaults synchronize];
    gAWEAuthorizationCacheLoaded = YES;
    gAWEAuthorizationCacheValid = YES;
    AWEPostAuthorizationChanged();
}

static void AWERevokeAuthorization(void) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults removeObjectForKey:AWEAuthorizationDefaultsKey(0)];
    [defaults removeObjectForKey:AWEAuthorizationDefaultsKey(1)];
    [defaults setBool:NO forKey:AWEAuthorizationDefaultsKey(3)];
    [defaults synchronize];
    gAWEAuthorizationCacheLoaded = YES;
    gAWEAuthorizationCacheValid = NO;
    AWEPostAuthorizationChanged();
}

static NSArray<NSString *> *AWEAuthorizationTextCandidates(UIView *view) {
    if (!view) return @[];
    NSMutableArray<NSString *> *values = [NSMutableArray array];
    if ([view isKindOfClass:UILabel.class]) {
        UILabel *label = (UILabel *)view;
        if (label.text.length) [values addObject:label.text];
        if (label.attributedText.string.length) [values addObject:label.attributedText.string];
    }
    if ([view isKindOfClass:UIButton.class] && ((UIButton *)view).currentTitle.length)
        [values addObject:((UIButton *)view).currentTitle];
    if ([view isKindOfClass:UITextField.class] && ((UITextField *)view).text.length)
        [values addObject:((UITextField *)view).text];
    if ([view isKindOfClass:UITextView.class] && ((UITextView *)view).text.length)
        [values addObject:((UITextView *)view).text];
    if (view.accessibilityLabel.length) [values addObject:view.accessibilityLabel];
    if (view.accessibilityValue.length) [values addObject:view.accessibilityValue];
    return values;
}

static NSString *AWEAccountIdentifierFromMarkedText(NSString *text, BOOL *markerSeen) {
    if (![text isKindOfClass:NSString.class] || text.length == 0) return nil;
    NSString *lower = text.lowercaseString;
    NSArray<NSString *> *markers = @[@"抖音号", @"抖音id", @"douyin id", @"douyinid"];
    NSRange matched = NSMakeRange(NSNotFound, 0);
    for (NSString *marker in markers) {
        NSRange range = [lower rangeOfString:marker options:NSCaseInsensitiveSearch];
        if (range.location != NSNotFound) { matched = range; break; }
    }
    if (matched.location == NSNotFound) return nil;
    if (markerSeen) *markerSeen = YES;
    NSUInteger start = NSMaxRange(matched);
    if (start >= text.length) return nil;
    NSCharacterSet *skip = [NSCharacterSet characterSetWithCharactersInString:@" \t\r\n:：·|-"];
    while (start < text.length && [skip characterIsMember:[text characterAtIndex:start]]) start++;
    if (start >= text.length) return nil;
    NSString *tail = [text substringFromIndex:start];
    NSArray<NSString *> *parts = [tail componentsSeparatedByCharactersInSet:
        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *candidate = parts.firstObject ?: tail;
    for (NSString *separator in @[@"复制", @"｜", @"|", @"，", @",", @"；", @";"]) {
        NSRange range = [candidate rangeOfString:separator];
        if (range.location != NSNotFound) candidate = [candidate substringToIndex:range.location];
    }
    candidate = AWENormalizedAccountIdentifier(candidate);
    return candidate.length ? candidate : nil;
}

static void AWECollectAuthorizationTexts(UIView *root, NSMutableArray<NSString *> *texts,
                                         NSUInteger depth) {
    if (!root || !texts || depth > 36 || root.hidden || root.alpha < 0.01) return;
    [texts addObjectsFromArray:AWEAuthorizationTextCandidates(root)];
    for (UIView *child in root.subviews)
        AWECollectAuthorizationTexts(child, texts, depth + 1);
}

static BOOL AWECurrentMainTabAppearsToBeMe(void) {
    AWENormalModeTabBarController *controller = gAWELastController;
    if (!controller) return NO;
    for (NSString *key in @[@"selectedIndex", @"currentSelectedIndex", @"currentIndex"]) {
        @try {
            id value = [controller valueForKey:key];
            if ([value respondsToSelector:@selector(integerValue)] && [value integerValue] == 4)
                return YES;
        } @catch (__unused NSException *exception) {}
    }
    NSArray *buttons = nil;
    @try { buttons = [controller buttons]; } @catch (__unused NSException *exception) {}
    if (buttons.count == 5) {
        id meButton = buttons[4];
        if ([meButton isKindOfClass:UIControl.class] && ((UIControl *)meButton).selected)
            return YES;
        for (NSString *key in @[@"selected", @"isSelected"]) {
            @try {
                id value = [meButton valueForKey:key];
                if ([value respondsToSelector:@selector(boolValue)] && [value boolValue]) return YES;
            } @catch (__unused NSException *exception) {}
        }
    }
    return NO;
}

static BOOL AWECurrentPageAllowsSettingsGesture(void) {
    if (!AWESettingsGestureMineOnlyEnabled()) return YES;

    /* Fail open instead of locking the user out. If the Profile entry was
       disabled in the bottom-bar configurator, a profile-only gesture would
       otherwise become impossible to trigger. In that configuration the
       two-finger long press automatically falls back to global availability. */
    if (![AWEStoredAlbumMorphEnabledItemIdentifiers() containsObject:@"profile"]) {
        return YES;
    }

    /* Prefer the canonical tab identity exposed by the custom/native bridge.
       On some Douyin builds the underlying AWENormalModeTabBarController no
       longer reports selectedIndex/isSelected in the way older builds did;
       using only that private state made the opt-in guard reject the real Me
       page and could lock the settings gesture out completely. */
    NSInteger resolvedIndex = AWECurrentMainTabIndex();
    if (resolvedIndex == 4) return YES;

    /* Keep the older detector as a secondary compatibility signal. */
    if (AWECurrentMainTabAppearsToBeMe()) return YES;

    return NO;
}

static BOOL AWEPageLooksLikeOwnProfile(UIViewController *controller,
                                       NSArray<NSString *> *texts) {
    NSString *name = NSStringFromClass(controller.class).lowercaseString;
    BOOL hasEditProfile = NO;
    BOOL hasDouyinMarker = NO;
    BOOL hasOwnProfileText = NO;

    for (NSString *text in texts) {
        NSString *lower = text.lowercaseString;
        if ([lower containsString:@"编辑主页"] ||
            [lower containsString:@"编辑资料"] ||
            [lower containsString:@"编辑个人资料"] ||
            [lower containsString:@"edit profile"]) {
            hasEditProfile = YES;
        }
        if ([lower containsString:@"我的主页"] ||
            [lower containsString:@"个人主页"] ||
            [lower containsString:@"my profile"]) {
            hasOwnProfileText = YES;
        }
        if ([lower containsString:@"抖音号"] ||
            [lower containsString:@"抖音id"] ||
            [lower containsString:@"douyin id"]) {
            hasDouyinMarker = YES;
        }
    }

    /* UserDetail-style controllers are also used for the signed-in profile. */
    if (AWECurrentMainTabAppearsToBeMe()) return YES;
    if (hasEditProfile && hasDouyinMarker) return YES;
    if (hasOwnProfileText && hasDouyinMarker) return YES;

    if ([name containsString:@"otheruser"]) return NO;
    if ([name containsString:@"mine"] || [name containsString:@"self"] ||
        [name containsString:@"personal"] || [name containsString:@"myhome"]) return YES;
    return NO;
}

static BOOL AWEAttemptAuthorizationFromVisiblePage(UIViewController *controller) {
    UIWindow *window = controller.view.window ?: AWEActiveMainWindow();
    if (!window) return NO;
    NSMutableArray<NSString *> *texts = [NSMutableArray array];
    AWECollectAuthorizationTexts(window, texts, 0);
    BOOL ownProfile = AWEPageLooksLikeOwnProfile(controller, texts);
    BOOL markerSeen = NO;
    NSString *explicitCandidate = nil;
    for (NSString *text in texts) {
        BOOL localMarker = NO;
        NSString *candidate = AWEAccountIdentifierFromMarkedText(text, &localMarker);
        markerSeen = markerSeen || localMarker;
        if (candidate.length) { explicitCandidate = candidate; break; }
    }
    if (explicitCandidate.length) {
        NSData *digest = AWEAuthorizationDigestForIdentifier(explicitCandidate);
        if (ownProfile && AWEAuthorizationDigestAllowed(digest)) {
            AWEBindAuthorizationDigest(digest);
            return YES;
        }
        if (ownProfile && markerSeen && AWEAuthorizationValid()) AWERevokeAuthorization();
        return NO;
    }
    if (!ownProfile) return NO;
    for (NSString *text in texts) {
        NSString *candidate = AWENormalizedAccountIdentifier(text);
        if (candidate.length < 3 || candidate.length > 48) continue;
        NSData *digest = AWEAuthorizationDigestForIdentifier(candidate);
        if (AWEAuthorizationDigestAllowed(digest)) {
            AWEBindAuthorizationDigest(digest);
            return YES;
        }
    }
    return NO;
}

static void AWETrySilentAuthorization(UIViewController *controller) {
    if (!controller) return;
    AWEAttemptAuthorizationFromVisiblePage(controller);
}

static BOOL AWEChatCapsuleEnabled(void) {
    if (!AWEPluginFeaturesEnabled()) return NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:kAWEChatCapsuleEnabledDefaultsKey]) {
        return NO;
    }
    return [defaults boolForKey:kAWEChatCapsuleEnabledDefaultsKey];
}

static BOOL AWEChatSeparateLeftEnabled(void) {
    if (!AWEPluginFeaturesEnabled()) return NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:kAWEChatSeparateLeftDefaultsKey]) {
        return NO;
    }
    return [defaults boolForKey:kAWEChatSeparateLeftDefaultsKey];
}

static NSHashTable *AWESensitiveVisibleControllers(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gAWESensitiveVisibleControllers = [NSHashTable weakObjectsHashTable];
    });
    return gAWESensitiveVisibleControllers;
}

static NSHashTable *AWECommerceProductDetailMarkers(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gAWECommerceProductDetailMarkers = [NSHashTable weakObjectsHashTable];
    });
    return gAWECommerceProductDetailMarkers;
}

static void AWERegisterCommerceProductDetailMarker(UIView *view) {
    if (!view) return;

    [AWECommerceProductDetailMarkers() addObject:view];
    gAWECommerceSuppressionUntil = CACurrentMediaTime() + 0.35;
}

static void AWEUnregisterCommerceProductDetailMarker(UIView *view) {
    if (!view) return;

    [AWECommerceProductDetailMarkers() removeObject:view];
    gAWECommerceSuppressionUntil =
        MAX(gAWECommerceSuppressionUntil, CACurrentMediaTime() + 0.08);
}

static BOOL AWEShouldSuppressBarForCommerceProductDetail(void) {
    if (CACurrentMediaTime() < gAWECommerceSuppressionUntil) {
        return YES;
    }

    for (UIView *marker in AWECommerceProductDetailMarkers()) {
        if (marker.window != nil && !marker.hidden && marker.alpha > 0.01) {
            return YES;
        }
    }

    return NO;
}

#pragma mark - Chat composer diagnostics

static dispatch_queue_t AWEComposerLogQueue(void) {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.awemeliquidbar.chat-input-log",
                                      DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

static NSString *AWEComposerLogPath(void) {
    static NSString *path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *documents =
            NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                NSUserDomainMask,
                                                YES).firstObject;
        if (documents.length > 0) {
            path = [[documents
                stringByAppendingPathComponent:
                    @"AwemeLiquidBar_chat_input.log"] copy];
        }
    });
    return path;
}

static BOOL AWEComposerDiagnosticsEnabled(void) { return NO; }

static void AWEComposerLog(NSString *format, ...) { (void)format; }

static NSString *AWEComposerColorDescription(UIColor *color) {
    if (!color) return @"<nil>";

    CGFloat white = 0.0;
    CGFloat alpha = 0.0;
    if ([color getWhite:&white alpha:&alpha]) {
        return [NSString stringWithFormat:@"white=%.4f alpha=%.4f dynamic=%d",
                                          white, alpha,
                                          color != [color resolvedColorWithTraitCollection:
                                              [UITraitCollection traitCollectionWithUserInterfaceStyle:
                                                  UIUserInterfaceStyleLight]]];
    }

    CGFloat red = 0.0, green = 0.0, blue = 0.0;
    if ([color getRed:&red green:&green blue:&blue alpha:&alpha]) {
        return [NSString stringWithFormat:
            @"rgba=(%.4f,%.4f,%.4f,%.4f)", red, green, blue, alpha];
    }

    return color.description ?: @"<unknown>";
}

static NSString *AWEComposerViewSignature(UIView *view) {
    if (!view) return @"<nil>";

    return [NSString stringWithFormat:
        @"class=%@ ptr=%p frame=%@ bounds=%@ hidden=%d alpha=%.3f "
         @"bg={%@} radius=%.3f curve=%@ masks=%d clips=%d opaque=%d "
         @"window=%p super=%@ subviews=%lu",
         NSStringFromClass(view.class), (__bridge void *)view,
         NSStringFromCGRect(view.frame), NSStringFromCGRect(view.bounds),
         view.hidden, view.alpha,
         AWEComposerColorDescription(view.backgroundColor),
         view.layer.cornerRadius,
         view.layer.cornerCurve ?: @"<nil>",
         view.layer.masksToBounds, view.clipsToBounds, view.opaque,
         (__bridge void *)view.window,
         view.superview ? NSStringFromClass(view.superview.class) : @"<nil>",
         (unsigned long)view.subviews.count];
}

static void AWEAppendComposerTree(NSMutableString *output,
                                  UIView *view,
                                  NSUInteger depth,
                                  NSUInteger maximumDepth) {
    if (!output || !view || depth > maximumDepth) return;

    NSMutableString *indent = [NSMutableString string];
    for (NSUInteger index = 0; index < depth; index++) {
        [indent appendString:@"  "];
    }

    [output appendFormat:@"\n%@- %@",
                         indent, AWEComposerViewSignature(view)];

    if (depth == maximumDepth) return;
    for (UIView *subview in view.subviews) {
        AWEAppendComposerTree(output, subview, depth + 1, maximumDepth);
    }
}

static void AWELogComposerTree(NSString *event,
                               UIView *root,
                               NSUInteger maximumDepth) {
    if (!AWEComposerDiagnosticsEnabled()) return;

    if (!event || !root) return;

    NSMutableString *tree = [NSMutableString
        stringWithFormat:@"%@ ROOT %@", event,
                         AWEComposerViewSignature(root)];
    for (UIView *subview in root.subviews) {
        AWEAppendComposerTree(tree, subview, 1, maximumDepth);
    }
    AWEComposerLog(@"%@", tree);
}

static void AWELogComposerSnapshot(NSString *event,
                                   UIView *composer,
                                   BOOL includeTree,
                                   BOOL force) {
    if (!AWEComposerDiagnosticsEnabled()) return;

    if (!event || !composer) return;

    NSString *signature = AWEComposerViewSignature(composer);
    NSString *last = objc_getAssociatedObject(
        composer, &kAWEComposerProbeLastSignatureKey);
    if (!force && [last isEqualToString:signature]) return;

    objc_setAssociatedObject(composer,
                             &kAWEComposerProbeLastSignatureKey,
                             signature,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);

    AWEComposerLog(@"%@ %@", event, signature);
    if (includeTree) {
        AWELogComposerTree([event stringByAppendingString:@".tree"],
                           composer, 3);
    }
}


static BOOL AWEApproximatelyEqual(CGFloat first,
                                  CGFloat second,
                                  CGFloat tolerance) {
    return fabs(first - second) <= tolerance;
}

static UIView *AWEFindViewByRuntimeClassName(UIView *root, NSString *className);

static UIView *AWEChatPaintFillView(UIView *container) {
    if (!container) return nil;

    for (UIView *subview in container.subviews) {
        BOOL fillsBounds =
            AWEApproximatelyEqual(CGRectGetMinX(subview.frame), 0.0, 1.0) &&
            AWEApproximatelyEqual(CGRectGetMinY(subview.frame), 0.0, 1.0) &&
            AWEApproximatelyEqual(CGRectGetWidth(subview.frame),
                                  CGRectGetWidth(container.bounds), 1.5) &&
            AWEApproximatelyEqual(CGRectGetHeight(subview.frame),
                                  CGRectGetHeight(container.bounds), 1.5);

        if (fillsBounds && subview.backgroundColor) {
            return subview;
        }
    }

    return nil;
}

static BOOL AWEChatViewHasVisiblePaint(UIView *view) {
    if (!view || !view.backgroundColor) return NO;
    UIColor *resolved = view.backgroundColor;
    if (@available(iOS 13.0, *)) {
        resolved = [resolved resolvedColorWithTraitCollection:view.traitCollection];
    }
    CGFloat alpha = 0.0, white = 0.0;
    if ([resolved getWhite:&white alpha:&alpha]) return alpha > 0.02;
    CGFloat red = 0.0, green = 0.0, blue = 0.0;
    if ([resolved getRed:&red green:&green blue:&blue alpha:&alpha]) {
        return alpha > 0.02;
    }
    return CGColorGetAlpha(resolved.CGColor) > 0.02;
}

static UIView *AWEChatPaintContainer(UIView *inputRoot) {
    if (!inputRoot) return nil;

    CGFloat rootWidth = CGRectGetWidth(inputRoot.bounds);
    CGFloat rootHeight = CGRectGetHeight(inputRoot.bounds);
    if (rootWidth <= 1.0 || rootHeight <= 1.0) return nil;

    UIView *growing = AWEFindViewByRuntimeClassName(
        inputRoot, @"IESIMGrowingTextView");
    CGRect growingRect = CGRectNull;
    if (growing) {
        @try { growingRect = [growing convertRect:growing.bounds toView:inputRoot]; }
        @catch (__unused NSException *exception) { growingRect = CGRectNull; }
    }

    NSMutableArray<NSDictionary *> *queue = [NSMutableArray arrayWithObject:
        @{ @"view": inputRoot, @"depth": @0 }];
    UIView *best = nil;
    NSInteger bestScore = NSIntegerMin;
    NSUInteger visited = 0;

    while (queue.count > 0 && visited < 240) {
        NSDictionary *entry = queue.firstObject;
        [queue removeObjectAtIndex:0];
        UIView *candidate = entry[@"view"];
        NSUInteger depth = [entry[@"depth"] unsignedIntegerValue];
        visited++;

        if (candidate != inputRoot &&
            ![candidate isKindOfClass:UILabel.class] &&
            ![candidate isKindOfClass:UIImageView.class] &&
            ![candidate isKindOfClass:UITextView.class] &&
            ![candidate isKindOfClass:UITextField.class] &&
            ![candidate isKindOfClass:UIControl.class]) {
            CGRect frame = CGRectNull;
            @try { frame = [candidate convertRect:candidate.bounds toView:inputRoot]; }
            @catch (__unused NSException *exception) {}
            CGFloat width = CGRectGetWidth(frame);
            CGFloat height = CGRectGetHeight(frame);
            UIView *fill = AWEChatPaintFillView(candidate);
            BOOL painted = AWEChatViewHasVisiblePaint(candidate) || fill != nil;
            BOOL plausibleSize = !CGRectIsNull(frame) && !CGRectIsEmpty(frame) &&
                width >= MAX(150.0, rootWidth * 0.42) &&
                width <= rootWidth + 4.0 && height >= 40.0 && height <= 190.0;
            if (painted && plausibleSize) {
                NSInteger score = 0;
                if (fill) score += 180;
                if (AWEChatViewHasVisiblePaint(candidate)) score += 90;
                if (candidate.superview == inputRoot) score += 40;
                NSString *name = NSStringFromClass(candidate.class).lowercaseString;
                if ([name containsString:@"input"] ||
                    [name containsString:@"text"] ||
                    [name containsString:@"container"] ||
                    [name containsString:@"background"] ||
                    [name containsString:@"panel"]) score += 45;
                if (!CGRectIsNull(growingRect)) {
                    CGRect expanded = CGRectInset(growingRect, -34.0, -12.0);
                    CGRect intersection = CGRectIntersection(frame, expanded);
                    if (!CGRectIsNull(intersection) && !CGRectIsEmpty(intersection)) {
                        CGFloat overlap = CGRectGetWidth(intersection) *
                                          CGRectGetHeight(intersection);
                        CGFloat growingArea = MAX(1.0, CGRectGetWidth(growingRect) *
                                                       CGRectGetHeight(growingRect));
                        if (overlap / growingArea > 0.55) score += 220;
                    }
                    score -= (NSInteger)MIN(100.0,
                        fabs(CGRectGetMidY(frame) - CGRectGetMidY(growingRect)));
                }
                score -= (NSInteger)(depth * 3);
                if (score > bestScore) { bestScore = score; best = candidate; }
            }
        }

        if (depth < 6) {
            for (UIView *child in candidate.subviews) {
                [queue addObject:@{ @"view": child, @"depth": @(depth + 1) }];
            }
        }
    }
    return best;
}

static UIView *AWEFindLeftComposerAction(UIView *root) {
    if (!root) return nil;

    UIView *best = nil;
    CGFloat bestMinX = CGFLOAT_MAX;

    NSMutableArray<UIView *> *queue =
        [NSMutableArray arrayWithObject:root];

    while (queue.count > 0) {
        UIView *view = queue.firstObject;
        [queue removeObjectAtIndex:0];

        NSString *className = NSStringFromClass(view.class);
        BOOL matchingClass =
            [className isEqualToString:@"AWEIMInputVCBadgeButton"] ||
            [className isEqualToString:
                @"AWEIMInputVCUnhighlightedBadgeButton"];

        if (matchingClass && view != root) {
            CGRect rect = [view convertRect:view.bounds toView:root];
            CGFloat width = CGRectGetWidth(rect);
            CGFloat height = CGRectGetHeight(rect);

            BOOL expectedSize =
                width >= 24.0 && width <= 40.0 &&
                height >= 24.0 && height <= 40.0;
            BOOL onLeft =
                CGRectGetMinX(rect) >= -2.0 &&
                CGRectGetMaxX(rect) <= 90.0;

            if (expectedSize && onLeft &&
                CGRectGetMinX(rect) < bestMinX) {
                best = view;
                bestMinX = CGRectGetMinX(rect);
            }
        }

        [queue addObjectsFromArray:view.subviews];
    }

    return best;
}

static CGFloat AWEChatCapsuleLeftInset(UIView *backgroundView) {
    if (!backgroundView || !AWEChatSeparateLeftEnabled()) return 0.0;

    UIView *root = backgroundView.superview;
    if (!root) return 45.0;

    UIView *leftAction = AWEFindLeftComposerAction(root);
    if (!leftAction) {
        return MIN(45.0, MAX(0.0,
                   CGRectGetWidth(backgroundView.bounds) - 44.0));
    }

    CGRect localRect =
        [leftAction convertRect:leftAction.bounds toView:backgroundView];

    /*
     The logged layout uses a 30 pt action at root x=15 and a background at
     root x=8. This calculation therefore yields 45 pt locally:
     maxX(37) + 8 pt visual gap. It also adapts if Douyin shifts the button.
    */
    CGFloat inset = CGRectGetMaxX(localRect) + 8.0;
    CGFloat maximum =
        MAX(0.0, CGRectGetWidth(backgroundView.bounds) - 44.0);
    return MIN(MAX(inset, 36.0), MIN(64.0, maximum));
}

static void AWEStoreOriginalChatShapeIfNeeded(UIView *view) {
    if (!view) return;
    if (objc_getAssociatedObject(view, &kAWEChatOriginalRadiusKey)) return;

    objc_setAssociatedObject(view,
                             &kAWEChatOriginalRadiusKey,
                             @(view.layer.cornerRadius),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(view,
                             &kAWEChatOriginalMasksKey,
                             @(view.layer.masksToBounds),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(view,
                             &kAWEChatOriginalClipsKey,
                             @(view.clipsToBounds),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void AWERestoreOriginalChatShape(UIView *view) {
    if (!view) return;

    NSNumber *radius =
        objc_getAssociatedObject(view, &kAWEChatOriginalRadiusKey);
    NSNumber *masks =
        objc_getAssociatedObject(view, &kAWEChatOriginalMasksKey);
    NSNumber *clips =
        objc_getAssociatedObject(view, &kAWEChatOriginalClipsKey);

    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    view.layer.mask = nil;
    view.layer.cornerRadius = radius ? radius.doubleValue : 8.0;
    view.layer.masksToBounds = masks ? masks.boolValue : YES;
    view.clipsToBounds = clips ? clips.boolValue : YES;

    [CATransaction commit];
}

static void AWEApplyExactChatCapsuleMask(UIView *view,
                                         NSString *event,
                                         BOOL shouldLog) {
    if (!view || !AWEChatCapsuleEnabled()) return;

    AWEStoreOriginalChatShapeIfNeeded(view);

    CGFloat width = CGRectGetWidth(view.bounds);
    CGFloat height = CGRectGetHeight(view.bounds);
    if (width <= 1.0 || height <= 1.0) return;

    CGFloat leftInset = AWEChatCapsuleLeftInset(view);
    CGRect capsuleRect =
        CGRectMake(leftInset, 0.0, MAX(1.0, width - leftInset), height);
    /* Keep the single-line 22 pt end radius while the composer grows.
       Using height/2 on a multi-line field turns the whole tall background
       into two oversized semicircles instead of vertically stretching it. */
    CGFloat radius = MIN(22.0, height * 0.5);

    CAShapeLayer *mask =
        objc_getAssociatedObject(view, &kAWEChatCapsuleMaskKey);
    if (![mask isKindOfClass:[CAShapeLayer class]]) {
        mask = [CAShapeLayer layer];
        objc_setAssociatedObject(view,
                                 &kAWEChatCapsuleMaskKey,
                                 mask,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    UIBezierPath *path =
        [UIBezierPath bezierPathWithRoundedRect:capsuleRect
                                   cornerRadius:radius];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    mask.frame = view.bounds;
    mask.path = path.CGPath;
    view.layer.mask = mask;

    /*
     Use the geometric path itself for the two half-circles. Do not combine it
     with continuous-corner rounding, which made the 44 pt bar look swollen.
    */
    view.layer.cornerRadius = 0.0;
    view.layer.masksToBounds = NO;
    view.clipsToBounds = NO;

    [CATransaction commit];

    if (shouldLog) {
        AWEComposerLog(@"%@ exactCapsule inset=%.2f radius=%.2f rect=%@ view={%@}",
                       event ?: @"chatCapsule",
                       leftInset,
                       radius,
                       NSStringFromCGRect(capsuleRect),
                       AWEComposerViewSignature(view));
    }
}

static BOOL AWEApplyPaintedChatInputPill(UIViewController *controller,
                                        NSString *event,
                                        BOOL shouldLog) {
    if (!controller.view || !AWEChatCapsuleEnabled()) return NO;

    UIView *container = AWEChatPaintContainer(controller.view);
    UIView *fill = AWEChatPaintFillView(container);
    if (container && !fill && AWEChatViewHasVisiblePaint(container)) {
        fill = container;
    }
    if (!container || !fill) {
        if (shouldLog) {
            AWEComposerLog(@"%@ target-missing root=%@",
                           event ?: @"paintedPill",
                           AWEComposerViewSignature(controller.view));
        }
        return NO;
    }

    if (shouldLog) {
        AWEComposerLog(@"%@ before container={%@} fill={%@}",
                       event ?: @"paintedPill",
                       AWEComposerViewSignature(container),
                       AWEComposerViewSignature(fill));
    }

    AWEApplyExactChatCapsuleMask(container,
                                event ?: @"paintedPill",
                                shouldLog);

    AWEStoreOriginalChatShapeIfNeeded(fill);

    if (AWEChatCapsuleEnabled()) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        fill.layer.cornerRadius = 0.0;
        fill.layer.masksToBounds = NO;
        fill.clipsToBounds = NO;
        [CATransaction commit];
    } else {
        AWERestoreOriginalChatShape(fill);
    }

    if (shouldLog) {
        AWEComposerLog(@"%@ after container={%@} fill={%@}",
                       event ?: @"paintedPill",
                       AWEComposerViewSignature(container),
                       AWEComposerViewSignature(fill));
    }

    return YES;
}

static void AWEApplyChatPillNearGrowingTextView(UIView *growing,
                                                NSString *event) {
    if (!growing || !AWEChatCapsuleEnabled()) return;
    UIView *root = growing;
    for (NSUInteger depth = 0; depth < 6 && root.superview; depth++) {
        UIView *next = root.superview;
        root = next;
        if (CGRectGetWidth(root.bounds) >= CGRectGetWidth(growing.bounds) + 70.0 &&
            CGRectGetHeight(root.bounds) <= 220.0) {
            UIView *container = AWEChatPaintContainer(root);
            if (container) {
                UIView *fill = AWEChatPaintFillView(container);
                AWEApplyExactChatCapsuleMask(container, event, NO);
                if (fill && fill != container) {
                    [CATransaction begin];
                    [CATransaction setDisableActions:YES];
                    fill.layer.cornerRadius = 0.0;
                    fill.layer.masksToBounds = NO;
                    fill.clipsToBounds = NO;
                    [CATransaction commit];
                }
                return;
            }
        }
    }
}

static void AWEApplyChatCornerToView(UIView *view,
                                     NSString *event,
                                     BOOL shouldLog) {
    if (!AWEChatCapsuleEnabled()) return;
    AWEApplyExactChatCapsuleMask(view, event, shouldLog);
}

static UIView *AWEFindViewByRuntimeClassName(UIView *root,
                                             NSString *className) {
    if (!root || className.length == 0) return nil;
    if ([NSStringFromClass(root.class) isEqualToString:className]) {
        return root;
    }
    for (UIView *subview in root.subviews) {
        UIView *match = AWEFindViewByRuntimeClassName(subview, className);
        if (match) return match;
    }
    return nil;
}


static BOOL AWEFrameNearEqual(CGRect left, CGRect right) {
    return fabs(CGRectGetMinX(left) - CGRectGetMinX(right)) < 0.6 &&
           fabs(CGRectGetMinY(left) - CGRectGetMinY(right)) < 0.6 &&
           fabs(CGRectGetWidth(left) - CGRectGetWidth(right)) < 0.6 &&
           fabs(CGRectGetHeight(left) - CGRectGetHeight(right)) < 0.6;
}

static void AWEApplyHorizontalFrameShift(UIView *view,
                                         CGFloat shift,
                                         const void *baseKey,
                                         const void *appliedKey) {
    if (!view) return;

    CGRect current = view.frame;
    NSValue *baseValue = objc_getAssociatedObject(view, baseKey);
    NSValue *appliedValue = objc_getAssociatedObject(view, appliedKey);
    CGRect base = current;

    if (baseValue && appliedValue &&
        AWEFrameNearEqual(current, appliedValue.CGRectValue)) {
        base = baseValue.CGRectValue;
    } else {
        objc_setAssociatedObject(view,
                                 baseKey,
                                 [NSValue valueWithCGRect:current],
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGFloat safeShift =
        MIN(MAX(shift, 0.0), MAX(0.0, CGRectGetWidth(base) - 20.0));

    CGRect target = base;
    target.origin.x += safeShift;
    target.size.width = MAX(20.0, target.size.width - safeShift);

    if (!AWEFrameNearEqual(current, target)) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        view.frame = target;
        [CATransaction commit];
    }

    objc_setAssociatedObject(view,
                             appliedKey,
                             [NSValue valueWithCGRect:target],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static BOOL AWEViewIsDescendantOfView(UIView *view, UIView *ancestor) {
    if (!view || !ancestor) return NO;

    UIView *cursor = view;
    while (cursor) {
        if (cursor == ancestor) return YES;
        cursor = cursor.superview;
    }
    return NO;
}

static void AWECollectPlaceholderLabels(UIView *root,
                                        NSMutableArray *results) {
    if (!root || !results) return;

    if ([root isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)root;
        NSString *value = label.text ?: label.accessibilityLabel;
        if ([value containsString:@"发消息"]) {
            [results addObject:label];
        }
    }

    for (UIView *subview in root.subviews) {
        AWECollectPlaceholderLabels(subview, results);
    }
}

static void AWEApplyChatTextGeometry(UIView *root) {
    if (!root) return;

    /*
     IESIMTextViewInternal is corrected by its own setFrame:/layoutSubviews
     hook below. FLEX confirmed that Douyin resets that frame after the input
     controller has completed layout, which is why the previous controller-
     level correction did not remain visible.

     Keep only the fallback for builds that render “发消息…” as a separate
     UILabel outside IESIMTextViewInternal.
    */
    CGFloat shift =
        (AWEChatCapsuleEnabled() && AWEChatSeparateLeftEnabled()) ? 10.0 : 0.0;

    UIView *internal =
        AWEFindViewByRuntimeClassName(root, @"IESIMTextViewInternal");

    NSMutableArray *labels = [NSMutableArray array];
    AWECollectPlaceholderLabels(root, labels);

    for (UILabel *label in labels) {
        if (internal && AWEViewIsDescendantOfView(label, internal)) continue;

        AWEApplyHorizontalFrameShift(label,
                                     shift,
                                     &kAWEChatPlaceholderBaseFrameKey,
                                     &kAWEChatPlaceholderAppliedFrameKey);
    }
}

#pragma mark - Transition diagnostics

static dispatch_queue_t AWETransitionLogQueue(void) {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.awemeliquidbar.transition-log",
                                      DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

static NSString *AWETransitionLogPath(void) {
    static NSString *path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *documents =
            NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                NSUserDomainMask,
                                                YES).firstObject;
        if (documents.length > 0) {
            path = [[documents
                stringByAppendingPathComponent:@"AwemeLiquidBar_021d_native_bootstrap_release_fix.log"]
                    copy];
        }
    });
    return path;
}

static void AWETransitionLog(NSString *format, ...) { (void)format; }

static NSString *AWEViewStateDescription(UIView *view) {
    if (!view) return @"<nil>";

    UIView *superview = view.superview;
    UIWindow *window = view.window;
    CGRect windowFrame = CGRectNull;
    if (window) {
        @try {
            windowFrame = [view convertRect:view.bounds toView:window];
        } @catch (__unused NSException *exception) {
            windowFrame = CGRectNull;
        }
    }

    NSUInteger index = NSNotFound;
    if (superview) {
        index = [superview.subviews indexOfObjectIdenticalTo:view];
    }

    return [NSString stringWithFormat:
        @"class=%@ ptr=%p hidden=%d alpha=%.4f frame=%@ winFrame=%@ "
         @"bounds=%@ center=%@ transform=%@ super=%@/%p index=%@ "
         @"window=%@/%p level=%.1f",
        NSStringFromClass(view.class), (__bridge void *)view,
        view.hidden, view.alpha,
        NSStringFromCGRect(view.frame),
        NSStringFromCGRect(windowFrame),
        NSStringFromCGRect(view.bounds),
        NSStringFromCGPoint(view.center),
        NSStringFromCGAffineTransform(view.transform),
        superview ? NSStringFromClass(superview.class) : @"nil",
        (__bridge void *)superview,
        index == NSNotFound ? @"NSNotFound" :
            [NSString stringWithFormat:@"%lu", (unsigned long)index],
        window ? NSStringFromClass(window.class) : @"nil",
        (__bridge void *)window,
        window ? window.windowLevel : 0.0];
}

static NSString *AWEControllerTrail(UIViewController *controller) {
    if (!controller) return @"<nil>";

    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    UIViewController *current = controller;

    for (NSUInteger depth = 0; current && depth < 12; depth++) {
        [parts addObject:[NSString stringWithFormat:@"%@/%p",
                          NSStringFromClass(current.class),
                          (__bridge void *)current]];

        UIViewController *next = nil;
        if (current.presentedViewController &&
            !current.presentedViewController.isBeingDismissed) {
            next = current.presentedViewController;
        } else if ([current isKindOfClass:[UINavigationController class]]) {
            next = ((UINavigationController *)current).visibleViewController;
        } else if ([current isKindOfClass:[UITabBarController class]]) {
            next = ((UITabBarController *)current).selectedViewController;
        } else {
            for (UIViewController *child in
                 current.childViewControllers.reverseObjectEnumerator) {
                if (child.viewIfLoaded.window) {
                    next = child;
                    break;
                }
            }
        }

        if (!next || next == current) break;
        current = next;
    }

    return [parts componentsJoinedByString:@" -> "];
}

static void AWELogBarSnapshot(NSString *event,
                              UIViewController *controller,
                              BOOL force) {
    if (!gAWETransitionDiagnosticsEnabled) return;
    AWENormalModeTabBar *original = gAWELastTabBar;
    if (!original) return;

    UITabBar *nativeBar = original ?
        objc_getAssociatedObject((UIView *)original, &kAWENativeBarKey) : nil;

    UIWindow *window = original.window ?: nativeBar.window ?:
                       controller.viewIfLoaded.window;
    UIViewController *root = window.rootViewController;

    NSString *originalState = AWEViewStateDescription((UIView *)original);
    NSString *nativeState = AWEViewStateDescription(nativeBar);
    NSString *trail = AWEControllerTrail(root ?: controller);

    NSString *signature = [NSString stringWithFormat:@"%@|%@|%@",
                            trail, originalState, nativeState];

    id signatureOwner = original ?: (UIView *)nativeBar;
    if (!force && signatureOwner) {
        NSString *last =
            objc_getAssociatedObject(signatureOwner, &kAWELogSignatureKey);
        if ([last isEqualToString:signature]) return;
        objc_setAssociatedObject(signatureOwner, &kAWELogSignatureKey,
                                 signature,
                                 OBJC_ASSOCIATION_COPY_NONATOMIC);
    }

    AWETransitionLog(@"event=%@ sourceVC=%@/%p trail=[%@] "
                     @"original={%@} native={%@}",
                     event ?: @"unknown",
                     controller ? NSStringFromClass(controller.class) : @"nil",
                     (__bridge void *)controller,
                     trail,
                     originalState,
                     nativeState);
}

static BOOL AWEIsOurNativeBar(UITabBar *bar) {
    return [bar.accessibilityIdentifier
        isEqualToString:@"AwemeLiquidBar.NativeUITabBar"];
}

#pragma mark - Helpers

static BOOL AWEIsApplying(UIView *view) {
    return [objc_getAssociatedObject(view, &kAWEApplyingKey) boolValue];
}

static void AWESetApplying(UIView *view, BOOL applying) {
    objc_setAssociatedObject(view, &kAWEApplyingKey, @(applying),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static NSArray *AWEControllerButtons(id controller) {
    if (!controller) return nil;

    NSArray *buttons = nil;
    @try {
        if ([controller respondsToSelector:@selector(buttons)]) {
            buttons = [controller buttons];
        } else {
            buttons = [controller valueForKey:@"buttons"];
        }
    } @catch (__unused NSException *exception) {
        buttons = nil;
    }

    return [buttons isKindOfClass:[NSArray class]] ? buttons : nil;
}

static AWENormalModeTabBar *AWETabBarFromButtons(NSArray *buttons) {
    for (id object in buttons) {
        if ([object isKindOfClass:[UIView class]]) {
            UIView *view = (UIView *)object;
            if ([NSStringFromClass(view.superview.class) isEqualToString:@"AWENormalModeTabBar"]) {
                return (AWENormalModeTabBar *)view.superview;
            }
        }
    }
    return nil;
}

static NSInteger AWEIndexOfButton(id button, NSArray *buttons) {
    if (!button || buttons.count == 0) return NSNotFound;

    NSUInteger exact = [buttons indexOfObjectIdenticalTo:button];
    if (exact != NSNotFound) return (NSInteger)exact;

    if ([button isKindOfClass:[UIView class]]) {
        UIView *selectedView = (UIView *)button;
        CGFloat selectedMidX = CGRectGetMidX(selectedView.frame);
        CGFloat bestDistance = CGFLOAT_MAX;
        NSInteger bestIndex = NSNotFound;

        for (NSUInteger index = 0; index < buttons.count; index++) {
            id candidate = buttons[index];
            if (![candidate isKindOfClass:[UIView class]]) continue;

            CGFloat distance = fabs(CGRectGetMidX(((UIView *)candidate).frame) - selectedMidX);
            if (distance < bestDistance) {
                bestDistance = distance;
                bestIndex = (NSInteger)index;
            }
        }
        return bestIndex;
    }

    return NSNotFound;
}

#pragma mark - Native UIKit bar

static NSString *AWECanonicalHexString(NSString *input) {
    if (![input isKindOfClass:[NSString class]]) return nil;

    NSString *value =
        [[input stringByTrimmingCharactersInSet:
                 [NSCharacterSet whitespaceAndNewlineCharacterSet]]
         uppercaseString];

    if ([value hasPrefix:@"#"]) value = [value substringFromIndex:1];

    NSCharacterSet *invalid =
        [[NSCharacterSet characterSetWithCharactersInString:@"0123456789ABCDEF"]
         invertedSet];

    if ((value.length != 6 && value.length != 8) ||
        [value rangeOfCharacterFromSet:invalid].location != NSNotFound) {
        return nil;
    }

    return [@"#" stringByAppendingString:value];
}

static UIColor *AWEColorFromHexString(NSString *input) {
    NSString *canonical = AWECanonicalHexString(input);
    if (!canonical) return nil;

    NSString *digits = [canonical substringFromIndex:1];
    unsigned long long rgba = 0;
    [[NSScanner scannerWithString:digits] scanHexLongLong:&rgba];

    CGFloat red = 0.0;
    CGFloat green = 0.0;
    CGFloat blue = 0.0;
    CGFloat alpha = 1.0;

    if (digits.length == 6) {
        red = ((rgba >> 16) & 0xFF) / 255.0;
        green = ((rgba >> 8) & 0xFF) / 255.0;
        blue = (rgba & 0xFF) / 255.0;
    } else {
        red = ((rgba >> 24) & 0xFF) / 255.0;
        green = ((rgba >> 16) & 0xFF) / 255.0;
        blue = ((rgba >> 8) & 0xFF) / 255.0;
        alpha = (rgba & 0xFF) / 255.0;
    }

    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

static NSString *AWEStoredAccentHex(void) {
    NSString *stored =
        [[NSUserDefaults standardUserDefaults] stringForKey:kAWEAccentHexDefaultsKey];
    NSString *canonical = AWECanonicalHexString(stored);
    return canonical ?: @"#007AFF";
}

static UIColor *AWEStoredAccentColor(void) {
    UIColor *color = AWEColorFromHexString(AWEStoredAccentHex());
    if (color) return color;

    if (@available(iOS 13.0, *)) return UIColor.systemBlueColor;
    return UIColor.blueColor;
}


static NSArray<NSString *> *AWEStoredAccentHistory(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *stored = [defaults arrayForKey:kAWEAccentHistoryDefaultsKey];
    NSMutableArray<NSString *> *history = [NSMutableArray arrayWithCapacity:2];

    for (id value in stored) {
        if (![value isKindOfClass:[NSString class]]) continue;
        NSString *canonical = AWECanonicalHexString((NSString *)value);
        if (!canonical || [history containsObject:canonical]) continue;
        [history addObject:canonical];
        if (history.count == 2) break;
    }

    NSString *current = AWEStoredAccentHex();
    if (history.count == 0) {
        [history addObject:current];
    } else if (history.count < 2 && ![history containsObject:current]) {
        [history addObject:current];
    }

    NSString *fallback =
        [current isEqualToString:@"#007AFF"] ? @"#FE2C55" : @"#007AFF";
    if (history.count < 2 && ![history containsObject:fallback]) {
        [history addObject:fallback];
    }

    if (history.count < 2) {
        [history addObject:@"#34C759"];
    }

    return [history subarrayWithRange:NSMakeRange(0, MIN((NSUInteger)2,
                                                         history.count))];
}

static void AWERecordAccentHistory(NSString *hex) {
    NSString *canonical = AWECanonicalHexString(hex);
    if (!canonical) return;

    NSMutableArray<NSString *> *updated =
        [NSMutableArray arrayWithObject:canonical];

    for (NSString *existing in AWEStoredAccentHistory()) {
        if ([existing isEqualToString:canonical]) continue;
        [updated addObject:existing];
        if (updated.count == 2) break;
    }

    NSString *fallback =
        [canonical isEqualToString:@"#007AFF"] ? @"#FE2C55" : @"#007AFF";
    if (updated.count < 2 && ![updated containsObject:fallback]) {
        [updated addObject:fallback];
    }

    [[NSUserDefaults standardUserDefaults]
        setObject:updated
           forKey:kAWEAccentHistoryDefaultsKey];
}

static CGFloat AWEStoredVerticalOffset(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:kAWEVerticalOffsetDefaultsKey]) return 3.0;

    CGFloat value = [defaults doubleForKey:kAWEVerticalOffsetDefaultsKey];
    return MIN(MAX(value, -24.0), 80.0);
}

static CGFloat AWEStoredDoubleTapLikeFraction(void) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:kAWEDoubleTapLikeFractionDefaultsKey]) {
        return 1.0 / 3.0;
    }

    CGFloat value = [defaults doubleForKey:kAWEDoubleTapLikeFractionDefaultsKey];
    return MIN(MAX(value, 0.20), 0.80);
}

static BOOL gAWEWanToWLoaded = NO;
static BOOL gAWEWanToWEnabled = NO;

static BOOL AWEWanToWEnabled(void) {
    if (!AWEPluginFeaturesEnabled()) return NO;
    if (!gAWEWanToWLoaded) {
        gAWEWanToWEnabled =
            [[NSUserDefaults standardUserDefaults]
                boolForKey:kAWEWanToWDefaultsKey];
        gAWEWanToWLoaded = YES;
    }
    return gAWEWanToWEnabled;
}

static void AWESetWanToWEnabled(BOOL enabled) {
    gAWEWanToWEnabled = enabled;
    gAWEWanToWLoaded = YES;
    [[NSUserDefaults standardUserDefaults]
        setBool:enabled
         forKey:kAWEWanToWDefaultsKey];
}

/*
 Only replace an entire compact numeric count. This deliberately does not
 touch prose, usernames, comments or labels such as “1.2万获赞”.
*/
static NSString *AWECountStringByReplacingWan(NSString *text) {
    if (![text isKindOfClass:[NSString class]] || text.length < 2 ||
        text.length > 16) {
        return text;
    }

    NSUInteger wanIndex = NSNotFound;
    if ([text hasSuffix:@"万"]) {
        wanIndex = text.length - 1;
    } else if ([text hasSuffix:@"万+"] && text.length >= 3) {
        wanIndex = text.length - 2;
    } else {
        return text;
    }

    NSString *number = [text substringToIndex:wanIndex];
    if (number.length == 0 || number.length > 12) return text;

    BOOL sawDigit = NO;
    BOOL sawDot = NO;
    for (NSUInteger index = 0; index < number.length; index++) {
        unichar character = [number characterAtIndex:index];
        if (character >= '0' && character <= '9') {
            sawDigit = YES;
            continue;
        }
        if (character == '.' && !sawDot && index > 0 &&
            index + 1 < number.length) {
            sawDot = YES;
            continue;
        }
        return text;
    }

    if (!sawDigit) return text;
    return [text stringByReplacingCharactersInRange:NSMakeRange(wanIndex, 1)
                                          withString:@"W"];
}

/*
 Compact UI counters use a slightly different visual scale from the larger
 profile statistics. Keep large counters untouched; for labels at 17.5 pt or
 below, reduce only W to 97.5% while preserving the original baseline.
*/
static UIFont *AWECompactWFont(UIFont *font) {
    if (![font isKindOfClass:[UIFont class]] ||
        font.pointSize <= 0.0 || font.pointSize > 17.5) {
        return nil;
    }

    CGFloat compactSize = MAX(8.0, font.pointSize * 0.975);
    return [UIFont fontWithDescriptor:font.fontDescriptor size:compactSize];
}

static void AWEApplyCompactWStyle(NSMutableAttributedString *text,
                                  NSRange wRange,
                                  UILabel *label) {
    if (!text || !label || wRange.location == NSNotFound ||
        NSMaxRange(wRange) > text.length) {
        return;
    }

    UIFont *baseFont = nil;
    if (wRange.location < text.length) {
        id value = [text attribute:NSFontAttributeName
                           atIndex:wRange.location
                    effectiveRange:NULL];
        if ([value isKindOfClass:[UIFont class]]) baseFont = value;
    }
    if (!baseFont) baseFont = label.font;

    UIFont *compactFont = AWECompactWFont(baseFont);
    if (compactFont) {
        [text addAttribute:NSFontAttributeName
                     value:compactFont
                     range:wRange];

        /* Add a very small optical gap between the final digit and W.
           Applying kern to the preceding character adds space after it. */
        if (wRange.location > 0) {
            NSRange precedingRange = NSMakeRange(wRange.location - 1, 1);
            [text addAttribute:NSKernAttributeName
                         value:@0.3
                         range:precedingRange];
        }
    }
}


#pragma mark - 1.0.0 fixed icon configuration

typedef NS_ENUM(NSInteger, AWEConfiguredIconColorMode) {
    AWEConfiguredIconColorModeAutomatic = 0,
    AWEConfiguredIconColorModeWhite = 1,
    AWEConfiguredIconColorModeBlack = 2,
    AWEConfiguredIconColorModeAccent = 3,
    AWEConfiguredIconColorModeCustom = 4
};

static NSDictionary<NSString *, NSString *> *AWEStoredSymbolOverrides(void) {
    id value = [NSUserDefaults.standardUserDefaults
        dictionaryForKey:kAWESymbolOverridesDefaultsKey];
    return [value isKindOfClass:NSDictionary.class] ? value : @{};
}

static NSString *AWEStoredSymbolOverride(NSString *key) {
    id value = key.length ? AWEStoredSymbolOverrides()[key] : nil;
    return [value isKindOfClass:NSString.class] && [value length] ? value : nil;
}

static BOOL AWESystemSymbolNameIsValid(NSString *name) {
    return name.length > 0 && [UIImage systemImageNamed:name] != nil;
}

static NSString *AWEConfiguredSymbolName(NSString *key, NSString *fallback) {
    NSString *stored = AWEStoredSymbolOverride(key);
    return AWESystemSymbolNameIsValid(stored) ? stored : fallback;
}

static void AWESetStoredSymbolOverride(NSString *key, NSString *name) {
    if (!key.length) return;
    NSMutableDictionary *values = [AWEStoredSymbolOverrides() mutableCopy];
    if (!values) values = [NSMutableDictionary dictionary];
    NSString *trimmed = [name stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length) values[key] = trimmed;
    else [values removeObjectForKey:key];
    [NSUserDefaults.standardUserDefaults setObject:values
                                            forKey:kAWESymbolOverridesDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

static NSDictionary<NSString *, NSNumber *> *AWEStoredSymbolColorModes(void) {
    id value = [NSUserDefaults.standardUserDefaults
        dictionaryForKey:kAWESymbolColorModesDefaultsKey];
    return [value isKindOfClass:NSDictionary.class] ? value : @{};
}

static AWEConfiguredIconColorMode AWEStoredSymbolColorMode(NSString *key) {
    id value = key.length ? AWEStoredSymbolColorModes()[key] : nil;
    NSInteger mode = [value respondsToSelector:@selector(integerValue)]
        ? [value integerValue] : AWEConfiguredIconColorModeAutomatic;
    if (mode < 0 || mode > 4) mode = AWEConfiguredIconColorModeAutomatic;
    return (AWEConfiguredIconColorMode)mode;
}

static void AWESetStoredSymbolColorMode(NSString *key,
                                         AWEConfiguredIconColorMode mode) {
    if (!key.length) return;
    NSMutableDictionary *values = [AWEStoredSymbolColorModes() mutableCopy];
    if (!values) values = [NSMutableDictionary dictionary];
    if (mode == AWEConfiguredIconColorModeAutomatic) [values removeObjectForKey:key];
    else values[key] = @(mode);
    [NSUserDefaults.standardUserDefaults setObject:values
                                            forKey:kAWESymbolColorModesDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

static NSDictionary<NSString *, NSString *> *AWEStoredSymbolCustomColors(void) {
    id value = [NSUserDefaults.standardUserDefaults
        dictionaryForKey:kAWESymbolCustomColorsDefaultsKey];
    return [value isKindOfClass:NSDictionary.class] ? value : @{};
}

static NSString *AWEStoredSymbolCustomHex(NSString *key) {
    id value = key.length ? AWEStoredSymbolCustomColors()[key] : nil;
    return [value isKindOfClass:NSString.class] ? AWECanonicalHexString(value) : nil;
}

static NSString *AWEHexStringFromColor(UIColor *color) {
    if (!color) return nil;
    UIColor *resolved = color;
    if (@available(iOS 13.0, *)) {
        resolved = [color resolvedColorWithTraitCollection:
            [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]];
    }
    CGFloat red = 0, green = 0, blue = 0, alpha = 1;
    if (![resolved getRed:&red green:&green blue:&blue alpha:&alpha]) return nil;
    return [NSString stringWithFormat:@"#%02X%02X%02X",
        (int)lround(red * 255.0), (int)lround(green * 255.0),
        (int)lround(blue * 255.0)];
}

static void AWESetStoredSymbolCustomColor(NSString *key, UIColor *color) {
    if (!key.length) return;
    NSMutableDictionary *values = [AWEStoredSymbolCustomColors() mutableCopy];
    if (!values) values = [NSMutableDictionary dictionary];
    NSString *hex = AWEHexStringFromColor(color);
    if (hex.length) values[key] = hex;
    else [values removeObjectForKey:key];
    [NSUserDefaults.standardUserDefaults setObject:values
                                            forKey:kAWESymbolCustomColorsDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

static UIColor *AWEStoredSymbolCustomColor(NSString *key) {
    UIColor *color = AWEColorFromHexString(AWEStoredSymbolCustomHex(key));
    return color ?: AWEStoredAccentColor();
}

static UIColor *AWEApplyConfiguredIconColorMode(NSString *key,
                                                 UIColor *automaticColor) {
    switch (AWEStoredSymbolColorMode(key)) {
        case AWEConfiguredIconColorModeWhite:
            return UIColor.whiteColor;
        case AWEConfiguredIconColorModeBlack:
            return UIColor.blackColor;
        case AWEConfiguredIconColorModeAccent:
            return AWEStoredAccentColor();
        case AWEConfiguredIconColorModeCustom:
            return AWEStoredSymbolCustomColor(key);
        case AWEConfiguredIconColorModeAutomatic:
        default:
            return automaticColor ?: UIColor.labelColor;
    }
}

static BOOL AWESecondTabIsShop(void) {
    if (!gAWESecondTabRoleLoaded) {
        gAWESecondTabIsShop = [NSUserDefaults.standardUserDefaults
            boolForKey:kAWESecondTabShopDefaultsKey];
        gAWESecondTabRoleLoaded = YES;
    }
    return gAWESecondTabIsShop;
}

static void AWECollectSecondTabEvidence(UIView *view,
                                        NSMutableArray<NSString *> *parts,
                                        NSInteger depth) {
    if (!view || !parts || depth > 5 || parts.count > 80) return;
    NSArray *direct = @[
        view.accessibilityLabel ?: @"",
        view.accessibilityValue ?: @"",
        view.accessibilityIdentifier ?: @"",
        NSStringFromClass(view.class) ?: @""
    ];
    for (NSString *value in direct) if (value.length) [parts addObject:value];
    if ([view isKindOfClass:UILabel.class]) {
        NSString *text = ((UILabel *)view).text;
        if (text.length) [parts addObject:text];
    }
    if ([view isKindOfClass:UIButton.class]) {
        UIButton *button = (UIButton *)view;
        NSString *title = [button titleForState:UIControlStateNormal];
        if (title.length) [parts addObject:title];
        if (button.titleLabel.text.length) [parts addObject:button.titleLabel.text];
    }
    for (UIView *subview in view.subviews) {
        AWECollectSecondTabEvidence(subview, parts, depth + 1);
    }
}

static BOOL AWEUpdateSecondTabRoleFromButtons(NSArray *buttons) {
    if (buttons.count < 2 || ![buttons[1] isKindOfClass:UIView.class]) return NO;
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    AWECollectSecondTabEvidence((UIView *)buttons[1], parts, 0);
    NSString *evidence = [[parts componentsJoinedByString:@"|"] lowercaseString];
    BOOL resolved = NO;
    BOOL shop = AWESecondTabIsShop();
    NSArray<NSString *> *shopWords = @[@"商城", @"商店", @"购物", @"shop", @"mall", @"storefront"];
    NSArray<NSString *> *friendWords = @[@"朋友", @"好友", @"friend"];
    for (NSString *word in shopWords) {
        if ([evidence containsString:word]) { shop = YES; resolved = YES; break; }
    }
    if (!resolved) {
        for (NSString *word in friendWords) {
            if ([evidence containsString:word]) { shop = NO; resolved = YES; break; }
        }
    }
    if (!resolved || (gAWESecondTabRoleLoaded && shop == gAWESecondTabIsShop)) return NO;
    gAWESecondTabIsShop = shop;
    gAWESecondTabRoleLoaded = YES;
    [NSUserDefaults.standardUserDefaults setBool:shop forKey:kAWESecondTabShopDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    return YES;
}

static BOOL AWEHomeCustomPNGModeEnabled(void) {
    return [NSUserDefaults.standardUserDefaults
        boolForKey:kAWEHomeCustomPNGModeDefaultsKey];
}


static BOOL AWETopGlassEnabled(void) {
    id value = [NSUserDefaults.standardUserDefaults
        objectForKey:kAWETopGlassEnabledDefaultsKey];
    return value ? [value boolValue] : YES;
}

static BOOL AWEHideTopLeftButtonEnabled(void) {
    return [NSUserDefaults.standardUserDefaults
        boolForKey:kAWEHideTopLeftButtonDefaultsKey];
}

static BOOL AWEHomeTransparentGlassEnabled(void) {
    /* This is a new independent opt-in.  Do not inherit the old tinted-glass
       switch: upgrades as well as fresh installs must land on the verified
       1.0.41a system-adaptive path by default. */
    id stored = [NSUserDefaults.standardUserDefaults
        objectForKey:kAWEHomeTransparentGlassDefaultsKey];
    return [stored isKindOfClass:NSNumber.class]
        ? [(NSNumber *)stored boolValue]
        : NO;
}

static BOOL AWEHomeTintedGlassEnabled(void) {
    /* glassButtonConfiguration is the system-adaptive, lower-overhead default.
       clearGlassButtonConfiguration is now an explicit opt-in. */
    return !AWEHomeTransparentGlassEnabled();
}

static BOOL AWETopTelegramSwitcherEnabled(void) {
    id stored = [NSUserDefaults.standardUserDefaults
        objectForKey:kAWETopTelegramSwitcherEnabledDefaultsKey];
    return [stored isKindOfClass:NSNumber.class]
        ? [(NSNumber *)stored boolValue]
        : YES;
}

static NSInteger AWETopTelegramVisibleCount(void) {
    id stored = [NSUserDefaults.standardUserDefaults
        objectForKey:kAWETopTelegramVisibleCountDefaultsKey];
    NSInteger count = [stored isKindOfClass:NSNumber.class]
        ? [(NSNumber *)stored integerValue]
        : 3;
    return MIN(4, MAX(1, count));
}

static BOOL AWETopMenuMorphEnabled(void) {
    id stored = [NSUserDefaults.standardUserDefaults
        objectForKey:kAWETopMenuMorphEnabledDefaultsKey];
    return [stored isKindOfClass:NSNumber.class]
        ? [(NSNumber *)stored boolValue]
        : NO;
}

static NSString *AWEHomeCustomIconsDirectory(void) {
    NSString *documents = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    if (!documents.length) return nil;
    return [[documents stringByAppendingPathComponent:@"AwemeLiquidBar"]
        stringByAppendingPathComponent:@"CustomIcons"];
}

static void AWEEnsureHomeCustomIconsDirectory(void) {
    NSString *directory = AWEHomeCustomIconsDirectory();
    if (!directory.length) return;
    [[NSFileManager defaultManager] createDirectoryAtPath:directory
                              withIntermediateDirectories:YES
                                               attributes:nil error:nil];
    NSString *guidePath = [directory stringByAppendingPathComponent:@"图标命名说明.txt"];
    NSString *guide =
        @"AwemeLiquidBar 自定义 PNG（透明背景、保留原始比例）\n\n"
         "menu.png\nsearch.png\n"
         "like.png\nlike_selected.png\n"
         "comment.png（评论不区分选中状态）\n"
         "favorite.png\nfavorite_selected.png\n"
         "share.png（分享不区分选中状态）\n\n"
         "玻璃按钮本体固定为 46×46 pt。PNG 按源文件像素以 @3x 显示：30×30 px 约为 10×10 pt，100×100 px 约为 33.3×33.3 pt；小图不放大，任一边超过 100 px 时才等比例缩小。透明留白也会计入尺寸。\n\n"
         "只有点赞和收藏支持 selected 文件；缺少 selected 文件时继续使用普通文件，缺少普通文件时回退到内置 SF Symbol。\n";
    [guide writeToFile:guidePath atomically:YES
              encoding:NSUTF8StringEncoding error:nil];
}

static NSString *AWEBottomSymbolKeyForTag(NSInteger tag, __unused BOOL selected) {
    NSArray<NSString *> *roles = @[
        @"home", AWESecondTabIsShop() ? @"shop" : @"friends",
        @"publish", @"messages", @"profile"
    ];
    if (tag < 0 || tag >= (NSInteger)roles.count) return nil;
    /* 1.0.49e: one artwork per destination. Selection is expressed only by
       foreground/accent state; there is no second selected-icon preference. */
    return [NSString stringWithFormat:@"bottom.%@.normal", roles[(NSUInteger)tag]];
}

static NSString *AWEHomeCustomPNGFilenameForKey(NSString *key) {
    NSDictionary *map = @{
        @"top.menu": @"menu.png", @"top.search": @"search.png",
        @"right.like.normal": @"like.png",
        @"right.like.selected": @"like_selected.png",
        @"right.comment.normal": @"comment.png",
        @"right.favorite.normal": @"favorite.png",
        @"right.favorite.selected": @"favorite_selected.png",
        @"right.share.normal": @"share.png"
    };
    return map[key];
}

static NSCache<NSString *, UIImage *> *AWEHomeCustomPNGCache(void) {
    static NSCache<NSString *, UIImage *> *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [NSCache new];
        cache.countLimit = 16;
        cache.totalCostLimit = 8 * 1024 * 1024;
    });
    return cache;
}

static void AWEInvalidateHomeCustomPNGCache(void) {
    [AWEHomeCustomPNGCache() removeAllObjects];
}

static UIImage *AWENormalizeImportedPNGForDisplay(UIImage *image) {
    if (!image) return nil;
    CGImageRef cgImage = image.CGImage;
    if (!cgImage) return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    const CGFloat designScale = 3.0;
    const CGFloat maximumPixelEdge = 100.0;
    CGFloat pixelWidth = (CGFloat)CGImageGetWidth(cgImage);
    CGFloat pixelHeight = (CGFloat)CGImageGetHeight(cgImage);
    if (pixelWidth <= 0.0 || pixelHeight <= 0.0) {
        return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }

    CGFloat longestEdge = MAX(pixelWidth, pixelHeight);
    CGFloat resizeScale = longestEdge > maximumPixelEdge
        ? maximumPixelEdge / longestEdge
        : 1.0;
    UIImage *pixelImage = image;
    if (resizeScale < 0.999) {
        CGSize targetPixels = CGSizeMake(
            MAX(1.0, round(pixelWidth * resizeScale)),
            MAX(1.0, round(pixelHeight * resizeScale)));
        UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
        format.scale = 1.0;
        format.opaque = NO;
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc]
            initWithSize:targetPixels format:format];
        pixelImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
            (void)context;
            [image drawInRect:(CGRect){CGPointZero, targetPixels}];
        }];
    }

    CGImageRef normalizedCG = pixelImage.CGImage;
    if (!normalizedCG) {
        return [pixelImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    UIImage *normalized = [UIImage imageWithCGImage:normalizedCG
                                               scale:designScale
                                         orientation:UIImageOrientationUp];
    return [normalized imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

static UIImage *AWEHomeCustomPNGForKey(NSString *key) {
    if (!AWEHomeCustomPNGModeEnabled()) return nil;
    NSString *directory = AWEHomeCustomIconsDirectory();
    if (!directory.length) return nil;

    NSMutableArray<NSString *> *filenames = [NSMutableArray array];
    NSString *primary = AWEHomeCustomPNGFilenameForKey(key);
    if (primary.length) [filenames addObject:primary];
    /* Selected like/favorite PNGs fall back to the normal PNG without
       changing its original pixels, canvas or aspect ratio. */
    if ([key isEqualToString:@"right.like.selected"] &&
        ![filenames containsObject:@"like.png"]) {
        [filenames addObject:@"like.png"];
    } else if ([key isEqualToString:@"right.favorite.selected"] &&
               ![filenames containsObject:@"favorite.png"]) {
        [filenames addObject:@"favorite.png"];
    }

    for (NSString *filename in filenames) {
        NSString *path = [directory stringByAppendingPathComponent:filename];
        UIImage *image = [AWEHomeCustomPNGCache() objectForKey:path];
        if (!image) {
            image = [UIImage imageWithContentsOfFile:path];
            if (!image) continue;
            if (@available(iOS 15.0, *)) {
                UIImage *prepared = [image imageByPreparingForDisplay];
                if (prepared) image = prepared;
            }
            /* UIKit UIButtonConfiguration interprets UIImage.size in points.
               Force imported artwork back to the established @3x contract so
               30 px -> 10 pt and 100 px -> 33.33 pt, matching 1.0.39. */
            image = AWENormalizeImportedPNGForDisplay(image);
            NSUInteger width = (NSUInteger)MAX(1.0, image.size.width * image.scale);
            NSUInteger height = (NSUInteger)MAX(1.0, image.size.height * image.scale);
            [AWEHomeCustomPNGCache() setObject:image forKey:path cost:width * height * 4];
        }
        return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    return nil;
}

static UIImage *AWEConfiguredRoleImage(NSString *key,
                                        NSArray<NSString *> *fallbackNames,
                                        CGFloat pointSize,
                                        UIImageSymbolWeight weight,
                                        BOOL *preserveOriginalOut) {
    UIImage *png = AWEHomeCustomPNGForKey(key);
    if (png) {
        /* PNG is a separate original-colour path. It never enters the
           SF-Symbol tint pipeline and is never redrawn into a square canvas. */
        if (preserveOriginalOut) *preserveOriginalOut = YES;
        return [png imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }

    NSString *fallback = fallbackNames.firstObject;
    NSString *preferred = AWEConfiguredSymbolName(key, fallback);
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    if (preferred.length) [names addObject:preferred];
    for (NSString *name in fallbackNames) {
        if (name.length && ![names containsObject:name]) [names addObject:name];
    }

    UIImageSymbolConfiguration *configuration =
        [UIImageSymbolConfiguration configurationWithPointSize:pointSize
                                                         weight:weight
                                                          scale:UIImageSymbolScaleMedium];
    for (NSString *name in names) {
        UIImage *image = [UIImage systemImageNamed:name];
        if (!image) continue;
        image = [image imageWithConfiguration:configuration];
        if (preserveOriginalOut) *preserveOriginalOut = NO;
        /* All SF Symbols remain templates. Automatic/fixed/custom colour is
           selected later by the host foreground, never baked into the image. */
        return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    if (preserveOriginalOut) *preserveOriginalOut = NO;
    return nil;
}

void *AWEAlbumMorphCreateConfiguredImage(const char *keyCString,
                                          const char *fallbackCString,
                                          double pointSize) {
    NSString *key = keyCString ? [NSString stringWithUTF8String:keyCString] : @"";
    NSString *fallback = fallbackCString
        ? [NSString stringWithUTF8String:fallbackCString] : @"questionmark";
    BOOL preserveOriginal = NO;
    UIImage *image = AWEConfiguredRoleImage(
        key, fallback.length ? @[fallback] : @[@"questionmark"],
        (CGFloat)pointSize, UIImageSymbolWeightMedium, &preserveOriginal);
    if (!image) image = [UIImage systemImageNamed:fallback ?: @"questionmark"];
    return image ? (__bridge_retained void *)image : NULL;
}

static UIImage *AWESymbol(NSString *name, CGFloat pointSize);

static UIImage *AWEBottomConfiguredSymbolImage(NSString *key,
                                                   NSString *fallback,
                                                   CGFloat pointSize,
                                                   __unused UIColor *automaticColor) {
    NSString *name = AWEConfiguredSymbolName(key, fallback);
    UIImage *image = AWESymbol(name, pointSize) ?: AWESymbol(fallback, pointSize);
    if (!image) return nil;
    /* Bottom-bar symbols only choose artwork. UIKit owns the unselected
       foreground and the bar's global accent owns the selected foreground. */
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

static NSString *AWEBottomTitleForIndex(NSInteger index) {
    switch (index) {
        case 0: return @"首页";
        case 1: return AWESecondTabIsShop() ? @"商城" : @"朋友";
        case 2: return @"发布";
        case 3: return @"消息";
        case 4: return @"我";
        default: return @"";
    }
}

static void AWEApplyBottomTitleVisibility(UITabBar *nativeBar) {
    if (!nativeBar || nativeBar.items.count < 5) return;
    BOOL hidden = AWEHideBottomTitlesEnabled();
    for (NSInteger index = 0; index < 5; index++) {
        UITabBarItem *item = nativeBar.items[(NSUInteger)index];
        NSString *visibleTitle = AWEBottomTitleForIndex(index);
        item.accessibilityLabel = visibleTitle;
        if (hidden) {
            item.title = nil;
            /* UIKit still reserves part of the classic icon/title geometry.
               A symmetric 5.75 pt inset recentres the symbol inside the
               62 pt floating platter without moving the hit target. */
            item.imageInsets = UIEdgeInsetsMake(5.75, 0.0, -5.75, 0.0);
            item.titlePositionAdjustment = UIOffsetZero;
        } else {
            item.title = visibleTitle;
            item.imageInsets = UIEdgeInsetsMake(0.5, 0.0, -0.5, 0.0);
            item.titlePositionAdjustment = UIOffsetMake(0.0, -0.25);
        }
    }
    [nativeBar setNeedsLayout];
}

static void AWERefreshNativeBarSymbolItems(UITabBar *nativeBar) {
    if (!nativeBar || nativeBar.items.count < 5) return;
    BOOL shop = AWESecondTabIsShop();
    NSArray<NSString *> *defaults = @[
        @"sparkles", shop ? @"storefront" : @"hands.and.sparkles",
        @"pencil.and.outline", @"ellipsis.message", @"touchid"
    ];
    NSMutableArray<NSString *> *signatureParts = [NSMutableArray arrayWithObjects:
        shop ? @"SHOP" : @"FRIENDS",
        AWEHideBottomTitlesEnabled() ? @"TITLES_HIDDEN" : @"TITLES_VISIBLE", nil];
    for (NSInteger index = 0; index < 5; index++) {
        NSString *key = AWEBottomSymbolKeyForTag(index, NO);
        NSString *name = AWEConfiguredSymbolName(key, defaults[(NSUInteger)index]);
        [signatureParts addObject:name ?: @""];
    }
    NSString *signature = [signatureParts componentsJoinedByString:@"|"];
    NSString *old = objc_getAssociatedObject(nativeBar, &kAWETabBarSymbolSignatureKey);
    if ([old isEqualToString:signature]) return;
    objc_setAssociatedObject(nativeBar, &kAWETabBarSymbolSignatureKey,
                             signature, OBJC_ASSOCIATION_COPY_NONATOMIC);
    AWEApplyBottomTitleVisibility(nativeBar);
    for (NSInteger index = 0; index < 5; index++) {
        UITabBarItem *item = nativeBar.items[(NSUInteger)index];
        CGFloat size = index == 2 ? 20.475 : 19.5;
        NSString *key = AWEBottomSymbolKeyForTag(index, NO);
        UIImage *image = AWEBottomConfiguredSymbolImage(
            key, defaults[(NSUInteger)index], size, UIColor.whiteColor);
        item.image = image;
        item.selectedImage = image;
    }
    [nativeBar setNeedsLayout];
}

static UIImage *AWESymbol(NSString *name, CGFloat pointSize) {
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *configuration =
            [UIImageSymbolConfiguration configurationWithPointSize:pointSize
                                                             weight:UIImageSymbolWeightSemibold
                                                              scale:UIImageSymbolScaleMedium];
        UIImage *image = [[UIImage systemImageNamed:name]
                          imageWithConfiguration:configuration];
        return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    return nil;
}

static UITabBarItem *AWEMakeItem(NSString *title,
                                 NSString *normalSymbol,
                                 NSString *selectedSymbol,
                                 NSInteger tag) {
    CGFloat pointSize = (tag == 2) ? 20.475 : 19.5;
    NSString *iconKey = AWEBottomSymbolKeyForTag(tag, NO);
    BOOL hideTitle = AWEHideBottomTitlesEnabled();
    UIImage *sharedImage = AWEBottomConfiguredSymbolImage(
        iconKey, normalSymbol ?: selectedSymbol, pointSize, UIColor.whiteColor);
    UITabBarItem *item = [[UITabBarItem alloc]
        initWithTitle:(hideTitle ? nil : title)
                image:sharedImage
        selectedImage:sharedImage];
    item.tag = tag;
    item.accessibilityLabel = title;
    item.imageInsets = hideTitle
        ? UIEdgeInsetsMake(5.75, 0.0, -5.75, 0.0)
        : UIEdgeInsetsMake(0.5, 0.0, -0.5, 0.0);
    item.titlePositionAdjustment = hideTitle
        ? UIOffsetZero
        : UIOffsetMake(0.0, -0.25);
    return item;
}

static void AWEConfigureNativeBarAppearance(UITabBar *nativeBar,
                                             UIColor *accentColor) {
    if (!nativeBar) return;
    if (!accentColor) accentColor = AWEStoredAccentColor();

    /*
     iOS 27 changed the backdrop sampling used by Liquid Glass.  Supplying an
     explicit normal icon/title colour prevents the new native renderer from
     choosing black or white against the sampled content.  In automatic mode
     on iOS 27, leave the normal foreground unset and let UIKit own it.
    */
    BOOL nativeAdaptiveForeground =
        AWEIsIOS27OrLater() && !AWEHomeForceDarkGlassEnabled();

    UIColor *normalColor = nil;
    if (!nativeAdaptiveForeground) {
        if (@available(iOS 13.0, *)) {
            normalColor = [UIColor.labelColor colorWithAlphaComponent:0.78];
        } else {
            normalColor = [UIColor colorWithWhite:0.0 alpha:0.78];
        }
    }

    nativeBar.translucent = YES;
    nativeBar.opaque = NO;
    nativeBar.clipsToBounds = NO;
    nativeBar.backgroundColor = UIColor.clearColor;
    nativeBar.layer.backgroundColor = UIColor.clearColor.CGColor;
    nativeBar.tintColor = accentColor;
    nativeBar.unselectedItemTintColor = normalColor;

    /*
     On iOS 26 and later, keep the standalone five-item UITabBar on UIKit's
     default appearance path. The previous transparent-background appearance
     froze the private floating platter on one regular/tinted material and
     prevented the system Clear/Tinted preference from rebuilding it. We only
     customize item foregrounds; UIKit owns the bar material itself.
    */
    BOOL systemOwnsLiquidGlass = AWEOperatingSystemMajorVersion() >= 26;
    if (systemOwnsLiquidGlass) {
        nativeBar.barTintColor = nil;
        nativeBar.backgroundImage = nil;
        nativeBar.shadowImage = nil;
    } else {
        nativeBar.barTintColor = UIColor.clearColor;
        nativeBar.backgroundImage = [UIImage new];
        nativeBar.shadowImage = [UIImage new];
    }

    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
        if (systemOwnsLiquidGlass) {
            [appearance configureWithDefaultBackground];
        } else {
            [appearance configureWithTransparentBackground];
            appearance.backgroundColor = UIColor.clearColor;
            appearance.shadowColor = UIColor.clearColor;
        }

        NSMutableDictionary *normalTitle = [@{
            NSFontAttributeName: [UIFont systemFontOfSize:10.5
                                                   weight:UIFontWeightMedium]
        } mutableCopy];
        if (normalColor) {
            normalTitle[NSForegroundColorAttributeName] = normalColor;
        }
        NSDictionary *selectedTitle = @{
            NSForegroundColorAttributeName: accentColor,
            NSFontAttributeName: [UIFont systemFontOfSize:10.5
                                                   weight:UIFontWeightSemibold]
        };

        NSArray *appearances = @[
            appearance.stackedLayoutAppearance,
            appearance.inlineLayoutAppearance,
            appearance.compactInlineLayoutAppearance
        ];

        for (UITabBarItemAppearance *itemAppearance in appearances) {
            itemAppearance.normal.iconColor = normalColor;
            itemAppearance.normal.titleTextAttributes = normalTitle;
            itemAppearance.selected.iconColor = accentColor;
            itemAppearance.selected.titleTextAttributes = selectedTitle;
        }

        nativeBar.standardAppearance = appearance;
        if (@available(iOS 15.0, *)) {
            nativeBar.scrollEdgeAppearance = appearance;
        }
    }

    AWEApplyBottomTitleVisibility(nativeBar);
    [nativeBar setNeedsLayout];
}

static BOOL AWEViewNearlyFillsNativeBar(UIView *view, UITabBar *bar) {
    if (!view || !bar || !view.superview) return NO;

    CGRect frame = [view.superview convertRect:view.frame toView:bar];
    CGFloat barWidth = MAX(CGRectGetWidth(bar.bounds), 1.0);
    CGFloat barHeight = MAX(CGRectGetHeight(bar.bounds), 1.0);

    return CGRectGetWidth(frame) >= barWidth * 0.92 &&
           CGRectGetHeight(frame) >= barHeight * 0.78 &&
           fabs(CGRectGetMidX(frame) - CGRectGetMidX(bar.bounds)) <= 8.0;
}

static BOOL AWENativeBarSubviewIsContentOrPlatter(UIView *view) {
    if (!view) return NO;
    NSString *name = NSStringFromClass(view.class);
    return [name rangeOfString:@"Platter"
                       options:NSCaseInsensitiveSearch].location != NSNotFound ||
           [name rangeOfString:@"Content"
                       options:NSCaseInsensitiveSearch].location != NSNotFound ||
           [name rangeOfString:@"Selected"
                       options:NSCaseInsensitiveSearch].location != NSNotFound ||
           [name rangeOfString:@"Button"
                       options:NSCaseInsensitiveSearch].location != NSNotFound;
}

static void AWEHideLegacyNativeBarBackgroundView(UIView *view) {
    if (!view) return;
    view.opaque = NO;
    view.backgroundColor = UIColor.clearColor;
    view.layer.backgroundColor = UIColor.clearColor.CGColor;
    view.userInteractionEnabled = NO;
    view.alpha = 0.0;
    view.hidden = YES;
}

static void AWEClearDirectNativeBarBackground(UITabBar *nativeBar) {
    if (!nativeBar || !AWEIsOurNativeBar(nativeBar)) return;

    nativeBar.opaque = NO;
    nativeBar.backgroundColor = UIColor.clearColor;
    nativeBar.layer.backgroundColor = UIColor.clearColor.CGColor;

    /*
     Keep the iOS 26 floating platter and all item content. Clear only a
     full-size legacy background/effect layer, matching the selective strategy
     used by ForceLiquidGlassUnified instead of recursively erasing the bar.
    */
    for (UIView *subview in nativeBar.subviews) {
        if (AWENativeBarSubviewIsContentOrPlatter(subview)) continue;

        NSString *name = NSStringFromClass(subview.class);
        BOOL backgroundLike =
            [subview isKindOfClass:[UIVisualEffectView class]] ||
            [name rangeOfString:@"Background"
                         options:NSCaseInsensitiveSearch].location != NSNotFound ||
            [name rangeOfString:@"VisualEffect"
                         options:NSCaseInsensitiveSearch].location != NSNotFound;

        if (backgroundLike &&
            AWEViewNearlyFillsNativeBar(subview, nativeBar)) {
            AWEHideLegacyNativeBarBackgroundView(subview);
            continue;
        }

        for (UIView *innerView in subview.subviews) {
            if (AWENativeBarSubviewIsContentOrPlatter(innerView)) continue;

            NSString *innerName = NSStringFromClass(innerView.class);
            BOOL innerBackgroundLike =
                [innerView isKindOfClass:[UIVisualEffectView class]] ||
                [innerName rangeOfString:@"Background"
                                 options:NSCaseInsensitiveSearch].location != NSNotFound ||
                [innerName rangeOfString:@"VisualEffect"
                                 options:NSCaseInsensitiveSearch].location != NSNotFound;

            if (innerBackgroundLike &&
                AWEViewNearlyFillsNativeBar(innerView, nativeBar)) {
                AWEHideLegacyNativeBarBackgroundView(innerView);
            }
        }
    }
}

static void AWEPrimeNativeBarRenderTree(UITabBar *nativeBar) {
    if (!nativeBar) return;

    AWEApplyNativeDarkBootstrap(nativeBar);

    [UIView performWithoutAnimation:^{
        [nativeBar setNeedsLayout];
        [nativeBar layoutIfNeeded];

        NSMutableArray<UIView *> *queue =
            [NSMutableArray arrayWithObject:nativeBar];
        NSUInteger index = 0;
        while (index < queue.count && index < 96) {
            UIView *view = queue[index++];
            [view setNeedsLayout];
            [view layoutIfNeeded];
            [view setNeedsDisplay];
            for (UIView *subview in view.subviews) {
                [queue addObject:subview];
            }
        }

        AWEClearDirectNativeBarBackground(nativeBar);
        AWEApplyNativeDarkBootstrap(nativeBar);
    }];
}

static BOOL AWEIsNativeGlassMaterialView(UIView *view) {
    if (!view) return NO;
    NSString *name = NSStringFromClass(view.class);
    NSArray<NSString *> *tokens = @[
        @"UITabBarPlatterView",
        @"UILiquidLensView",
        @"ClearGlassView",
        @"SelectedContentView",
        @"SDFView",
        @"SDFElementView",
        @"DestOutView"
    ];
    for (NSString *token in tokens) {
        if ([name rangeOfString:token
                       options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

static void AWEApplyHomeOnlyGlassStyleToNativeBar(UITabBar *nativeBar) {
    if (!nativeBar || !AWEIsOurNativeBar(nativeBar) ||
        gAWENativeDarkBootstrapActive) {
        return;
    }

    UIUserInterfaceStyle desired = UIUserInterfaceStyleUnspecified;

    BOOL changed = nativeBar.overrideUserInterfaceStyle != desired;
    [UIView performWithoutAnimation:^{
        nativeBar.overrideUserInterfaceStyle = desired;

        NSMutableArray<UIView *> *queue =
            [NSMutableArray arrayWithObject:nativeBar];
        NSUInteger index = 0;
        while (index < queue.count && index < 160) {
            UIView *view = queue[index++];
            if (AWEIsNativeGlassMaterialView(view)) {
                view.overrideUserInterfaceStyle = desired;
            }
            for (UIView *subview in view.subviews) {
                [queue addObject:subview];
            }
        }

        if (changed) {
            AWEConfigureNativeBarAppearance(nativeBar, AWEStoredAccentColor());
            [nativeBar setNeedsLayout];
            [nativeBar layoutIfNeeded];
            [nativeBar setNeedsDisplay];
        }
    }];
}

static void AWEApplyHomeOnlyGlassStyleToExistingSurfaces(void) {
    if (gAWEAlbumMorphController) {
        NSInteger index = [gAWEAlbumMorphController currentOriginalIndex];
        if (index == NSNotFound) index = 0;
        AWEApplyAlbumMorphResolvedAppearance(AWEActiveMainWindow(), index);
    }

    UITabBar *nativeBar = nil;
    if (gAWELastTabBar) {
        nativeBar = objc_getAssociatedObject(
            (UIView *)gAWELastTabBar, &kAWENativeBarKey);
    }
    if (nativeBar) AWEApplyHomeOnlyGlassStyleToNativeBar(nativeBar);
    AWERefreshAllConfiguredIcons();
}

static void AWEApplyNativeDarkBootstrap(UITabBar *nativeBar) {
    if (!nativeBar || !gAWENativeDarkBootstrapActive) return;

    [UIView performWithoutAnimation:^{
        /* The object is still the untouched UIKit UITabBar. The override only
           affects its first material resolution; item colors remain governed
           by UITabBarAppearance. */
        nativeBar.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;

        NSMutableArray<UIView *> *queue =
            [NSMutableArray arrayWithObject:nativeBar];
        NSUInteger index = 0;
        while (index < queue.count && index < 128) {
            UIView *view = queue[index++];
            if (AWEIsNativeGlassMaterialView(view)) {
                view.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
            }
            for (UIView *subview in view.subviews) {
                [queue addObject:subview];
            }
        }
    }];
}

static void AWEReleaseNativeDarkBootstrap(UITabBar *nativeBar) {
    if (!nativeBar || !gAWENativeDarkBootstrapActive) return;

    CFTimeInterval elapsed =
        gAWENativeDarkBootstrapBeganAt > 0.0
            ? CACurrentMediaTime() - gAWENativeDarkBootstrapBeganAt
            : 0.0;

    /* Critical ordering fix:
       layoutSubviews calls AWEApplyNativeDarkBootstrap(). In 0.0.21b/21c the
       active flag was cleared only after layoutIfNeeded, so the layout hook
       immediately wrote UIUserInterfaceStyleDark back onto the real UITabBar.
       The glass stopped flashing, but the native item labels/icons stayed in
       dark-mode foreground forever. Disable the bootstrap before any release
       layout work so it cannot re-apply itself. */
    gAWENativeDarkBootstrapActive = NO;

    UIUserInterfaceStyle finalStyle = UIUserInterfaceStyleUnspecified;

    [UIView performWithoutAnimation:^{
        nativeBar.overrideUserInterfaceStyle = finalStyle;

        NSMutableArray<UIView *> *queue =
            [NSMutableArray arrayWithObject:nativeBar];
        NSUInteger index = 0;
        while (index < queue.count && index < 128) {
            UIView *view = queue[index++];
            if (AWEIsNativeGlassMaterialView(view)) {
                view.overrideUserInterfaceStyle = finalStyle;
            }
            for (UIView *subview in view.subviews) {
                [queue addObject:subview];
            }
        }

        AWEConfigureNativeBarAppearance(nativeBar, AWEStoredAccentColor());
        [nativeBar setNeedsLayout];
        [nativeBar layoutIfNeeded];
        [nativeBar setNeedsDisplay];
    }];

    AWETransitionLog(@"NATIVE_DARK_BOOTSTRAP release elapsed=%.3f override=%ld trait=%ld screen=%ld",
                     elapsed,
                     (long)nativeBar.overrideUserInterfaceStyle,
                     (long)nativeBar.traitCollection.userInterfaceStyle,
                     (long)UIScreen.mainScreen.traitCollection.userInterfaceStyle);

    /* UIKit 26 may materialize the private tab buttons one run-loop later.
       Re-submit the same native appearance after those views exist. This does
       not alter the glass material or selected capsule. */
    __weak UITabBar *weakBar = nativeBar;
    dispatch_async(dispatch_get_main_queue(), ^{
        UITabBar *strongBar = weakBar;
        if (!strongBar) return;
        [UIView performWithoutAnimation:^{
            AWEConfigureNativeBarAppearance(strongBar,
                                            AWEStoredAccentColor());
            AWEApplyHomeOnlyGlassStyleToNativeBar(strongBar);
            [strongBar setNeedsLayout];
            [strongBar layoutIfNeeded];
        }];
    });
}

static void AWEScheduleNativeDarkBootstrapRelease(UITabBar *nativeBar) {
    if (!nativeBar || !gAWENativeDarkBootstrapActive ||
        gAWENativeDarkBootstrapReleaseScheduled) {
        return;
    }

    gAWENativeDarkBootstrapReleaseScheduled = YES;
    gAWENativeDarkBootstrapBeganAt = CACurrentMediaTime();
    __weak UITabBar *weakNativeBar = nativeBar;

    /* The probe showed the native material settled roughly 0.42 s after its
       first visible frame. 1.25 s leaves margin for a cold device while
       keeping the override launch-only. */
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(1.25 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        UITabBar *strongNativeBar = weakNativeBar;
        if (strongNativeBar) {
            AWEReleaseNativeDarkBootstrap(strongNativeBar);
        } else {
            gAWENativeDarkBootstrapActive = NO;
        }
    });
}

static UITabBar *AWEAllocateConfiguredNativeBar(void) {
    UITabBar *nativeBar = [[UITabBar alloc] initWithFrame:CGRectZero];
    nativeBar.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
    nativeBar.autoresizingMask = UIViewAutoresizingNone;
    nativeBar.translucent = YES;
    nativeBar.opaque = NO;
    nativeBar.clipsToBounds = NO;
    nativeBar.hidden = NO;
    nativeBar.alpha = 1.0;
    nativeBar.itemPositioning = UITabBarItemPositioningFill;
    nativeBar.userInteractionEnabled = YES;
    nativeBar.accessibilityIdentifier = @"AwemeLiquidBar.NativeUITabBar";

    AWEConfigureNativeBarAppearance(nativeBar, AWEStoredAccentColor());

    nativeBar.items = @[
        AWEMakeItem(@"首页", @"sparkles", @"sparkles", 0),
        AWEMakeItem(AWESecondTabIsShop() ? @"商城" : @"朋友",
                    AWESecondTabIsShop() ? @"storefront" : @"hands.and.sparkles",
                    AWESecondTabIsShop() ? @"storefront.fill" : @"hands.and.sparkles.fill", 1),
        AWEMakeItem(@"发布", @"pencil.and.outline", @"pencil.and.outline", 2),
        AWEMakeItem(@"消息", @"ellipsis.message",
                    @"ellipsis.message.fill", 3),
        AWEMakeItem(@"我", @"touchid", @"touchid", 4)
    ];
    nativeBar.selectedItem = nativeBar.items.firstObject;
    AWEApplyNativeDarkBootstrap(nativeBar);
    return nativeBar;
}

static void AWEWarmActualNativeBarInWindow(UIWindow *window) {
    if (!AWEPluginFeaturesEnabled() || !window) return;

    UITabBar *liveBar = nil;
    if (gAWELastTabBar) {
        liveBar = objc_getAssociatedObject((UIView *)gAWELastTabBar,
                                           &kAWENativeBarKey);
    }

    if (liveBar) {
        AWEPrimeNativeBarRenderTree(liveBar);
        return;
    }

    if (!gAWEStagedNativeBar) {
        gAWEStagedNativeBar = AWEAllocateConfiguredNativeBar();
    }

    CGFloat width = MAX(CGRectGetWidth(window.bounds), 320.0);
    CGFloat height = MAX(62.0, 49.0 + window.safeAreaInsets.bottom);
    CGRect warmFrame =
        CGRectMake(0.0, CGRectGetHeight(window.bounds) - height,
                   width, height);

    if (!gAWEStagedNativeBarHost) {
        gAWEStagedNativeBarHost =
            [[UIView alloc] initWithFrame:warmFrame];
        gAWEStagedNativeBarHost.userInteractionEnabled = NO;
        gAWEStagedNativeBarHost.accessibilityElementsHidden = YES;
        gAWEStagedNativeBarHost.opaque = NO;
        gAWEStagedNativeBarHost.backgroundColor = UIColor.clearColor;
        gAWEStagedNativeBarHost.clipsToBounds = NO;
        /*
         Keep it on-screen at a nearly invisible compositor opacity. This
         forces the exact full-size UITabBar/platter render tree to exist before
         the home controller supplies Douyin's five forwarding buttons.
        */
        gAWEStagedNativeBarHost.alpha = 0.012;
        gAWEStagedNativeBarHost.layer.zPosition = CGFLOAT_MAX - 4096.0;
    }

    [UIView performWithoutAnimation:^{
        gAWEStagedNativeBarHost.frame = warmFrame;
        gAWEStagedNativeBarHost.hidden = NO;
        gAWEStagedNativeBarHost.alpha = 0.012;

        if (gAWEStagedNativeBarHost.superview != window) {
            [gAWEStagedNativeBarHost removeFromSuperview];
            [window addSubview:gAWEStagedNativeBarHost];
        }

        if (gAWEStagedNativeBar.superview != gAWEStagedNativeBarHost) {
            [gAWEStagedNativeBar removeFromSuperview];
            [gAWEStagedNativeBarHost addSubview:gAWEStagedNativeBar];
        }

        gAWEStagedNativeBar.frame = gAWEStagedNativeBarHost.bounds;
        gAWEStagedNativeBar.hidden = NO;
        gAWEStagedNativeBar.alpha = 1.0;
        gAWEStagedNativeBar.userInteractionEnabled = NO;
        AWEPrimeNativeBarRenderTree(gAWEStagedNativeBar);
    }];
}

static void AWEScheduleActualNativeBarWarmup(void) {
    if (!AWEPluginFeaturesEnabled()) return;
    NSUInteger generation = ++gAWEActualBarWarmupGeneration;
    NSArray<NSNumber *> *delays = @[@0.0, @0.05, @0.16, @0.45, @1.0];

    for (NSNumber *delayNumber in delays) {
        NSTimeInterval delay = delayNumber.doubleValue;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(delay * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            if (generation != gAWEActualBarWarmupGeneration) return;
            UIWindow *window = AWEActiveMainWindow();
            if (window) {
                AWEWarmActualNativeBarInWindow(window);
            }
        });
    }
}

static UITabBar *AWECreateNativeBar(UIView *tabBar) {
    UITabBar *nativeBar = gAWEStagedNativeBar;

    if (nativeBar) {
        [nativeBar removeFromSuperview];
        [gAWEStagedNativeBarHost removeFromSuperview];
        gAWEStagedNativeBarHost = nil;
        gAWEStagedNativeBar = nil;
    } else {
        nativeBar = AWEAllocateConfiguredNativeBar();
    }

    nativeBar.userInteractionEnabled = YES;
    objc_setAssociatedObject(tabBar, &kAWENativeBarKey, nativeBar,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return nativeBar;
}

static void AWEUpdateColdStartBackplateFrame(UIView *tabBar,
                                              UIView *host,
                                              CGRect frame) {
    UIView *backplate =
        objc_getAssociatedObject(tabBar, &kAWEColdStartBackplateKey);
    if (!backplate || !host || CGRectIsNull(frame) || CGRectIsEmpty(frame)) {
        return;
    }

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    backplate.frame = frame;
    [CATransaction commit];
}

static void AWEInstallColdStartBackplateIfNeeded(UIView *tabBar,
                                                  UIView *host,
                                                  UITabBar *nativeBar,
                                                  CGRect frame) {
    if (!tabBar || !host || !nativeBar ||
        gAWEColdStartBackplateRetired ||
        gAWEColdStartBackplateEverInstalled ||
        CGRectIsNull(frame) || CGRectIsEmpty(frame)) {
        return;
    }

    UIView *backplate = [[UIView alloc] initWithFrame:frame];
    backplate.userInteractionEnabled = NO;
    backplate.opaque = YES;
    backplate.backgroundColor = UIColor.blackColor;
    backplate.layer.backgroundColor = UIColor.blackColor.CGColor;
    backplate.accessibilityElementsHidden = YES;

    if (nativeBar.superview == host) {
        [host insertSubview:backplate belowSubview:nativeBar];
    } else {
        [host addSubview:backplate];
    }

    objc_setAssociatedObject(tabBar, &kAWEColdStartBackplateKey,
                             backplate,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    gAWEColdStartBackplateEverInstalled = YES;

    /*
     The backplate is home-launch-only. Keep it for several real-bar layout
     passes, then remove it without animation after the floating platter has
     been primed. It never participates in later page transitions.
    */
    __weak UIView *weakTabBar = tabBar;
    NSArray<NSNumber *> *delays = @[@0.06, @0.16, @0.34];
    for (NSNumber *delayNumber in delays) {
        NSTimeInterval delay = delayNumber.doubleValue;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(delay * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            UIView *strongTabBar = weakTabBar;
            if (!strongTabBar) return;

            UITabBar *strongNative =
                objc_getAssociatedObject(strongTabBar, &kAWENativeBarKey);
            if (strongNative) {
                AWEPrimeNativeBarRenderTree(strongNative);
            }

            if (delayNumber == delays.lastObject) {
                UIView *strongBackplate =
                    objc_getAssociatedObject(strongTabBar,
                                             &kAWEColdStartBackplateKey);
                [UIView performWithoutAnimation:^{
                    [strongBackplate removeFromSuperview];
                }];
                objc_setAssociatedObject(strongTabBar,
                                         &kAWEColdStartBackplateKey,
                                         nil,
                                         OBJC_ASSOCIATION_ASSIGN);
                gAWEColdStartBackplateRetired = YES;
            }
        });
    }
}

static void AWEHideOriginalTabBarContents(UIView *tabBar) {
    /*
     The native overlay lives in tabBar.superview, not inside tabBar. Therefore
     every direct child here belongs to Douyin. Keep objects alive and enabled
     for programmatic forwarding, but remove only their visual output.

     1.0.56c13 also preserves each child's pre-LiquidBar state so OFF can truly
     hand the native host back to Douyin/another tweak instead of leaving the
     original bar visually gutted after our overlay is removed.
    */
    for (UIView *subview in tabBar.subviews) {
        if (!objc_getAssociatedObject(subview, &kAWEOriginalChildHiddenStateKey)) {
            objc_setAssociatedObject(subview,
                                     &kAWEOriginalChildHiddenStateKey,
                                     @(subview.hidden),
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        if (!objc_getAssociatedObject(subview, &kAWEOriginalChildAlphaStateKey)) {
            objc_setAssociatedObject(subview,
                                     &kAWEOriginalChildAlphaStateKey,
                                     @(subview.alpha),
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        subview.hidden = YES;
        subview.alpha = 0.0;
        /* Do not disable interaction state; some internal handlers inspect it. */
    }

    tabBar.opaque = NO;
    tabBar.backgroundColor = UIColor.clearColor;
    tabBar.layer.backgroundColor = UIColor.clearColor.CGColor;
    objc_setAssociatedObject(tabBar, &kAWEOriginalHiddenKey, @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void AWERestoreOriginalTabBarContents(UIView *tabBar) {
    if (!tabBar) return;

    for (UIView *subview in tabBar.subviews) {
        NSNumber *hidden = objc_getAssociatedObject(
            subview, &kAWEOriginalChildHiddenStateKey);
        NSNumber *alpha = objc_getAssociatedObject(
            subview, &kAWEOriginalChildAlphaStateKey);
        if (hidden) subview.hidden = hidden.boolValue;
        if (alpha) subview.alpha = alpha.doubleValue;
        objc_setAssociatedObject(subview,
                                 &kAWEOriginalChildHiddenStateKey,
                                 nil,
                                 OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(subview,
                                 &kAWEOriginalChildAlphaStateKey,
                                 nil,
                                 OBJC_ASSOCIATION_ASSIGN);
    }

    UITabBar *legacyNativeBar = objc_getAssociatedObject(
        tabBar, &kAWENativeBarKey);
    if (legacyNativeBar) {
        legacyNativeBar.hidden = YES;
        legacyNativeBar.userInteractionEnabled = NO;
        legacyNativeBar.layer.opacity = 0.0f;
        [legacyNativeBar removeFromSuperview];
    }

    objc_setAssociatedObject(tabBar,
                             &kAWEOriginalHiddenKey,
                             nil,
                             OBJC_ASSOCIATION_ASSIGN);
}

static void AWESetNativeSelectedIndex(UIView *tabBar, NSInteger index) {
    UITabBar *nativeBar = objc_getAssociatedObject(tabBar, &kAWENativeBarKey);
    if (!nativeBar || index < 0 || index >= (NSInteger)nativeBar.items.count) return;

    UITabBarItem *item = nativeBar.items[(NSUInteger)index];
    if (nativeBar.selectedItem != item) {
        nativeBar.selectedItem = item;
    }
    AWEApplyHomeOnlyGlassStyleToNativeBar(nativeBar);
}

static BOOL AWEFrameEqualEnough(CGRect a, CGRect b) {
    return fabs(a.origin.x - b.origin.x) < 0.25 &&
           fabs(a.origin.y - b.origin.y) < 0.25 &&
           fabs(a.size.width - b.size.width) < 0.25 &&
           fabs(a.size.height - b.size.height) < 0.25;
}

static BOOL AWEControllerTreeContainsSearchRoute(UIViewController *controller,
                                                  NSUInteger depth) {
    if (!controller || depth > 12) return NO;

    NSString *className = NSStringFromClass(controller.class);
    if ([className hasPrefix:@"AWESearch"]) return YES;

    UIViewController *presented = controller.presentedViewController;
    if (presented && !presented.isBeingDismissed &&
        AWEControllerTreeContainsSearchRoute(presented, depth + 1)) {
        return YES;
    }

    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigation =
            (UINavigationController *)controller;

        /* Search remains in the navigation stack while a search result is
           pushed, so keep the bar suppressed for the whole search route. */
        for (UIViewController *item in navigation.viewControllers) {
            NSString *itemName = NSStringFromClass(item.class);
            if ([itemName hasPrefix:@"AWESearch"]) return YES;
        }

        UIViewController *visible = navigation.visibleViewController;
        if (visible && visible != controller &&
            AWEControllerTreeContainsSearchRoute(visible, depth + 1)) {
            return YES;
        }
    }

    if ([controller isKindOfClass:[UITabBarController class]]) {
        UIViewController *selected =
            ((UITabBarController *)controller).selectedViewController;
        if (selected && selected != controller &&
            AWEControllerTreeContainsSearchRoute(selected, depth + 1)) {
            return YES;
        }
    }

    for (UIViewController *child in controller.childViewControllers) {
        if (child.viewIfLoaded.window &&
            AWEControllerTreeContainsSearchRoute(child, depth + 1)) {
            return YES;
        }
    }

    return NO;
}

static BOOL AWEShouldSuppressBarForSearch(void) {
    if (gAWESearchPageVisible) return YES;
    return AWEControllerTreeContainsSearchRoute(gAWELastController, 0);
}

static BOOL AWEControllerTreeContainsUserDetailRoute(UIViewController *controller,
                                                      NSUInteger depth) {
    if (!controller || depth > 12) return NO;

    NSString *className = NSStringFromClass(controller.class);
    if ([className hasPrefix:@"AWEUserDetailViewController"]) return YES;

    UIViewController *presented = controller.presentedViewController;
    if (presented && !presented.isBeingDismissed &&
        AWEControllerTreeContainsUserDetailRoute(presented, depth + 1)) {
        return YES;
    }

    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigation =
            (UINavigationController *)controller;

        /* A video opened from another user's profile is pushed above the
           profile controller. Inspect the complete navigation stack so the
           hidden state survives both the video and the return to the profile. */
        for (UIViewController *item in navigation.viewControllers) {
            NSString *itemName = NSStringFromClass(item.class);
            if ([itemName hasPrefix:@"AWEUserDetailViewController"]) {
                return YES;
            }
        }

        UIViewController *visible = navigation.visibleViewController;
        if (visible && visible != controller &&
            AWEControllerTreeContainsUserDetailRoute(visible, depth + 1)) {
            return YES;
        }
    }

    if ([controller isKindOfClass:[UITabBarController class]]) {
        UIViewController *selected =
            ((UITabBarController *)controller).selectedViewController;
        if (selected && selected != controller &&
            AWEControllerTreeContainsUserDetailRoute(selected, depth + 1)) {
            return YES;
        }
    }

    for (UIViewController *child in controller.childViewControllers) {
        if (child.viewIfLoaded.window &&
            AWEControllerTreeContainsUserDetailRoute(child, depth + 1)) {
            return YES;
        }
    }

    return NO;
}

static BOOL AWEClassNameLooksLikeTransientCommerceDestination(NSString *className) {
    if (className.length == 0) return NO;
    NSString *lower = className.lowercaseString;
    BOOL controllerLike =
        [lower containsString:@"controller"] ||
        [lower containsString:@"container"] ||
        [lower containsString:@"panel"] ||
        [lower containsString:@"sheet"];
    if (!controllerLike) return NO;

    /* Presented life-service/group-buy/product sheets are not home-feed chrome.
       Keep this matcher controller-scoped so normal feed-side commerce views do
       not suppress LiquidBar merely because their view names contain EC/Lynx. */
    return [lower containsString:@"groupbuy"] ||
           [lower containsString:@"group_buy"] ||
           [lower containsString:@"poi"] ||
           [lower containsString:@"ecommerce"] ||
           [lower hasPrefix:@"ecom"] ||
           [lower containsString:@".ecom"] ||
           [lower containsString:@"_ecom"] ||
           [lower containsString:@"commerce"] ||
           [lower containsString:@"life"] ||
           [lower containsString:@"goods"] ||
           [lower containsString:@"product"] ||
           [lower containsString:@"trade"] ||
           [lower containsString:@"order"] ||
           [lower containsString:@"shoppingcart"] ||
           [lower containsString:@"shopcart"] ||
           [lower containsString:@"cartpanel"] ||
           [lower containsString:@"buypanel"] ||
           [lower containsString:@"purchase"];
}

static BOOL AWEClassNameRequiresHardOverlaySuppression(NSString *className) {
    if (className.length == 0) return NO;
    NSString *lower = className.lowercaseString;
    BOOL controllerLike =
        [lower containsString:@"controller"] ||
        [lower containsString:@"container"] ||
        [lower containsString:@"panel"] ||
        [lower containsString:@"sheet"];

    BOOL forwardOrShare = controllerLike &&
        ([lower containsString:@"share"] ||
         [lower containsString:@"forward"] ||
         [lower containsString:@"transpond"] ||
         [lower containsString:@"sendpanel"]);
    BOOL systemSheet =
        [lower containsString:@"activityviewcontroller"] ||
        [lower containsString:@"activitycontentviewcontroller"] ||
        [lower containsString:@"activitygroupviewcontroller"] ||
        [lower containsString:@"documentpicker"] ||
        [lower containsString:@"documentbrowser"] ||
        [lower containsString:@"fileprovider"] ||
        [lower containsString:@"quicklook"] ||
        [lower containsString:@"qlpreview"];
    BOOL publish = controllerLike &&
        ([lower containsString:@"publish"] ||
         [lower containsString:@"record"] ||
         [lower containsString:@"shoot"] ||
         [lower containsString:@"camera"] ||
         [lower containsString:@"creation"] ||
         [lower containsString:@"composer"] ||
         [lower containsString:@"postedit"] ||
         [lower containsString:@"videoedit"]);
    return forwardOrShare || systemSheet || publish ||
           AWEClassNameLooksLikeTransientCommerceDestination(className);
}

static void AWEHardSuspendAlbumMorphOverlay(NSString *reason) {
    AWEAlbumMorphOverlayWindow *overlay =
        (AWEAlbumMorphOverlayWindow *)gAWEAlbumMorphOverlayWindow;
    if (!overlay) return;
    overlay.contentVisible = NO;
    if (overlay.searchTouchProxy) {
        overlay.searchTouchProxy.hidden = YES;
        overlay.searchTouchProxy.userInteractionEnabled = NO;
    }
    overlay.hidden = YES;
    overlay.alpha = 1.0;
    gAWEAlbumMorphVisible = NO;
    AWEHideAlbumMorphTintProbe();
    AWEAlbumMorphProbeWrite(@"HARD_OVERLAY_SUSPEND reason=%@", reason ?: @"unknown");
}

static BOOL AWEClassNameIsSensitiveDestination(NSString *className) {
    if (className.length == 0) return NO;

    NSString *lower = className.lowercaseString;
    BOOL controllerLike =
        [lower containsString:@"controller"] ||
        [lower containsString:@"container"] ||
        [lower containsString:@"panel"] ||
        [lower containsString:@"sheet"];

    /* Chat detail routes changed class names across Douyin builds.  Keep the
       matcher controller-scoped and require detail/session/input semantics so
       the root Messages tab itself is not mistaken for a conversation. */
    BOOL directConversation =
        [className isEqualToString:@"AWEIMMessageBaseViewController"] ||
        ([lower containsString:@"conversation"] && controllerLike) ||
        ([lower containsString:@"chatroom"] && controllerLike);

    /* IM photo/media viewers can be pushed above the conversation without the
       text composer remaining in the hierarchy. Keep the independent LiquidBar
       out of those viewers as well. Limit generic image/preview matching to the
       real Messages main tab so ordinary feed/profile media is untouched. */
    BOOL explicitIMMediaDestination = controllerLike &&
        ([lower hasPrefix:@"aweim"] || [lower containsString:@"immessage"] ||
         [lower containsString:@"imchat"]) &&
        ([lower containsString:@"image"] || [lower containsString:@"photo"] ||
         [lower containsString:@"media"] || [lower containsString:@"preview"] ||
         [lower containsString:@"picture"]);
    BOOL messagesTabMediaDestination = controllerLike &&
        AWECurrentOriginalMainTabIndex() == 3 &&
        ([lower containsString:@"image"] || [lower containsString:@"photo"] ||
         [lower containsString:@"preview"] || [lower containsString:@"picture"]);
    BOOL imMediaDestination = explicitIMMediaDestination || messagesTabMediaDestination;

    BOOL commentDestination =
        [className isEqualToString:@"AWECommentContainerViewController"] ||
        [className isEqualToString:@"AWECommentPanelViewController"] ||
        [className isEqualToString:@"AWECommentListViewController"] ||
        [className isEqualToString:@"AWECommentViewController"] ||
        ([lower containsString:@"comment"] && controllerLike);

    /* Forward/share panels are bottom sheets and must own the lower screen.
       Restrict matching to controller/container/panel/sheet classes so normal
       share buttons and feed action views are not suppressed. */
    BOOL forwardDestination = controllerLike &&
        ([lower containsString:@"share"] ||
         [lower containsString:@"forward"] ||
         [lower containsString:@"transpond"] ||
         [lower containsString:@"sendpanel"]);

    /* UIKit's system share sheet and Save-to-Files flow are hosted by
       activity/document controllers rather than Douyin share controllers.
       Because AlbumMorph uses a window above the app window, these system
       controllers must suppress it explicitly or the bar remains visible on
       top of the sheet. */
    BOOL systemActivityDestination =
        [className isEqualToString:@"UIActivityViewController"] ||
        [lower containsString:@"activityviewcontroller"] ||
        [lower containsString:@"activitycontentviewcontroller"] ||
        [lower containsString:@"activitygroupviewcontroller"];

    BOOL systemDocumentDestination = controllerLike &&
        ([lower containsString:@"documentpicker"] ||
         [lower containsString:@"documentbrowser"] ||
         [lower containsString:@"fileprovider"] ||
         [lower containsString:@"remotedocument"] ||
         [lower containsString:@"quicklook"] ||
         [lower containsString:@"qlpreview"]);

    BOOL publishDestination = controllerLike &&
        ([lower containsString:@"publish"] ||
         [lower containsString:@"record"] ||
         [lower containsString:@"shoot"] ||
         [lower containsString:@"camera"] ||
         [lower containsString:@"creation"] ||
         [lower containsString:@"composer"] ||
         [lower containsString:@"postedit"] ||
         [lower containsString:@"videoedit"]);

    BOOL transientCommerceDestination =
        AWEClassNameLooksLikeTransientCommerceDestination(className);

    /* The replacement bar lives in its own window, so pushed settings pages do
       not automatically clip it with Douyin's native hierarchy.  Treat real
       settings/privacy/account-security controllers as ordinary suppressed
       destinations (not hard-suspended sheets), which also preserves the
       existing interactive return-mask path. */
    BOOL settingsDestination = controllerLike &&
        ([lower containsString:@"setting"] ||
         [lower containsString:@"settings"] ||
         [lower containsString:@"accountsecurity"] ||
         [lower containsString:@"accountandsecurity"] ||
         [lower containsString:@"privacycenter"] ||
         [lower containsString:@"privacysetting"] ||
         [lower containsString:@"generalsetting"]);

    return directConversation || imMediaDestination || commentDestination || forwardDestination ||
           systemActivityDestination || systemDocumentDestination ||
           publishDestination || transientCommerceDestination ||
           settingsDestination;
}

static void AWERegisterSensitiveDestination(UIViewController *controller) {
    if (!controller) return;

    [AWESensitiveVisibleControllers() addObject:controller];
    gAWESensitiveEntrySuppressionUntil = CACurrentMediaTime() + 0.85;
    AWEAlbumMorphProbeWrite(@"ROUTE_ENTER class=%@ presented=%d window=%d style=%ld",
        NSStringFromClass(controller.class),
        controller.presentingViewController != nil,
        controller.viewIfLoaded.window != nil,
        (long)controller.modalPresentationStyle);
}

static BOOL AWEUnregisterSensitiveDestination(UIViewController *controller) {
    if (!controller) return NO;

    [AWESensitiveVisibleControllers() removeObject:controller];

    /* Do not create a fresh suppression window after the destination has
       already disappeared. 1.0.23y briefly restored the bar, re-hid it for
       another 80 ms here, then restored it again. That visibility pulse was
       perceived as a vertical jump even though the overlay frame stayed
       fixed. Remaining sensitive controllers in the weak table still keep the
       route suppressed naturally. */
    BOOL anotherSensitiveControllerIsVisible = NO;
    for (UIViewController *remaining in AWESensitiveVisibleControllers()) {
        if (!remaining || remaining == controller) continue;
        UIView *view = remaining.viewIfLoaded;
        if (view.window || remaining.isBeingPresented ||
            remaining.isMovingToParentViewController) {
            anotherSensitiveControllerIsVisible = YES;
            break;
        }
    }
    if (!anotherSensitiveControllerIsVisible) {
        gAWESensitiveEntrySuppressionUntil = 0.0;
    }

    AWEAlbumMorphProbeWrite(@"ROUTE_EXIT class=%@ window=%d remaining=%d",
        NSStringFromClass(controller.class),
        controller.viewIfLoaded.window != nil,
        anotherSensitiveControllerIsVisible);
    return anotherSensitiveControllerIsVisible;
}

static BOOL AWEShouldSuppressBarForSensitiveDestination(void) {
    if (CACurrentMediaTime() < gAWESensitiveEntrySuppressionUntil) {
        return YES;
    }

    for (UIViewController *controller in AWESensitiveVisibleControllers()) {
        if (!controller) continue;

        UIView *view = controller.viewIfLoaded;
        if (view.window != nil ||
            controller.isBeingPresented ||
            controller.isMovingToParentViewController) {
            return YES;
        }
    }

    return NO;
}

static BOOL AWEShouldSuppressBarForUserDetailRoute(void) {
    return AWEControllerTreeContainsUserDetailRoute(gAWELastController, 0);
}

static BOOL AWEFrameLooksLikeBottomBarInHost(CGRect frame, UIView *host) {
    if (!host || CGRectIsNull(frame) || CGRectIsEmpty(frame)) return NO;

    CGFloat hostHeight = MAX(CGRectGetHeight(host.bounds), 1.0);
    CGFloat midY = CGRectGetMidY(frame);
    CGFloat maxY = CGRectGetMaxY(frame);

    return CGRectGetWidth(frame) > 100.0 &&
           CGRectGetHeight(frame) > 20.0 &&
           midY > hostHeight * 0.66 &&
           maxY > hostHeight - 170.0 &&
           maxY < hostHeight + 170.0;
}

static BOOL AWETransitionPrewarmIsActive(void) {
    return CACurrentMediaTime() < gAWETransitionPrewarmUntil;
}

static BOOL AWEReturnRevealGraceIsActive(void) {
    return CACurrentMediaTime() < gAWEReturnRevealGraceUntil;
}

static UIView *AWEStableTabBarWrapperInHost(UIView *host) {
    if (!host) return nil;

    UIView *best = nil;
    for (UIView *candidate in host.subviews) {
        NSString *className = NSStringFromClass(candidate.class);
        if (![className containsString:@"TabBarContainerWrapperView"]) continue;

        CGRect frame = candidate.frame;
        if (CGRectGetWidth(frame) > 100.0 &&
            CGRectGetHeight(frame) > 20.0 &&
            AWEFrameLooksLikeBottomBarInHost(frame, host)) {
            best = candidate;
            break;
        }
    }
    return best;
}

static UIView *AWEFindFirstDescendantWhoseClassContains(UIView *root,
                                                          NSString *needle,
                                                          NSUInteger depth) {
    if (!root || !needle.length || depth > 10) return nil;
    NSString *name = NSStringFromClass(root.class);
    if ([name rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound) {
        return root;
    }
    for (UIView *child in root.subviews) {
        UIView *found = AWEFindFirstDescendantWhoseClassContains(child, needle, depth + 1);
        if (found) return found;
    }
    return nil;
}

static NSString *AWEFirstVisibleLabelText(UIView *root, NSUInteger depth) {
    if (!root || depth > 8 || root.hidden || root.alpha <= 0.01) return nil;
    if ([root isKindOfClass:UILabel.class]) {
        NSString *text = [((UILabel *)root).text stringByTrimmingCharactersInSet:
            NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (text.length) return text;
    }
    for (UIView *child in root.subviews) {
        NSString *text = AWEFirstVisibleLabelText(child, depth + 1);
        if (text.length) return text;
    }
    return nil;
}

static UIView *AWEFindOriginalBottomBadgeView(UIView *button) {
    if (!button) return nil;
    for (NSString *needle in @[@"Badge", @"Unread", @"RedDot"]) {
        UIView *candidate = AWEFindFirstDescendantWhoseClassContains(button, needle, 0);
        if (candidate && !candidate.hidden && candidate.alpha > 0.01 &&
            candidate.layer.opacity > 0.01f) return candidate;
    }
    return nil;
}

static NSString *AWECurrentOriginalBadgeValueForButtonIndex(NSUInteger index) {
    if (!AWEMessageBadgeEnabled()) return nil;
    NSArray *buttons = AWEControllerButtons(gAWELastController);
    if (buttons.count <= index) return nil;
    UIView *button = [buttons[index] isKindOfClass:UIView.class] ? buttons[index] : nil;
    if (!button) return nil;
    UIView *badge = AWEFindOriginalBottomBadgeView(button);
    if (!badge) return nil;
    NSString *text = AWEFirstVisibleLabelText(badge, 0);
    if (text.length) return text;
    /* Preserve UIKit's compact red-dot semantics with a single blank. */
    return @" ";
}

static NSString *AWECurrentOriginalMessagesBadgeValue(void) {
    NSString *value = AWECurrentOriginalBadgeValueForButtonIndex(3);
    if (!value.length) return nil;

    /* Messages is a numeric unread counter. Douyin can leave its native badge
       container visible after the count reaches zero; mirroring that empty
       container as @" " makes UIKit draw an empty red circle. Only mirror a
       strictly positive numeric value (compact forms such as 99+ still pass). */
    NSString *trimmed = [value stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!trimmed.length) return nil;
    NSScanner *scanner = [NSScanner scannerWithString:trimmed];
    NSInteger count = 0;
    if (![scanner scanInteger:&count] || count <= 0) return nil;
    return trimmed;
}

static NSString *AWECurrentOriginalSecondBadgeValue(void) {
    /* Only mirror Friends. Never copy the promotional badge of a Shop second tab.
       Douyin can keep an empty native badge shell alive after unread reaches 0;
       do not translate that stale shell into UIKit's blank red dot. */
    if (AWESecondTabIsShop()) return nil;
    NSString *value = AWECurrentOriginalBadgeValueForButtonIndex(1);
    NSString *trimmed = [value stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!trimmed.length) return nil;

    NSScanner *scanner = [NSScanner scannerWithString:trimmed];
    NSInteger count = 0;
    if ([scanner scanInteger:&count]) {
        return count > 0 ? trimmed : nil;
    }
    /* Friends unread is a count mirror in this plugin. Non-numeric remnants
       such as a recycled empty badge must not survive as a red dot. */
    return nil;
}

static void AWEUpdateAlbumMorphMessageBadge(void) {
    if (!gAWEAlbumMorphController) return;
    static NSString *lastMessageValue = nil;
    static NSString *lastSecondValue = nil;
    static BOOL initialized = NO;
    NSString *messageValue = AWECurrentOriginalMessagesBadgeValue();
    NSString *secondValue = AWECurrentOriginalSecondBadgeValue();
    BOOL sameMessage = initialized &&
        ((lastMessageValue == messageValue) || [lastMessageValue isEqualToString:messageValue]);
    BOOL sameSecond = initialized &&
        ((lastSecondValue == secondValue) || [lastSecondValue isEqualToString:secondValue]);
    if (sameMessage && sameSecond) return;
    initialized = YES;
    lastMessageValue = [messageValue copy];
    lastSecondValue = [secondValue copy];
    [gAWEAlbumMorphController updateMessageBadgeValue:messageValue];
    [gAWEAlbumMorphController updateSecondBadgeValue:secondValue];
    if (AWEInteractionDiagnosticsEnabled()) {
        AWEInteractionDiagnosticWrite(
            @"BOTTOM_BADGES_NATIVE enabled=%d friends=%@ messages=%@",
            AWEMessageBadgeEnabled(), secondValue ?: @"<none>",
            messageValue ?: @"<none>");
    }
}

static void AWEAttachNativeBarWithForce(UIView *tabBar, BOOL forceVisible) {
    if (!AWEPluginFeaturesEnabled()) return;
    if (!tabBar || AWEIsApplying(tabBar) || CGRectIsEmpty(tabBar.bounds)) return;

    UIView *host = tabBar.superview;
    if (!host) return;

    /* True release mode. This early return is essential: without it the
       AlbumMorph install would fail while OFF and the function would fall
       through into LiquidBar's legacy native-bar fallback, still occupying the
       exact host another tweak needs. */
    if (!AWEBottomBarDisplayEnabled()) {
        AWESetApplying(tabBar, YES);
        AWEUninstallAlbumMorphBar();
        AWEApplyAlbumMorphOriginalSuppression(tabBar, NO);
        AWERestoreOriginalTabBarContents(tabBar);
        AWESetApplying(tabBar, NO);
        return;
    }

    AWESetApplying(tabBar, YES);

    if (AWEAlbumMorphStyleEnabled() &&
        AWEOperatingSystemMajorVersion() >= 26) {
        BOOL installed =
            AWEInstallOrUpdateAlbumMorphBar(tabBar, NO);
        if (installed) {
            AWEHideOriginalTabBarContents(tabBar);
            UITabBar *oldNativeBar =
                objc_getAssociatedObject(tabBar, &kAWENativeBarKey);
            if (oldNativeBar) {
                oldNativeBar.hidden = YES;
                oldNativeBar.userInteractionEnabled = NO;
                oldNativeBar.layer.opacity = 0.0f;
                [oldNativeBar removeFromSuperview];
            }
            AWESetApplying(tabBar, NO);
            return;
        }

        /* Never leave the user with an empty bottom area. If the Swift
           controller cannot be resolved or attached, fall through to the
           already-proven native LiquidBar implementation. */
        AWEInteractionDiagnosticWrite(
            @"ALBUM_MORPH_FALLBACK_TO_STABLE_NATIVE_BAR");
    }

    AWEApplyAlbumMorphOriginalSuppression(tabBar, NO);
    AWEHideOriginalTabBarContents(tabBar);
    AWEUninstallAlbumMorphBar();

    UITabBar *nativeBar =
        objc_getAssociatedObject(tabBar, &kAWENativeBarKey);
    if (!nativeBar) nativeBar = AWECreateNativeBar(tabBar);

    UIView *wrapper = AWEStableTabBarWrapperInHost(host);

    if (nativeBar.superview != host) {
        [nativeBar removeFromSuperview];

        /*
         0.0.20a stable-carrier geometry:
         keep one UITabBar permanently in the root tab-bar host.  Insert it
         next to UIKit's stable wrapper when available; otherwise keep it next
         to Douyin's original AWENormalModeTabBar.  It is never moved offscreen
         to represent page state.
        */
        if (wrapper && wrapper.superview == host) {
            [host insertSubview:nativeBar aboveSubview:wrapper];
        } else if (tabBar.superview == host) {
            [host insertSubview:nativeBar aboveSubview:tabBar];
        } else {
            [host addSubview:nativeBar];
        }

        objc_setAssociatedObject(tabBar, &kAWELastFrameKey, nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGRect carrierFrame = CGRectNull;
    NSString *carrierName = nil;
    UIView *carrier = nil;

    if (wrapper && wrapper.window &&
        AWEFrameLooksLikeBottomBarInHost(wrapper.frame, host)) {
        carrier = wrapper;
        carrierFrame = wrapper.frame;
        carrierName = NSStringFromClass(wrapper.class);
    } else {
        CGRect measured = [tabBar convertRect:tabBar.bounds toView:host];
        if (AWEFrameLooksLikeBottomBarInHost(measured, host)) {
            carrier = tabBar;
            carrierFrame = measured;
            carrierName = NSStringFromClass(tabBar.class);
        }
    }

    NSValue *lastVisibleValue =
        objc_getAssociatedObject(tabBar, &kAWELastVisibleFrameKey);
    CGRect lastVisibleFrame =
        lastVisibleValue ? lastVisibleValue.CGRectValue : CGRectNull;

    if (!CGRectIsNull(carrierFrame) && !CGRectIsEmpty(carrierFrame)) {
        objc_setAssociatedObject(tabBar,
                                 &kAWELastVisibleFrameKey,
                                 [NSValue valueWithCGRect:carrierFrame],
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        lastVisibleFrame = carrierFrame;
    } else if (!CGRectIsNull(lastVisibleFrame)) {
        carrierFrame = lastVisibleFrame;
        carrierName = @"cached-stable-frame";
    } else {
        carrierFrame = CGRectMake(0.0,
                                  MAX(0.0, CGRectGetHeight(host.bounds) - 83.0),
                                  CGRectGetWidth(host.bounds),
                                  83.0);
        carrierName = @"host-bottom-fallback";
    }

    carrierFrame = CGRectOffset(carrierFrame,
                                0.0,
                                AWEStoredVerticalOffset());

    NSValue *lastValue =
        objc_getAssociatedObject(tabBar, &kAWELastFrameKey);
    CGRect lastFrame = lastValue ? lastValue.CGRectValue : CGRectNull;
    BOOL frameChanged =
        CGRectIsNull(lastFrame) ||
        !AWEFrameEqualEnough(lastFrame, carrierFrame);

    if (frameChanged) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        nativeBar.transform = CGAffineTransformIdentity;
        nativeBar.frame = carrierFrame;
        [CATransaction commit];

        objc_setAssociatedObject(tabBar,
                                 &kAWELastFrameKey,
                                 [NSValue valueWithCGRect:carrierFrame],
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    /*
     0.0.20a:
     geometry remains permanently warm and stable, but visibility now follows
     Douyin's own original bar. Interactive navigation uses a horizontal mask
     driven by transitionCoordinator.percentComplete, so a return exposes only
     the portion already uncovered by the outgoing page.
    */
    AWEUpdateNativeBarVisibility(tabBar,
                                 nativeBar,
                                 @"attach.original-state");

    AWEApplyNativeDarkBootstrap(nativeBar);
    AWEScheduleNativeDarkBootstrapRelease(nativeBar);

    AWEInstallColdStartBackplateIfNeeded(tabBar,
                                         host,
                                         nativeBar,
                                         carrierFrame);
    AWEUpdateColdStartBackplateFrame(tabBar, host, carrierFrame);

    if (frameChanged) {
        AWEPrimeNativeBarRenderTree(nativeBar);
    } else {
        AWEClearDirectNativeBarBackground(nativeBar);
    }

    NSString *decision = [NSString stringWithFormat:
        @"carrier=%@/%p wrapper=%@/%p frame=%@ frameChanged=%d "
         "original(h=%d,a=%.3f) native(h=%d,a=%.3f) fraction=%.3f "
         "maskMode=%ld host=%@/%p",
        carrierName ?: @"<nil>",
        (__bridge void *)carrier,
        wrapper ? NSStringFromClass(wrapper.class) : @"<nil>",
        (__bridge void *)wrapper,
        NSStringFromCGRect(carrierFrame),
        frameChanged,
        tabBar.hidden,
        tabBar.alpha,
        nativeBar.hidden,
        nativeBar.alpha,
        gAWEBarLastVisibleFraction,
        (long)gAWEBarTransitionMaskMode,
        NSStringFromClass(host.class),
        (__bridge void *)host];

    if (![gAWEProbeLastDecisionSignature isEqualToString:decision]) {
        gAWEProbeLastDecisionSignature = decision;
        AWETransitionLog(@"PERSISTENT_CARRIER %@", decision);
    }

    AWESetApplying(tabBar, NO);
}

static void AWEAttachNativeBar(UIView *tabBar) {
    AWEAttachNativeBarWithForce(tabBar, NO);
}

static BOOL AWEViewActuallyVisibleInWindow(UIView *view) {
    if (!view || !view.window || view.hidden || view.alpha < 0.01) return NO;
    for (UIView *ancestor = view.superview;
         ancestor && ancestor != view.window;
         ancestor = ancestor.superview) {
        if (ancestor.hidden || ancestor.alpha < 0.01) return NO;
    }
    CGRect frame = CGRectNull;
    @try {
        frame = [view convertRect:view.bounds toView:view.window];
    } @catch (__unused NSException *exception) {
        return NO;
    }
    return !CGRectIsNull(frame) && !CGRectIsEmpty(frame) &&
        CGRectIntersectsRect(CGRectInset(view.window.bounds, -8.0, -8.0), frame);
}

static NSHashTable<UIView *> *AWEVisibleMessagingComposers(void) {
    if (!gAWEVisibleMessagingComposers) {
        gAWEVisibleMessagingComposers = [NSHashTable weakObjectsHashTable];
    }
    return gAWEVisibleMessagingComposers;
}

static void AWETrackMessagingComposer(UIView *view) {
    if (!view) return;
    if (view.window) [AWEVisibleMessagingComposers() addObject:view];
    else [AWEVisibleMessagingComposers() removeObject:view];
}

static BOOL AWECurrentMessagingComposerVisible(void) {
    /* This predicate sits on hot fullscreen/layout paths, so never search the
       whole window tree here. The two known composer hooks maintain a tiny weak
       set and we only validate those live candidates. */
    for (UIView *view in AWEVisibleMessagingComposers()) {
        if (AWEViewActuallyVisibleInWindow(view)) return YES;
    }
    return NO;
}

static BOOL AWECurrentHomeFeedSurfaceVisible(void) {
    if (AWECurrentOriginalMainTabIndex() != 0) return NO;
    /* AWEAlbumMorphSteadyWantsVisible is sampled frequently. The exact
       AWEFeedTopBarContainer hook keeps this weak pointer current so this page
       predicate never performs a recursive view-tree scan on the hot path. */
    return AWEViewActuallyVisibleInWindow(gAWEHomeFeedTopContainer);
}

static BOOL AWECurrentRouteSuppressesBar(void) {
    return AWEShouldSuppressBarForSearch() ||
           AWECurrentMessagingComposerVisible() ||
           AWEShouldSuppressBarForUserDetailRoute() ||
           AWEShouldSuppressBarForSensitiveDestination() ||
           AWEShouldSuppressBarForCommerceProductDetail() ||
           CACurrentMediaTime() < gAWEAlbumMorphPublishLaunchSuppressionUntil;
}

#pragma mark - 0.0.20a original-state visibility and interactive mask

/*
 Use only live, exact suppression state here. The older grace timers are
 intentionally excluded because the 0.0.18b log proved that an 80 ms tail
 suppression caused the chat-list flash after a completed return.
*/
static BOOL AWEImmediateSensitiveDestinationVisible(void) {
    for (UIViewController *controller in AWESensitiveVisibleControllers()) {
        if (!controller) continue;
        UIView *view = controller.viewIfLoaded;
        if (view.window != nil ||
            controller.isBeingPresented ||
            controller.isMovingToParentViewController) {
            return YES;
        }
    }
    return NO;
}

static BOOL AWEImmediateCommerceProductDetailVisible(void) {
    for (UIView *marker in AWECommerceProductDetailMarkers()) {
        if (marker.window != nil && !marker.hidden && marker.alpha > 0.01) {
            return YES;
        }
    }
    return NO;
}

static BOOL AWEImmediateRouteSuppressesBar(void) {
    return AWEShouldSuppressBarForSearch() ||
           AWECurrentMessagingComposerVisible() ||
           AWEShouldSuppressBarForUserDetailRoute() ||
           AWEImmediateSensitiveDestinationVisible() ||
           AWEImmediateCommerceProductDetailVisible() ||
           CACurrentMediaTime() < gAWEAlbumMorphPublishLaunchSuppressionUntil;
}

static BOOL AWEOriginalBarSteadyWantsVisible(UIView *originalBar) {
    if (!originalBar || !originalBar.window) return NO;

    /*
     The chat-return log shows that Douyin can keep the destination tab bar at
     alpha=0 for roughly 1.7 seconds after the return has already completed,
     while hidden has already become NO.  Treat hidden as the authoritative
     page-state signal and ignore that transient opacity hand-off; otherwise
     LiquidBar would disappear after a successful return and reappear later.
    */
    return !originalBar.hidden;
}

/*
 The independent Album Morph overlay lives in a separate UIWindow, so it cannot
 inherit Douyin's tab-bar clipping/hierarchy automatically.  Mirror the live
 original bar instead of allowing recovery callers to force the overlay on.
 Ignore layer.opacity because this plugin intentionally sets it to zero while
 the replacement owns the bottom area; hidden state, ancestor state, and live
 bottom geometry remain authoritative.
*/
static BOOL AWEAlbumMorphOriginalBarWantsVisible(UIView *originalBar) {
    if (!AWEOriginalBarSteadyWantsVisible(originalBar)) return NO;

    UIWindow *window = originalBar.window;
    for (UIView *ancestor = originalBar.superview;
         ancestor && ancestor != window;
         ancestor = ancestor.superview) {
        if (ancestor.hidden) return NO;
    }

    CGRect frameInWindow = CGRectNull;
    @try {
        frameInWindow = [originalBar convertRect:originalBar.bounds
                                          toView:window];
    } @catch (__unused NSException *exception) {
        return NO;
    }

    if (CGRectIsNull(frameInWindow) || CGRectIsEmpty(frameInWindow) ||
        !CGRectIntersectsRect(CGRectInset(window.bounds, -8.0, -8.0),
                              frameInWindow)) {
        return NO;
    }

    CGFloat width = CGRectGetWidth(frameInWindow);
    CGFloat height = CGRectGetHeight(frameInWindow);
    CGFloat windowHeight = CGRectGetHeight(window.bounds);
    BOOL validSize = width >= 100.0 && height >= 20.0;
    BOOL inBottomRegion = CGRectGetMidY(frameInWindow) > windowHeight * 0.68;
    BOOL nearBottom = CGRectGetMaxY(frameInWindow) > windowHeight - 170.0 &&
                      CGRectGetMinY(frameInWindow) < windowHeight;
    return validSize && inBottomRegion && nearBottom;
}

static id<UIViewControllerTransitionCoordinator>
AWECurrentBarTransitionCoordinator(void) {
    UIWindow *window = AWEActiveMainWindow();
    UIViewController *top =
        AWETopViewControllerFrom(window.rootViewController);
    UINavigationController *navigation = nil;

    if ([top isKindOfClass:[UINavigationController class]]) {
        navigation = (UINavigationController *)top;
    } else {
        navigation = top.navigationController;
    }

    return top.transitionCoordinator ?: navigation.transitionCoordinator;
}


static void AWEUpdateFriendsTabLatch(NSInteger index) {
    if (AWESecondTabIsShop()) {
        gAWEFriendsTabLatched = NO;
        return;
    }
    if (index == 1) gAWEFriendsTabLatched = YES;
    else if (index == 0 || index == 3 || index == 4) gAWEFriendsTabLatched = NO;
}

static BOOL AWEAlbumMorphSteadyWantsVisible(UIView *originalBar) {
    if (!originalBar || gAWESettingsVisible) return NO;

    NSInteger currentIndex = AWECurrentOriginalMainTabIndex();
    AWEUpdateFriendsTabLatch(currentIndex);
    BOOL friendsRoot = !AWESecondTabIsShop() &&
        (currentIndex == 1 || gAWEFriendsTabLatched);

    /* Some Douyin builds detach or hide the native tab bar after the Friends
       batch is exhausted. Treat that as feed content state, not navigation.
       The latch is cleared as soon as Home/Messages/Profile is selected, while
       route suppression still wins for profile/search/comment/share/etc. */
    if (friendsRoot && !AWECurrentRouteSuppressesBar()) return YES;

    /* Article-style Home feed cards can temporarily hide/detach Douyin's
       original tab bar without actually navigating away from the Home feed.
       The visible native top-feed container is a stronger page-state signal;
       keep LiquidBar present and let explicit route suppression still win. */
    if (AWECurrentHomeFeedSurfaceVisible() &&
        !AWECurrentRouteSuppressesBar()) return YES;

    if (!originalBar.window) return NO;
    return AWEOriginalBarSteadyWantsVisible(originalBar);
}

static void AWEApplyAlbumMorphVisibleFraction(CGFloat fraction,
                                               NSString *reason,
                                               BOOL animated) {
    if (!gAWEAlbumMorphController || !gAWEAlbumMorphOverlayWindow) return;

    /* 1.0.56c13: hard no-show gate for clean screen. Recovery, route, pause,
       selection and lifecycle callbacks are allowed to keep their bookkeeping,
       but none of them may make LiquidBar visible for even one compositor frame
       while clean screen is active. This avoids the historical one/two-frame
       flash without adding a timer, polling loop or global UIView hook. */
    if (gAWEStableCleanScreenEnabled) {
        AWEAlbumMorphOverlayWindow *cleanOverlay =
            (AWEAlbumMorphOverlayWindow *)gAWEAlbumMorphOverlayWindow;
        gAWEBarLastVisibleFraction = 0.0;
        [gAWEAlbumMorphController setVisibleFraction:0.0 animated:NO];
        cleanOverlay.contentVisible = NO;
        gAWEAlbumMorphVisible = NO;
        AWEStableCleanEnforceBottomBarSuppression();
        return;
    }

    fraction = MIN(MAX(fraction, 0.0), 1.0);
    /* No recovery caller may resurrect the bottom overlay on top of a modal
       share/publish/commerce route.  This guards against late coordinator and
       lifecycle callbacks that arrive after route registration. */
    if (fraction > 0.0 && AWECurrentRouteSuppressesBar()) fraction = 0.0;
    BOOL changed = fabs(gAWEBarLastVisibleFraction - fraction) > 0.002;
    gAWEBarLastVisibleFraction = fraction;

    AWEAlbumMorphOverlayWindow *overlay =
        (AWEAlbumMorphOverlayWindow *)gAWEAlbumMorphOverlayWindow;
    BOOL bottomBarDisplayEnabled = AWEBottomBarDisplayEnabled();
    overlay.hidden = NO;
    overlay.alpha = 1.0;
    gAWEAlbumMorphController.view.hidden = NO;
    gAWEAlbumMorphController.view.alpha = 1.0;

    /* Keep the native-tab bridge alive even when the user hides only our
       bottom chrome. This preserves routing/badges/settings/top/right extras
       and, critically, does not unsuppress Douyin's original tab bar. */
    gAWEAlbumMorphController.tabBar.hidden = !bottomBarDisplayEnabled;
    gAWEAlbumMorphController.tabBar.alpha = bottomBarDisplayEnabled ? 1.0 : 0.0;
    gAWEAlbumMorphController.tabBar.userInteractionEnabled =
        bottomBarDisplayEnabled;

    [gAWEAlbumMorphController setVisibleFraction:fraction animated:animated];

    BOOL hitVisible = fraction > 0.001;
    /* contentVisible remains the route/lifecycle state so the shared adaptive
       glass resolver can continue serving the other plugin glass buttons. */
    overlay.contentVisible = hitVisible;
    if (overlay.searchTouchProxy) {
        BOOL searchInteractive = bottomBarDisplayEnabled && fraction >= 0.82;
        overlay.searchTouchProxy.hidden = !searchInteractive;
        overlay.searchTouchProxy.userInteractionEnabled = searchInteractive;
    }
    gAWEAlbumMorphVisible = hitVisible;
    if (gAWEStableCleanScreenEnabled) AWEStableCleanEnforceBottomBarSuppression();

    if (changed) {
        AWEAlbumMorphProbeWrite(
            @"VISIBILITY_MASK reason=%@ fraction=%.4f mode=%ld stable=%d animated=%d",
            reason ?: @"unknown", fraction,
            (long)gAWEBarTransitionMaskMode,
            gAWEBarStableVisible, animated);
    }
}

static void AWEFinishAlbumMorphTransition(
    id<UIViewControllerTransitionCoordinatorContext> context,
    UIView *originalBar,
    AWEBarTransitionMaskMode mode,
    BOOL fromVisible,
    id<UIViewControllerTransitionCoordinator> coordinator) {

    if (gAWEBarVisibilityCoordinator &&
        gAWEBarVisibilityCoordinator != coordinator) return;

    BOOL targetVisible = fromVisible;
    if (!context.isCancelled) {
        if (mode == AWEBarTransitionMaskModeReveal) targetVisible = YES;
        else if (mode == AWEBarTransitionMaskModeHide) targetVisible = NO;
        else targetVisible = AWEAlbumMorphSteadyWantsVisible(originalBar);
    }

    gAWEBarStableStateInitialized = YES;
    gAWEBarStableVisible = targetVisible;
    gAWEBarTransitionMaskMode = AWEBarTransitionMaskModeNone;
    gAWEBarVisibilityCoordinator = nil;
    AWEApplyAlbumMorphVisibleFraction(
        targetVisible ? 1.0 : 0.0,
        context.isCancelled ? @"transition.cancelled" : @"transition.completed",
        NO);
    AWEScheduleTransitionRecovery();
}

static void AWERegisterAlbumMorphCoordinator(
    UIView *originalBar,
    id<UIViewControllerTransitionCoordinator> coordinator,
    AWEBarTransitionMaskMode mode,
    BOOL fromVisible,
    BOOL animateTarget) {
    if (!coordinator || mode == AWEBarTransitionMaskModeNone) return;
    if (gAWEBarVisibilityCoordinator == coordinator &&
        gAWEBarTransitionMaskMode == mode) return;

    gAWEBarVisibilityCoordinator = coordinator;
    gAWEBarTransitionMaskMode = mode;
    gAWEBarTransitionFromVisible = fromVisible;

    if ([objc_getAssociatedObject((id)coordinator,
            &kAWEVisibilityCoordinatorRegistrationKey) boolValue]) return;
    objc_setAssociatedObject((id)coordinator,
        &kAWEVisibilityCoordinatorRegistrationKey, @YES,
        OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    __weak UIView *weakOriginal = originalBar;
    __weak id<UIViewControllerTransitionCoordinator> weakCoordinator = coordinator;
    AWEBarTransitionMaskMode capturedMode = mode;
    BOOL capturedFromVisible = fromVisible;

    [coordinator animateAlongsideTransition:
        ^(id<UIViewControllerTransitionCoordinatorContext> context) {
            (void)context;
            if (!animateTarget) return;
            CGFloat target = capturedMode == AWEBarTransitionMaskModeReveal
                ? 1.0 : 0.0;
            AWEApplyAlbumMorphVisibleFraction(
                target, @"coordinator.animation", YES);
        }
        completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            AWEFinishAlbumMorphTransition(
                context, weakOriginal, capturedMode, capturedFromVisible,
                weakCoordinator);
        }];
}

static void AWEUpdateAlbumMorphVisibility(UIView *originalBar,
                                           NSString *reason) {
    if (!originalBar || !gAWEAlbumMorphController ||
        !gAWEAlbumMorphOverlayWindow) return;

    BOOL targetVisible = AWEAlbumMorphSteadyWantsVisible(originalBar);
    BOOL fromVisible = gAWEBarStableStateInitialized
        ? gAWEBarStableVisible
        : targetVisible;
    id<UIViewControllerTransitionCoordinator> coordinator =
        AWECurrentBarTransitionCoordinator();

    if (coordinator && coordinator.isInteractive) {
        AWEBarTransitionMaskMode mode = AWEBarTransitionMaskModeNone;
        /* Preserve 1.0.10b's exact direction signal. During an interactive
           return Douyin flips the original bar hidden flag before alpha/frame
           settle, which is enough to identify a reveal. */
        if (!fromVisible && !originalBar.hidden) {
            mode = AWEBarTransitionMaskModeReveal;
        } else if (fromVisible &&
                   (originalBar.hidden || AWECurrentRouteSuppressesBar())) {
            mode = AWEBarTransitionMaskModeHide;
        } else if (targetVisible != fromVisible) {
            mode = targetVisible ? AWEBarTransitionMaskModeReveal
                                 : AWEBarTransitionMaskModeHide;
        }

        if (mode != AWEBarTransitionMaskModeNone) {
            AWERegisterAlbumMorphCoordinator(
                originalBar, coordinator, mode, fromVisible, NO);
        }

        if (gAWEBarVisibilityCoordinator == coordinator &&
            gAWEBarTransitionMaskMode != AWEBarTransitionMaskModeNone) {
            CGFloat progress = MIN(MAX(coordinator.percentComplete, 0.0), 1.0);
            CGFloat fraction = gAWEBarTransitionMaskMode ==
                AWEBarTransitionMaskModeReveal ? progress : 1.0 - progress;
            AWEApplyAlbumMorphVisibleFraction(
                fraction, reason ?: @"interactive.tick", NO);
            return;
        }

        AWEApplyAlbumMorphVisibleFraction(
            fromVisible ? 1.0 : 0.0,
            @"interactive.awaiting-signal", NO);
        return;
    }

    if (coordinator && targetVisible != fromVisible) {
        AWEBarTransitionMaskMode mode = targetVisible
            ? AWEBarTransitionMaskModeReveal
            : AWEBarTransitionMaskModeHide;
        AWEApplyAlbumMorphVisibleFraction(
            fromVisible ? 1.0 : 0.0, @"coordinator.start", NO);
        AWERegisterAlbumMorphCoordinator(
            originalBar, coordinator, mode, fromVisible, YES);
        return;
    }

    if (gAWEBarTransitionMaskMode != AWEBarTransitionMaskModeNone &&
        gAWEBarVisibilityCoordinator && !coordinator) {
        gAWEBarTransitionMaskMode = AWEBarTransitionMaskModeNone;
        gAWEBarVisibilityCoordinator = nil;
    }

    gAWEBarStableStateInitialized = YES;
    gAWEBarStableVisible = targetVisible;
    AWEApplyAlbumMorphVisibleFraction(
        targetVisible ? 1.0 : 0.0,
        reason ?: @"steady.original-state", NO);
}

static CAShapeLayer *AWEVisibilityMaskForNativeBar(UITabBar *nativeBar) {
    if (!nativeBar) return nil;

    CAShapeLayer *mask =
        objc_getAssociatedObject(nativeBar, &kAWEVisibilityMaskKey);
    if (!mask) {
        mask = [CAShapeLayer layer];
        mask.fillColor = UIColor.blackColor.CGColor;
        mask.actions = @{
            @"path": [NSNull null],
            @"bounds": [NSNull null],
            @"position": [NSNull null],
            @"frame": [NSNull null]
        };
        objc_setAssociatedObject(nativeBar,
                                 &kAWEVisibilityMaskKey,
                                 mask,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return mask;
}

static void AWEApplyNativeBarVisibleFraction(UITabBar *nativeBar,
                                             CGFloat fraction,
                                             NSString *reason) {
    if (!nativeBar) return;

    fraction = MIN(MAX(fraction, 0.0), 1.0);
    BOOL changed = fabs(gAWEBarLastVisibleFraction - fraction) > 0.002;
    gAWEBarLastVisibleFraction = fraction;

    [CATransaction begin];
    [CATransaction setDisableActions:YES];

    /*
     Keep the actual Liquid Glass object alive and laid out even when the page
     does not show a tab bar. A zero-width mask prevents both drawing and hit
     testing without moving the object off screen or rebuilding it later.
    */
    nativeBar.hidden = NO;
    nativeBar.alpha = 1.0;

    if (fraction >= 0.999) {
        nativeBar.layer.mask = nil;
        nativeBar.userInteractionEnabled = YES;
    } else {
        CAShapeLayer *mask = AWEVisibilityMaskForNativeBar(nativeBar);
        mask.frame = nativeBar.bounds;

        CGFloat visibleWidth =
            CGRectGetWidth(nativeBar.bounds) * fraction;
        CGRect visibleRect = CGRectMake(0.0,
                                        0.0,
                                        MAX(0.0, visibleWidth),
                                        CGRectGetHeight(nativeBar.bounds));
        mask.path =
            [UIBezierPath bezierPathWithRect:visibleRect].CGPath;
        nativeBar.layer.mask = mask;
        /* Keep the bar tappable once most of it is visibly exposed. This
           avoids a stale partial-mask state leaving a fully visible bar dead. */
        nativeBar.userInteractionEnabled = fraction >= 0.82;
    }

    [CATransaction commit];

    if (changed) {
        AWETransitionLog(@"VISIBILITY_MASK reason=%@ fraction=%.4f "
                         "mode=%ld stable=%d",
                         reason ?: @"<nil>",
                         fraction,
                         (long)gAWEBarTransitionMaskMode,
                         gAWEBarStableVisible);
    }
}

static void AWEFinishBarTransition(
    id<UIViewControllerTransitionCoordinatorContext> context,
    UIView *originalBar,
    UITabBar *nativeBar,
    AWEBarTransitionMaskMode mode,
    BOOL fromVisible,
    id<UIViewControllerTransitionCoordinator> coordinator) {

    if (gAWEBarVisibilityCoordinator &&
        gAWEBarVisibilityCoordinator != coordinator) {
        return;
    }

    BOOL targetVisible = fromVisible;
    if (!context.isCancelled) {
        if (mode == AWEBarTransitionMaskModeReveal) {
            targetVisible = YES;
        } else if (mode == AWEBarTransitionMaskModeHide) {
            targetVisible = NO;
        } else {
            targetVisible =
                AWEOriginalBarSteadyWantsVisible(originalBar);
        }
    }

    gAWEBarStableStateInitialized = YES;
    gAWEBarStableVisible = targetVisible;
    gAWEBarTransitionMaskMode = AWEBarTransitionMaskModeNone;
    gAWEBarVisibilityCoordinator = nil;

    AWEApplyNativeBarVisibleFraction(nativeBar,
                                     targetVisible ? 1.0 : 0.0,
                                     context.isCancelled ?
                                         @"interactive.cancelled" :
                                         @"interactive.completed");
}

static void AWEConfigureInteractiveMaskIfNeeded(
    UIView *originalBar,
    UITabBar *nativeBar,
    id<UIViewControllerTransitionCoordinator> coordinator) {

    if (!coordinator || !coordinator.isInteractive ||
        !originalBar || !nativeBar) {
        return;
    }

    if (gAWEBarVisibilityCoordinator == coordinator &&
        gAWEBarTransitionMaskMode != AWEBarTransitionMaskModeNone) {
        return;
    }

    BOOL fromVisible = gAWEBarStableStateInitialized
        ? gAWEBarStableVisible
        : AWEOriginalBarSteadyWantsVisible(originalBar);

    AWEBarTransitionMaskMode mode = AWEBarTransitionMaskModeNone;

    /*
     Key signal found in the chat log:
       steady chat page       original hidden=YES
       interactive return     original hidden=NO
     Douyin also toggles alpha independently and can leave it at zero well
     after completion, so hidden alone is used for the transition direction.
    */
    if (!fromVisible && !originalBar.hidden) {
        mode = AWEBarTransitionMaskModeReveal;
    } else if (fromVisible && originalBar.hidden) {
        mode = AWEBarTransitionMaskModeHide;
    }

    /*
     Do not register a coordinator while its target is still ambiguous.
     A later original setHidden:/setAlpha: callback will retry after Douyin
     publishes the transition state.
    */
    if (mode == AWEBarTransitionMaskModeNone) return;

    gAWEBarVisibilityCoordinator = coordinator;
    gAWEBarTransitionMaskMode = mode;
    gAWEBarTransitionFromVisible = fromVisible;

    if (![objc_getAssociatedObject((id)coordinator,
                                   &kAWEVisibilityCoordinatorRegistrationKey)
            boolValue]) {
        objc_setAssociatedObject((id)coordinator,
                                 &kAWEVisibilityCoordinatorRegistrationKey,
                                 @YES,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        __weak UIView *weakOriginal = originalBar;
        __weak UITabBar *weakNative = nativeBar;
        __weak id<UIViewControllerTransitionCoordinator> weakCoordinator =
            coordinator;
        AWEBarTransitionMaskMode capturedMode = mode;
        BOOL capturedFromVisible = fromVisible;

        [coordinator
            animateAlongsideTransition:nil
            completion:^(
                id<UIViewControllerTransitionCoordinatorContext> context) {
                UIView *strongOriginal = weakOriginal;
                UITabBar *strongNative = weakNative;
                id<UIViewControllerTransitionCoordinator> strongCoordinator =
                    weakCoordinator;
                if (!strongNative) return;

                AWEFinishBarTransition(context,
                                       strongOriginal,
                                       strongNative,
                                       capturedMode,
                                       capturedFromVisible,
                                       strongCoordinator);
            }];
    }

    AWETransitionLog(@"INTERACTIVE_MASK_BEGIN mode=%ld fromVisible=%d "
                     "original(h=%d,a=%.3f)",
                     (long)mode,
                     fromVisible,
                     originalBar.hidden,
                     originalBar.alpha);
}

static void AWEUpdateNativeBarVisibility(UIView *originalBar,
                                         UITabBar *nativeBar,
                                         NSString *reason) {
    if (!originalBar || !nativeBar) return;

    id<UIViewControllerTransitionCoordinator> coordinator =
        AWECurrentBarTransitionCoordinator();

    if (coordinator && coordinator.isInteractive) {
        AWEConfigureInteractiveMaskIfNeeded(originalBar,
                                            nativeBar,
                                            coordinator);

        if (gAWEBarVisibilityCoordinator == coordinator &&
            gAWEBarTransitionMaskMode != AWEBarTransitionMaskModeNone) {
            CGFloat progress =
                MIN(MAX(coordinator.percentComplete, 0.0), 1.0);
            CGFloat fraction =
                gAWEBarTransitionMaskMode ==
                    AWEBarTransitionMaskModeReveal
                    ? progress
                    : 1.0 - progress;

            AWEApplyNativeBarVisibleFraction(nativeBar,
                                             fraction,
                                             reason ?: @"interactive.tick");
            return;
        }

        /*
         The coordinator exists but Douyin has not published a clear target
         yet. Preserve the settled state instead of guessing.
        */
        BOOL settled = gAWEBarStableStateInitialized
            ? gAWEBarStableVisible
            : AWEOriginalBarSteadyWantsVisible(originalBar);
        AWEApplyNativeBarVisibleFraction(nativeBar,
                                         settled ? 1.0 : 0.0,
                                         @"interactive.awaiting-signal");
        return;
    }

    if (gAWEBarTransitionMaskMode != AWEBarTransitionMaskModeNone &&
        gAWEBarVisibilityCoordinator) {
        /*
         Completion normally clears this state. If a private transition ends
         without invoking the public completion callback, settle from the
         original bar's final state rather than leaving a partial mask.
        */
        BOOL visible = AWEOriginalBarSteadyWantsVisible(originalBar);
        gAWEBarStableStateInitialized = YES;
        gAWEBarStableVisible = visible;
        gAWEBarTransitionMaskMode = AWEBarTransitionMaskModeNone;
        gAWEBarVisibilityCoordinator = nil;
        AWEApplyNativeBarVisibleFraction(nativeBar,
                                         visible ? 1.0 : 0.0,
                                         @"coordinator.disappeared");
        return;
    }

    BOOL visible = AWEOriginalBarSteadyWantsVisible(originalBar);
    gAWEBarStableStateInitialized = YES;
    gAWEBarStableVisible = visible;
    AWEApplyNativeBarVisibleFraction(nativeBar,
                                     visible ? 1.0 : 0.0,
                                     reason ?: @"steady.original-state");
}

@interface AWEBarVisibilityDisplayDriver : NSObject
@property(nonatomic, strong) CADisplayLink *displayLink;
@property(nonatomic, assign) CFTimeInterval idleDeadline;
+ (instancetype)sharedDriver;
- (void)start;
@end

@implementation AWEBarVisibilityDisplayDriver

+ (instancetype)sharedDriver {
    static AWEBarVisibilityDisplayDriver *driver = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        driver = [AWEBarVisibilityDisplayDriver new];
    });
    return driver;
}

- (void)start {
    self.idleDeadline = CACurrentMediaTime() + 0.75;
    if (self.displayLink) return;

    self.displayLink =
        [CADisplayLink displayLinkWithTarget:self
                                    selector:@selector(tick:)];
    self.displayLink.preferredFramesPerSecond = 60;
    [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop
                           forMode:NSRunLoopCommonModes];
}

- (void)tick:(CADisplayLink *)displayLink {
    (void)displayLink;

    UIView *originalBar = (UIView *)gAWELastTabBar;
    if (originalBar && AWEAlbumMorphStyleEnabled() &&
        gAWEAlbumMorphController && gAWEAlbumMorphOverlayWindow) {
        AWEUpdateAlbumMorphVisibility(originalBar, @"display-link");
    } else {
        UITabBar *nativeBar = originalBar
            ? objc_getAssociatedObject(originalBar, &kAWENativeBarKey)
            : nil;
        if (originalBar && nativeBar) {
            AWEUpdateNativeBarVisibility(originalBar,
                                         nativeBar,
                                         @"display-link");
        }
    }

    id<UIViewControllerTransitionCoordinator> coordinator =
        AWECurrentBarTransitionCoordinator();
    if (coordinator && coordinator.isInteractive) {
        self.idleDeadline = CACurrentMediaTime() + 0.75;
        return;
    }

    if (CACurrentMediaTime() >= self.idleDeadline &&
        gAWEBarTransitionMaskMode == AWEBarTransitionMaskModeNone) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

@end

static void AWEStartBarVisibilityDriver(void) {
    if (!AWEPluginFeaturesEnabled()) return;
    [[AWEBarVisibilityDisplayDriver sharedDriver] start];
}

#pragma mark - 0.0.20a hierarchy / carrier probe

static CGRect AWEProbeFrameInWindow(UIView *view) {
    if (!view || !view.window) return CGRectNull;

    @try {
        return [view convertRect:view.bounds toView:view.window];
    } @catch (__unused NSException *exception) {
        return CGRectNull;
    }
}

static NSString *AWEProbeAffineDescription(CGAffineTransform transform) {
    return [NSString stringWithFormat:
        @"{%.3f,%.3f,%.3f,%.3f,%.2f,%.2f}",
        transform.a,
        transform.b,
        transform.c,
        transform.d,
        transform.tx,
        transform.ty];
}

static NSString *AWEProbeCompactViewState(UIView *view) {
    if (!view) return @"<nil>";

    UIView *superview = view.superview;
    NSUInteger index = superview
        ? [superview.subviews indexOfObjectIdenticalTo:view]
        : NSNotFound;

    CGRect windowFrame = AWEProbeFrameInWindow(view);
    CALayer *presentation = (CALayer *)view.layer.presentationLayer;

    CGRect presentationFrame = presentation
        ? presentation.frame
        : CGRectNull;
    CGFloat presentationOpacity = presentation
        ? presentation.opacity
        : -1.0;
    CGAffineTransform presentationTransform = presentation
        ? [presentation affineTransform]
        : CGAffineTransformIdentity;

    return [NSString stringWithFormat:
        @"%@/%p idx=%@ h=%d a=%.3f op=%.3f f=%@ wf=%@ t=%@ "
         "pf=%@ pop=%.3f pt=%@ super=%@/%p win=%@/%p",
        NSStringFromClass(view.class),
        (__bridge void *)view,
        index == NSNotFound
            ? @"-"
            : [NSString stringWithFormat:@"%lu", (unsigned long)index],
        view.hidden,
        view.alpha,
        view.layer.opacity,
        NSStringFromCGRect(view.frame),
        NSStringFromCGRect(windowFrame),
        AWEProbeAffineDescription(view.transform),
        NSStringFromCGRect(presentationFrame),
        presentationOpacity,
        AWEProbeAffineDescription(presentationTransform),
        superview ? NSStringFromClass(superview.class) : @"nil",
        (__bridge void *)superview,
        view.window ? NSStringFromClass(view.window.class) : @"nil",
        (__bridge void *)view.window];
}

static NSString *AWEProbeAncestorChain(UIView *view) {
    if (!view) return @"<nil>";

    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    UIView *current = view;

    for (NSUInteger depth = 0; current && depth < 18; depth++) {
        [parts addObject:[NSString stringWithFormat:
            @"[%lu] %@",
            (unsigned long)depth,
            AWEProbeCompactViewState(current)]];
        current = current.superview;
    }

    return [parts componentsJoinedByString:@" || "];
}

static void AWEProbeCollectUIKitBarCandidates(UIView *root,
                                               NSMutableArray<UIView *> *out,
                                               NSUInteger depth) {
    if (!root || depth > 24 || out.count >= 40) return;

    NSString *className = NSStringFromClass(root.class);
    BOOL isWrapper =
        [className containsString:@"TabBarContainerWrapperView"];
    BOOL isUIKitBar = [root isKindOfClass:[UITabBar class]];

    if (isWrapper || isUIKitBar) {
        [out addObject:root];
    }

    for (UIView *subview in root.subviews) {
        AWEProbeCollectUIKitBarCandidates(subview, out, depth + 1);
        if (out.count >= 40) break;
    }
}

static NSString *AWEProbeUIKitCandidateSummary(UIWindow *window) {
    if (!window) return @"<no-window>";

    NSMutableArray<UIView *> *candidates = [NSMutableArray array];
    AWEProbeCollectUIKitBarCandidates(window, candidates, 0);

    if (candidates.count == 0) {
        return @"<none>";
    }

    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (NSUInteger index = 0; index < candidates.count; index++) {
        [parts addObject:[NSString stringWithFormat:
            @"[%lu] %@",
            (unsigned long)index,
            AWEProbeCompactViewState(candidates[index])]];
    }

    return [parts componentsJoinedByString:@" || "];
}

static NSString *AWEProbeSiblingStack(UIView *view) {
    UIView *host = view.superview;
    if (!host) return @"<no-host>";

    NSArray<UIView *> *siblings = host.subviews;
    NSMutableArray<NSString *> *parts = [NSMutableArray array];

    NSUInteger count = MIN((NSUInteger)32, siblings.count);
    for (NSUInteger index = 0; index < count; index++) {
        UIView *candidate = siblings[index];
        NSString *marker = candidate == view ? @"ORIGINAL" : @"";

        UITabBar *nativeBar = view
            ? objc_getAssociatedObject(view, &kAWENativeBarKey)
            : nil;
        if (candidate == nativeBar) marker = @"NATIVE";

        [parts addObject:[NSString stringWithFormat:
            @"[%lu %@] %@",
            (unsigned long)index,
            marker,
            AWEProbeCompactViewState(candidate)]];
    }

    if (siblings.count > count) {
        [parts addObject:[NSString stringWithFormat:
            @"... %lu more siblings",
            (unsigned long)(siblings.count - count)]];
    }

    return [parts componentsJoinedByString:@" || "];
}

static NSString *AWEProbeInteractiveGestureSummary(UIViewController *controller) {
    UIViewController *current = controller;
    if (!current) {
        UIWindow *window = gAWELastTabBar.window ?: AWEActiveMainWindow();
        current = window.rootViewController;
    }

    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    NSMutableArray<UIViewController *> *queue = [NSMutableArray array];
    if (current) [queue addObject:current];

    NSUInteger index = 0;
    while (index < queue.count && index < 32) {
        UIViewController *candidate = queue[index++];

        if ([candidate isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigation =
                (UINavigationController *)candidate;
            UIGestureRecognizer *gesture =
                navigation.interactivePopGestureRecognizer;

            if (gesture) {
                CGPoint translation = CGPointZero;
                CGPoint velocity = CGPointZero;

                if ([gesture isKindOfClass:[UIPanGestureRecognizer class]]) {
                    UIPanGestureRecognizer *pan =
                        (UIPanGestureRecognizer *)gesture;
                    translation = [pan translationInView:pan.view];
                    velocity = [pan velocityInView:pan.view];
                }

                [parts addObject:[NSString stringWithFormat:
                    @"nav=%@/%p gesture=%@/%p state=%ld enabled=%d "
                     "translation=%@ velocity=%@",
                    NSStringFromClass(navigation.class),
                    (__bridge void *)navigation,
                    NSStringFromClass(gesture.class),
                    (__bridge void *)gesture,
                    (long)gesture.state,
                    gesture.enabled,
                    NSStringFromCGPoint(translation),
                    NSStringFromCGPoint(velocity)]];
            }
        }

        if (candidate.presentedViewController &&
            !candidate.presentedViewController.isBeingDismissed) {
            [queue addObject:candidate.presentedViewController];
        }

        for (UIViewController *child in candidate.childViewControllers) {
            if (child) [queue addObject:child];
        }
    }

    return parts.count > 0
        ? [parts componentsJoinedByString:@" || "]
        : @"<none>";
}

static void AWEProbeLogExpandedSnapshot(NSString *event,
                                        UIViewController *controller,
                                        BOOL force) {
    if (!gAWETransitionDiagnosticsEnabled) return;

    AWENormalModeTabBar *original = gAWELastTabBar;
    if (!original) return;

    UITabBar *nativeBar =
        objc_getAssociatedObject((UIView *)original, &kAWENativeBarKey);
    UIWindow *window = original.window ?: nativeBar.window ?:
                       controller.viewIfLoaded.window ?:
                       AWEActiveMainWindow();

    NSString *originalChain =
        AWEProbeAncestorChain((UIView *)original);
    NSString *nativeChain =
        AWEProbeAncestorChain(nativeBar);
    NSString *candidates =
        AWEProbeUIKitCandidateSummary(window);
    NSString *siblings =
        AWEProbeSiblingStack((UIView *)original);
    NSString *gesture =
        AWEProbeInteractiveGestureSummary(controller);

    NSString *route = [NSString stringWithFormat:
        @"search=%d userDetail=%d sensitive=%d commerce=%d "
         "prewarm=%d revealGrace=%d",
        AWEShouldSuppressBarForSearch(),
        AWEShouldSuppressBarForUserDetailRoute(),
        AWEShouldSuppressBarForSensitiveDestination(),
        AWEShouldSuppressBarForCommerceProductDetail(),
        AWETransitionPrewarmIsActive(),
        AWEReturnRevealGraceIsActive()];

    NSString *signature = [NSString stringWithFormat:
        @"%@|%@|%@|%@|%@|%@",
        originalChain,
        nativeChain,
        candidates,
        siblings,
        gesture,
        route];

    if (!force &&
        [gAWEProbeLastHierarchySignature isEqualToString:signature]) {
        return;
    }

    gAWEProbeLastHierarchySignature = signature;

    AWETransitionLog(
        @"PROBE event=%@ sourceVC=%@/%p route={%@}\n"
         "  ORIGINAL_CHAIN: %@\n"
         "  NATIVE_CHAIN: %@\n"
         "  UIKIT_CANDIDATES: %@\n"
         "  ORIGINAL_HOST_SIBLINGS: %@\n"
         "  INTERACTIVE_GESTURES: %@",
        event ?: @"unknown",
        controller ? NSStringFromClass(controller.class) : @"nil",
        (__bridge void *)controller,
        route,
        originalChain,
        nativeChain,
        candidates,
        siblings,
        gesture);
}

@interface AWEWrapperProbeSampler : NSObject
@property(nonatomic, strong) CADisplayLink *displayLink;
@property(nonatomic, weak) UIViewController *sourceController;
@property(nonatomic, copy) NSString *reason;
@property(nonatomic, assign) CFTimeInterval deadline;
+ (instancetype)sharedSampler;
- (void)startWithReason:(NSString *)reason
             controller:(UIViewController *)controller;
@end

@implementation AWEWrapperProbeSampler

+ (instancetype)sharedSampler {
    static AWEWrapperProbeSampler *sampler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sampler = [AWEWrapperProbeSampler new];
    });
    return sampler;
}

- (void)startWithReason:(NSString *)reason
             controller:(UIViewController *)controller {
    self.reason = reason ?: @"transition";
    self.sourceController = controller;
    self.deadline = CACurrentMediaTime() + 6.0;

    if (!self.displayLink) {
        self.displayLink =
            [CADisplayLink displayLinkWithTarget:self
                                         selector:@selector(probeTick:)];
        self.displayLink.preferredFramesPerSecond = 20;
        [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop
                               forMode:NSRunLoopCommonModes];
    }

    self.displayLink.paused = NO;
    AWEProbeLogExpandedSnapshot(
        [NSString stringWithFormat:@"sample.begin.%@", self.reason],
        controller,
        YES);
}

- (void)probeTick:(CADisplayLink *)displayLink {
    if (CACurrentMediaTime() > self.deadline) {
        displayLink.paused = YES;
        AWEProbeLogExpandedSnapshot(
            [NSString stringWithFormat:@"sample.end.%@", self.reason],
            self.sourceController,
            YES);
        return;
    }

    AWEProbeLogExpandedSnapshot(
        [NSString stringWithFormat:@"sample.%@", self.reason],
        self.sourceController,
        NO);
}

@end

static void AWEProbeStartSampling(NSString *reason,
                                  UIViewController *controller) {
    if (!gAWETransitionDiagnosticsEnabled) return;
    [[AWEWrapperProbeSampler sharedSampler]
        startWithReason:reason
             controller:controller];
}


#pragma mark - 0.0.20a manual transition-surface probe

static BOOL AWETransitionSurfaceClassIsInteresting(NSString *className) {
    if (className.length == 0) return NO;

    static NSArray<NSString *> *tokens = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tokens = @[
            @"Transition", @"Container", @"Wrapper", @"Navigation",
            @"Drawer", @"Sliding", @"Slide", @"Side", @"Panel",
            @"Presentation", @"Dimming", @"Shadow", @"Mask",
            @"Root", @"TabBar", @"Window", @"Sheet"
        ];
    });

    for (NSString *token in tokens) {
        if ([className rangeOfString:token
                            options:NSCaseInsensitiveSearch].location !=
            NSNotFound) {
            return YES;
        }
    }
    return NO;
}

static NSString *AWETransitionSurfaceLayerDescription(UIView *view) {
    if (!view) return @"<nil>";

    CALayer *presentation = (CALayer *)view.layer.presentationLayer;
    CGRect presentationFrame =
        presentation ? presentation.frame : view.layer.frame;
    CATransform3D presentationTransform =
        presentation ? presentation.transform : view.layer.transform;

    CGRect windowFrame = AWEProbeFrameInWindow(view);
    UIView *superview = view.superview;
    NSUInteger index = superview ?
        [superview.subviews indexOfObjectIdenticalTo:view] : NSNotFound;

    return [NSString stringWithFormat:
        @"%@/%p idx=%@ h=%d a=%.3f clips=%d "
         @"f=%@ wf=%@ t=%@ "
         @"pf=%@ pt={%.3f,%.3f,%.3f,%.3f,%.2f,%.2f} "
         @"super=%@/%p",
        NSStringFromClass(view.class),
        (__bridge void *)view,
        index == NSNotFound ? @"-" :
            [NSString stringWithFormat:@"%lu", (unsigned long)index],
        view.hidden,
        view.alpha,
        view.clipsToBounds,
        NSStringFromCGRect(view.frame),
        NSStringFromCGRect(windowFrame),
        AWEProbeAffineDescription(view.transform),
        NSStringFromCGRect(presentationFrame),
        presentationTransform.m11,
        presentationTransform.m12,
        presentationTransform.m21,
        presentationTransform.m22,
        presentationTransform.m41,
        presentationTransform.m42,
        superview ? NSStringFromClass(superview.class) : @"<nil>",
        (__bridge void *)superview];
}

static void AWETransitionSurfaceCollectViews(UIView *root,
                                             NSMutableArray<UIView *> *output,
                                             NSUInteger depth,
                                             NSUInteger *visited) {
    if (!root || !output || !visited ||
        depth > 12 || output.count >= 90 || *visited >= 1200) {
        return;
    }

    (*visited)++;

    NSString *className = NSStringFromClass(root.class);
    if (depth <= 1 || AWETransitionSurfaceClassIsInteresting(className)) {
        [output addObject:root];
        if (output.count >= 90) return;
    }

    for (UIView *child in root.subviews) {
        AWETransitionSurfaceCollectViews(child,
                                         output,
                                         depth + 1,
                                         visited);
        if (output.count >= 90 || *visited >= 1200) break;
    }
}

static NSString *AWETransitionSurfaceHitChain(UIWindow *window,
                                              CGPoint point) {
    if (!window) return @"<nil-window>";

    UIView *hit = nil;
    @try {
        hit = [window hitTest:point withEvent:nil];
    } @catch (__unused NSException *exception) {
        hit = nil;
    }

    if (!hit) return @"<none>";

    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    UIView *current = hit;
    NSUInteger depth = 0;
    while (current && depth < 7) {
        [parts addObject:[NSString stringWithFormat:@"%@/%p",
            NSStringFromClass(current.class),
            (__bridge void *)current]];
        current = current.superview;
        depth++;
    }

    return [parts componentsJoinedByString:@" <- "];
}

static NSString *AWETransitionSurfaceWindowSummary(UIWindow *window) {
    if (!window) return @"<nil>";

    NSMutableArray<UIView *> *candidates = [NSMutableArray array];
    NSUInteger visited = 0;
    AWETransitionSurfaceCollectViews(window, candidates, 0, &visited);

    NSMutableArray<NSString *> *candidateParts = [NSMutableArray array];
    for (UIView *view in candidates) {
        [candidateParts addObject:
            AWETransitionSurfaceLayerDescription(view)];
    }

    CGFloat width = CGRectGetWidth(window.bounds);
    CGFloat height = CGRectGetHeight(window.bounds);
    CGFloat y = MAX(0.0, height - 44.0);
    NSArray<NSNumber *> *fractions = @[@0.05, @0.25, @0.50, @0.75, @0.95];
    NSMutableArray<NSString *> *hits = [NSMutableArray array];

    for (NSNumber *fraction in fractions) {
        CGFloat x = width * fraction.doubleValue;
        CGPoint point = CGPointMake(x, y);
        [hits addObject:[NSString stringWithFormat:
            @"(%.0f,%.0f)=%@",
            point.x,
            point.y,
            AWETransitionSurfaceHitChain(window, point)]];
    }

    UIViewController *root = window.rootViewController;
    UIViewController *top = AWETopViewControllerFrom(root);

    UINavigationController *navigation = nil;
    if ([top isKindOfClass:[UINavigationController class]]) {
        navigation = (UINavigationController *)top;
    } else {
        navigation = top.navigationController;
    }

    UIGestureRecognizer *popGesture =
        navigation.interactivePopGestureRecognizer;
    CGPoint popTranslation = CGPointZero;
    CGPoint popVelocity = CGPointZero;
    if ([popGesture isKindOfClass:[UIPanGestureRecognizer class]]) {
        UIPanGestureRecognizer *pan = (UIPanGestureRecognizer *)popGesture;
        popTranslation = [pan translationInView:window];
        popVelocity = [pan velocityInView:window];
    }

    id<UIViewControllerTransitionCoordinator> coordinator =
        top.transitionCoordinator ?: navigation.transitionCoordinator;
    NSString *transition = coordinator ?
        [NSString stringWithFormat:
            @"animated=%d interactive=%d initiallyInteractive=%d "
             @"cancelled=%d percent=%.4f duration=%.4f "
             @"container=%@/%p",
            coordinator.isAnimated,
            coordinator.isInteractive,
            coordinator.initiallyInteractive,
            coordinator.isCancelled,
            coordinator.percentComplete,
            coordinator.transitionDuration,
            coordinator.containerView ?
                NSStringFromClass(coordinator.containerView.class) : @"<nil>",
            (__bridge void *)(coordinator.containerView)] :
        @"<none>";

    NSString *pop = popGesture ?
        [NSString stringWithFormat:
            @"%@/%p state=%ld enabled=%d translation=%@ velocity=%@",
            NSStringFromClass(popGesture.class),
            (__bridge void *)popGesture,
            (long)popGesture.state,
            popGesture.enabled,
            NSStringFromCGPoint(popTranslation),
            NSStringFromCGPoint(popVelocity)] :
        @"<none>";

    return [NSString stringWithFormat:
        @"WINDOW %@/%p level=%.1f key=%d h=%d a=%.3f "
         @"f=%@ root=%@/%p top=%@/%p\n"
         @"    TRANSITION: %@\n"
         @"    POP_GESTURE: %@\n"
         @"    SURFACES: %@\n"
         @"    BOTTOM_HITS: %@",
        NSStringFromClass(window.class),
        (__bridge void *)window,
        window.windowLevel,
        window.isKeyWindow,
        window.hidden,
        window.alpha,
        NSStringFromCGRect(window.frame),
        root ? NSStringFromClass(root.class) : @"<nil>",
        (__bridge void *)root,
        top ? NSStringFromClass(top.class) : @"<nil>",
        (__bridge void *)top,
        transition,
        pop,
        [candidateParts componentsJoinedByString:@" || "],
        [hits componentsJoinedByString:@" || "]];
}

static NSString *AWETransitionSurfaceSnapshotText(void) {
    UIApplication *application = UIApplication.sharedApplication;
    NSArray<UIWindow *> *windows = application.windows ?: @[];

    NSArray<UIWindow *> *sorted =
        [windows sortedArrayUsingComparator:
            ^NSComparisonResult(UIWindow *left, UIWindow *right) {
                if (left.windowLevel < right.windowLevel) {
                    return NSOrderedAscending;
                }
                if (left.windowLevel > right.windowLevel) {
                    return NSOrderedDescending;
                }
                return NSOrderedSame;
            }];

    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (UIWindow *window in sorted) {
        if (window.hidden && window.alpha <= 0.001) continue;
        [parts addObject:AWETransitionSurfaceWindowSummary(window)];
    }

    AWENormalModeTabBar *original = gAWELastTabBar;
    UITabBar *nativeBar = original ?
        objc_getAssociatedObject((UIView *)original, &kAWENativeBarKey) : nil;

    NSString *barState = [NSString stringWithFormat:
        @"BAR original={%@} native={%@}",
        AWETransitionSurfaceLayerDescription((UIView *)original),
        AWETransitionSurfaceLayerDescription(nativeBar)];

    return [NSString stringWithFormat:@"%@\n%@",
        barState,
        [parts componentsJoinedByString:@"\n"]];
}

static void AWETransitionSurfaceLogSnapshot(NSString *event, BOOL force) {
    if (!gAWETransitionDiagnosticsEnabled) return;

    NSString *snapshot = AWETransitionSurfaceSnapshotText();
    if (!force &&
        [gAWETransitionSurfaceLastSignature isEqualToString:snapshot]) {
        return;
    }

    gAWETransitionSurfaceLastSignature = snapshot;
    AWETransitionLog(@"SURFACE_PROBE event=%@\n%@",
                     event ?: @"tick",
                     snapshot);
}

@interface AWETransitionSurfaceSampler : NSObject
@property(nonatomic, strong) CADisplayLink *displayLink;
@property(nonatomic, copy) NSString *reason;
@property(nonatomic, assign) CFTimeInterval deadline;
+ (instancetype)sharedSampler;
- (void)startWithReason:(NSString *)reason;
@end

@implementation AWETransitionSurfaceSampler

+ (instancetype)sharedSampler {
    static AWETransitionSurfaceSampler *sampler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sampler = [AWETransitionSurfaceSampler new];
    });
    return sampler;
}

- (void)startWithReason:(NSString *)reason {
    self.reason = reason.length > 0 ? reason : @"manual";
    self.deadline = CACurrentMediaTime() + 14.0;
    gAWETransitionSurfaceLastSignature = nil;

    if (!self.displayLink) {
        self.displayLink =
            [CADisplayLink displayLinkWithTarget:self
                                         selector:@selector(probeTick:)];
        self.displayLink.preferredFramesPerSecond = 20;
        [self.displayLink addToRunLoop:NSRunLoop.mainRunLoop
                               forMode:NSRunLoopCommonModes];
    }

    self.displayLink.paused = NO;
    AWETransitionSurfaceLogSnapshot(
        [NSString stringWithFormat:@"begin.%@", self.reason],
        YES);
}

- (void)probeTick:(CADisplayLink *)displayLink {
    if (CACurrentMediaTime() > self.deadline) {
        displayLink.paused = YES;
        AWETransitionSurfaceLogSnapshot(
            [NSString stringWithFormat:@"end.%@", self.reason],
            YES);
        return;
    }

    AWETransitionSurfaceLogSnapshot(
        [NSString stringWithFormat:@"tick.%@", self.reason],
        NO);
}

@end

static void AWETransitionSurfaceProbeStart(NSString *reason) { (void)reason; }

static BOOL AWEControllerShouldBeginReturnPrewarm(UIViewController *controller) {
    if (!controller || !gAWELastTabBar) return NO;

    NSString *className = NSStringFromClass(controller.class);
    if (AWEClassNameIsSensitiveDestination(className)) {
        return YES;
    }

    BOOL isLeavingHierarchy =
        controller.isMovingFromParentViewController ||
        controller.isBeingDismissed;

    return isLeavingHierarchy && AWECurrentRouteSuppressesBar();
}

static void AWEFinishReturnPrewarm(NSUInteger generation, BOOL cancelled) {
    if (generation != gAWETransitionPrewarmGeneration) return;

    gAWETransitionPrewarmUntil = 0.0;

    if (cancelled) {
        gAWEReturnRevealGraceUntil = 0.0;
        if (gAWELastTabBar) {
            AWEAttachNativeBarWithForce((UIView *)gAWELastTabBar, NO);
        }
        return;
    }

    /*
     Keep the bar at the already-revealed cached frame while Douyin restores
     its original tab-bar flags/geometry. This grace period prevents a
     completed pop from briefly parking and recreating the visible bar.
    */
    gAWEReturnRevealGraceUntil = CACurrentMediaTime() + 0.65;
    if (gAWELastTabBar) {
        AWEAttachNativeBarWithForce((UIView *)gAWELastTabBar, YES);
    }
    AWEScheduleTransitionRecovery();
}

static void AWEBeginReturnPrewarm(UIViewController *controller) {
    /* 1.0.55a: viewWillDisappear is emitted by many nested feed controllers
       during ordinary paging and settings teardown. Prewarming on every one
       caused the resident bottom bar to oscillate 0 -> 1 hundreds of times,
       which also exposed a one-frame caption/safe-area drop. Only genuine
       return transitions need this path; the helper above already encodes
       that condition. */
    if (!AWEControllerShouldBeginReturnPrewarm(controller)) return;
    /*
     Preserve the verified 1.0.10b invariant for both implementations: the
     glass object already exists before the return transition starts and only
     its mask changes.  The coordinator becomes observable after UIKit begins
     the pop/dismiss, so the display driver performs the progress follow-up.
    */
    gAWETransitionPrewarmUntil = 0.0;
    gAWEReturnRevealGraceUntil = 0.0;
    if (!gAWELastTabBar) return;

    AWEAttachNativeBarWithForce((UIView *)gAWELastTabBar, NO);
    if (AWEAlbumMorphStyleEnabled() && gAWEAlbumMorphController) {
        AWEApplyAlbumMorphVisibleFraction(
            0.0, @"return.prewarm.resident", NO);
    }
    AWEStartBarVisibilityDriver();
}


#pragma mark - Safe original-button routing

static Ivar AWEFindIvar(Class cls, const char *preferredName, const char *typePrefix) {
    for (Class current = cls; current; current = class_getSuperclass(current)) {
        unsigned int count = 0;
        Ivar *ivars = class_copyIvarList(current, &count);
        Ivar found = NULL;

        for (unsigned int index = 0; index < count; index++) {
            const char *name = ivar_getName(ivars[index]);
            const char *type = ivar_getTypeEncoding(ivars[index]);

            if (preferredName && name && strcmp(name, preferredName) == 0) {
                found = ivars[index];
                break;
            }
            if (!preferredName && typePrefix && type &&
                strncmp(type, typePrefix, strlen(typePrefix)) == 0) {
                found = ivars[index];
                break;
            }
        }

        free(ivars);
        if (found) return found;
    }
    return NULL;
}

static id AWEObjectIvar(id object, const char *name) {
    if (!object) return nil;
    Ivar ivar = AWEFindIvar(object_getClass(object), name, "@");
    return ivar ? object_getIvar(object, ivar) : nil;
}

static SEL AWESelectorIvar(id object, const char *name) {
    if (!object) return NULL;
    Ivar ivar = AWEFindIvar(object_getClass(object), name, ":");
    if (!ivar) return NULL;

    ptrdiff_t offset = ivar_getOffset(ivar);
    uint8_t *bytes = (uint8_t *)(__bridge void *)object;
    return *(SEL *)(bytes + offset);
}


static BOOL AWESetIntegerIvar(id object, const char *name, NSInteger value,
                              NSInteger *oldValue) {
    if (!object) return NO;
    Ivar ivar = AWEFindIvar(object_getClass(object), name, NULL);
    if (!ivar) return NO;

    const char *type = ivar_getTypeEncoding(ivar);
    if (!type || (type[0] != 'q' && type[0] != 'i' && type[0] != 'l')) {
        return NO;
    }

    ptrdiff_t offset = ivar_getOffset(ivar);
    uint8_t *bytes = (uint8_t *)(__bridge void *)object;

    if (type[0] == 'q') {
        NSInteger *slot = (NSInteger *)(bytes + offset);
        if (oldValue) *oldValue = *slot;
        *slot = value;
    } else {
        int *slot = (int *)(bytes + offset);
        if (oldValue) *oldValue = *slot;
        *slot = (int)value;
    }
    return YES;
}

static BOOL AWEInvokeRealTabTapGesture(UIView *buttonView) {
    if (!buttonView) return NO;

    for (UIGestureRecognizer *recognizer in buttonView.gestureRecognizers) {
        NSString *className = NSStringFromClass(recognizer.class);
        if (![className isEqualToString:@"AWENormalModeTabBarButtonTapGesture"]) {
            continue;
        }

        id targetContainers = AWEObjectIvar(recognizer, "_targets");
        if (![targetContainers isKindOfClass:[NSArray class]]) {
            @try {
                targetContainers = [recognizer valueForKey:@"_targets"];
            } @catch (__unused NSException *exception) {
                targetContainers = nil;
            }
        }

        for (id container in (NSArray *)targetContainers) {
            id target = AWEObjectIvar(container, "_target");
            SEL action = AWESelectorIvar(container, "_action");

            if (action != NSSelectorFromString(@"onTouchUpInside:") ||
                !target || ![target respondsToSelector:action]) {
                continue;
            }

            /*
             The handler is normally called after UIKit has moved this custom
             tap recognizer to Ended. A synthetic sendAction while its state is
             Possible is ignored by Douyin, so temporarily present the same
             state to the existing handler and restore it immediately.
             UIGestureRecognizerStateEnded == 3.
            */
            NSInteger oldState = 0;
            BOOL changedState =
                AWESetIntegerIvar(recognizer,
                                 "_state_DO_NOT_USE_DIRECTLY",
                                 UIGestureRecognizerStateEnded,
                                 &oldState);

            BOOL sent = [[UIApplication sharedApplication] sendAction:action
                                                                  to:target
                                                                from:recognizer
                                                            forEvent:nil];

            if (changedState) {
                AWESetIntegerIvar(recognizer,
                                 "_state_DO_NOT_USE_DIRECTLY",
                                 oldState,
                                 NULL);
            }
            return sent;
        }
    }

    return NO;
}

static __attribute__((unused)) BOOL AWEInvokeGestureRecognizer(UIGestureRecognizer *recognizer) {
    if (!recognizer || !recognizer.enabled) return NO;

    id targetContainers = AWEObjectIvar(recognizer, "_targets");
    if (![targetContainers isKindOfClass:[NSArray class]]) {
        @try {
            targetContainers = [recognizer valueForKey:@"_targets"];
        } @catch (__unused NSException *exception) {
            targetContainers = nil;
        }
    }

    if (![targetContainers isKindOfClass:[NSArray class]]) return NO;

    BOOL invoked = NO;
    NSArray *snapshot = [(NSArray *)targetContainers copy];

    for (id container in snapshot) {
        id target = AWEObjectIvar(container, "_target");
        SEL action = AWESelectorIvar(container, "_action");

        if (!target || !action || ![target respondsToSelector:action]) continue;

        BOOL sent = [[UIApplication sharedApplication] sendAction:action
                                                              to:target
                                                            from:recognizer
                                                        forEvent:nil];
        invoked = invoked || sent;
    }

    return invoked;
}

static BOOL AWEInvokeCompatibleTabTapGesture(UIView *buttonView) {
    if (!buttonView) return NO;
    for (UIGestureRecognizer *recognizer in buttonView.gestureRecognizers) {
        NSString *recognizerName = NSStringFromClass(recognizer.class).lowercaseString;
        if ([recognizerName containsString:@"long"] ||
            [recognizerName containsString:@"pan"] ||
            [recognizerName containsString:@"swipe"] ||
            [recognizerName containsString:@"pinch"]) {
            continue;
        }
        BOOL likelyTap = [recognizer isKindOfClass:UITapGestureRecognizer.class] ||
            [recognizerName containsString:@"tap"] ||
            ([recognizerName containsString:@"tab"] &&
             [recognizerName containsString:@"button"]);
        if (!likelyTap) continue;

        id targetContainers = AWEObjectIvar(recognizer, "_targets");
        if (![targetContainers isKindOfClass:NSArray.class]) {
            @try { targetContainers = [recognizer valueForKey:@"_targets"]; }
            @catch (__unused NSException *exception) { targetContainers = nil; }
        }
        for (id container in (NSArray *)targetContainers) {
            id target = AWEObjectIvar(container, "_target");
            SEL action = AWESelectorIvar(container, "_action");
            if (!target || !action || ![target respondsToSelector:action]) continue;
            NSString *actionName = NSStringFromSelector(action).lowercaseString;
            BOOL likelyAction = [actionName containsString:@"tap"] ||
                [actionName containsString:@"click"] ||
                [actionName containsString:@"touchup"] ||
                [actionName containsString:@"select"] ||
                [actionName containsString:@"press"];
            if (!likelyAction || [actionName containsString:@"long"]) continue;

            NSInteger oldState = 0;
            BOOL changedState = AWESetIntegerIvar(
                recognizer, "_state_DO_NOT_USE_DIRECTLY",
                UIGestureRecognizerStateEnded, &oldState);
            BOOL sent = [[UIApplication sharedApplication] sendAction:action
                                                                  to:target
                                                                from:recognizer
                                                            forEvent:nil];
            if (changedState) {
                AWESetIntegerIvar(recognizer, "_state_DO_NOT_USE_DIRECTLY",
                                  oldState, NULL);
            }
            if (sent) {
                AWEInteractionDiagnosticWrite(
                    @"TAB_COMPAT_GESTURE recognizer=%@ action=%@ target=%@",
                    NSStringFromClass(recognizer.class), NSStringFromSelector(action),
                    AWEInteractionObjectSummary(target));
                return YES;
            }
        }
    }
    return NO;
}

static BOOL AWEInvokeRealTabTapGestureInTree(UIView *root, NSUInteger depth) {
    if (!root || depth > 7) return NO;
    if (AWEInvokeRealTabTapGesture(root)) return YES;
    if (AWEInvokeCompatibleTabTapGesture(root)) return YES;
    for (UIView *child in root.subviews) {
        if (AWEInvokeRealTabTapGestureInTree(child, depth + 1)) return YES;
    }
    return NO;
}

static NSArray<UIView *> *AWEFallbackOriginalButtonsFromTabBar(UIView *tabBar) {
    if (!tabBar) return @[];
    NSMutableArray<UIView *> *result = [NSMutableArray array];
    for (UIView *child in tabBar.subviews) {
        NSString *name = NSStringFromClass(child.class);
        if ([name containsString:@"TabBarButton"] ||
            [name containsString:@"NormalModeTabBarButton"]) {
            [result addObject:child];
        }
    }
    [result sortUsingComparator:^NSComparisonResult(UIView *lhs, UIView *rhs) {
        CGFloat lx = CGRectGetMidX(lhs.frame);
        CGFloat rx = CGRectGetMidX(rhs.frame);
        if (lx < rx) return NSOrderedAscending;
        if (lx > rx) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    return result;
}

static BOOL AWEInvokeControllerTabRoute(id controller, NSInteger index) {
    if (!controller || index < 0) return NO;
    NSArray<NSString *> *candidates = @[
        @"selectTabAtIndex:", @"switchToTabAtIndex:", @"selectIndex:",
        @"setSelectedIndex:", @"setCurrentIndex:"
    ];
    for (NSString *name in candidates) {
        SEL selector = NSSelectorFromString(name);
        if (![controller respondsToSelector:selector]) continue;
        NSMethodSignature *signature = [controller methodSignatureForSelector:selector];
        if (!signature || signature.numberOfArguments < 3) continue;
        const char *type = [signature getArgumentTypeAtIndex:2];
        while (type && (*type == 'r' || *type == 'n' || *type == 'N' ||
                        *type == 'o' || *type == 'O' || *type == 'R' || *type == 'V')) type++;
        if (!type || !strchr("qQiIlLsScC", *type)) continue;
        @try {
            ((void (*)(id, SEL, NSInteger))objc_msgSend)(controller, selector, index);
            AWEInteractionDiagnosticWrite(
                @"TAB_CONTROLLER_ROUTE index=%ld selector=%@ controller=%@",
                (long)index, name, AWEInteractionObjectSummary(controller));
            return YES;
        } @catch (__unused NSException *exception) {}
    }
    return NO;
}

static BOOL AWEForwardToOriginalButton(UIView *tabBar, NSInteger index) {
    if (!tabBar || index < 0) return NO;
    id controller = objc_getAssociatedObject(tabBar, &kAWEControllerKey);
    if (!controller) controller = gAWELastController;
    NSArray *buttons = AWEControllerButtons(controller);
    if (buttons.count < 5 && gAWELastController && controller != gAWELastController) {
        controller = gAWELastController;
        buttons = AWEControllerButtons(controller);
    }
    if (buttons.count <= (NSUInteger)index) {
        buttons = AWEFallbackOriginalButtonsFromTabBar(tabBar);
    }

    AWEInteractionDiagnosticWrite(
        @"TAB_FORWARD_BEGIN index=%ld tab=%@ controller=%@ buttons=%lu",
        (long)index, AWEInteractionObjectSummary(tabBar),
        AWEInteractionObjectSummary(controller), (unsigned long)buttons.count);

    if (index >= (NSInteger)buttons.count) {
        AWEInteractionDiagnosticWrite(@"TAB_FORWARD_END index=%ld result=NO reason=no-button",
                                      (long)index);
        return NO;
    }
    id object = buttons[(NSUInteger)index];
    if (![object isKindOfClass:UIView.class]) return NO;
    UIView *buttonView = object;

    if ([buttonView isKindOfClass:UIControl.class]) {
        UIControl *control = (UIControl *)buttonView;
        NSSet *targets = control.allTargets;
        BOOL hasTouchUp = NO;
        BOOL hasPrimary = NO;
        for (id target in targets) {
            hasTouchUp = hasTouchUp ||
                ([control actionsForTarget:target
                           forControlEvent:UIControlEventTouchUpInside].count > 0);
            hasPrimary = hasPrimary ||
                ([control actionsForTarget:target
                           forControlEvent:UIControlEventPrimaryActionTriggered].count > 0);
        }
        UIControlEvents event = hasTouchUp
            ? UIControlEventTouchUpInside
            : (hasPrimary ? UIControlEventPrimaryActionTriggered : 0);
        if (event != 0 || index == 2) {
            if (event == 0) event = UIControlEventTouchUpInside;
            [control sendActionsForControlEvents:event];
            AWEInteractionDiagnosticWrite(
                @"TAB_FORWARD_END index=%ld result=YES path=control event=%@ targetCount=%lu button=%@",
                (long)index,
                event == UIControlEventTouchUpInside ? @"touchUp" : @"primary",
                (unsigned long)targets.count,
                AWEInteractionObjectSummary(buttonView));
            return YES;
        }
    }

    if (index != 2 && AWEInvokeRealTabTapGestureInTree(buttonView, 0)) {
        AWEInteractionDiagnosticWrite(
            @"TAB_FORWARD_END index=%ld result=YES path=gesture-tree button=%@",
            (long)index, AWEInteractionObjectSummary(buttonView));
        return YES;
    }

    BOOL activated = NO;
    @try { activated = [buttonView accessibilityActivate]; }
    @catch (__unused NSException *exception) { activated = NO; }
    if (activated) {
        AWEInteractionDiagnosticWrite(
            @"TAB_FORWARD_END index=%ld result=YES path=accessibility button=%@",
            (long)index, AWEInteractionObjectSummary(buttonView));
        return YES;
    }

    if (index != 2 && AWEInvokeControllerTabRoute(controller, index)) {
        AWEInteractionDiagnosticWrite(
            @"TAB_FORWARD_END index=%ld result=YES path=controller-route controller=%@",
            (long)index, AWEInteractionObjectSummary(controller));
        return YES;
    }

    AWEInteractionDiagnosticWrite(
        @"TAB_FORWARD_END index=%ld result=NO reason=no-route button=%@ recognizers=%lu subviews=%lu",
        (long)index, AWEInteractionObjectSummary(buttonView),
        (unsigned long)buttonView.gestureRecognizers.count,
        (unsigned long)buttonView.subviews.count);
    return NO;
}

@interface AWELiquidBarDelegate : NSObject <UITabBarDelegate>
@property (nonatomic, assign) UIView *tabBar;
@property (nonatomic, assign) BOOL forwarding;
@end

@implementation AWELiquidBarDelegate

- (void)tabBar:(UITabBar *)nativeBar didSelectItem:(UITabBarItem *)item {
    if (self.forwarding || !self.tabBar) return;
    NSInteger index = item.tag;
    AWEUpdateFriendsTabLatch(index);
    self.forwarding = YES;

    BOOL forwarded = AWEForwardToOriginalButton(self.tabBar, index);
    if (!forwarded && gAWELastController) {
        AWENormalModeTabBar *fresh = AWEPrepareBarForController(gAWELastController, NO);
        if (fresh) {
            self.tabBar = (UIView *)fresh;
            forwarded = AWEForwardToOriginalButton((UIView *)fresh, index);
            AWEInteractionDiagnosticWrite(
                @"TAB_FORWARD_REBIND index=%ld fresh=%@ result=%d",
                (long)index, AWEInteractionObjectSummary(fresh), forwarded);
        }
    }

    if (!forwarded) {
        id controller = objc_getAssociatedObject(self.tabBar, &kAWEControllerKey);
        NSArray *buttons = AWEControllerButtons(controller);
        NSInteger selectedIndex = NSNotFound;
        for (NSUInteger i = 0; i < buttons.count; i++) {
            UIView *candidate = [buttons[i] isKindOfClass:UIView.class] ? buttons[i] : nil;
            if (!candidate) continue;
            UIColor *tint = candidate.tintColor;
            if (tint && CGColorGetAlpha(tint.CGColor) > 0.9) {
                selectedIndex = (NSInteger)i;
            }
        }
        if (selectedIndex != NSNotFound) {
            AWESetNativeSelectedIndex(self.tabBar, selectedIndex);
        }
    }
    AWEApplyHomeOnlyGlassStyleToNativeBar(nativeBar);
    self.forwarding = NO;
}

@end

static void AWEInstallDelegateIfNeeded(UIView *tabBar) {
    if (!AWEPluginFeaturesEnabled() || !tabBar) return;
    UITabBar *nativeBar = objc_getAssociatedObject(tabBar, &kAWENativeBarKey);
    if (!nativeBar) return;

    AWELiquidBarDelegate *delegate =
        objc_getAssociatedObject(tabBar, &kAWEDelegateKey);
    if (!delegate) {
        delegate = [AWELiquidBarDelegate new];
        delegate.tabBar = tabBar;
        objc_setAssociatedObject(tabBar, &kAWEDelegateKey, delegate,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    if (nativeBar.delegate != delegate) nativeBar.delegate = delegate;
}



#pragma mark - 0.0.22f native glass buttons + persistent overlays

/*
 0.0.22f keeps the verified 0.0.21d bottom-bar architecture untouched and
 replaces only the experimental home action decoration layer.

 Right action column:
 - Visual slots live on the stable AWEElementStackView instead of inside each
   recycled AWEFeedVideoButton.
 - The native Liquid Glass UIButton now owns touch highlighting and stretch;
   completed taps are forwarded to the original Douyin action view.
 - Douyin's solid PNG is hidden only while the matching slot is bound.
 - Each replacement is a real non-prominent UIKit glass UIButton constrained to
   46 x 46 pt. Clear and regular modes use Apple's native configurations only.
 - No custom material tint, backdrop opacity, border or blur stack is added.
 - Like/favorite selected states keep their configured foreground symbols.

 Top menu/search:
 - AWEFeedTopBarContainer performs a bounded descendant scan after its real
   layout, so first launch and search-return use the final coordinates.
 - Exact classes are preferred; geometric fallbacks cover builds where the
   search wrapper class changes.
*/

static BOOL AWETriggerQuickMenuDestinationView(UIView *target);
static void AWEScheduleHomeActionStackRefresh(UIView *stack);

typedef NS_ENUM(NSInteger, AWEHomeActionKind) {
    AWEHomeActionKindUnknown = 0,
    AWEHomeActionKindLike,
    AWEHomeActionKindComment,
    AWEHomeActionKindFavorite,
    AWEHomeActionKindShare
};

@interface AWEHomeActionSlotView : UIView
@property (nonatomic, weak) UIView *originalView;
@property (nonatomic, weak) UIImageView *sourceImageView;
@property (nonatomic, assign) AWEHomeActionKind actionKind;
@property (nonatomic, strong) AWEPhotosExactGlassButtonHostView *photosGlassHost;
@property (nonatomic, strong) UIButton *systemGlassButton;
@end

@implementation AWEHomeActionSlotView
@end

@interface AWEHomeProfileGlassView : UIView
@property (nonatomic, strong) UIButton *glassButton;
@property (nonatomic, strong) UIButton *menuButton;
@property (nonatomic, weak) UIView *profileHost;
@property (nonatomic, weak) UIImageView *avatarImageView;
@end
@implementation AWEHomeProfileGlassView
@end

@interface AWEExternalBridgeMenuSlotView : UIView
@property(nonatomic, strong) UIButton *menuButton;
@property(nonatomic, weak) UIView *sourceStack;
@end
@implementation AWEExternalBridgeMenuSlotView
@end

/* One process-wide download source. 1.0.51 attached one button per recycled
   AWEElementStackView, which allowed stale/offscreen cells to leave duplicate
   buttons floating over comments or profile pages. */
static AWEExternalBridgeMenuSlotView *gAWEDownloadMenuSlot = nil;
static __weak UIView *gAWEDownloadMenuSourceStack = nil;

/* Short compatibility window after closing comments inside a third-party
   profile-fullscreen feed. During this window, prevent the currently visible
   AWEElementStackView from being hidden/removed a second time by the external
   fullscreen tweak after our normal comment recovery has already completed. */
static CFTimeInterval gAWEProfileFullscreenRightProtectUntil = 0.0;
static __weak UIView *gAWEProfileFullscreenProtectedRightStack = nil;

#pragma mark - Native current-item downloader / quality selection

@interface AWEVideoVariant : NSObject
@property(nonatomic, strong) id sourceModel;
@property(nonatomic, copy) NSString *urlString;
@property(nonatomic, assign) NSInteger sourceIndex;
@property(nonatomic, assign) NSInteger width;
@property(nonatomic, assign) NSInteger height;
@property(nonatomic, assign) NSInteger fps;
@property(nonatomic, assign) long long bitrate;
@property(nonatomic, assign) BOOL h265;
@property(nonatomic, assign) BOOL hdr;
@end
@implementation AWEVideoVariant
@end

static __weak UIView *gAWEDownloadToastView = nil;
static NSUInteger gAWEDownloadToastGeneration = 0;
static CFTimeInterval gAWEPlaybackPreferenceResumeGraceUntil = 0.0;

static id AWESafeValueForKey(id object, NSString *key) {
    if (!object || key.length == 0) return nil;
    if ([object isKindOfClass:NSDictionary.class]) {
        id value = ((NSDictionary *)object)[key];
        return value == NSNull.null ? nil : value;
    }
    @try {
        id value = [object valueForKey:key];
        return value == NSNull.null ? nil : value;
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static id AWEFirstSafeValue(id object, NSArray<NSString *> *keys) {
    for (NSString *key in keys) {
        id value = AWESafeValueForKey(object, key);
        if (value) return value;
    }
    return nil;
}

static NSArray *AWEArrayFromValue(id value) {
    if ([value isKindOfClass:NSArray.class]) return value;
    if ([value isKindOfClass:NSSet.class]) return ((NSSet *)value).allObjects;
    if ([value isKindOfClass:NSOrderedSet.class]) return ((NSOrderedSet *)value).array;
    return nil;
}

static long long AWEInteger64FromValue(id value) {
    if ([value respondsToSelector:@selector(longLongValue)]) {
        return [value longLongValue];
    }
    return 0;
}

static BOOL AWEBoolFromValue(id value) {
    if ([value respondsToSelector:@selector(boolValue)]) return [value boolValue];
    return NO;
}

static NSString *AWEStringFromValue(id value) {
    if ([value isKindOfClass:NSString.class]) return value;
    if ([value isKindOfClass:NSURL.class]) return ((NSURL *)value).absoluteString;
    if ([value respondsToSelector:@selector(stringValue)]) return [value stringValue];
    return nil;
}

static BOOL AWEStringLooksLikeRemoteURL(NSString *string) {
    if (string.length < 8) return NO;
    NSString *lower = string.lowercaseString;
    return [lower hasPrefix:@"http://"] || [lower hasPrefix:@"https://"];
}

static NSString *AWEFirstRemoteURLString(id value, NSUInteger depth) {
    if (!value || depth > 6) return nil;
    if ([value isKindOfClass:NSURL.class]) {
        NSString *string = ((NSURL *)value).absoluteString;
        return AWEStringLooksLikeRemoteURL(string) ? string : nil;
    }
    if ([value isKindOfClass:NSString.class]) {
        NSString *string = (NSString *)value;
        return AWEStringLooksLikeRemoteURL(string) ? string : nil;
    }
    if ([value isKindOfClass:NSArray.class] ||
        [value isKindOfClass:NSOrderedSet.class] ||
        [value isKindOfClass:NSSet.class]) {
        for (id child in AWEArrayFromValue(value)) {
            NSString *string = AWEFirstRemoteURLString(child, depth + 1);
            if (string.length) return string;
        }
        return nil;
    }
    NSArray<NSString *> *keys = @[
        @"originURLList", @"urlList", @"URLList", @"urls",
        @"playURL", @"playAddr", @"downloadURL", @"downloadAddr",
        @"mainURL", @"url", @"URL"
    ];
    for (NSString *key in keys) {
        id child = AWESafeValueForKey(value, key);
        if (!child || child == value) continue;
        NSString *string = AWEFirstRemoteURLString(child, depth + 1);
        if (string.length) return string;
    }
    return nil;
}

static NSString *AWEJoinedVariantMetadata(id model) {
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (NSString *key in @[@"gearName", @"qualityType", @"videoResolution",
                            @"codecType", @"codec", @"format", @"definition"]) {
        NSString *value = AWEStringFromValue(AWESafeValueForKey(model, key));
        if (value.length) [parts addObject:value];
    }
    return [[parts componentsJoinedByString:@" "] lowercaseString];
}

static NSInteger AWEParseFPSFromMetadata(NSString *metadata) {
    if (metadata.length == 0) return 0;
    NSRegularExpression *regex = [NSRegularExpression
        regularExpressionWithPattern:@"([0-9]{2,3})\\s*fps"
        options:NSRegularExpressionCaseInsensitive error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:metadata
        options:0 range:NSMakeRange(0, metadata.length)];
    if (match.numberOfRanges >= 2) {
        return [[metadata substringWithRange:[match rangeAtIndex:1]] integerValue];
    }
    if ([metadata containsString:@"120fps"] || [metadata containsString:@"120p"]) return 120;
    if ([metadata containsString:@"60fps"] || [metadata containsString:@"60p"]) return 60;
    if ([metadata containsString:@"30fps"] || [metadata containsString:@"30p"]) return 30;
    return 0;
}

static NSInteger AWEParseHeightFromMetadata(NSString *metadata) {
    if (metadata.length == 0) return 0;
    if ([metadata containsString:@"2160"] || [metadata containsString:@"4k"]) return 2160;
    if ([metadata containsString:@"1440"] || [metadata containsString:@"2k"]) return 1440;
    if ([metadata containsString:@"1080"]) return 1080;
    if ([metadata containsString:@"720"]) return 720;
    if ([metadata containsString:@"540"]) return 540;
    if ([metadata containsString:@"480"]) return 480;
    return 0;
}

static AWEVideoVariant *AWEVideoVariantFromModel(id model,
                                                  id fallbackVideo,
                                                  NSInteger index) {
    if (!model) return nil;
    id address = AWEFirstSafeValue(model, @[@"playAddr", @"playURL", @"downloadAddr"]);
    NSString *urlString = AWEFirstRemoteURLString(address ?: model, 0);
    if (urlString.length == 0) return nil;

    AWEVideoVariant *variant = [AWEVideoVariant new];
    variant.sourceModel = model;
    variant.urlString = urlString;
    variant.sourceIndex = index;

    variant.width = (NSInteger)AWEInteger64FromValue(
        AWEFirstSafeValue(model, @[@"width", @"videoWidth", @"w"]));
    variant.height = (NSInteger)AWEInteger64FromValue(
        AWEFirstSafeValue(model, @[@"height", @"videoHeight", @"h"]));
    variant.fps = (NSInteger)AWEInteger64FromValue(
        AWEFirstSafeValue(model, @[@"fps", @"frameRate", @"videoFPS", @"videoFps"]));
    variant.bitrate = AWEInteger64FromValue(
        AWEFirstSafeValue(model, @[@"bitrate", @"bitRate", @"videoBitrate",
                                   @"avgBitrate", @"bitrateInBps", @"bitRateInBps"]));

    if (variant.width <= 0) {
        variant.width = (NSInteger)AWEInteger64FromValue(
            AWEFirstSafeValue(address, @[@"width", @"videoWidth", @"w"]));
    }
    if (variant.height <= 0) {
        variant.height = (NSInteger)AWEInteger64FromValue(
            AWEFirstSafeValue(address, @[@"height", @"videoHeight", @"h"]));
    }
    if (variant.fps <= 0) {
        variant.fps = (NSInteger)AWEInteger64FromValue(
            AWEFirstSafeValue(address, @[@"fps", @"frameRate", @"videoFPS"]));
    }
    if (variant.bitrate <= 0) {
        variant.bitrate = AWEInteger64FromValue(
            AWEFirstSafeValue(address, @[@"bitrate", @"bitRate", @"videoBitrate"]));
    }

    if (fallbackVideo) {
        if (variant.width <= 0) {
            variant.width = (NSInteger)AWEInteger64FromValue(
                AWEFirstSafeValue(fallbackVideo, @[@"width", @"videoWidth"]));
        }
        if (variant.height <= 0) {
            variant.height = (NSInteger)AWEInteger64FromValue(
                AWEFirstSafeValue(fallbackVideo, @[@"height", @"videoHeight"]));
        }
        if (variant.fps <= 0) {
            variant.fps = (NSInteger)AWEInteger64FromValue(
                AWEFirstSafeValue(fallbackVideo, @[@"fps", @"frameRate", @"videoFPS"]));
        }
    }

    NSString *metadata = AWEJoinedVariantMetadata(model);
    if (variant.height <= 0) variant.height = AWEParseHeightFromMetadata(metadata);
    if (variant.width <= 0 && variant.height > 0) {
        variant.width = (NSInteger)llround((double)variant.height * 9.0 / 16.0);
    }
    if (variant.fps <= 0) variant.fps = AWEParseFPSFromMetadata(metadata);
    variant.h265 = AWEBoolFromValue(AWESafeValueForKey(model, @"isH265")) ||
        [metadata containsString:@"h265"] ||
        [metadata containsString:@"hevc"] ||
        [metadata containsString:@"bytevc1"] ||
        [metadata containsString:@"bytevc2"];
    variant.hdr = AWEBoolFromValue(AWESafeValueForKey(model, @"isHDR")) ||
        AWEInteger64FromValue(AWESafeValueForKey(model, @"hdrType")) > 0 ||
        AWEInteger64FromValue(AWESafeValueForKey(model, @"hdrBit")) > 0 ||
        [metadata containsString:@"hdr"];
    return variant;
}

static NSArray<AWEVideoVariant *> *AWEVideoVariantsForVideo(id video,
                                                             BOOL allowFallback) {
    if (!video) return @[];
    NSArray *models = AWEArrayFromValue(AWESafeValueForKey(video, @"bitrateModels_origin"));
    if (models.count == 0) {
        models = AWEArrayFromValue(AWESafeValueForKey(video, @"bitrateModels"));
    }
    NSMutableArray<AWEVideoVariant *> *variants = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    NSInteger index = 0;
    for (id model in models) {
        AWEVideoVariant *variant = AWEVideoVariantFromModel(model, video, index++);
        if (!variant || [seen containsObject:variant.urlString]) continue;
        [seen addObject:variant.urlString];
        [variants addObject:variant];
    }
    if (variants.count == 0 && allowFallback) {
        for (NSString *key in @[@"playAddr", @"playURL"]) {
            id model = AWESafeValueForKey(video, key);
            AWEVideoVariant *variant = AWEVideoVariantFromModel(model ?: video, video, 0);
            if (!variant || [seen containsObject:variant.urlString]) continue;
            [seen addObject:variant.urlString];
            [variants addObject:variant];
        }
    }
    return variants;
}

static long long AWEVariantArea(AWEVideoVariant *variant) {
    if (!variant) return 0;
    return (long long)MAX(variant.width, 0) * (long long)MAX(variant.height, 0);
}

static AWEVideoVariant *AWEChooseHighestPlaybackVariant(NSArray<AWEVideoVariant *> *variants) {
    AWEVideoVariant *best = nil;
    for (AWEVideoVariant *candidate in variants) {
        if (!best) { best = candidate; continue; }
        /* Keep this consistent with the early AWEVideoModel path below: the
           stream with the greatest advertised bitrate is the primary choice.
           Resolution/FPS/codec are only tie-breakers. */
        if (candidate.bitrate != best.bitrate) {
            if (candidate.bitrate > best.bitrate) best = candidate;
            continue;
        }
        long long area = AWEVariantArea(candidate);
        long long bestArea = AWEVariantArea(best);
        if (area != bestArea) { if (area > bestArea) best = candidate; continue; }
        if (candidate.fps != best.fps) { if (candidate.fps > best.fps) best = candidate; continue; }
        if (candidate.h265 != best.h265 && candidate.h265) best = candidate;
    }
    return best;
}

static AWEVideoVariant *AWEChooseSmartDownloadVariant(NSArray<AWEVideoVariant *> *variants) {
    if (variants.count == 0) return nil;
    long long maxArea = 0;
    for (AWEVideoVariant *variant in variants) maxArea = MAX(maxArea, AWEVariantArea(variant));

    NSMutableArray<AWEVideoVariant *> *pool = [NSMutableArray array];
    if (maxArea > 0) {
        for (AWEVideoVariant *variant in variants) {
            long long area = AWEVariantArea(variant);
            if (area >= (long long)((double)maxArea * 0.90)) [pool addObject:variant];
        }
    }
    if (pool.count == 0) [pool addObjectsFromArray:variants];

    NSInteger maxFPS = 0;
    for (AWEVideoVariant *variant in pool) maxFPS = MAX(maxFPS, variant.fps);
    if (maxFPS > 0) {
        NSIndexSet *drop = [pool indexesOfObjectsPassingTest:
            ^BOOL(AWEVideoVariant *variant, NSUInteger idx, BOOL *stop) {
                (void)idx; (void)stop;
                return variant.fps > 0 && variant.fps < maxFPS - 1;
            }];
        if (drop.count < pool.count) [pool removeObjectsAtIndexes:drop];
    }

    BOOL hasH265 = NO;
    for (AWEVideoVariant *variant in pool) if (variant.h265) { hasH265 = YES; break; }
    if (hasH265) {
        NSIndexSet *drop = [pool indexesOfObjectsPassingTest:
            ^BOOL(AWEVideoVariant *variant, NSUInteger idx, BOOL *stop) {
                (void)idx; (void)stop; return !variant.h265;
            }];
        if (drop.count < pool.count) [pool removeObjectsAtIndexes:drop];
    }

    long long maxBitrate = 0;
    for (AWEVideoVariant *variant in pool) maxBitrate = MAX(maxBitrate, variant.bitrate);
    if (maxBitrate > 0) {
        long long floorBitrate = (long long)((double)maxBitrate * 0.55);
        AWEVideoVariant *efficient = nil;
        for (AWEVideoVariant *variant in pool) {
            if (variant.bitrate <= 0 || variant.bitrate < floorBitrate) continue;
            if (!efficient || variant.bitrate < efficient.bitrate) efficient = variant;
        }
        if (efficient) return efficient;
    }
    return AWEChooseHighestPlaybackVariant(pool);
}

static NSString *AWEVariantSummary(AWEVideoVariant *variant) {
    if (!variant) return @"none";
    return [NSString stringWithFormat:@"%ldx%ld fps=%ld bitrate=%lld h265=%d hdr=%d index=%ld",
        (long)variant.width, (long)variant.height, (long)variant.fps,
        variant.bitrate, variant.h265, variant.hdr, (long)variant.sourceIndex];
}

static id AWECurrentAwemeModelForStack(UIView *stack) {
    SEL contextSelector = NSSelectorFromString(@"awelistkit_cellContext");
    for (UIView *view = stack; view; view = view.superview) {
        if ([view respondsToSelector:contextSelector]) {
            @try {
                id context = ((id (*)(id, SEL))objc_msgSend)(view, contextSelector);
                id model = AWEFirstSafeValue(context, @[@"model", @"awemeModel", @"itemModel"]);
                if (model) return model;
            } @catch (__unused NSException *exception) {}
        }
        id direct = AWEFirstSafeValue(view, @[@"awemeModel", @"itemModel"]);
        if (direct) return direct;
    }

    UIResponder *responder = stack;
    while (responder) {
        if ([responder isKindOfClass:UIViewController.class]) {
            id model = AWEFirstSafeValue(responder,
                @[@"awemeModel", @"currentAwemeModel", @"currentAweme", @"itemModel"]);
            if (model) return model;
        }
        responder = responder.nextResponder;
    }
    UIWindow *window = stack.window ?: AWEActiveMainWindow();
    UIViewController *top = window ? AWETopViewControllerFrom(window.rootViewController) : nil;
    return AWEFirstSafeValue(top,
        @[@"awemeModel", @"currentAwemeModel", @"currentAweme", @"itemModel"]);
}

static NSString *AWEAwemeIdentity(id aweme) {
    NSString *identity = AWEStringFromValue(AWEFirstSafeValue(aweme,
        @[@"awemeId", @"awemeID", @"itemId", @"itemID", @"groupId", @"aid"]));
    if (identity.length) return identity;
    return [NSString stringWithFormat:@"%p", aweme];
}

static BOOL AWEToastTextIndicatesLoading(NSString *text) {
    return [text containsString:@"正在"] || [text containsString:@"下载中"] ||
           [text containsString:@"准备中"];
}

static BOOL AWEToastTextIndicatesFailure(NSString *text) {
    NSArray<NSString *> *tokens = @[@"失败", @"未找到", @"没有解析", @"无效",
        @"无法", @"请允许", @"未识别", @"没有可复制"];
    for (NSString *token in tokens) if ([text containsString:token]) return YES;
    return NO;
}

static BOOL AWEToastTextIndicatesSuccess(NSString *text) {
    if (AWEToastTextIndicatesFailure(text) || AWEToastTextIndicatesLoading(text)) return NO;
    return [text containsString:@"已保存"] || [text containsString:@"保存完成"] ||
           [text containsString:@"已复制"] || [text containsString:@"完成"];
}

static void AWEShowDownloadToast(NSString *text) {
    if (text.length == 0) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = AWEActiveMainWindow();
        if (!window) return;

        NSUInteger generation = ++gAWEDownloadToastGeneration;
        UIView *old = gAWEDownloadToastView;
        [old removeFromSuperview];

        BOOL loading = AWEToastTextIndicatesLoading(text);
        BOOL failure = AWEToastTextIndicatesFailure(text);
        BOOL success = AWEToastTextIndicatesSuccess(text);

        UIView *host = [UIView new];
        host.translatesAutoresizingMaskIntoConstraints = NO;
        host.backgroundColor = UIColor.clearColor;
        host.userInteractionEnabled = NO;
        host.alpha = 0.0;
        host.transform = CGAffineTransformMakeScale(0.92, 0.92);
        host.layer.shadowColor = UIColor.blackColor.CGColor;
        host.layer.shadowOpacity = 0.12;
        host.layer.shadowRadius = 18.0;
        host.layer.shadowOffset = CGSizeMake(0.0, 7.0);

        UIVisualEffectView *glass = [[UIVisualEffectView alloc]
            initWithEffect:AWECreateHomeAdaptiveGlassEffect()];
        glass.translatesAutoresizingMaskIntoConstraints = NO;
        glass.userInteractionEnabled = NO;
        glass.clipsToBounds = YES;
        glass.layer.cornerRadius = 28.0;
        glass.layer.cornerCurve = kCACornerCurveContinuous;
        glass.layer.borderWidth = 0.5;
        glass.layer.borderColor = [UIColor.separatorColor colorWithAlphaComponent:0.22].CGColor;
        [host addSubview:glass];

        UIView *content = glass.contentView;
        UIStackView *row = [UIStackView new];
        row.translatesAutoresizingMaskIntoConstraints = NO;
        row.axis = UILayoutConstraintAxisHorizontal;
        row.alignment = UIStackViewAlignmentCenter;
        row.spacing = 10.0;
        [content addSubview:row];

        if (loading) {
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
            spinner.color = UIColor.labelColor;
            [spinner startAnimating];
            [row addArrangedSubview:spinner];
        } else {
            NSString *symbol = failure ? @"exclamationmark.triangle.fill" :
                (success ? @"checkmark.circle.fill" : @"arrow.down.circle.fill");
            UIImageView *icon = [[UIImageView alloc]
                initWithImage:[UIImage systemImageNamed:symbol]];
            icon.translatesAutoresizingMaskIntoConstraints = NO;
            icon.contentMode = UIViewContentModeScaleAspectFit;
            icon.tintColor = failure ? UIColor.systemOrangeColor :
                (success ? UIColor.systemGreenColor : UIColor.labelColor);
            [NSLayoutConstraint activateConstraints:@[
                [icon.widthAnchor constraintEqualToConstant:22.0],
                [icon.heightAnchor constraintEqualToConstant:22.0]
            ]];
            [row addArrangedSubview:icon];
        }

        UILabel *label = [UILabel new];
        label.text = text;
        label.textColor = UIColor.labelColor;
        label.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
        label.textAlignment = NSTextAlignmentCenter;
        label.numberOfLines = 2;
        label.adjustsFontSizeToFitWidth = YES;
        label.minimumScaleFactor = 0.86;
        [row addArrangedSubview:label];

        [NSLayoutConstraint activateConstraints:@[
            [glass.leadingAnchor constraintEqualToAnchor:host.leadingAnchor],
            [glass.trailingAnchor constraintEqualToAnchor:host.trailingAnchor],
            [glass.topAnchor constraintEqualToAnchor:host.topAnchor],
            [glass.bottomAnchor constraintEqualToAnchor:host.bottomAnchor],
            [row.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:18.0],
            [row.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-18.0],
            [row.topAnchor constraintEqualToAnchor:content.topAnchor constant:13.0],
            [row.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-13.0]
        ]];

        [window addSubview:host];
        NSLayoutConstraint *maxWidth = [host.widthAnchor
            constraintLessThanOrEqualToAnchor:window.widthAnchor multiplier:0.78];
        maxWidth.priority = UILayoutPriorityRequired;
        [NSLayoutConstraint activateConstraints:@[
            [host.centerXAnchor constraintEqualToAnchor:window.centerXAnchor],
            [host.centerYAnchor constraintEqualToAnchor:window.centerYAnchor constant:4.0],
            [host.heightAnchor constraintGreaterThanOrEqualToConstant:56.0],
            [host.widthAnchor constraintGreaterThanOrEqualToConstant:150.0],
            maxWidth
        ]];

        gAWEDownloadToastView = host;
        [window layoutIfNeeded];
        [UIView animateWithDuration:0.28
                              delay:0.0
             usingSpringWithDamping:0.78
              initialSpringVelocity:0.35
                            options:UIViewAnimationOptionAllowUserInteraction |
                                    UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
            host.alpha = 1.0;
            host.transform = CGAffineTransformIdentity;
        } completion:nil];

        NSTimeInterval lifetime = loading ? 12.0 : 1.65;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
            (int64_t)(lifetime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (generation != gAWEDownloadToastGeneration ||
                gAWEDownloadToastView != host) return;
            [UIView animateWithDuration:0.20 animations:^{
                host.alpha = 0.0;
                host.transform = CGAffineTransformMakeScale(0.96, 0.96);
            } completion:^(__unused BOOL finished) {
                if (gAWEDownloadToastView == host) gAWEDownloadToastView = nil;
                [host removeFromSuperview];
            }];
        });
    });
}

static NSMutableURLRequest *AWEMediaRequest(NSString *urlString) {
    NSURL *url = [NSURL URLWithString:urlString ?: @""];
    if (!url) return nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
        cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:75.0];
    request.HTTPShouldHandleCookies = YES;
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:@"https://www.douyin.com/" forHTTPHeaderField:@"Referer"];
    NSString *userAgent = [NSUserDefaults.standardUserDefaults stringForKey:@"UserAgent"];
    if (userAgent.length == 0) {
        userAgent = @"Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) AppleWebKit/605.1.15 Mobile/15E148 aweme";
    }
    [request setValue:userAgent forHTTPHeaderField:@"User-Agent"];
    return request;
}

static void AWERequestPhotoAddPermission(void (^completion)(BOOL granted)) {
    if (!completion) return;
    if (@available(iOS 14.0, *)) {
        PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelAddOnly];
        if (status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited) {
            completion(YES); return;
        }
        if (status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted) {
            completion(NO); return;
        }
        [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelAddOnly
            handler:^(PHAuthorizationStatus newStatus) {
                completion(newStatus == PHAuthorizationStatusAuthorized ||
                           newStatus == PHAuthorizationStatusLimited);
            }];
        return;
    }
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        completion(status == PHAuthorizationStatusAuthorized);
    }];
}

static void AWESaveVideoFileToPhotos(NSURL *fileURL, void (^completion)(BOOL)) {
    AWERequestPhotoAddPermission(^(BOOL granted) {
        if (!granted) { if (completion) completion(NO); return; }
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL];
        } completionHandler:^(BOOL success, __unused NSError *error) {
            if (completion) completion(success);
        }];
    });
}

static void AWESaveImageToPhotos(UIImage *image, void (^completion)(BOOL)) {
    if (!image) { if (completion) completion(NO); return; }
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
    } completionHandler:^(BOOL success, __unused NSError *error) {
        if (completion) completion(success);
    }];
}

static NSURL *AWEMoveDownloadedFile(NSURL *location, NSString *extension) {
    if (!location) return nil;
    NSString *ext = extension.length ? extension : @"bin";
    NSString *name = [NSString stringWithFormat:@"AwemeLiquidBar_%@.%@",
        NSUUID.UUID.UUIDString, ext];
    NSURL *target = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:name]];
    NSFileManager *fm = NSFileManager.defaultManager;
    [fm removeItemAtURL:target error:nil];
    NSError *error = nil;
    if (![fm moveItemAtURL:location toURL:target error:&error]) return nil;
    return target;
}

static NSString *AWERobustVideoURLForAweme(id aweme) {
    id video = AWESafeValueForKey(aweme, @"video");
    if (!video) return nil;

    /* DYYY's stable path on current Douyin builds starts from h264URL's
       originURLList. Prefer that simple platform-provided stream before any
       bitrate/DASH heuristics; the goal of 1.0.55a is reliable saving first. */
    id h264 = AWESafeValueForKey(video, @"h264URL");
    NSString *url = AWEFirstRemoteURLString(
        AWESafeValueForKey(h264, @"originURLList") ?: h264, 0);
    if (url.length) return url;

    for (NSString *key in @[@"playURL", @"playAddr", @"downloadURL", @"downloadAddr"]) {
        id value = AWESafeValueForKey(video, key);
        url = AWEFirstRemoteURLString(value, 0);
        if (url.length) return url;
    }

    NSArray<AWEVideoVariant *> *variants = AWEVideoVariantsForVideo(video, YES);
    return variants.firstObject.urlString;
}

static void AWEDownloadSmartVideoForAweme(id aweme) {
    NSString *urlString = AWERobustVideoURLForAweme(aweme);
    if (!urlString.length) {
        AWEShowDownloadToast(@"未找到可下载的视频资源");
        AWEInteractionDiagnosticWrite(@"DOWNLOAD_VIDEO model=%@ result=no-url",
            AWEAwemeIdentity(aweme));
        return;
    }
    AWEInteractionDiagnosticWrite(@"DOWNLOAD_VIDEO model=%@ mode=robust-h264 url=%@",
        AWEAwemeIdentity(aweme), urlString);
    NSMutableURLRequest *request = AWEMediaRequest(urlString);
    if (!request) { AWEShowDownloadToast(@"视频地址无效"); return; }
    AWEShowDownloadToast(@"正在保存视频");
    NSURLSessionDownloadTask *task = [NSURLSession.sharedSession
        downloadTaskWithRequest:request
        completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            NSInteger status = [response isKindOfClass:NSHTTPURLResponse.class]
                ? ((NSHTTPURLResponse *)response).statusCode : 0;
            AWEInteractionDiagnosticWrite(@"DOWNLOAD_VIDEO_HTTP status=%ld bytes=%lld error=%@",
                (long)status, response.expectedContentLength, error.localizedDescription ?: @"none");
            if (error || !location || (status >= 400 && status != 0)) {
                AWEShowDownloadToast([NSString stringWithFormat:@"视频下载失败%@",
                    status > 0 ? [NSString stringWithFormat:@"（HTTP %ld）", (long)status] : @""]);
                return;
            }
            NSString *ext = response.suggestedFilename.pathExtension.lowercaseString;
            if (ext.length == 0 || ext.length > 6) ext = @"mp4";
            NSURL *fileURL = AWEMoveDownloadedFile(location, ext);
            if (!fileURL) { AWEShowDownloadToast(@"视频临时文件保存失败"); return; }
            AWESaveVideoFileToPhotos(fileURL, ^(BOOL success) {
                [NSFileManager.defaultManager removeItemAtURL:fileURL error:nil];
                AWEShowDownloadToast(success ? @"视频已保存" : @"无法写入相册，请检查照片权限");
            });
        }];
    [task resume];
}

static NSArray *AWEAlbumImagesForAweme(id aweme) {
    NSArray *images = AWEArrayFromValue(AWESafeValueForKey(aweme, @"albumImages"));
    if (images.count == 0) images = AWEArrayFromValue(AWESafeValueForKey(aweme, @"imageList"));
    return images ?: @[];
}

static NSString *AWEImageURLForModel(id imageModel) {
    NSArray *urlList = AWEArrayFromValue(AWESafeValueForKey(imageModel, @"urlList"));
    NSString *fallback = nil;
    for (id value in urlList) {
        NSString *candidate = AWEStringFromValue(value);
        if (!AWEStringLooksLikeRemoteURL(candidate)) continue;
        if (!fallback.length) fallback = candidate;
        NSURL *url = [NSURL URLWithString:candidate];
        if (![[url.pathExtension lowercaseString] isEqualToString:@"image"]) {
            return candidate;
        }
    }
    if (fallback.length) return fallback;
    id address = AWEFirstSafeValue(imageModel,
        @[@"originURLList", @"imageList", @"displayImage", @"url"]);
    return AWEFirstRemoteURLString(address ?: imageModel, 0);
}

static id AWECurrentAlbumImageModelForAweme(id aweme) {
    NSArray *images = AWEAlbumImagesForAweme(aweme);
    if (images.count == 0) return nil;
    NSInteger index = (NSInteger)AWEInteger64FromValue(AWESafeValueForKey(aweme, @"currentImageIndex"));
    if (index > 0 && index <= (NSInteger)images.count) return images[index - 1];
    if (index >= 0 && index < (NSInteger)images.count) return images[index];
    return images.firstObject;
}

static void AWEDownloadCurrentImageForAweme(id aweme) {
    id imageModel = AWECurrentAlbumImageModelForAweme(aweme);
    NSString *urlString = AWEImageURLForModel(imageModel);
    if (!urlString.length) { AWEShowDownloadToast(@"没有解析到当前图片"); return; }
    AWERequestPhotoAddPermission(^(BOOL granted) {
        if (!granted) { AWEShowDownloadToast(@"请允许添加照片后重试"); return; }
        AWEShowDownloadToast(@"正在保存图片");
        NSMutableURLRequest *request = AWEMediaRequest(urlString);
        if (!request) { AWEShowDownloadToast(@"图片地址无效"); return; }
        NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithRequest:request
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSInteger status = [response isKindOfClass:NSHTTPURLResponse.class]
                    ? ((NSHTTPURLResponse *)response).statusCode : 0;
                AWEInteractionDiagnosticWrite(@"DOWNLOAD_IMAGE_HTTP status=%ld bytes=%lu error=%@",
                    (long)status, (unsigned long)data.length, error.localizedDescription ?: @"none");
                UIImage *image = (!error && data.length && (status < 400 || status == 0))
                    ? [UIImage imageWithData:data] : nil;
                if (!image) { AWEShowDownloadToast(@"当前图片下载失败"); return; }
                AWESaveImageToPhotos(image, ^(BOOL success) {
                    AWEShowDownloadToast(success ? @"图片已保存" : @"图片写入相册失败");
                });
            }];
        [task resume];
    });
}

static void AWEDownloadAllImagesForAweme(id aweme) {
    NSArray *images = AWEAlbumImagesForAweme(aweme);
    if (images.count == 0) { AWEShowDownloadToast(@"当前作品没有图集"); return; }
    AWERequestPhotoAddPermission(^(BOOL granted) {
        if (!granted) { AWEShowDownloadToast(@"请允许添加照片后重试"); return; }
        AWEShowDownloadToast([NSString stringWithFormat:@"正在保存 %lu 张图片",
            (unsigned long)images.count]);
        dispatch_group_t group = dispatch_group_create();
        __block NSInteger successCount = 0;
        __block NSInteger attemptedCount = 0;
        NSObject *counterLock = [NSObject new];
        for (id imageModel in images) {
            NSString *urlString = AWEImageURLForModel(imageModel);
            if (!urlString.length) continue;
            attemptedCount++;
            NSMutableURLRequest *request = AWEMediaRequest(urlString);
            if (!request) continue;
            dispatch_group_enter(group);
            NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithRequest:request
                completionHandler:^(NSData *data, __unused NSURLResponse *response, NSError *error) {
                    UIImage *image = (!error && data.length) ? [UIImage imageWithData:data] : nil;
                    if (!image) { dispatch_group_leave(group); return; }
                    AWESaveImageToPhotos(image, ^(BOOL success) {
                        if (success) @synchronized(counterLock) { successCount++; }
                        dispatch_group_leave(group);
                    });
                }];
            [task resume];
        }
        if (attemptedCount == 0) {
            AWEShowDownloadToast(@"没有解析到图片地址");
            return;
        }
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            AWEShowDownloadToast([NSString stringWithFormat:@"已保存 %ld/%ld 张图片",
                (long)successCount, (long)attemptedCount]);
        });
    });
}

static NSString *AWEAudioURLForAweme(id aweme) {
    id music = AWESafeValueForKey(aweme, @"music");
    id address = AWEFirstSafeValue(music,
        @[@"playURL", @"playAddr", @"urlList", @"originURLList", @"url"]);
    return AWEFirstRemoteURLString(address ?: music, 0);
}

static UIViewController *AWECurrentPresenter(void) {
    UIWindow *window = AWEActiveMainWindow();
    return window ? AWETopViewControllerFrom(window.rootViewController) : nil;
}

static void AWEDownloadAudioForAweme(id aweme) {
    NSString *urlString = AWEAudioURLForAweme(aweme);
    if (!urlString.length) { AWEShowDownloadToast(@"未找到音频资源"); return; }
    NSMutableURLRequest *request = AWEMediaRequest(urlString);
    if (!request) { AWEShowDownloadToast(@"音频地址无效"); return; }
    AWEShowDownloadToast(@"正在下载音频");
    NSURLSessionDownloadTask *task = [NSURLSession.sharedSession
        downloadTaskWithRequest:request
        completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
            if (error || !location) { AWEShowDownloadToast(@"音频下载失败"); return; }
            NSString *ext = response.suggestedFilename.pathExtension.lowercaseString;
            if (ext.length == 0 || ext.length > 6) {
                ext = [NSURL URLWithString:urlString].pathExtension.lowercaseString;
            }
            if (ext.length == 0 || ext.length > 6) ext = @"m4a";
            NSURL *fileURL = AWEMoveDownloadedFile(location, ext);
            if (!fileURL) { AWEShowDownloadToast(@"音频临时文件保存失败"); return; }
            dispatch_async(dispatch_get_main_queue(), ^{
                UIViewController *presenter = AWECurrentPresenter();
                if (!presenter) {
                    AWEShowDownloadToast(@"音频已下载，但无法打开导出面板");
                    return;
                }
                UIActivityViewController *activity = [[UIActivityViewController alloc]
                    initWithActivityItems:@[fileURL] applicationActivities:nil];
                if (activity.popoverPresentationController) {
                    activity.popoverPresentationController.sourceView = presenter.view;
                    activity.popoverPresentationController.sourceRect = CGRectMake(
                        CGRectGetMidX(presenter.view.bounds), CGRectGetMidY(presenter.view.bounds), 1, 1);
                }
                activity.completionWithItemsHandler = ^(__unused UIActivityType type,
                    __unused BOOL completed, __unused NSArray *items, __unused NSError *activityError) {
                    [NSFileManager.defaultManager removeItemAtURL:fileURL error:nil];
                };
                [presenter presentViewController:activity animated:YES completion:nil];
            });
        }];
    [task resume];
}

static void AWECopyCompleteTextForAweme(id aweme) {
    NSString *text = AWEStringFromValue(AWEFirstSafeValue(aweme,
        @[@"descriptionString", @"desc", @"text", @"caption"]));
    if (text.length == 0) { AWEShowDownloadToast(@"当前作品没有可复制文案"); return; }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIPasteboard.generalPasteboard.string = text;
        AWEShowDownloadToast(@"完整文案已复制");
    });
}

static UIAction *AWESelfDownloadAction(NSString *title,
                                       NSString *systemImage,
                                       id aweme,
                                       void (^handler)(id aweme)) {
    id capturedAweme = aweme;
    UIAction *action = [UIAction actionWithTitle:title
        image:[UIImage systemImageNamed:systemImage]
        identifier:nil
        handler:^(__kindof UIAction * _Nonnull ignored) {
            (void)ignored;
            if (!capturedAweme) {
                AWEShowDownloadToast(@"未识别到当前作品，请稍后重试");
                AWEInteractionDiagnosticWrite(@"DOWNLOAD_ACTION model=nil title=%@", title ?: @"");
                return;
            }
            AWEInteractionDiagnosticWrite(@"DOWNLOAD_ACTION model=%@ title=%@",
                AWEAwemeIdentity(capturedAweme), title ?: @"");
            if (handler) handler(capturedAweme);
        }];
    return action;
}

static UIMenu *AWESelfDownloadMenuForAweme(id aweme) {
    NSMutableArray<UIMenuElement *> *items = [NSMutableArray array];
    NSArray *images = AWEAlbumImagesForAweme(aweme);
    if (images.count > 0) {
        NSString *currentTitle = images.count == 1 ? @"保存图片" : @"保存当前图片";
        [items addObject:AWESelfDownloadAction(currentTitle, @"photo", aweme,
            ^(id model) { AWEDownloadCurrentImageForAweme(model); })];
        if (images.count > 1) {
            [items addObject:AWESelfDownloadAction(
                [NSString stringWithFormat:@"保存全部图片（%lu）", (unsigned long)images.count],
                @"photo.on.rectangle.angled", aweme,
                ^(id model) { AWEDownloadAllImagesForAweme(model); })];
        }
    } else {
        [items addObject:AWESelfDownloadAction(@"保存当前视频",
            @"arrow.down.circle", aweme,
            ^(id model) { AWEDownloadSmartVideoForAweme(model); })];
    }
    if (AWEAudioURLForAweme(aweme).length > 0) {
        [items addObject:AWESelfDownloadAction(@"保存音频", @"waveform", aweme,
            ^(id model) { AWEDownloadAudioForAweme(model); })];
    }
    [items addObject:AWESelfDownloadAction(@"复制完整文案", @"doc.on.doc", aweme,
        ^(id model) { AWECopyCompleteTextForAweme(model); })];
    return [UIMenu menuWithTitle:@"下载与复制" children:items];
}

/* Highest-quality playback deliberately avoids runtime stream switching.
   Reconfiguring an already-playing private player can race Douyin's own
   background/foreground pause state. The active implementation below only
   biases the advertised bitrate list before native selection. */

typedef NS_ENUM(NSInteger, AWEHomeTopActionKind) {
    AWEHomeTopActionKindMenu = 1,
    AWEHomeTopActionKindSearch = 2
};

static BOOL AWEForwardTopActionOwner(UIView *owner, AWEHomeTopActionKind kind);
static UIView *AWEFindTopOwnerCandidate(UIView *root, BOOL search);

@class AWETopLiquidGroupView;

@interface AWEHomeTopSlotView : UIView
@property (nonatomic, assign) AWEHomeTopActionKind topKind;
@property (nonatomic, strong) AWEPhotosExactGlassButtonHostView *photosGlassHost;
@property (nonatomic, strong) UIButton *systemGlassButton;
@property (nonatomic, weak) UIImageView *sourceImageView;
@property (nonatomic, weak) UIView *ownerView;
@property (nonatomic, strong) UIButton *hitButton;
- (void)alb_handleTopTap:(UIButton *)sender;
@end

static AWEHomeTopSlotView *AWEEnsureTopSlot(UIView *container,
                                            AWEHomeTopActionKind kind);
static void AWEHideTopSourceImage(AWEHomeTopSlotView *slot,
                                  UIImageView *source);

@implementation AWEHomeTopSlotView
- (void)alb_handleTopTap:(UIButton *)sender {
    (void)sender;
    UIView *owner = self.ownerView;
    UIView *container = self.superview;
    if ((!owner || !owner.window) && container) {
        owner = AWEFindTopOwnerCandidate(
            container, self.topKind == AWEHomeTopActionKindSearch);
        self.ownerView = owner;
    }
    BOOL result = AWEForwardTopActionOwner(owner, self.topKind);
    AWEInteractionDiagnosticWrite(
        @"TOP_TAP kind=%@ result=%d owner=%@ slot=%@",
        self.topKind == AWEHomeTopActionKindSearch ? @"SEARCH" : @"MENU",
        result, AWEInteractionObjectSummary(owner),
        AWEInteractionObjectSummary(self));
}
@end

static NSString *AWEHomeActionSymbolKey(AWEHomeActionKind kind, BOOL selected) {
    NSString *name = nil;
    BOOL supportsSelectedVariant = NO;
    switch (kind) {
        case AWEHomeActionKindLike:
            name = @"like"; supportsSelectedVariant = YES; break;
        case AWEHomeActionKindComment:
            name = @"comment"; break;
        case AWEHomeActionKindFavorite:
            name = @"favorite"; supportsSelectedVariant = YES; break;
        case AWEHomeActionKindShare:
            name = @"share"; break;
        default: return nil;
    }
    NSString *state = (selected && supportsSelectedVariant) ? @"selected" : @"normal";
    return [NSString stringWithFormat:@"right.%@.%@", name, state];
}

static NSString *AWETopSymbolKey(AWEHomeTopActionKind kind) {
    return kind == AWEHomeTopActionKindSearch ? @"top.search" : @"top.menu";
}

static void AWEHideTopSlot(UIView *container, AWEHomeTopActionKind kind);

static BOOL AWEHomeViewEffectivelyVisible(UIView *view) {
    if (!view || !view.window || view.hidden || view.alpha < 0.01) return NO;

    for (UIView *current = view.superview;
         current && current != view.window;
         current = current.superview) {
        if (current.hidden || current.alpha < 0.01) return NO;
    }

    CGRect frame = [view convertRect:view.bounds toView:view.window];
    if (CGRectIsEmpty(frame) || CGRectIsNull(frame)) return NO;
    return CGRectIntersectsRect(CGRectInset(view.window.bounds, -8.0, -8.0), frame);
}

static NSString *AWEHomeActionEvidence(UIView *view) {
    if (!view) return @"";

    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    NSArray *direct = @[
        view.accessibilityLabel ?: @"",
        view.accessibilityValue ?: @"",
        view.accessibilityIdentifier ?: @"",
        NSStringFromClass(view.class) ?: @""
    ];
    for (NSString *value in direct) {
        if (value.length > 0) [parts addObject:value];
    }

    NSUInteger visited = 0;
    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:view];
    while (queue.count > 0 && visited < 42) {
        UIView *current = queue.firstObject;
        [queue removeObjectAtIndex:0];
        visited++;

        if (current != view) {
            NSString *label = current.accessibilityLabel;
            NSString *identifier = current.accessibilityIdentifier;
            if (label.length > 0) [parts addObject:label];
            if (identifier.length > 0) [parts addObject:identifier];
            if ([current isKindOfClass:UILabel.class]) {
                NSString *value = ((UILabel *)current).text;
                if (value.length > 0 && value.length <= 16) [parts addObject:value];
            }
        }
        for (UIView *child in current.subviews) [queue addObject:child];
    }
    return [[parts componentsJoinedByString:@"|"] lowercaseString];
}

static AWEHomeActionKind AWEHomeActionKindFromEvidence(UIView *view) {
    NSString *evidence = AWEHomeActionEvidence(view);
    if ([evidence containsString:@"评论"] ||
        [evidence containsString:@"comment"] ||
        [evidence containsString:@"回复"]) {
        return AWEHomeActionKindComment;
    }
    if ([evidence containsString:@"收藏"] ||
        [evidence containsString:@"favorite"] ||
        [evidence containsString:@"favourite"] ||
        [evidence containsString:@"collect"] ||
        [evidence containsString:@"bookmark"]) {
        return AWEHomeActionKindFavorite;
    }
    if ([evidence containsString:@"分享"] ||
        [evidence containsString:@"share"] ||
        [evidence containsString:@"转发"]) {
        return AWEHomeActionKindShare;
    }
    if ([evidence containsString:@"点赞"] ||
        [evidence containsString:@"喜欢"] ||
        [evidence containsString:@"like"] ||
        [evidence containsString:@"digg"]) {
        return AWEHomeActionKindLike;
    }
    return AWEHomeActionKindUnknown;
}

static void AWECollectFeedActionButtons(UIView *root,
                                        NSMutableArray<UIView *> *result,
                                        NSUInteger depth) {
    if (!root || !result || depth > 12) return;
    if ([NSStringFromClass(root.class) isEqualToString:@"AWEFeedVideoButton"]) {
        [result addObject:root];
        return;
    }
    for (UIView *child in root.subviews) {
        if ([child isKindOfClass:AWEHomeActionSlotView.class]) continue;
        AWECollectFeedActionButtons(child, result, depth + 1);
    }
}

static UIView *AWEHomeActionStackForView(UIView *view) {
    for (UIView *current = view; current; current = current.superview) {
        if ([NSStringFromClass(current.class) containsString:@"AWEElementStackView"]) {
            return current;
        }
        if (current == view.window) break;
    }
    return nil;
}

static BOOL AWEHomeActionButtonLocallyUsable(UIView *button, UIView *stack) {
    if (!button || !stack || !button.window || button.hidden || button.alpha < 0.01) {
        return NO;
    }
    BOOL reachedStack = NO;
    for (UIView *cursor = button; cursor; cursor = cursor.superview) {
        if (cursor.hidden || cursor.alpha < 0.01) return NO;
        if (cursor == stack) { reachedStack = YES; break; }
        if (cursor == button.window) break;
    }
    if (!reachedStack) return NO;
    CGRect frame = [button convertRect:button.bounds toView:stack];
    if (CGRectIsNull(frame) || CGRectIsEmpty(frame) ||
        CGRectGetWidth(frame) < 8.0 || CGRectGetHeight(frame) < 8.0) return NO;
    /* Paging may place the whole stack outside the window for part of a drag.
       Judge buttons in the stack's own coordinate space so bindings survive
       the trip out and back instead of being permanently hidden on one pass. */
    return CGRectIntersectsRect(CGRectInset(stack.bounds, -80.0, -160.0), frame);
}

static NSArray<UIView *> *AWESortedVisibleHomeActionButtons(UIView *stack) {
    NSMutableArray<UIView *> *buttons = [NSMutableArray array];
    AWECollectFeedActionButtons(stack, buttons, 0);
    NSIndexSet *hiddenIndexes = [buttons indexesOfObjectsPassingTest:
        ^BOOL(UIView *button, NSUInteger idx, BOOL *stop) {
            (void)idx; (void)stop;
            return !AWEHomeActionButtonLocallyUsable(button, stack);
        }];
    [buttons removeObjectsAtIndexes:hiddenIndexes];
    [buttons sortUsingComparator:^NSComparisonResult(UIView *lhs, UIView *rhs) {
        CGRect lf = [lhs convertRect:lhs.bounds toView:stack];
        CGRect rf = [rhs convertRect:rhs.bounds toView:stack];
        CGFloat ly = CGRectGetMidY(lf);
        CGFloat ry = CGRectGetMidY(rf);
        if (ly < ry) return NSOrderedAscending;
        if (ly > ry) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    return buttons;
}

static AWEHomeActionKind AWEHomeActionKindForButton(UIView *button,
                                                     NSArray<UIView *> *ordered) {
    AWEHomeActionKind kind = AWEHomeActionKindFromEvidence(button);
    if (kind == AWEHomeActionKindUnknown) {
        NSNumber *stored = objc_getAssociatedObject(button, &kAWEHomeActionKindKey);
        if (stored) kind = (AWEHomeActionKind)stored.integerValue;
    }
    if (kind == AWEHomeActionKindUnknown) {
        NSUInteger index = [ordered indexOfObjectIdenticalTo:button];
        switch (index) {
            case 0: kind = AWEHomeActionKindLike; break;
            case 1: kind = AWEHomeActionKindComment; break;
            case 2: kind = AWEHomeActionKindFavorite; break;
            case 3: kind = AWEHomeActionKindShare; break;
            default: break;
        }
    }
    if (kind != AWEHomeActionKindUnknown) {
        objc_setAssociatedObject(button, &kAWEHomeActionKindKey, @(kind),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return kind;
}

static void AWECollectImageViews(UIView *root,
                                 NSMutableArray<UIImageView *> *result,
                                 NSUInteger depth) {
    if (!root || !result || depth > 10) return;
    if ([root isKindOfClass:UIImageView.class]) {
        UIImageView *imageView = (UIImageView *)root;
        if (imageView.image) [result addObject:imageView];
    }
    for (UIView *child in root.subviews) {
        if ([child isKindOfClass:AWEHomeActionSlotView.class]) continue;
        AWECollectImageViews(child, result, depth + 1);
    }
}

static BOOL AWEViewIsInsideOurHomeOverlay(UIView *view, UIView *root) {
    for (UIView *current = view; current && current != root; current = current.superview) {
        NSString *identifier = current.accessibilityIdentifier;
        if ([identifier hasPrefix:@"AwemeLiquidBar.Home"]) return YES;
    }
    return NO;
}

static UIImageView *AWEBestHomeActionImageView(UIView *root) {
    if (!root) return nil;
    UIImageView *bound = objc_getAssociatedObject(root,
                                                   &kAWEHomeActionOriginalImageViewKey);
    if (bound && bound.image && AWEViewIsDescendantOfView(bound, root)) return bound;

    NSMutableArray<UIImageView *> *images = [NSMutableArray array];
    AWECollectImageViews(root, images, 0);
    UIImageView *best = nil;
    CGFloat bestScore = -CGFLOAT_MAX;
    for (UIImageView *imageView in images) {
        if (AWEViewIsInsideOurHomeOverlay(imageView, root)) continue;
        CGRect frame = [imageView convertRect:imageView.bounds toView:root];
        CGFloat width = CGRectGetWidth(frame);
        CGFloat height = CGRectGetHeight(frame);
        if (width < 14.0 || height < 14.0 || width > 70.0 || height > 70.0) continue;
        CGFloat score = width * height;
        score -= MAX(0.0, CGRectGetMidY(frame) - 42.0) * 9.0;
        if (imageView.hidden || imageView.alpha < 0.01 ||
            imageView.layer.opacity < 0.01f) score -= 30.0;
        if (score > bestScore) {
            bestScore = score;
            best = imageView;
        }
    }
    return best;
}

static UIVisualEffect *AWECreateHomeAdaptiveGlassEffect(void) {
    /*
     Match XHSLiquidBar's proven home-button implementation exactly: create one
     native UIGlassEffect through -init and let UIKit choose its light/dark
     material from the view's trait environment. Do not add a manual tint fill.
    */
    Class glassClass = NSClassFromString(@"UIGlassEffect");
    if (glassClass) {
        id effect = [[glassClass alloc] init];
        if ([effect isKindOfClass:UIVisualEffect.class]) {
            return (UIVisualEffect *)effect;
        }
    }
    if (@available(iOS 13.0, *)) {
        return [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial];
    }
    return [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
}

static UIImage *AWEFirstAvailableSymbol(NSArray<NSString *> *names,
                                        CGFloat pointSize,
                                        UIImageSymbolWeight weight) {
    if (@available(iOS 13.0, *)) {
        UIImageSymbolConfiguration *configuration =
            [UIImageSymbolConfiguration configurationWithPointSize:pointSize
                                                             weight:weight
                                                              scale:UIImageSymbolScaleMedium];
        for (NSString *name in names) {
            UIImage *image = [UIImage systemImageNamed:name];
            if (!image) continue;
            image = [image imageWithConfiguration:configuration];
            return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
    }
    return nil;
}

static UIView *AWEFindViewByExactRuntimeClass(UIView *root,
                                              NSString *className,
                                              NSUInteger depth);
static void AWERefreshTopActionContainer(UIView *container);

static BOOL AWEImageAverageColor(UIImage *image,
                                 CGFloat *redOut,
                                 CGFloat *greenOut,
                                 CGFloat *blueOut) {
    if (!image) return NO;

    /* These same symbol/PNG objects are sampled repeatedly while Douyin lays
       out the action stack. Cache both successful and failed results on the
       UIImage so clear-mode foreground tracking never recopies pixel buffers
       on every layout pass. */
    NSArray<NSNumber *> *cached = objc_getAssociatedObject(
        image, &kAWEImageAverageColorCacheKey);
    if ([cached isKindOfClass:NSArray.class] && cached.count == 4) {
        BOOL valid = cached[0].boolValue;
        if (valid) {
            if (redOut) *redOut = cached[1].doubleValue;
            if (greenOut) *greenOut = cached[2].doubleValue;
            if (blueOut) *blueOut = cached[3].doubleValue;
        }
        return valid;
    }

    CGImageRef cgImage = image.CGImage;
    if (!cgImage) {
        objc_setAssociatedObject(image, &kAWEImageAverageColorCacheKey,
            @[@NO, @0.0, @0.0, @0.0], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return NO;
    }
    CFDataRef data = CGDataProviderCopyData(CGImageGetDataProvider(cgImage));
    if (!data) {
        objc_setAssociatedObject(image, &kAWEImageAverageColorCacheKey,
            @[@NO, @0.0, @0.0, @0.0], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return NO;
    }

    const UInt8 *bytes = CFDataGetBytePtr(data);
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    size_t bits = CGImageGetBitsPerPixel(cgImage);
    size_t rowBytes = CGImageGetBytesPerRow(cgImage);
    CGBitmapInfo info = CGImageGetBitmapInfo(cgImage);
    BOOL valid = NO;
    CGFloat red = 0.0, green = 0.0, blue = 0.0, count = 0.0;

    if (bytes && width > 0 && height > 0 && bits == 32 && rowBytes > 0) {
        BOOL little = (info & kCGBitmapByteOrderMask) == kCGBitmapByteOrder32Little;
        size_t stepX = MAX((size_t)1, width / 14);
        size_t stepY = MAX((size_t)1, height / 14);
        for (size_t y = 0; y < height; y += stepY) {
            const UInt8 *row = bytes + y * rowBytes;
            for (size_t x = 0; x < width; x += stepX) {
                const UInt8 *pixel = row + x * 4;
                UInt8 r = little ? pixel[2] : pixel[0];
                UInt8 g = pixel[1];
                UInt8 b = little ? pixel[0] : pixel[2];
                UInt8 a = pixel[3];
                if (a < 48) continue;
                red += r / 255.0;
                green += g / 255.0;
                blue += b / 255.0;
                count += 1.0;
            }
        }
        if (count > 0.0) {
            red /= count;
            green /= count;
            blue /= count;
            valid = YES;
        }
    }
    CFRelease(data);

    objc_setAssociatedObject(image, &kAWEImageAverageColorCacheKey,
        @[@(valid), @(red), @(green), @(blue)],
        OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (valid) {
        if (redOut) *redOut = red;
        if (greenOut) *greenOut = green;
        if (blueOut) *blueOut = blue;
    }
    return valid;
}

static BOOL AWEImageLooksSelected(UIImage *image, AWEHomeActionKind kind) {
    CGFloat red = 0.0, green = 0.0, blue = 0.0;
    if (!AWEImageAverageColor(image, &red, &green, &blue)) return NO;
    if (kind == AWEHomeActionKindLike) {
        return red > 0.56 && red > green * 1.18 && red > blue * 1.08;
    }
    if (kind == AWEHomeActionKindFavorite) {
        BOOL yellow = red > 0.58 && green > 0.38 && blue < 0.42;
        BOOL warmPink = red > 0.62 && red > green * 1.15;
        return yellow || warmPink;
    }
    return NO;
}

static BOOL AWEImagePrefersLightForeground(UIImage *image,
                                           UITraitCollection *fallbackTrait) {
    CGFloat red = 0.0, green = 0.0, blue = 0.0;
    if (AWEImageAverageColor(image, &red, &green, &blue)) {
        CGFloat luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue;
        return luminance >= 0.58;
    }
    return fallbackTrait.userInterfaceStyle != UIUserInterfaceStyleLight;
}

static BOOL AWEColorPrefersLightForeground(UIColor *color,
                                            UITraitCollection *trait,
                                            BOOL *validOut) {
    if (validOut) *validOut = NO;
    if (!color) return YES;
    UIColor *resolved = trait
        ? [color resolvedColorWithTraitCollection:trait]
        : color;
    CGFloat white = 0.0, alpha = 0.0;
    if ([resolved getWhite:&white alpha:&alpha] && alpha > 0.05) {
        if (validOut) *validOut = YES;
        return white >= 0.58;
    }
    CGFloat red = 0.0, green = 0.0, blue = 0.0;
    if ([resolved getRed:&red green:&green blue:&blue alpha:&alpha] &&
        alpha > 0.05) {
        if (validOut) *validOut = YES;
        CGFloat luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue;
        return luminance >= 0.58;
    }
    return YES;
}

static BOOL AWEHomeSourcePrefersLightForeground(UIImageView *source,
                                                 UITraitCollection *fallbackTrait,
                                                 BOOL *validOut) {
    if (validOut) *validOut = NO;
    if (!source) {
        return fallbackTrait.userInterfaceStyle != UIUserInterfaceStyleLight;
    }

    /*
     Douyin changes the visible template icon's tint between white and black as
     the video underneath changes. Reading the template bitmap first sees only
     its black mask and freezes our replacement symbol in black. For template
     images, mirror the source UIImageView's resolved tint first; original PNGs
     still use their actual pixels, preserving selected and multicolour artwork.
     This changes only the symbol foreground and does not touch SwiftUI glass.
    */
    UIImage *image = source.image;
    BOOL templateImage = image &&
        image.renderingMode == UIImageRenderingModeAlwaysTemplate;
    if (templateImage) {
        BOOL tintValid = NO;
        BOOL tintLight = AWEColorPrefersLightForeground(
            source.tintColor, source.traitCollection ?: fallbackTrait, &tintValid);
        if (tintValid) {
            if (validOut) *validOut = YES;
            return tintLight;
        }
    }

    if (image) {
        CGFloat red = 0.0, green = 0.0, blue = 0.0;
        if (AWEImageAverageColor(image, &red, &green, &blue)) {
            if (validOut) *validOut = YES;
            CGFloat luminance =
                0.2126 * red + 0.7152 * green + 0.0722 * blue;
            return luminance >= 0.58;
        }
    }

    BOOL tintValid = NO;
    BOOL tintLight = AWEColorPrefersLightForeground(
        source.tintColor, source.traitCollection ?: fallbackTrait, &tintValid);
    if (tintValid) {
        if (validOut) *validOut = YES;
        return tintLight;
    }
    return fallbackTrait.userInterfaceStyle != UIUserInterfaceStyleLight;
}

static UIColor *AWEHomeExplicitForegroundForSource(UIImageView *source,
                                                    UIView *context,
                                                    BOOL allowGlobalFallback) {
    BOOL valid = NO;
    BOOL light = AWEHomeSourcePrefersLightForeground(
        source, context.traitCollection, &valid);
    if (!valid && allowGlobalFallback && gAWEHomeAdaptiveForegroundValid) {
        light = gAWEHomeAdaptiveForegroundIsLight;
        valid = YES;
    }
    if (!valid) {
        /* Douyin's immersive feed defaults to a white foreground. */
        light = YES;
    }
    return light ? UIColor.whiteColor : UIColor.blackColor;
}

static void AWEUpdateGlobalHomeForegroundFromSource(UIImageView *source,
                                                     UIView *context) {
    BOOL valid = NO;
    BOOL light = AWEHomeSourcePrefersLightForeground(
        source, context.traitCollection, &valid);
    if (!valid) return;
    BOOL changed = !gAWEHomeAdaptiveForegroundValid ||
                   gAWEHomeAdaptiveForegroundIsLight != light;
    gAWEHomeAdaptiveForegroundValid = YES;
    gAWEHomeAdaptiveForegroundIsLight = light;
    if (changed && context.window) {
        UIView *top = AWEFindViewByExactRuntimeClass(
            context.window, @"AWEFeedTopBarContainer", 0);
        if (top) {
            dispatch_async(dispatch_get_main_queue(), ^{
                AWERefreshTopActionContainer(top);
            });
        }
    }
}

static BOOL AWEHomeActionIsSelected(UIView *view,
                                    AWEHomeActionKind kind,
                                    UIImageView *source) {
    if (!view) return NO;
    if ([view respondsToSelector:@selector(isSelected)] &&
        ((BOOL (*)(id, SEL))objc_msgSend)(view, @selector(isSelected))) {
        return YES;
    }
    NSString *evidence = AWEHomeActionEvidence(view);
    if ([evidence containsString:@"取消点赞"] ||
        [evidence containsString:@"已点赞"] ||
        [evidence containsString:@"取消收藏"] ||
        [evidence containsString:@"已收藏"] ||
        [evidence containsString:@"liked"] ||
        [evidence containsString:@"collected"] ||
        [evidence containsString:@"selected"]) {
        return YES;
    }
    if ((kind == AWEHomeActionKindLike || kind == AWEHomeActionKindFavorite) &&
        source.image) {
        return AWEImageLooksSelected(source.image, kind);
    }
    return NO;
}

static NSArray<NSString *> *AWEHomeActionSymbolNames(AWEHomeActionKind kind, BOOL selected) {
    switch (kind) {
        case AWEHomeActionKindLike: return selected ? @[@"hand.thumbsup.fill"] : @[@"hand.thumbsup"];
        case AWEHomeActionKindComment: return @[@"quote.closing"];
        case AWEHomeActionKindFavorite: return selected ? @[@"star.fill"] : @[@"star"];
        case AWEHomeActionKindShare: return @[@"square.and.arrow.up"];
        default: return @[];
    }
}

static void AWEUnbindHomeActionSource(UIImageView *source) {
    if (!source) return;
    NSNumber *hidden = objc_getAssociatedObject(source, &kAWEHomeActionSourceHiddenKey);
    NSNumber *alpha = objc_getAssociatedObject(source, &kAWEHomeActionSourceAlphaKey);
    objc_setAssociatedObject(source, &kAWEHomeActionSourceOwnerKey, nil,
                             OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(source, &kAWEHomeActionSourceHiddenKey, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(source, &kAWEHomeActionSourceAlphaKey, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    source.hidden = hidden ? hidden.boolValue : NO;
    source.alpha = alpha ? alpha.doubleValue : 1.0;
    source.layer.opacity = (float)source.alpha;
}

static void AWEBindHomeActionSource(UIView *owner, UIImageView *source) {
    if (!owner || !source) return;
    UIImageView *previous = objc_getAssociatedObject(
        owner, &kAWEHomeActionOriginalImageViewKey);
    if (previous && previous != source) AWEUnbindHomeActionSource(previous);

    UIView *oldOwner = objc_getAssociatedObject(source, &kAWEHomeActionSourceOwnerKey);
    if (oldOwner && oldOwner != owner) {
        UIImageView *oldSource = objc_getAssociatedObject(
            oldOwner, &kAWEHomeActionOriginalImageViewKey);
        if (oldSource == source) {
            objc_setAssociatedObject(oldOwner,
                                     &kAWEHomeActionOriginalImageViewKey,
                                     nil,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        AWEUnbindHomeActionSource(source);
    }

    if (!objc_getAssociatedObject(source, &kAWEHomeActionSourceHiddenKey)) {
        objc_setAssociatedObject(source, &kAWEHomeActionSourceHiddenKey,
                                 @(source.hidden),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(source, &kAWEHomeActionSourceAlphaKey,
                                 @(source.alpha),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    objc_setAssociatedObject(owner, &kAWEHomeActionOriginalImageViewKey,
                             source, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(source, &kAWEHomeActionSourceOwnerKey,
                             owner, OBJC_ASSOCIATION_ASSIGN);
    source.hidden = YES;
    source.alpha = 0.0;
    source.layer.opacity = 0.0f;
}

static UIColor *AWEHomeDiagnosticForegroundOverride(UIColor *automaticColor) {
    if (gAWEHomeDiagnosticForegroundMode ==
        AWEHomeDiagnosticForegroundModeForceWhite) {
        return UIColor.whiteColor;
    }
    if (gAWEHomeDiagnosticForegroundMode ==
        AWEHomeDiagnosticForegroundModeForceBlack) {
        return UIColor.blackColor;
    }
    return automaticColor;
}

@interface AWEGlassPressFeedbackTarget : NSObject <UIGestureRecognizerDelegate>
@property(nonatomic, weak) UIButton *glassButton;
@property(nonatomic, assign) CGPoint startPoint;
- (void)handlePress:(UILongPressGestureRecognizer *)gesture;
@end

@implementation AWEGlassPressFeedbackTarget
- (void)handlePress:(UILongPressGestureRecognizer *)gesture {
    UIButton *button = self.glassButton;
    if (!button) return;
    CGPoint point = [gesture locationInView:gesture.view];
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            self.startPoint = point;
            button.highlighted = YES;
            [button setNeedsUpdateConfiguration];
            [UIView animateWithDuration:0.12 delay:0
                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseOut
                animations:^{
                    button.transform = CGAffineTransformMakeScale(1.10, 1.10);
                } completion:nil];
            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGFloat dx = point.x - self.startPoint.x;
            CGFloat dy = point.y - self.startPoint.y;
            CGFloat ax = MIN(fabs(dx), 34.0);
            CGFloat ay = MIN(fabs(dy), 34.0);
            CGFloat sx = 1.10 + ax / 240.0 - ay / 520.0;
            CGFloat sy = 1.10 + ay / 240.0 - ax / 520.0;
            CGAffineTransform t = CGAffineTransformMakeTranslation(dx * 0.055, dy * 0.055);
            button.transform = CGAffineTransformScale(t, sx, sy);
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            button.highlighted = NO;
            [button setNeedsUpdateConfiguration];
            [UIView animateWithDuration:0.34 delay:0
                usingSpringWithDamping:0.62 initialSpringVelocity:0.35
                options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                animations:^{ button.transform = CGAffineTransformIdentity; }
                completion:nil];
            break;
        }
        default:
            break;
    }
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
        shouldRecognizeSimultaneouslyWithGestureRecognizer:
            (UIGestureRecognizer *)otherGestureRecognizer {
    (void)gestureRecognizer; (void)otherGestureRecognizer;
    return YES;
}
@end

static void AWEInstallGlassPressFeedback(UIView *touchOwner,
                                         UIButton *glassButton) {
    if (!touchOwner || !glassButton) return;
    UILongPressGestureRecognizer *recognizer = objc_getAssociatedObject(
        touchOwner, &kAWEGlassPressFeedbackRecognizerKey);
    AWEGlassPressFeedbackTarget *target = objc_getAssociatedObject(
        touchOwner, &kAWEGlassPressFeedbackTargetKey);
    if (!target) {
        target = [AWEGlassPressFeedbackTarget new];
        objc_setAssociatedObject(touchOwner, &kAWEGlassPressFeedbackTargetKey,
                                 target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    target.glassButton = glassButton;
    if (!recognizer) {
        recognizer = [[UILongPressGestureRecognizer alloc]
            initWithTarget:target action:@selector(handlePress:)];
        recognizer.minimumPressDuration = 0.0;
        recognizer.allowableMovement = 44.0;
        recognizer.cancelsTouchesInView = NO;
        recognizer.delaysTouchesBegan = NO;
        recognizer.delaysTouchesEnded = NO;
        recognizer.delegate = target;
        [touchOwner addGestureRecognizer:recognizer];
        objc_setAssociatedObject(touchOwner, &kAWEGlassPressFeedbackRecognizerKey,
                                 recognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

/*
 Custom top/right controls must stay on the same system-owned material path as
 the native UITabBar.  Direct SwiftUI glassEffect(.clear/.regular) pins a
 concrete material variant and can miss the user's system Clear/Tinted glass
 preference.  A real UIButtonConfiguration glass style lets UIKit rebuild the
 material when system glass appearance, contrast, transparency or traits
 change.  No custom background tint or opacity is added, keeping both modes
 restrained.
*/
static NSHashTable<UIButton *> *AWEAdaptiveGlassButtonRegistry(void) {
    if (!gAWEAdaptiveGlassButtons) {
        gAWEAdaptiveGlassButtons = [NSHashTable weakObjectsHashTable];
    }
    return gAWEAdaptiveGlassButtons;
}

static void AWERegisterAdaptiveGlassButton(UIButton *button) {
    if (!button) return;
    [AWEAdaptiveGlassButtonRegistry() addObject:button];
}

static UIColor *AWESoftClearEdgeColor(UIUserInterfaceStyle style,
                                       BOOL strong) {
    (void)style; (void)strong;
    /* 1.0.43a intentionally removes the custom perimeter. UIKit still owns
       its internal refractive highlight, but no CALayer stroke is composited
       over the morphing source button, so a pressed/elongated circle cannot
       expose a rigid gray outline. */
    return UIColor.clearColor;
}

static void AWEApplySoftClearEdgeToButton(UIButton *button) {
    if (!button) return;
    button.layer.borderWidth = 0.0;
    button.layer.borderColor = UIColor.clearColor.CGColor;
    button.layer.cornerRadius = 0.0;
}

static BOOL AWEAdaptiveButtonIsEffectivelyVisible(UIButton *button) {
    if (!button || !button.window || button.hidden || button.alpha <= 0.01 ||
        button.layer.opacity <= 0.01f || CGRectIsEmpty(button.bounds)) return NO;
    CGRect frame = [button convertRect:button.bounds toView:button.window];
    return CGRectIntersectsRect(frame, button.window.bounds);
}

static UIUserInterfaceStyle AWEGlassInternalInterfaceStyle(
    UIView *glass, UIUserInterfaceStyle fallbackStyle);

/*
 Clear glass already resolves a local light/dark material internally. Reading
 that resolved material is both more reliable and much cheaper than rendering
 the whole Douyin window into a bitmap (video/Metal layers are not faithfully
 captured by renderInContext and were the reason automatic icons stayed white).
 */
static UIUserInterfaceStyle AWEAdaptiveButtonResolvedLocalStyle(UIButton *button) {
    UIUserInterfaceStyle fallback = button.traitCollection.userInterfaceStyle;
    if (fallback != UIUserInterfaceStyleLight &&
        fallback != UIUserInterfaceStyleDark) {
        fallback = gAWEHomeChromeLastStableStyle;
    }
    if (fallback != UIUserInterfaceStyleLight &&
        fallback != UIUserInterfaceStyleDark) {
        fallback = gAWEAlbumMorphLastAppliedStyle;
    }
    if (fallback != UIUserInterfaceStyleLight &&
        fallback != UIUserInterfaceStyleDark) {
        fallback = UIScreen.mainScreen.traitCollection.userInterfaceStyle;
    }
    if (fallback != UIUserInterfaceStyleLight &&
        fallback != UIUserInterfaceStyleDark) fallback = UIUserInterfaceStyleDark;
    return AWEGlassInternalInterfaceStyle(button, fallback);
}

static void AWEApplyAutomaticContrastForeground(UIButton *button,
                                                 BOOL foregroundLight) {
    if (!button || !button.configuration) return;
    NSNumber *previous = objc_getAssociatedObject(
        button, &kAWEAdaptiveGlassForegroundLightKey);
    if (previous && previous.boolValue == foregroundLight &&
        button.imageView.image != nil && button.imageView.alpha > 0.01) return;

    UIColor *color = foregroundLight ? UIColor.whiteColor : UIColor.blackColor;
    UIButtonConfiguration *configuration = [button.configuration copy];
    UIImage *image = configuration.image;
    if (image) {
        configuration.image = [image imageWithRenderingMode:
            UIImageRenderingModeAlwaysTemplate];
    }
    configuration.baseForegroundColor = color;
    button.configuration = configuration;
    button.tintColor = color;
    button.imageView.tintColor = color;
    button.imageView.hidden = NO;
    button.imageView.alpha = 1.0;
    [button setNeedsUpdateConfiguration];
    [button setNeedsLayout];
    objc_setAssociatedObject(button, &kAWEAdaptiveGlassForegroundLightKey,
                             @(foregroundLight), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void AWERefreshAutomaticContrastForButton(UIButton *button) {
    if (!button || ![objc_getAssociatedObject(
            button, &kAWEAdaptiveGlassAutomaticContrastKey) boolValue]) return;
    UIUserInterfaceStyle localStyle = AWEAdaptiveButtonResolvedLocalStyle(button);
    /* Dark material needs a light glyph; light material needs a dark glyph. */
    BOOL foregroundLight = localStyle != UIUserInterfaceStyleLight;
    AWEApplyAutomaticContrastForeground(button, foregroundLight);
    objc_setAssociatedObject(button, &kAWEAdaptiveGlassLastSampleTimeKey,
                             @(CACurrentMediaTime()),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void AWERefreshOneAdaptiveButtonContrast(void) {
    NSArray<UIButton *> *buttons = AWEAdaptiveGlassButtonRegistry().allObjects;
    if (buttons.count == 0) return;
    for (NSUInteger attempt = 0; attempt < buttons.count; attempt++) {
        NSUInteger index = gAWEAdaptiveContrastRoundRobinIndex % buttons.count;
        gAWEAdaptiveContrastRoundRobinIndex++;
        UIButton *button = buttons[index];
        if (![objc_getAssociatedObject(
                button, &kAWEAdaptiveGlassAutomaticContrastKey) boolValue] ||
            !AWEAdaptiveButtonIsEffectivelyVisible(button)) continue;
        AWERefreshAutomaticContrastForButton(button);
        break;
    }
}

static BOOL AWEAdaptiveForegroundMatches(UIColor *left, UIColor *right) {
    if (left == right) return YES;
    if (!left || !right) return NO;
    NSString *leftHex = AWEHexStringFromColor(left);
    NSString *rightHex = AWEHexStringFromColor(right);
    return leftHex.length && [leftHex isEqualToString:rightHex];
}

static void AWEEnforceExplicitForeground(UIButton *button, BOOL force) {
    if (!button) return;
    UIColor *explicitForeground = objc_getAssociatedObject(
        button, &kAWEAdaptiveGlassExplicitForegroundKey);
    if (!explicitForeground) return;

    NSString *signature = AWEHexStringFromColor(explicitForeground)
        ?: explicitForeground.description;
    NSString *previous = objc_getAssociatedObject(
        button, &kAWEAdaptiveGlassAppliedForegroundSignatureKey);
    UIButtonConfiguration *configuration = [button.configuration copy];
    UIImage *baseImage = objc_getAssociatedObject(
        button, &kAWEAdaptiveGlassBaseImageKey);
    BOOL needsConfiguration = force || ![previous isEqualToString:signature] ||
        !AWEAdaptiveForegroundMatches(configuration.baseForegroundColor,
                                      explicitForeground);
    if (configuration && needsConfiguration) {
        if (baseImage) {
            configuration.image = [baseImage imageWithTintColor:explicitForeground
                renderingMode:UIImageRenderingModeAlwaysOriginal];
        } else if (configuration.image) {
            configuration.image = [configuration.image imageWithTintColor:explicitForeground
                renderingMode:UIImageRenderingModeAlwaysOriginal];
        }
        configuration.baseForegroundColor = explicitForeground;
        button.configuration = configuration;
        objc_setAssociatedObject(button,
            &kAWEAdaptiveGlassAppliedForegroundSignatureKey,
            signature, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    button.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
    button.tintColor = explicitForeground;
    button.imageView.tintColor = explicitForeground;
    button.imageView.hidden = NO;
    button.imageView.alpha = 1.0;
}

static void AWEInstallAdaptiveForegroundUpdateHandler(UIButton *button) {
    if (!button || [objc_getAssociatedObject(
            button, &kAWEAdaptiveGlassUpdateHandlerInstalledKey) boolValue]) {
        return;
    }
    __weak UIButton *weakButton = button;
    button.configurationUpdateHandler = ^(UIButton *updatedButton) {
        UIButton *liveButton = weakButton ?: updatedButton;
        AWEEnforceExplicitForeground(liveButton, NO);
    };
    objc_setAssociatedObject(button,
        &kAWEAdaptiveGlassUpdateHandlerInstalledKey,
        @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void AWEApplyResolvedGlassStyleToAdaptiveButton(UIButton *button) {
    if (!button) return;
    if (button.window && !AWEHomeViewEffectivelyVisible(button)) return;
    BOOL transparent = [objc_getAssociatedObject(
        button, &kAWEAdaptiveGlassTransparentKey) boolValue];
    UIColor *explicitForeground = objc_getAssociatedObject(
        button, &kAWEAdaptiveGlassExplicitForegroundKey);
    UIUserInterfaceStyle homeStyle = gAWEHomeChromeLastStableStyle;
    if (homeStyle != UIUserInterfaceStyleLight &&
        homeStyle != UIUserInterfaceStyleDark) {
        homeStyle = gAWEAlbumMorphLastAppliedStyle;
    }
    UIUserInterfaceStyle style = transparent
        ? UIUserInterfaceStyleUnspecified
        : homeStyle;
    if (style != UIUserInterfaceStyleLight &&
        style != UIUserInterfaceStyleDark) {
        style = UIUserInterfaceStyleUnspecified;
    }
    BOOL changed = button.overrideUserInterfaceStyle != style;
    if (changed) {
        button.overrideUserInterfaceStyle = style;
        [button setNeedsUpdateConfiguration];
        [button setNeedsLayout];
    }
    AWEApplySoftClearEdgeToButton(button);
    if (explicitForeground) {
        AWEInstallAdaptiveForegroundUpdateHandler(button);
        AWEEnforceExplicitForeground(button, changed);
    }
}

static void AWERefreshRegisteredAdaptiveGlassButtons(void) {
    for (UIButton *button in AWEAdaptiveGlassButtonRegistry().allObjects) {
        AWEApplyResolvedGlassStyleToAdaptiveButton(button);
    }
}

static UIButtonConfiguration *AWECreateAdaptiveGlassIconConfiguration(
    BOOL tintedGlass) {
    Class configurationClass = NSClassFromString(@"UIButtonConfiguration");
    SEL selector = NSSelectorFromString(tintedGlass
        ? @"glassButtonConfiguration"
        : @"clearGlassButtonConfiguration");
    if (configurationClass &&
        [configurationClass respondsToSelector:selector]) {
        return ((id (*)(id, SEL))objc_msgSend)(configurationClass, selector);
    }

    UIButtonConfiguration *fallback = tintedGlass
        ? [UIButtonConfiguration tintedButtonConfiguration]
        : [UIButtonConfiguration plainButtonConfiguration];
    return fallback;
}

static NSString *AWEAdaptiveGlassConfigurationSignature(
    NSString *identityKey,
    CGFloat pointSize,
    UIColor *foregroundColor,
    BOOL preserveOriginalImage,
    BOOL tintedGlass,
    BOOL strongEdgeSoftening) {
    NSString *foreground = foregroundColor
        ? (AWEHexStringFromColor(foregroundColor) ?: foregroundColor.description)
        : @"SYSTEM";
    return [NSString stringWithFormat:@"%@|%.2f|%@|%d|%d|%d|%lu",
        identityKey ?: @"unknown", pointSize, foreground,
        preserveOriginalImage, tintedGlass, strongEdgeSoftening,
        (unsigned long)gAWEConfiguredIconGeneration];
}

static void AWEConfigureAdaptiveSystemGlassIconButton(
    UIButton *button,
    UIImage *image,
    NSString *identityKey,
    CGFloat pointSize,
    UIColor *foregroundColor,
    BOOL preserveOriginalImage,
    BOOL tintedGlass,
    BOOL strongEdgeSoftening) {
    if (!button || !image) return;

    BOOL transparent = !tintedGlass;
    BOOL automaticContrast = transparent && !preserveOriginalImage &&
                             foregroundColor == nil;
    objc_setAssociatedObject(button, &kAWEAdaptiveGlassTransparentKey,
                             @(transparent), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(button, &kAWEAdaptiveGlassStrongEdgeKey,
                             @(strongEdgeSoftening), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(button, &kAWEAdaptiveGlassAutomaticContrastKey,
                             @(automaticContrast), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(button, &kAWEAdaptiveGlassExplicitForegroundKey,
                             foregroundColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(button, &kAWEAdaptiveGlassBaseImageKey,
                             image, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (foregroundColor) AWEInstallAdaptiveForegroundUpdateHandler(button);
    if (!automaticContrast) {
        objc_setAssociatedObject(button, &kAWEAdaptiveGlassForegroundLightKey,
                                 nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    NSString *signature = AWEAdaptiveGlassConfigurationSignature(
        identityKey, pointSize, foregroundColor, preserveOriginalImage,
        tintedGlass, strongEdgeSoftening);
    NSString *previous = objc_getAssociatedObject(
        button, &kAWEAdaptiveGlassConfigurationSignatureKey);
    BOOL needsConfiguration = ![previous isEqualToString:signature] ||
                              button.configuration == nil;

    if (needsConfiguration) {
        UIButtonConfiguration *configuration =
            AWECreateAdaptiveGlassIconConfiguration(tintedGlass);
        configuration.title = nil;
        configuration.subtitle = nil;
        configuration.image = image;
        configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
        configuration.contentInsets = NSDirectionalEdgeInsetsZero;
        configuration.imagePadding = 0.0;
        configuration.baseBackgroundColor = nil;

        if (!preserveOriginalImage) {
            UIColor *resolvedForeground = foregroundColor;
            if (automaticContrast) {
                NSNumber *storedLight = objc_getAssociatedObject(
                    button, &kAWEAdaptiveGlassForegroundLightKey);
                BOOL light = storedLight
                    ? storedLight.boolValue
                    : ((gAWEHomeChromeLastStableStyle != UIUserInterfaceStyleUnspecified
                        ? gAWEHomeChromeLastStableStyle
                        : gAWEAlbumMorphLastAppliedStyle) != UIUserInterfaceStyleLight);
                resolvedForeground = light ? UIColor.whiteColor : UIColor.blackColor;
            }
            /* Explicit white/black/accent/custom always win. In clear mode,
               Automatic is driven by the button's own sampled backdrop rather
               than Douyin's permanently-white source artwork. */
            configuration.baseForegroundColor = resolvedForeground;
            if (foregroundColor) {
                configuration.image = [image imageWithTintColor:foregroundColor
                    renderingMode:UIImageRenderingModeAlwaysOriginal];
            }
            if (@available(iOS 13.0, *)) {
                configuration.preferredSymbolConfigurationForImage =
                    [UIImageSymbolConfiguration
                        configurationWithPointSize:pointSize
                                             weight:UIImageSymbolWeightMedium
                                              scale:UIImageSymbolScaleMedium];
            }
        } else {
            configuration.baseForegroundColor = nil;
        }

        button.configuration = configuration;
        button.backgroundColor = UIColor.clearColor;
        button.opaque = NO;
        button.clipsToBounds = NO;
        button.imageView.contentMode = UIViewContentModeCenter;
        button.adjustsImageWhenHighlighted = NO;
        button.adjustsImageWhenDisabled = NO;
        if (!preserveOriginalImage && foregroundColor) {
            button.tintColor = foregroundColor;
            button.imageView.tintColor = foregroundColor;
        } else if (!preserveOriginalImage && !automaticContrast) {
            button.tintColor = nil;
            button.imageView.tintColor = nil;
        }
        objc_setAssociatedObject(button,
            &kAWEAdaptiveGlassConfigurationSignatureKey,
            signature, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }

    AWERegisterAdaptiveGlassButton(button);
    AWEApplyResolvedGlassStyleToAdaptiveButton(button);
    if (!preserveOriginalImage && foregroundColor) {
        AWEInstallAdaptiveForegroundUpdateHandler(button);
        AWEEnforceExplicitForeground(button, needsConfiguration);
        if (needsConfiguration) [button setNeedsUpdateConfiguration];
    }
    if (automaticContrast) {
        NSNumber *storedLight = objc_getAssociatedObject(
            button, &kAWEAdaptiveGlassForegroundLightKey);
        if (!storedLight) {
            AWEApplyAutomaticContrastForeground(
                button,
                (gAWEHomeChromeLastStableStyle != UIUserInterfaceStyleUnspecified
                    ? gAWEHomeChromeLastStableStyle
                    : gAWEAlbumMorphLastAppliedStyle) != UIUserInterfaceStyleLight);
        }
        if (!objc_getAssociatedObject(
                button, &kAWEAdaptiveGlassLastSampleTimeKey) && button.window) {
            __weak UIButton *weakButton = button;
            dispatch_async(dispatch_get_main_queue(), ^{
                AWERefreshAutomaticContrastForButton(weakButton);
            });
        }
    }
}

static void AWEConfigureAdaptiveSystemGlassPlateButton(
    UIButton *button,
    NSString *identityKey,
    BOOL tintedGlass) {
    if (!button) return;
    NSString *signature = [NSString stringWithFormat:
        @"PLATE|%@|%d|%lu", identityKey ?: @"plate", tintedGlass,
        (unsigned long)gAWEConfiguredIconGeneration];
    NSString *previous = objc_getAssociatedObject(
        button, &kAWEAdaptiveGlassConfigurationSignatureKey);
    if (![previous isEqualToString:signature] || !button.configuration) {
        UIButtonConfiguration *configuration =
            AWECreateAdaptiveGlassIconConfiguration(tintedGlass);
        configuration.title = nil;
        configuration.subtitle = nil;
        configuration.image = nil;
        configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
        configuration.contentInsets = NSDirectionalEdgeInsetsZero;
        configuration.baseBackgroundColor = nil;
        configuration.baseForegroundColor = nil;
        button.configuration = configuration;
        button.backgroundColor = UIColor.clearColor;
        button.opaque = NO;
        button.clipsToBounds = NO;
        objc_setAssociatedObject(button,
            &kAWEAdaptiveGlassConfigurationSignatureKey,
            signature, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    objc_setAssociatedObject(button, &kAWEAdaptiveGlassTransparentKey,
                             @(!tintedGlass), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(button, &kAWEAdaptiveGlassAutomaticContrastKey,
                             @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    AWERegisterAdaptiveGlassButton(button);
    AWEApplyResolvedGlassStyleToAdaptiveButton(button);
}

static void AWEHideGlobalDownloadMenu(void) {
    if (!gAWEDownloadMenuSlot) return;
    gAWEDownloadMenuSlot.hidden = YES;
    gAWEDownloadMenuSlot.alpha = 0.0;
    gAWEDownloadMenuSourceStack = nil;
}

static BOOL AWEDownloadMenuRouteBlocked(void) {
    if (gAWESettingsVisible) return YES;
    if (AWEAnyVisibleCommentPanelForRightRecovery()) return YES;
    if (AWEShouldSuppressBarForSearch() || AWEImmediateCommerceProductDetailVisible()) return YES;

    BOOL playableFeed = AWECurrentRouteHasPlayableFeedController();
    /* Stale sensitive-controller registrations can survive a completed route
       transition for a short time. Do not let those stale objects suppress the
       download control when a real playable feed is already visible. */
    if (AWEImmediateSensitiveDestinationVisible() && !playableFeed) return YES;

    if (AWEShouldSuppressBarForUserDetailRoute() && !playableFeed) return YES;
    return NO;
}

static UIView *AWEDownloadMenuOverlayHostView(UIView *stack) {
    if (!stack || !stack.window) return nil;

    /* 1.0.55a: keep the singleton download control inside the *current feed
       cell's interaction hierarchy instead of the independent bottom-bar
       UIWindow. The latter is intentionally masked/parked during route and
       settings transitions, so a perfectly valid download button could exist
       but never be composited. A cell-owned overlay also disappears naturally
       with paging/profile/comment transitions without becoming an arranged
       element of AWEElementStackView. */
    UIView *fallback = nil;
    for (UIView *cursor = stack.superview;
         cursor && cursor != (UIView *)stack.window;
         cursor = cursor.superview) {
        if (cursor.window != stack.window) break;
        CGFloat width = CGRectGetWidth(cursor.bounds);
        CGFloat height = CGRectGetHeight(cursor.bounds);
        if (!fallback && width > 220.0 && height > 320.0) fallback = cursor;

        NSString *lower = NSStringFromClass(cursor.class).lowercaseString;
        BOOL interactionHost =
            [lower containsString:@"playinteraction"] ||
            [lower containsString:@"feedcell"] ||
            [lower containsString:@"playercontainer"] ||
            [lower containsString:@"richcontent"];
        if (interactionHost && width > 220.0 && height > 320.0) {
            return cursor;
        }
    }
    return fallback ?: stack.superview;
}

static UIView *AWEDownloadMenuProfileAnchorForStack(UIView *stack) {
    if (!stack) return nil;
    AWEHomeProfileGlassView *profile = objc_getAssociatedObject(
        stack, &kAWEProfileGlassSlotKey);
    if (profile && !profile.hidden && profile.window) return profile;

    UIView *nativeProfile = AWEFindViewByExactRuntimeClass(
        stack, @"AWEPlayInteractionUserProfilePictureView", 0);
    if (!nativeProfile) {
        nativeProfile = AWEFindViewByExactRuntimeClass(
            stack, @"AWEPlayInteractionUserProfileContainerView", 0);
    }
    return nativeProfile.window ? nativeProfile : nil;
}

static AWEExternalBridgeMenuSlotView *AWEEnsureExternalBridgeMenuSlot(UIView *stack) {
    if (!stack) return nil;
    if (!gAWEDownloadMenuSlot) {
        gAWEDownloadMenuSlot = [[AWEExternalBridgeMenuSlotView alloc] initWithFrame:CGRectZero];
        gAWEDownloadMenuSlot.backgroundColor = UIColor.clearColor;
        gAWEDownloadMenuSlot.opaque = NO;
        gAWEDownloadMenuSlot.clipsToBounds = NO;
        gAWEDownloadMenuSlot.userInteractionEnabled = YES;
        gAWEDownloadMenuSlot.accessibilityIdentifier = @"AwemeLiquidBar.NativeDownloadMenuSlot";
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.backgroundColor = UIColor.clearColor;
        button.opaque = NO;
        button.clipsToBounds = NO;
        button.accessibilityLabel = @"下载与复制";
        button.showsMenuAsPrimaryAction = YES;
        [gAWEDownloadMenuSlot addSubview:button];
        gAWEDownloadMenuSlot.menuButton = button;
    }
    gAWEDownloadMenuSlot.sourceStack = stack;
    gAWEDownloadMenuSourceStack = stack;

    UIView *hostView = AWEDownloadMenuOverlayHostView(stack);
    if (hostView && gAWEDownloadMenuSlot.superview != hostView) {
        [gAWEDownloadMenuSlot removeFromSuperview];
        [hostView addSubview:gAWEDownloadMenuSlot];
    }
    return gAWEDownloadMenuSlot;
}

static void AWELayoutExternalBridgeMenuForStack(UIView *stack) {
    (void)stack;
    /* 1.0.55a: independent download button retired. Download now lives only
       in the stable avatar-base menu, so no feed/right-stack geometry can
       create, move, hide, or resurrect a floating download control. */
    AWEHideGlobalDownloadMenu();
}

static void AWERefreshExternalBridgeMenu(UIView *stack) {
    (void)stack;
    AWEHideGlobalDownloadMenu();
}

static UIImageView *AWEBestProfileAvatarImageView(UIView *root) {
    if (!root) return nil;
    NSMutableArray<UIImageView *> *images = [NSMutableArray array];
    AWECollectImageViews(root, images, 0);
    UIImageView *best = nil;
    CGFloat bestScore = -CGFLOAT_MAX;
    for (UIImageView *imageView in images) {
        CGRect frame = [imageView convertRect:imageView.bounds toView:root];
        CGFloat width = CGRectGetWidth(frame), height = CGRectGetHeight(frame);
        if (width < 34.0 || height < 34.0 || width > 66.0 || height > 66.0) {
            continue;
        }
        CGFloat score = width * height - fabs(width - height) * 40.0;
        if (imageView.hidden || imageView.alpha < 0.01) score -= 500.0;
        if (score > bestScore) { bestScore = score; best = imageView; }
    }
    return best;
}

static void AWEStoreAndClearProfileVisual(UIView *view) {
    if (!view) return;
    if (![objc_getAssociatedObject(view, &kAWEProfileVisualMarkerKey) boolValue]) {
        objc_setAssociatedObject(view, &kAWEProfileVisualMarkerKey, @YES,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(view, &kAWEProfileOriginalBackgroundKey,
            view.backgroundColor ?: (id)NSNull.null,
            OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(view, &kAWEProfileOriginalBorderWidthKey,
            @(view.layer.borderWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        UIColor *border = view.layer.borderColor
            ? [UIColor colorWithCGColor:view.layer.borderColor]
            : nil;
        objc_setAssociatedObject(view, &kAWEProfileOriginalBorderColorKey,
            border ?: (id)NSNull.null, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    view.backgroundColor = UIColor.clearColor;
    view.layer.borderWidth = 0.0;
    view.layer.borderColor = UIColor.clearColor.CGColor;
}

static UIView *AWETopLevelDescendantOfStack(UIView *view, UIView *stack) {
    UIView *cursor = view;
    while (cursor && cursor.superview && cursor.superview != stack) {
        cursor = cursor.superview;
    }
    return cursor && cursor.superview == stack ? cursor : nil;
}

static UIAction *AWEAvatarLiveAwemeAction(NSString *title,
                                          NSString *systemImage,
                                          UIView *stack,
                                          void (^handler)(id aweme)) {
    __weak UIView *weakStack = stack;
    return [UIAction actionWithTitle:title
        image:[UIImage systemImageNamed:systemImage]
        identifier:nil
        handler:^(__kindof UIAction * _Nonnull action) {
            (void)action;
            UIView *currentStack = weakStack;
            id aweme = AWECurrentAwemeModelForStack(currentStack);
            if (!aweme) {
                AWEShowDownloadToast(@"未识别到当前作品，请稍后重试");
                AWEInteractionDiagnosticWrite(@"AVATAR_MENU_DOWNLOAD model=nil title=%@",
                                              title ?: @"");
                return;
            }
            AWEInteractionDiagnosticWrite(@"AVATAR_MENU_DOWNLOAD model=%@ title=%@",
                                          AWEAwemeIdentity(aweme), title ?: @"");
            if (handler) handler(aweme);
        }];
}

#pragma mark - 1.0.56c13 clean screen v2 (display-only, persistent across reuse)

static void AWEStableCleanSuppressView(UIView *view, BOOL disableInteraction) {
    if (!view) return;
    if (![objc_getAssociatedObject(view, &kAWEStableCleanMarkerKey) boolValue]) {
        objc_setAssociatedObject(view, &kAWEStableCleanMarkerKey, @YES,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(view, &kAWEStableCleanOriginalOpacityKey,
                                 @(view.layer.opacity),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(view, &kAWEStableCleanOriginalInteractionKey,
                                 @(view.userInteractionEnabled),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (!gAWEStableCleanSuppressedViews) {
            gAWEStableCleanSuppressedViews = [NSHashTable weakObjectsHashTable];
        }
        [gAWEStableCleanSuppressedViews addObject:view];
    }
    view.layer.opacity = 0.0f;
    if (disableInteraction) view.userInteractionEnabled = NO;
}

static void AWEStableCleanRestoreView(UIView *view) {
    if (!view || ![objc_getAssociatedObject(view, &kAWEStableCleanMarkerKey) boolValue]) return;
    NSNumber *opacity = objc_getAssociatedObject(view, &kAWEStableCleanOriginalOpacityKey);
    NSNumber *interaction = objc_getAssociatedObject(view, &kAWEStableCleanOriginalInteractionKey);
    if (opacity) view.layer.opacity = opacity.floatValue;
    if (interaction) view.userInteractionEnabled = interaction.boolValue;
    objc_setAssociatedObject(view, &kAWEStableCleanMarkerKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(view, &kAWEStableCleanOriginalOpacityKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(view, &kAWEStableCleanOriginalInteractionKey, nil, OBJC_ASSOCIATION_ASSIGN);
}

static void AWEStableCleanRestoreAll(void) {
    NSArray<UIView *> *views = gAWEStableCleanSuppressedViews.allObjects ?: @[];
    for (UIView *view in views) AWEStableCleanRestoreView(view);
    [gAWEStableCleanSuppressedViews removeAllObjects];
}

static BOOL AWEStableCleanClassLooksLikeSystemMenu(UIView *view) {
    NSString *lower = NSStringFromClass(view.class).lowercaseString;
    return [lower containsString:@"contextmenu"] ||
           [lower containsString:@"menuplatter"] ||
           [lower containsString:@"menulist"] ||
           [lower containsString:@"calloutbar"];
}

static BOOL AWEStableCleanClassIsExplicitTarget(UIView *view) {
    if (!view) return NO;
    /* Runtime builds frequently insert private subclasses around these views.
       Comparing NSStringFromClass() alone misses an already-visible CURRENT
       cell even though the next reused cell later hits the base-class hook.
       Cache the real Class objects and accept subclasses via isKindOfClass:. */
    static NSSet<NSString *> *exactNames = nil;
    static NSArray<Class> *targetClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<NSString *> *names = @[
            @"AWEHPTopBarCTAContainer", @"AWEHPDiscoverFeedEntranceView",
            @"AWELeftSideBarEntranceView", @"DUXBadge", @"AWEBaseElementView",
            @"AWEPlayInteractionDescriptionLabel", @"AWEUserNameLabel",
            @"ACCEditTagStickerView", @"AWEFeedTemplateAnchorView",
            @"AWESearchFeedTagView", @"AWEPlayInteractionSearchAnchorView",
            @"AFDRecommendToFriendTagView", @"AWELandscapeFeedEntryView",
            @"AWEFeedAnchorContainerView", @"AFDAIbumFolioView",
            @"AFDAlbumFolioView", @"DUXPopover", @"AWEMixVideoPanelMoreView",
            @"AWEHotSearchInnerBottomView", @"AWEHPSegmentControlScrollView",
            @"AWEVideoPlayDanmakuContainerView", @"AWEDanmakuContainerView",
            @"AWEStoryProgressSlideView", @"AWEStoryProgressContainerView",
            @"AWEDemaciaChapterProgressSlider",
            @"AWEPlayInteractionProgressContainerView", @"AWEDPlayerProgressContainerView"
        ];
        exactNames = [NSSet setWithArray:names];
        NSMutableArray<Class> *classes = [NSMutableArray arrayWithCapacity:names.count];
        for (NSString *name in names) {
            Class cls = NSClassFromString(name);
            if (cls) [classes addObject:cls];
        }
        targetClasses = [classes copy];
    });
    if ([exactNames containsObject:NSStringFromClass(view.class)]) return YES;
    for (Class cls in targetClasses) {
        if ([view isKindOfClass:cls]) return YES;
    }
    return NO;
}

static BOOL AWEStableCleanViewIsInsideCommentUI(UIView *view) {
    if (!view) return NO;
    UIResponder *responder = view;
    for (NSUInteger depth = 0; responder && depth < 32; depth++) {
        if ([responder isKindOfClass:UIViewController.class]) {
            NSString *lower = NSStringFromClass(((UIViewController *)responder).class).lowercaseString;
            if ([lower containsString:@"comment"]) return YES;
        }
        responder = responder.nextResponder;
    }
    for (UIView *ancestor = view; ancestor; ancestor = ancestor.superview) {
        NSString *lower = NSStringFromClass(ancestor.class).lowercaseString;
        if ([lower containsString:@"comment"] &&
            ([lower containsString:@"panel"] || [lower containsString:@"container"] ||
             [lower containsString:@"list"] || [lower containsString:@"input"])) {
            return YES;
        }
    }
    return NO;
}

static BOOL AWEStableCleanShouldSuppressElementStack(UIView *stack) {
    return gAWEStableCleanScreenEnabled && stack &&
           !AWEStableCleanViewIsInsideCommentUI(stack);
}

static void AWEStableCleanSuppressRightStack(UIView *stack) {
    if (!gAWEStableCleanScreenEnabled || !stack) return;
    AWEHomeProfileGlassView *slot = objc_getAssociatedObject(stack, &kAWEProfileGlassSlotKey);
    UIButton *menuButton = slot.menuButton;
    for (UIView *child in [stack.subviews copy]) {
        if (child == menuButton) continue; /* invisible exit/menu hit target */
        AWEStableCleanSuppressView(child, YES);
    }
    if (menuButton) {
        AWEStableCleanRestoreView(menuButton);
        menuButton.layer.opacity = 1.0f;
        menuButton.userInteractionEnabled = YES;
        menuButton.hidden = NO;
        menuButton.alpha = 1.0;
        menuButton.menu = AWEAvatarBaseMenuForStack(stack, slot.profileHost);
        menuButton.showsMenuAsPrimaryAction = YES;
        [stack bringSubviewToFront:menuButton];
    }
}

/* DYYY's stable clear-screen idea is class-targeted, not a global UILabel /
   UIImageView heuristic.  Scan every visible feed hierarchy so the CURRENT
   item is cleared immediately, but stop at comment UI roots to keep the
   comment drawer fully interactive and readable. */
static void AWEStableCleanSuppressExactTargetsInTree(UIView *root,
                                                       NSUInteger depth) {
    if (!gAWEStableCleanScreenEnabled || !root || depth > 28) return;
    if (AWEStableCleanClassLooksLikeSystemMenu(root)) return;
    if (AWEStableCleanViewIsInsideCommentUI(root)) return;

    NSString *className = NSStringFromClass(root.class);
    if ([className isEqualToString:@"AWEElementStackView"]) {
        AWEStableCleanSuppressRightStack(root);
        return;
    }
    if ([className isEqualToString:@"AWEFeedTopBarContainer"] ||
        AWEStableCleanClassIsExplicitTarget(root)) {
        AWEStableCleanSuppressView(root, YES);
        return;
    }
    for (UIView *child in [root.subviews copy]) {
        AWEStableCleanSuppressExactTargetsInTree(child, depth + 1);
    }
}

static char kAWEStableStatusBarClassHookedKey;

static BOOL AWEClassOwnsInstanceSelector(Class cls, SEL selector) {
    if (!cls || !selector) return NO;
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    BOOL owns = NO;
    for (unsigned int index = 0; index < count; index++) {
        if (method_getName(methods[index]) == selector) { owns = YES; break; }
    }
    free(methods);
    return owns;
}

/* Current Douyin often inserts private hosting/container subclasses above the
   six historical DYYY roots. Install a permanent per-class wrapper on every
   active controller class. The wrapper only changes behavior while our clean
   state is active and otherwise delegates to that class's original IMP. */
static void AWEStableEnsureStatusBarHookForClass(Class cls) {
    if (!cls || [objc_getAssociatedObject((id)cls,
            &kAWEStableStatusBarClassHookedKey) boolValue]) return;
    SEL selector = @selector(prefersStatusBarHidden);
    Method resolved = class_getInstanceMethod(cls, selector);
    if (!resolved) return;
    IMP original = method_getImplementation(resolved);
    const char *types = method_getTypeEncoding(resolved);
    if (!original || !types) return;

    BOOL (^replacementBlock)(id) = ^BOOL(id receiver) {
        if (gAWEStableCleanScreenEnabled) return YES;
        return ((BOOL (*)(id, SEL))original)(receiver, selector);
    };
    IMP replacement = imp_implementationWithBlock(replacementBlock);
    if (!replacement) return;

    if (AWEClassOwnsInstanceSelector(cls, selector)) {
        Method ownMethod = class_getInstanceMethod(cls, selector);
        method_setImplementation(ownMethod, replacement);
    } else {
        class_addMethod(cls, selector, replacement, types);
    }
    objc_setAssociatedObject((id)cls, &kAWEStableStatusBarClassHookedKey,
        @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void AWEStableCleanSuppressStatusBarViewsInTree(UIView *root,
                                                        NSUInteger depth) {
    if (!gAWEStableCleanScreenEnabled || !root || depth > 16) return;
    NSString *lower = NSStringFromClass(root.class).lowercaseString;
    CGRect screenFrame = [root convertRect:root.bounds toView:nil];
    BOOL nearTop = CGRectGetMinY(screenFrame) < 110.0 &&
                   CGRectGetHeight(screenFrame) <= 110.0;
    if (nearTop && [lower containsString:@"statusbar"]) {
        AWEStableCleanSuppressView(root, NO);
        return;
    }
    for (UIView *child in [root.subviews copy]) {
        AWEStableCleanSuppressStatusBarViewsInTree(child, depth + 1);
    }
}

static void AWEStableCleanRequestStatusBarRefreshController(UIViewController *controller,
                                                             NSUInteger depth) {
    if (!controller || depth > 18) return;
    if (gAWEStableCleanScreenEnabled)
        AWEStableEnsureStatusBarHookForClass(controller.class);
    [controller setNeedsStatusBarAppearanceUpdate];
    if (controller.presentedViewController) {
        AWEStableCleanRequestStatusBarRefreshController(controller.presentedViewController,
                                                        depth + 1);
    }
    if ([controller isKindOfClass:UINavigationController.class]) {
        AWEStableCleanRequestStatusBarRefreshController(
            ((UINavigationController *)controller).topViewController, depth + 1);
    }
    if ([controller isKindOfClass:UITabBarController.class]) {
        AWEStableCleanRequestStatusBarRefreshController(
            ((UITabBarController *)controller).selectedViewController, depth + 1);
    }
    for (UIViewController *child in controller.childViewControllers) {
        AWEStableCleanRequestStatusBarRefreshController(child, depth + 1);
    }
}

static void AWEStableCleanRequestStatusBarRefresh(void) {
    UIApplication *app = UIApplication.sharedApplication;
    NSMutableArray<UIWindow *> *windows = [NSMutableArray array];
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in app.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            if (scene.activationState != UISceneActivationStateForegroundActive &&
                scene.activationState != UISceneActivationStateForegroundInactive) continue;
            [windows addObjectsFromArray:((UIWindowScene *)scene).windows ?: @[]];
        }
    } else {
        [windows addObjectsFromArray:app.windows ?: @[]];
    }
    for (UIWindow *window in windows) {
        if (!window.hidden && window.alpha > 0.01 && window.rootViewController) {
            AWEStableCleanRequestStatusBarRefreshController(window.rootViewController, 0);
        }
    }
}

static void AWEStableApplyCleanScreenGlobal(void) {
    if (!gAWEStableCleanScreenEnabled) return;
    UIApplication *app = UIApplication.sharedApplication;
    NSArray<UIWindow *> *windows = nil;
    if (@available(iOS 13.0, *)) {
        NSMutableArray<UIWindow *> *collected = [NSMutableArray array];
        for (UIScene *scene in app.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            if (scene.activationState != UISceneActivationStateForegroundActive &&
                scene.activationState != UISceneActivationStateForegroundInactive) continue;
            [collected addObjectsFromArray:((UIWindowScene *)scene).windows ?: @[]];
        }
        windows = collected;
    } else {
        windows = app.windows ?: @[];
    }
    for (UIWindow *window in windows) {
        if (!window || window.hidden || window.alpha <= 0.01) continue;
        AWEStableCleanSuppressStatusBarViewsInTree(window, 0);
        if (window.windowLevel != UIWindowLevelNormal) continue;
        if (window == (UIWindow *)gAWEAlbumMorphOverlayWindow ||
            [NSStringFromClass(window.class) containsString:@"AWEAlbumMorphOverlayWindow"]) continue;
        AWEStableCleanSuppressExactTargetsInTree(window, 0);
    }
    AWEStableCleanEnforceBottomBarSuppression();
}

static void AWEStableCleanEnforceBottomBarSuppression(void) {
    if (!gAWEStableCleanScreenEnabled) return;
    if (gAWELastTabBar) {
        UIView *original = (UIView *)gAWELastTabBar;
        AWEStableCleanSuppressView(original, YES);
        UITabBar *nativeBar = objc_getAssociatedObject(original, &kAWENativeBarKey);
        if (nativeBar) AWEStableCleanSuppressView(nativeBar, YES);
    }
    if (gAWEAlbumMorphController) {
        AWEStableCleanSuppressView(gAWEAlbumMorphController.view, YES);
        AWEStableCleanSuppressView(gAWEAlbumMorphController.tabBar, YES);
    }
    if (gAWEAlbumMorphOverlayWindow) {
        AWEStableCleanSuppressView((UIView *)gAWEAlbumMorphOverlayWindow, YES);
    }
}

static void AWEScheduleCleanScreenReapply(NSString *reason) {
    if (!gAWEStableCleanScreenEnabled) return;
    CFTimeInterval now = CACurrentMediaTime();
    if (now - gAWEStableCleanLastReapplyTime < 0.035) return;
    gAWEStableCleanLastReapplyTime = now;
    NSUInteger generation = ++gAWEStableCleanReapplyGeneration;
    AWEStableApplyCleanScreenGlobal();
    const NSTimeInterval delays[] = {0.055, 0.16, 0.36};
    for (NSUInteger i = 0; i < sizeof(delays) / sizeof(delays[0]); i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
            (int64_t)(delays[i] * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!gAWEStableCleanScreenEnabled ||
                generation != gAWEStableCleanReapplyGeneration) return;
            AWEStableApplyCleanScreenGlobal();
        });
    }
    if (AWEInteractionDiagnosticsEnabled() && reason.length) {
        AWEInteractionDiagnosticWrite(@"CLEAN_V2_REAPPLY reason=%@ gen=%lu",
                                      reason, (unsigned long)generation);
    }
}

static void AWEStableRefreshCurrentCleanMenu(void) {
    UIView *stack = gAWEStableCleanScreenStack;
    if (!stack) return;
    AWEHomeProfileGlassView *slot = objc_getAssociatedObject(stack, &kAWEProfileGlassSlotKey);
    if (!slot.menuButton) return;
    slot.menuButton.menu = AWEAvatarBaseMenuForStack(stack, slot.profileHost);
    slot.menuButton.showsMenuAsPrimaryAction = YES;
}

static void AWEStableEnterCleanScreenFromStack(UIView *stack) {
    if (gAWEStableCleanScreenEnabled || !stack || !stack.window) return;
    gAWEStableCleanScreenEnabled = YES;
    gAWEStableCleanScreenStack = stack;
    AWEStableCleanRequestStatusBarRefresh();
    AWEStableRefreshCurrentCleanMenu();
    AWEStableApplyCleanScreenGlobal();
    AWEScheduleCleanScreenReapply(@"enter");
    AWEInteractionDiagnosticWrite(@"CLEAN_STABLE enter stack=%@", AWEInteractionObjectSummary(stack));
}

static void AWEStableExitCleanScreen(void) {
    if (!gAWEStableCleanScreenEnabled) return;
    UIView *stack = gAWEStableCleanScreenStack;
    gAWEStableCleanScreenEnabled = NO;
    ++gAWEStableCleanReapplyGeneration;
    AWEStableCleanRestoreAll();
    AWEStableCleanRequestStatusBarRefresh();
    gAWEStableCleanScreenStack = stack;
    AWEStableRefreshCurrentCleanMenu();
    gAWEStableCleanScreenStack = nil;
    AWEInteractionDiagnosticWrite(@"CLEAN_STABLE exit");
}

static UIMenu *AWEAvatarBaseMenuForStack(UIView *stack, UIView *profileHost) {
    NSMutableArray<UIMenuElement *> *children = [NSMutableArray array];
    __weak UIView *weakProfileHost = profileHost;
    UIAction *profileAction = [UIAction actionWithTitle:@"进入主页"
        image:[UIImage systemImageNamed:@"person.crop.circle"]
        identifier:nil
        handler:^(__kindof UIAction * _Nonnull action) {
            (void)action;
            UIView *target = weakProfileHost;
            BOOL result = AWETriggerQuickMenuDestinationView(target);
            AWEInteractionDiagnosticWrite(@"AVATAR_MENU profile result=%d target=%@",
                                          result, AWEInteractionObjectSummary(target));
        }];
    [children addObject:profileAction];

    __weak UIView *weakCleanStack = stack;
    UIAction *cleanAction = [UIAction actionWithTitle:(gAWEStableCleanScreenEnabled ? @"退出清屏" : @"一键清屏")
        image:[UIImage systemImageNamed:(gAWEStableCleanScreenEnabled ? @"eye" : @"eye.slash")]
        identifier:nil
        handler:^(__kindof UIAction * _Nonnull action) {
            (void)action;
            if (gAWEStableCleanScreenEnabled) {
                AWEStableExitCleanScreen();
            } else {
                UIView *currentStack = weakCleanStack;
                if (currentStack.window) AWEStableEnterCleanScreenFromStack(currentStack);
            }
        }];
    [children addObject:cleanAction];

    if (AWEAvatarMenuDownloadEnabled()) {
        id snapshot = AWECurrentAwemeModelForStack(stack);
        BOOL snapshotIsAlbum = snapshot && AWEAlbumImagesForAweme(snapshot).count > 0;
        NSString *saveTitle = snapshotIsAlbum ? @"保存图片" : @"保存视频";
        NSString *saveSymbol = snapshotIsAlbum ? @"photo" : @"video";
        [children addObject:AWEAvatarLiveAwemeAction(
            saveTitle, saveSymbol, stack, ^(id aweme) {
                if (AWEAlbumImagesForAweme(aweme).count > 0) {
                    AWEDownloadCurrentImageForAweme(aweme);
                } else {
                    AWEDownloadSmartVideoForAweme(aweme);
                }
            })];

        if (snapshot && AWEAlbumImagesForAweme(snapshot).count > 1) {
            [children addObject:AWEAvatarLiveAwemeAction(
                @"保存全部图片", @"photo.on.rectangle.angled", stack,
                ^(id aweme) { AWEDownloadAllImagesForAweme(aweme); })];
        }

        [children addObject:AWEAvatarLiveAwemeAction(
            @"保存音频", @"waveform", stack,
            ^(id aweme) { AWEDownloadAudioForAweme(aweme); })];
        [children addObject:AWEAvatarLiveAwemeAction(
            @"复制完整文案", @"doc.on.doc", stack,
            ^(id aweme) { AWECopyCompleteTextForAweme(aweme); })];
    }
    return [UIMenu menuWithTitle:@"" children:children];
}

static AWEHomeProfileGlassView *AWEEnsureProfileGlassSlot(UIView *stack) {
    if (!stack) return nil;
    AWEHomeProfileGlassView *slot = objc_getAssociatedObject(
        stack, &kAWEProfileGlassSlotKey);
    if (!slot) {
        slot = [[AWEHomeProfileGlassView alloc] initWithFrame:CGRectZero];
        slot.userInteractionEnabled = NO;
        slot.backgroundColor = UIColor.clearColor;
        slot.opaque = NO;
        slot.accessibilityIdentifier = @"AwemeLiquidBar.HomeAction.ProfileGlass";
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.userInteractionEnabled = NO;
        button.backgroundColor = UIColor.clearColor;
        button.opaque = NO;
        button.clipsToBounds = NO;
        [slot addSubview:button];
        slot.glassButton = button;

        UIButton *menuButton = [UIButton buttonWithType:UIButtonTypeCustom];
        menuButton.backgroundColor = UIColor.clearColor;
        menuButton.opaque = NO;
        menuButton.clipsToBounds = NO;
        menuButton.userInteractionEnabled = YES;
        menuButton.showsMenuAsPrimaryAction = YES;
        menuButton.accessibilityLabel = @"头像操作";
        menuButton.accessibilityIdentifier = @"AwemeLiquidBar.HomeAction.ProfileMenu";
        [stack addSubview:menuButton];
        slot.menuButton = menuButton;

        objc_setAssociatedObject(stack, &kAWEProfileGlassSlotKey, slot,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [stack insertSubview:slot atIndex:0];
    } else {
        if (slot.superview != stack) {
            [slot removeFromSuperview];
            [stack insertSubview:slot atIndex:0];
        }
        if (slot.menuButton.superview != stack) {
            [slot.menuButton removeFromSuperview];
            [stack addSubview:slot.menuButton];
        }
    }
    return slot;
}

static void AWERefreshProfileAvatarGlass(UIView *stack) {
    if (!stack || !stack.window) {
        AWEHomeProfileGlassView *existing = stack ? objc_getAssociatedObject(
            stack, &kAWEProfileGlassSlotKey) : nil;
        existing.hidden = YES;
        existing.menuButton.hidden = YES;
        return;
    }
    if (stack.hidden || stack.alpha < 0.01) {
        /* Preserve the live binding during paging/comment transitions. The
           parent stack already controls actual visibility. */
        return;
    }
    UIView *pictureHost = AWEFindViewByExactRuntimeClass(
        stack, @"AWEPlayInteractionUserProfilePictureView", 0);
    if (!pictureHost) {
        pictureHost = AWEFindViewByExactRuntimeClass(
            stack, @"AWEPlayInteractionUserProfileContainerView", 0);
    }
    UIImageView *avatar = AWEBestProfileAvatarImageView(pictureHost);
    if (!pictureHost || !avatar || !avatar.window) {
        AWEHomeProfileGlassView *existing = objc_getAssociatedObject(
            stack, &kAWEProfileGlassSlotKey);
        if (!existing.profileHost || !existing.profileHost.window) {
            existing.hidden = YES;
            existing.menuButton.hidden = YES;
        }
        return;
    }

    AWEHomeProfileGlassView *slot = AWEEnsureProfileGlassSlot(stack);
    if (!slot) return;
    const CGFloat diameter = 54.0;
    CGPoint center = [avatar convertPoint:
        CGPointMake(CGRectGetMidX(avatar.bounds), CGRectGetMidY(avatar.bounds))
        toView:stack];
    slot.bounds = CGRectMake(0.0, 0.0, diameter, diameter);
    slot.center = center;
    slot.glassButton.frame = slot.bounds;
    slot.profileHost = pictureHost;
    slot.avatarImageView = avatar;
    slot.hidden = NO;
    slot.alpha = 1.0;

    CGFloat avatarHitDiameter = MIN(50.0, MAX(40.0,
        MIN(CGRectGetWidth(avatar.bounds), CGRectGetHeight(avatar.bounds))));
    slot.menuButton.bounds = CGRectMake(0.0, 0.0, avatarHitDiameter, avatarHitDiameter);
    slot.menuButton.center = center;
    slot.menuButton.hidden = NO;
    slot.menuButton.alpha = 1.0;
    slot.menuButton.menu = AWEAvatarBaseMenuForStack(stack, pictureHost);
    slot.menuButton.showsMenuAsPrimaryAction = YES;

    UIView *anchor = AWETopLevelDescendantOfStack(pictureHost, stack);
    if (anchor && anchor != slot) {
        [stack insertSubview:slot belowSubview:anchor];
    }
    [stack bringSubviewToFront:slot.menuButton];
    AWEStoreAndClearProfileVisual(pictureHost);
    AWEStoreAndClearProfileVisual(avatar.superview);
    AWEStoreAndClearProfileVisual(avatar);
    avatar.layer.cornerRadius = MIN(CGRectGetWidth(avatar.bounds),
                                    CGRectGetHeight(avatar.bounds)) * 0.5;
    avatar.layer.cornerCurve = kCACornerCurveContinuous;
    avatar.clipsToBounds = YES;
    AWEConfigureAdaptiveSystemGlassPlateButton(
        slot.glassButton, @"right.profile.avatar", AWEHomeTintedGlassEnabled());
    AWEInstallGlassPressFeedback(slot.menuButton, slot.glassButton);
}

static NSMutableDictionary<NSNumber *, AWEHomeActionSlotView *> *
AWEHomeActionSlotsForStack(UIView *stack) {
    NSMutableDictionary *slots = objc_getAssociatedObject(stack,
                                                           &kAWEHomeActionStackSlotsKey);
    if (!slots) {
        slots = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(stack, &kAWEHomeActionStackSlotsKey, slots,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return slots;
}

static AWEHomeActionSlotView *AWEEnsureHomeActionSlot(UIView *stack,
                                                       AWEHomeActionKind kind) {
    if (!stack || kind == AWEHomeActionKindUnknown) return nil;
    NSMutableDictionary *slots = AWEHomeActionSlotsForStack(stack);
    NSNumber *key = @(kind);
    AWEHomeActionSlotView *slot = slots[key];
    if (!slot) {
        slot = [[AWEHomeActionSlotView alloc] initWithFrame:CGRectZero];
        slot.accessibilityIdentifier = [NSString stringWithFormat:
            @"AwemeLiquidBar.HomeActionSlot.%ld", (long)kind];
        slot.userInteractionEnabled = NO;
        slot.backgroundColor = UIColor.clearColor;
        slot.opaque = NO;

        if (@available(iOS 26.0, *)) {
            UIButton *glassButton = [UIButton buttonWithType:UIButtonTypeCustom];
            glassButton.userInteractionEnabled = NO;
            glassButton.backgroundColor = UIColor.clearColor;
            glassButton.opaque = NO;
            glassButton.clipsToBounds = NO;
            [slot addSubview:glassButton];
            slot.systemGlassButton = glassButton;
        }
        slot.actionKind = kind;

        slots[key] = slot;
        [stack addSubview:slot];
    } else if (slot.superview != stack) {
        [slot removeFromSuperview];
        [stack addSubview:slot];
    }
    return slot;
}

static void AWEConfigureHomeActionSlot(AWEHomeActionSlotView *slot,
                                        UIView *button,
                                        UIImageView *source,
                                        AWEHomeActionKind kind,
                                        BOOL selected,
                                        CGPoint center) {
    const CGFloat diameter = 46.0;
    const CGFloat symbolSize = (kind == AWEHomeActionKindShare) ? 20.0 : 21.0;
    NSString *symbolKey = AWEHomeActionSymbolKey(kind, selected);
    BOOL originalPNG = NO;
    UIImage *symbol = AWEConfiguredRoleImage(
        symbolKey, AWEHomeActionSymbolNames(kind, selected), symbolSize,
        UIImageSymbolWeightSemibold, &originalPNG);
    if (!symbol) { slot.hidden = YES; return; }

    slot.originalView = button;
    slot.sourceImageView = source;
    slot.actionKind = kind;
    slot.bounds = CGRectMake(0.0, 0.0, diameter, diameter);
    slot.center = CGPointMake(center.x, center.y - 4.0);
    slot.hidden = NO;
    slot.alpha = 1.0;
    slot.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
    /* Keep the verified pass-through interaction path: Douyin's original
       AWEFeedVideoButton remains the sole touch owner.  The glass is visual
       only, so like/comment/favorite/share cannot be intercepted or duplicated. */
    slot.userInteractionEnabled = NO;
    slot.systemGlassButton.userInteractionEnabled = NO;
    slot.systemGlassButton.frame = slot.bounds;

    UIColor *foregroundColor = nil;
    if (!originalPNG) {
        AWEConfiguredIconColorMode colorMode = AWEStoredSymbolColorMode(symbolKey);
        if (colorMode != AWEConfiguredIconColorModeAutomatic) {
            /* Fixed/accent/custom always outrank every automatic state colour. */
            foregroundColor = AWEApplyConfiguredIconColorMode(symbolKey, nil);
        } else if (selected && kind == AWEHomeActionKindLike) {
            foregroundColor = UIColor.systemPinkColor;
        } else if (selected && kind == AWEHomeActionKindFavorite) {
            foregroundColor = UIColor.systemYellowColor;
        } else if (AWEHomeTransparentGlassEnabled()) {
            /* The experimental per-button material sampler is intentionally
               not used for the right action stack.  It could hide the glyph
               and, more importantly, forced the overlay to own touches.  Use
               the last stable source-tint fallback while the original Douyin
               button continues to receive every gesture. */
            foregroundColor = AWEHomeExplicitForegroundForSource(
                source, slot, YES);
        }
    }

    if (@available(iOS 26.0, *)) {
        slot.photosGlassHost.hidden = YES;
        slot.systemGlassButton.hidden = NO;
        AWEConfigureAdaptiveSystemGlassIconButton(
            slot.systemGlassButton,
            symbol,
            symbolKey,
            symbolSize,
            foregroundColor,
            originalPNG,
            AWEHomeTintedGlassEnabled(),
            NO);
        AWEInstallGlassPressFeedback(button, slot.systemGlassButton);
    } else {
        slot.hidden = YES;
    }
}

static void AWEHideAndReleaseHomeActionSlot(AWEHomeActionSlotView *slot) {
    if (!slot) return;
    if (slot.sourceImageView) AWEUnbindHomeActionSource(slot.sourceImageView);
    if (slot.originalView) {
        objc_setAssociatedObject(slot.originalView,
                                 &kAWEHomeActionOriginalImageViewKey,
                                 nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    slot.originalView = nil;
    slot.sourceImageView = nil;
    slot.systemGlassButton.hidden = YES;
    slot.systemGlassButton.userInteractionEnabled = NO;
    slot.userInteractionEnabled = NO;
    slot.hidden = YES;
}

static void AWERefreshHomeActionStack(UIView *stack) {
    if (!AWEPluginFeaturesEnabled() || gAWESettingsVisible) return;
    if (!stack || objc_getAssociatedObject(stack, &kAWEHomeActionStackApplyingKey)) return;
    CGRect stackWindow = stack.window
        ? [stack convertRect:stack.bounds toView:stack.window]
        : CGRectZero;
    AWEHomeDiagnosticWrite(NO,
        @"STACK_REFRESH stack=%p class=%@ frame=%@ visible=%d hidden=%d alpha=%.3f",
        stack, NSStringFromClass(stack.class), NSStringFromCGRect(stackWindow),
        AWEHomeViewEffectivelyVisible(stack), stack.hidden, stack.alpha);
    objc_setAssociatedObject(stack, &kAWEHomeActionStackApplyingKey, @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    NSMutableDictionary<NSNumber *, AWEHomeActionSlotView *> *slots =
        AWEHomeActionSlotsForStack(stack);
    if (!stack.window) {
        if (gAWEDownloadMenuSourceStack == stack) AWEHideGlobalDownloadMenu();
        AWEHomeProfileGlassView *profileSlot = objc_getAssociatedObject(
            stack, &kAWEProfileGlassSlotKey);
        profileSlot.hidden = YES;
        profileSlot.menuButton.hidden = YES;
        AWEExternalBridgeMenuSlotView *bridgeSlot = objc_getAssociatedObject(
            stack, &kAWEExternalBridgeMenuSlotKey);
        bridgeSlot.hidden = YES;
        [bridgeSlot removeFromSuperview];
        for (AWEHomeActionSlotView *slot in slots.allValues) {
            AWEHideAndReleaseHomeActionSlot(slot);
        }
        objc_setAssociatedObject(stack, &kAWEHomeActionStackApplyingKey, nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }
    if (stack.hidden || stack.alpha < 0.01) {
        if (gAWEDownloadMenuSourceStack == stack) AWEHideGlobalDownloadMenu();
        /* Keep visual slots and source bindings intact. They are children of
           the stack and naturally follow its temporary hidden/offscreen state. */
        AWEExternalBridgeMenuSlotView *bridgeSlot = objc_getAssociatedObject(
            stack, &kAWEExternalBridgeMenuSlotKey);
        bridgeSlot.hidden = YES;
        objc_setAssociatedObject(stack, &kAWEHomeActionStackApplyingKey, nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }

    NSArray<UIView *> *buttons = AWESortedVisibleHomeActionButtons(stack);
    AWEHomeDiagnosticWrite(NO, @"STACK_BUTTONS stack=%p count=%lu",
                           stack, (unsigned long)buttons.count);
    NSMutableSet<NSNumber *> *seen = [NSMutableSet set];
    for (UIView *button in buttons) {
        AWEHomeActionKind kind = AWEHomeActionKindForButton(button, buttons);
        if (kind == AWEHomeActionKindUnknown || kind > AWEHomeActionKindShare) continue;
        NSNumber *kindKey = @(kind);
        if ([seen containsObject:kindKey]) continue;

        UIImageView *source = AWEBestHomeActionImageView(button);
        if (!source || !source.image) continue;
        BOOL selected = AWEHomeActionIsSelected(button, kind, source);
        CGPoint iconCenter = [source convertPoint:
            CGPointMake(CGRectGetMidX(source.bounds), CGRectGetMidY(source.bounds))
            toView:stack];
        if (!isfinite(iconCenter.x) || !isfinite(iconCenter.y)) continue;

        AWEHomeActionSlotView *slot = AWEEnsureHomeActionSlot(stack, kind);
        if (!slot) continue;
        if (slot.sourceImageView && slot.sourceImageView != source) {
            AWEUnbindHomeActionSource(slot.sourceImageView);
        }
        if (slot.originalView && slot.originalView != button) {
            objc_setAssociatedObject(slot.originalView,
                                     &kAWEHomeActionOriginalImageViewKey,
                                     nil,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }

        AWEBindHomeActionSource(button, source);
        AWEConfigureHomeActionSlot(slot, button, source, kind, selected, iconCenter);
        [stack bringSubviewToFront:slot];
        [seen addObject:kindKey];
    }

    for (NSNumber *key in slots.allKeys) {
        if (![seen containsObject:key]) {
            AWEHomeActionSlotView *slot = slots[key];
            BOOL bindingStillLocal = slot.originalView && slot.sourceImageView &&
                AWEViewIsDescendantOfView(slot.originalView, stack) &&
                slot.sourceImageView.image != nil;
            /* Do not make a one-frame incomplete paging tree permanent. */
            if (!bindingStillLocal) slot.hidden = YES;
        }
    }
    AWERefreshProfileAvatarGlass(stack);
    AWERefreshExternalBridgeMenu(stack);
    objc_setAssociatedObject(stack, &kAWEHomeActionStackApplyingKey, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void AWELayoutBoundHomeActionSlots(UIView *stack) {
    if (!stack || !stack.window) return;
    NSMutableDictionary<NSNumber *, AWEHomeActionSlotView *> *slots =
        objc_getAssociatedObject(stack, &kAWEHomeActionStackSlotsKey);
    if (![slots isKindOfClass:NSMutableDictionary.class]) return;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    for (AWEHomeActionSlotView *slot in slots.allValues) {
        UIImageView *source = slot.sourceImageView;
        UIView *owner = slot.originalView;
        if (!source || !owner || !source.image ||
            !AWEViewIsDescendantOfView(owner, stack)) continue;
        CGPoint center = [source convertPoint:
            CGPointMake(CGRectGetMidX(source.bounds), CGRectGetMidY(source.bounds))
            toView:stack];
        if (!isfinite(center.x) || !isfinite(center.y)) continue;
        slot.bounds = CGRectMake(0.0, 0.0, 46.0, 46.0);
        slot.center = CGPointMake(center.x, center.y - 4.0);
        slot.systemGlassButton.frame = slot.bounds;
        slot.hidden = NO;
    }
    AWELayoutExternalBridgeMenuForStack(stack);
    [CATransaction commit];
}

static void AWEScheduleHomeActionStackRefresh(UIView *stack) {
    if (!AWEPluginFeaturesEnabled() || !stack) return;
    if ([objc_getAssociatedObject(
            stack, &kAWEHomeActionStackRefreshPendingKey) boolValue]) {
        return;
    }
    objc_setAssociatedObject(stack, &kAWEHomeActionStackRefreshPendingKey,
                             @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSInteger generation =
        [objc_getAssociatedObject(stack, &kAWEHomeActionStackRetryGenerationKey)
            integerValue] + 1;
    objc_setAssociatedObject(stack, &kAWEHomeActionStackRetryGenerationKey,
                             @(generation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSArray<NSNumber *> *delays = @[@0.0, @0.18, @0.55];
    __weak UIView *weakStack = stack;
    for (NSUInteger index = 0; index < delays.count; index++) {
        NSNumber *delay = delays[index];
        BOOL finalPass = index + 1 == delays.count;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            UIView *strongStack = weakStack;
            if (!strongStack) return;
            NSInteger current = [objc_getAssociatedObject(
                strongStack, &kAWEHomeActionStackRetryGenerationKey) integerValue];
            if (current == generation) {
                AWERefreshHomeActionStack(strongStack);
            }
            if (finalPass) {
                objc_setAssociatedObject(strongStack,
                    &kAWEHomeActionStackRefreshPendingKey,
                    nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        });
    }
}

static void AWEScheduleHomeActionRefreshForButton(UIView *button) {
    if (!AWEPluginFeaturesEnabled()) return;
    UIView *stack = AWEHomeActionStackForView(button);
    if (stack) AWEScheduleHomeActionStackRefresh(stack);
}

static UIView *AWEFindViewByExactRuntimeClass(UIView *root,
                                              NSString *className,
                                              NSUInteger depth) {
    if (!root || depth > 18) return nil;
    if ([NSStringFromClass(root.class) isEqualToString:className]) return root;
    for (UIView *child in root.subviews) {
        UIView *result = AWEFindViewByExactRuntimeClass(child, className, depth + 1);
        if (result) return result;
    }
    return nil;
}

static UIImageView *AWEBestTopIconImageView(UIView *root) {
    if (!root) return nil;
    NSMutableArray<UIImageView *> *images = [NSMutableArray array];
    AWECollectImageViews(root, images, 0);
    UIImageView *best = nil;
    CGFloat bestScore = -CGFLOAT_MAX;
    for (UIImageView *imageView in images) {
        if (!imageView.image) continue;
        CGRect frame = [imageView convertRect:imageView.bounds toView:root];
        CGFloat width = CGRectGetWidth(frame), height = CGRectGetHeight(frame);
        if (width < 15.0 || height < 15.0 || width > 52.0 || height > 52.0) continue;
        CGFloat score = width * height - fabs(width - height) * 24.0;
        if (imageView.hidden || imageView.alpha < 0.01) score -= 200.0;
        if (score > bestScore) { bestScore = score; best = imageView; }
    }
    return best;
}

static UIView *AWEFindTopOwnerCandidate(UIView *root, BOOL search) {
    if (!root) return nil;
    if (search) {
        UIView *discover = AWEFindViewByExactRuntimeClass(
            root, @"AWEHPDiscoverFeedEntranceView", 0);
        if (discover) return discover;
        return AWEFindViewByExactRuntimeClass(
            root, @"AWEHPSearchBubbleEntranceView", 0);
    }
    return AWEFindViewByExactRuntimeClass(
        root, @"AWELeftSideBarEntranceView", 0);
}

static UIImageView *AWEFindTopImageByGeometry(UIView *container, BOOL search) {
    if (!container || !container.window) return nil;
    NSMutableArray<UIImageView *> *images = [NSMutableArray array];
    AWECollectImageViews(container.window, images, 0);
    UIImageView *best = nil;
    CGFloat bestScore = -CGFLOAT_MAX;
    for (UIImageView *imageView in images) {
        if (!imageView.image || !AWEHomeViewEffectivelyVisible(imageView)) continue;
        CGRect frame = [imageView convertRect:imageView.bounds toView:container];
        CGFloat w = CGRectGetWidth(frame), h = CGRectGetHeight(frame);
        CGFloat midX = CGRectGetMidX(frame), midY = CGRectGetMidY(frame);
        if (w < 16.0 || h < 16.0 || w > 48.0 || h > 48.0) continue;
        if (midY < -18.0 || midY > CGRectGetHeight(container.bounds) + 18.0) continue;
        if (search && midX < CGRectGetWidth(container.bounds) * 0.72) continue;
        if (!search && midX > CGRectGetWidth(container.bounds) * 0.28) continue;
        CGFloat targetX = search ? CGRectGetWidth(container.bounds) - 28.0 : 28.0;
        CGFloat targetY = CGRectGetMidY(container.bounds);
        CGFloat score = 1000.0 - fabs(midX - targetX) * 12.0
                              - fabs(midY - targetY) * 10.0
                              - fabs(w - h) * 12.0;
        NSString *name = NSStringFromClass(imageView.class).lowercaseString;
        NSString *evidence = AWEHomeActionEvidence(imageView);
        if (search && ([name containsString:@"search"] ||
                       [evidence containsString:@"搜索"] ||
                       [evidence containsString:@"search"])) score += 900.0;
        if (!search && ([name containsString:@"menu"] ||
                        [name containsString:@"sidebar"] ||
                        [evidence containsString:@"菜单"])) score += 900.0;
        if (score > bestScore) { bestScore = score; best = imageView; }
    }
    return best;
}

static void AWERestoreTopOwnerVisual(AWEHomeTopSlotView *slot) {
    if (!slot || !slot.ownerView) return;
    UIView *owner = slot.ownerView;
    NSNumber *opacity = objc_getAssociatedObject(
        owner, &kAWETopOwnerLayerOpacityKey);
    NSNumber *interaction = objc_getAssociatedObject(
        owner, &kAWETopOwnerInteractionKey);
    owner.layer.opacity = opacity ? opacity.floatValue : 1.0f;
    if (interaction) owner.userInteractionEnabled = interaction.boolValue;
    objc_setAssociatedObject(owner, &kAWETopOwnerLayerOpacityKey,
                             nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(owner, &kAWETopOwnerInteractionKey,
                             nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(owner, &kAWETopOwnerSlotKey,
                             nil, OBJC_ASSOCIATION_ASSIGN);
    slot.ownerView = nil;
}

static void AWEHideTopOwnerVisual(AWEHomeTopSlotView *slot,
                                  UIView *owner,
                                  UIView *container) {
    if (!slot) return;
    if (slot.ownerView && slot.ownerView != owner) {
        AWERestoreTopOwnerVisual(slot);
    }
    if (!owner || owner == container) return;
    slot.ownerView = owner;
    objc_setAssociatedObject(owner, &kAWETopOwnerSlotKey, slot,
                             OBJC_ASSOCIATION_ASSIGN);
    if (!objc_getAssociatedObject(owner, &kAWETopOwnerLayerOpacityKey)) {
        objc_setAssociatedObject(owner, &kAWETopOwnerLayerOpacityKey,
                                 @(owner.layer.opacity),
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    /*
     layer.opacity hides the original artwork but does not disable UIView hit
     testing, so the real Douyin menu/search control still receives the tap.
    */
    owner.layer.opacity = 0.0f;
    AWEHomeDiagnosticWrite(NO,
        @"TOP_OWNER_HIDE kind=%@ owner=%p/%@ frame=%@ layerOpacity=%.3f",
        slot.topKind == AWEHomeTopActionKindSearch ? @"SEARCH" : @"MENU",
        owner, NSStringFromClass(owner.class),
        NSStringFromCGRect(owner.window
            ? [owner convertRect:owner.bounds toView:owner.window]
            : CGRectZero),
        owner.layer.opacity);
}

static BOOL AWEBottomBarSearchIsVisible(void) {
    return [AWEAlbumMorphVisibleItemIdentifiers() containsObject:@"search"];
}

static void AWESuppressTopSearchForBottomSearch(UIView *container,
                                                 UIView *owner,
                                                 UIImageView *source) {
    if (!container) return;
    AWEHomeTopSlotView *slot = AWEEnsureTopSlot(
        container, AWEHomeTopActionKindSearch);
    if (!slot) return;

    if (owner) {
        AWEHideTopSourceImage(slot, source ?: AWEBestTopIconImageView(owner));
        AWEHideTopOwnerVisual(slot, owner, container);
        if (!objc_getAssociatedObject(owner, &kAWETopOwnerInteractionKey)) {
            objc_setAssociatedObject(owner, &kAWETopOwnerInteractionKey,
                                     @(owner.userInteractionEnabled),
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        owner.userInteractionEnabled = NO;
    } else if (slot.ownerView) {
        slot.ownerView.layer.opacity = 0.0f;
        slot.ownerView.userInteractionEnabled = NO;
    }

    slot.userInteractionEnabled = NO;
    slot.hitButton.userInteractionEnabled = NO;
    slot.hitButton.hidden = YES;
    slot.photosGlassHost.hidden = YES;
    slot.hidden = YES;
}

static void AWEHideTopSourceImage(AWEHomeTopSlotView *slot, UIImageView *source) {
    if (!slot) return;
    if (slot.sourceImageView && slot.sourceImageView != source) {
        NSNumber *hidden = objc_getAssociatedObject(slot.sourceImageView,
                                                     &kAWETopSourceHiddenKey);
        NSNumber *alpha = objc_getAssociatedObject(slot.sourceImageView,
                                                    &kAWETopSourceAlphaKey);
        slot.sourceImageView.hidden = hidden ? hidden.boolValue : NO;
        slot.sourceImageView.alpha = alpha ? alpha.doubleValue : 1.0;
        objc_setAssociatedObject(slot.sourceImageView, &kAWETopSourceHiddenKey,
                                 nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(slot.sourceImageView, &kAWETopSourceAlphaKey,
                                 nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(slot.sourceImageView, &kAWETopSourceSlotKey,
                                 nil, OBJC_ASSOCIATION_ASSIGN);
    }
    slot.sourceImageView = source;
    if (!source) return;
    objc_setAssociatedObject(source, &kAWETopSourceSlotKey, slot,
                             OBJC_ASSOCIATION_ASSIGN);
    if (!objc_getAssociatedObject(source, &kAWETopSourceHiddenKey)) {
        objc_setAssociatedObject(source, &kAWETopSourceHiddenKey,
                                 @(source.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(source, &kAWETopSourceAlphaKey,
                                 @(source.alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    source.hidden = YES;
    source.alpha = 0.0;
}

static void AWERestoreTopSourceImage(AWEHomeTopSlotView *slot) {
    if (!slot || !slot.sourceImageView) return;
    UIImageView *source = slot.sourceImageView;
    NSNumber *hidden = objc_getAssociatedObject(source, &kAWETopSourceHiddenKey);
    NSNumber *alpha = objc_getAssociatedObject(source, &kAWETopSourceAlphaKey);
    source.hidden = hidden ? hidden.boolValue : NO;
    source.alpha = alpha ? alpha.doubleValue : 1.0;
    objc_setAssociatedObject(source, &kAWETopSourceHiddenKey,
                             nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(source, &kAWETopSourceAlphaKey,
                             nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(source, &kAWETopSourceSlotKey,
                             nil, OBJC_ASSOCIATION_ASSIGN);
    slot.sourceImageView = nil;
}

static UIUserInterfaceStyle AWEGlassInternalInterfaceStyle(
    UIView *glass,
    UIUserInterfaceStyle fallbackStyle) {
    if (!glass) return fallbackStyle;
    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithArray:glass.subviews];
    NSInteger dark = 0, light = 0;
    NSUInteger visited = 0;
    while (queue.count > 0 && visited < 120) {
        UIView *view = queue.firstObject;
        [queue removeObjectAtIndex:0];
        visited++;
        for (UIView *child in view.subviews) [queue addObject:child];
        NSString *name = NSStringFromClass(view.class).lowercaseString;
        BOOL materialNode = [name containsString:@"glass"] ||
                            [name containsString:@"liquid"] ||
                            [name containsString:@"backdrop"] ||
                            [name containsString:@"material"] ||
                            [name containsString:@"visualeffect"] ||
                            [name containsString:@"contentview"] ||
                            [name containsString:@"platter"] ||
                            [name containsString:@"lens"];
        if (!materialNode) continue;
        UIUserInterfaceStyle style = view.traitCollection.userInterfaceStyle;
        if (style == UIUserInterfaceStyleDark) dark += 2;
        else if (style == UIUserInterfaceStyleLight) light += 2;

        BOOL valid = NO;
        BOOL colorIsLight = AWEColorPrefersLightForeground(
            view.backgroundColor, view.traitCollection, &valid);
        if (!valid && view.layer.backgroundColor) {
            UIColor *layerColor = [UIColor colorWithCGColor:view.layer.backgroundColor];
            colorIsLight = AWEColorPrefersLightForeground(
                layerColor, view.traitCollection, &valid);
        }
        if (valid) {
            if (colorIsLight) light++;
            else dark++;
        }
    }
    if (dark > light) return UIUserInterfaceStyleDark;
    if (light > dark) return UIUserInterfaceStyleLight;
    UIUserInterfaceStyle own = glass.traitCollection.userInterfaceStyle;
    return own == UIUserInterfaceStyleUnspecified ? fallbackStyle : own;
}



#pragma mark - Album Morph system tint probe

static UIVisualEffectView *AWEEnsureAlbumMorphTintProbe(UIWindow *sourceWindow) {
    if (!sourceWindow || !sourceWindow.rootViewController) return nil;

    UIView *rootView = sourceWindow.rootViewController.view;
    if (!rootView) return nil;

    BOOL needsRebuild =
        !gAWEAlbumMorphTintProbe ||
        gAWEAlbumMorphTintProbeWindow != sourceWindow ||
        gAWEAlbumMorphTintProbe.superview != rootView;

    if (needsRebuild) {
        [gAWEAlbumMorphTintProbe removeFromSuperview];
        gAWEAlbumMorphTintProbe = [[UIVisualEffectView alloc]
            initWithEffect:AWECreateHomeAdaptiveGlassEffect()];
        gAWEAlbumMorphTintProbe.userInteractionEnabled = NO;
        gAWEAlbumMorphTintProbe.backgroundColor = UIColor.clearColor;
        gAWEAlbumMorphTintProbe.contentView.backgroundColor = UIColor.clearColor;
        gAWEAlbumMorphTintProbe.opaque = NO;
        gAWEAlbumMorphTintProbe.clipsToBounds = YES;
        gAWEAlbumMorphTintProbe.layer.cornerRadius = 2.0;
        gAWEAlbumMorphTintProbe.accessibilityIdentifier =
            @"AwemeLiquidBar.AlbumMorph.SystemTintProbe";
        gAWEAlbumMorphTintProbe.overrideUserInterfaceStyle =
            UIUserInterfaceStyleUnspecified;
        [rootView addSubview:gAWEAlbumMorphTintProbe];
        gAWEAlbumMorphTintProbeWindow = sourceWindow;
    }

    /* Keep the original fully rendered 4 x 4 probe.  Scaling or reducing its
       opacity prevents UIGlassEffect from resolving the same material branch
       as the real bar.  Park it in the physical bottom-left display corner:
       the screen's rounded mask hides it, while UIKit still renders all four
       pixels in the source window. */
    CGFloat rootHeight = CGRectGetHeight(rootView.bounds);
    CGRect probeFrame = CGRectMake(0.0, MAX(0.0, rootHeight - 4.0), 4.0, 4.0);
    BOOL frameChanged = !CGRectEqualToRect(gAWEAlbumMorphTintProbe.frame,
                                            probeFrame);
    if (frameChanged) gAWEAlbumMorphTintProbe.frame = probeFrame;
    gAWEAlbumMorphTintProbe.transform = CGAffineTransformIdentity;
    gAWEAlbumMorphTintProbe.layer.cornerRadius = 2.0;
    gAWEAlbumMorphTintProbe.accessibilityElementsHidden = YES;
    gAWEAlbumMorphTintProbe.hidden = NO;
    gAWEAlbumMorphTintProbe.alpha = 1.0;
    gAWEAlbumMorphTintProbe.layer.opacity = 1.0f;
    [rootView bringSubviewToFront:gAWEAlbumMorphTintProbe];
    if (needsRebuild || frameChanged) {
        [gAWEAlbumMorphTintProbe setNeedsLayout];
        [gAWEAlbumMorphTintProbe layoutIfNeeded];
    }
    return gAWEAlbumMorphTintProbe;
}

static UIUserInterfaceStyle AWEAlbumMorphResolvedProbeStyle(
    UIWindow *sourceWindow) {
    UIUserInterfaceStyle fallback =
        UIScreen.mainScreen.traitCollection.userInterfaceStyle;
    if (fallback == UIUserInterfaceStyleUnspecified && sourceWindow) {
        fallback = sourceWindow.traitCollection.userInterfaceStyle;
    }
    if (fallback == UIUserInterfaceStyleUnspecified) {
        fallback = UIUserInterfaceStyleLight;
    }

    UIWindow *resolvedWindow = sourceWindow ?: AWEActiveMainWindow();
    UIVisualEffectView *probe = gAWEAlbumMorphTintProbe;
    if (!probe || gAWEAlbumMorphTintProbeWindow != resolvedWindow ||
        !probe.superview) {
        probe = AWEEnsureAlbumMorphTintProbe(resolvedWindow);
    }
    if (!probe) return fallback;

    UIUserInterfaceStyle resolved =
        AWEGlassInternalInterfaceStyle(probe, fallback);
    if (resolved != UIUserInterfaceStyleLight &&
        resolved != UIUserInterfaceStyleDark) {
        resolved = fallback;
    }
    return resolved;
}

static void AWERefreshAlbumMorphTintFromSystemProbe(void) {
    if (!AWEAlbumMorphStyleEnabled() || !gAWEAlbumMorphController ||
        !gAWEAlbumMorphVisible) {
        return;
    }

    UIWindow *sourceWindow =
        gAWEAlbumMorphSuppressedOriginalBar.window ?: AWEActiveMainWindow();
    if (!sourceWindow) return;

    UIUserInterfaceStyle resolved =
        AWEAlbumMorphResolvedProbeStyle(sourceWindow);
    if (resolved == gAWEAlbumMorphLastMirroredStyle) return;

    gAWEAlbumMorphLastMirroredStyle = resolved;
    NSInteger index = [gAWEAlbumMorphController currentOriginalIndex];
    if (index == NSNotFound) index = 0;
    AWEApplyAlbumMorphResolvedAppearance(sourceWindow, index);
}

@interface AWEAlbumMorphTintDisplayLinkTarget : NSObject
- (void)alb_tickAlbumMorphTint:(CADisplayLink *)displayLink;
@end

@implementation AWEAlbumMorphTintDisplayLinkTarget
- (void)alb_tickAlbumMorphTint:(CADisplayLink *)displayLink {
    if (!gAWEAlbumMorphVisible || !gAWEAlbumMorphOverlayWindow ||
        !((AWEAlbumMorphOverlayWindow *)gAWEAlbumMorphOverlayWindow).contentVisible ||
        !gAWEAlbumMorphController.tabBar.window) {
        /* Keep the 4 x 4 resolver warm in the physical rounded corner.  Only
           pause sampling; hiding/recreating the effect made the returned bar
           resolve through a temporary white material branch. */
        displayLink.paused = YES;
        return;
    }
    AWERefreshAlbumMorphTintFromSystemProbe();
    /* One clear-mode button per tick keeps local black/white contrast current
       without taking a full-screen snapshot for every control every frame. */
    AWERefreshOneAdaptiveButtonContrast();
}
@end

static void AWEStartAlbumMorphTintDisplayLink(void) {
    if (gAWEAlbumMorphTintDisplayLink) {
        gAWEAlbumMorphTintDisplayLink.paused = NO;
        return;
    }
    AWEAlbumMorphTintDisplayLinkTarget *target =
        [AWEAlbumMorphTintDisplayLinkTarget new];
    CADisplayLink *link = [CADisplayLink
        displayLinkWithTarget:target
                     selector:@selector(alb_tickAlbumMorphTint:)];
    if (@available(iOS 15.0, *)) {
        link.preferredFrameRateRange = CAFrameRateRangeMake(1.0, 2.0, 2.0);
    } else {
        link.preferredFramesPerSecond = 2;
    }
    [link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    gAWEAlbumMorphTintDisplayLinkTarget = target;
    gAWEAlbumMorphTintDisplayLink = link;
}

static void AWEStopAlbumMorphTintDisplayLink(void) {
    [gAWEAlbumMorphTintDisplayLink invalidate];
    gAWEAlbumMorphTintDisplayLink = nil;
    gAWEAlbumMorphTintDisplayLinkTarget = nil;
    [gAWEAlbumMorphTintProbe removeFromSuperview];
    gAWEAlbumMorphTintProbe = nil;
    gAWEAlbumMorphTintProbeWindow = nil;
    gAWEAlbumMorphLastMirroredStyle = UIUserInterfaceStyleUnspecified;
    gAWEAlbumMorphLastAppliedStyle = UIUserInterfaceStyleUnspecified;
    gAWEHomeChromeLastStableStyle = UIUserInterfaceStyleUnspecified;
    AWERefreshRegisteredAdaptiveGlassButtons();
}

static void AWEHideAlbumMorphTintProbe(void) {
    /* Historical name retained for callers.  The resolver now stays fully
       rendered in the physical bottom-left rounded corner so the material
       branch remains warm; only the low-frequency display link is paused. */
    UIWindow *sourceWindow =
        gAWEAlbumMorphSuppressedOriginalBar.window ?: AWEActiveMainWindow();
    if (sourceWindow) AWEEnsureAlbumMorphTintProbe(sourceWindow);
    gAWEAlbumMorphTintDisplayLink.paused = YES;
}

@interface AWEAlbumMorphCollapseGestureDelegate : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, assign) BOOL handledCurrentGesture;
- (void)alb_handleCollapsePan:(UIPanGestureRecognizer *)recognizer;
@end

@implementation AWEAlbumMorphCollapseGestureDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
        shouldRecognizeSimultaneouslyWithGestureRecognizer:
            (UIGestureRecognizer *)otherGestureRecognizer {
    (void)gestureRecognizer; (void)otherGestureRecognizer;
    return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch {
    if (!AWEAlbumMorphCollapseEnabled() || !gAWEAlbumMorphVisible ||
        gAWESettingsVisible) return NO;
    UIView *view = gestureRecognizer.view;
    CGPoint point = [touch locationInView:view];
    CGFloat height = CGRectGetHeight(view.bounds);
    /* Do not steal top-navigation or bottom-tab gestures. */
    return point.y > 110.0 && point.y < height - 118.0;
}
- (void)alb_handleCollapsePan:(UIPanGestureRecognizer *)recognizer {
    if (!AWEAlbumMorphCollapseEnabled() || !gAWEAlbumMorphVisible ||
        !gAWEAlbumMorphController) return;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.handledCurrentGesture = NO;
        return;
    }
    if (recognizer.state != UIGestureRecognizerStateEnded ||
        self.handledCurrentGesture) return;

    CGPoint translation = [recognizer translationInView:recognizer.view];
    CGPoint velocity = [recognizer velocityInView:recognizer.view];
    if (fabs(translation.y) < fabs(translation.x) * 1.25) return;
    BOOL requestCompact = !gAWEAlbumMorphCompact &&
        (translation.y <= -34.0 || velocity.y <= -620.0);
    BOOL requestExpand = gAWEAlbumMorphCompact &&
        (translation.y >= 34.0 || velocity.y >= 620.0);
    if (!requestCompact && !requestExpand) return;

    BOOL compact = requestCompact;
    self.handledCurrentGesture = YES;
    gAWEAlbumMorphCompact = compact;
    /* The overlay controller is not the host feed's tab controller, so private
       minimize selectors can report success without moving the visible bar.
       Use the stable native-tab-bar scale path instead; it never writes a
       fixed frame and therefore remains correct for every user height/offset. */
    [gAWEAlbumMorphController setCompactMode:compact animated:YES];
    AWEAlbumMorphProbeWrite(
        @"COLLAPSE_GESTURE compact=%d translation=%@ velocity=%@ height=%.2f offset=%.2f",
        compact, NSStringFromCGPoint(translation), NSStringFromCGPoint(velocity),
        CGRectGetHeight(gAWEAlbumMorphController.tabBar.frame),
        AWEStoredVerticalOffset());
}
@end

static void AWEInstallAlbumMorphCollapseGesture(UIWindow *sourceWindow) {
    if (!sourceWindow || !AWEAlbumMorphCollapseEnabled()) {
        if (gAWEAlbumMorphCollapseGesture.view) {
            [gAWEAlbumMorphCollapseGesture.view
                removeGestureRecognizer:gAWEAlbumMorphCollapseGesture];
        }
        gAWEAlbumMorphCollapseGesture = nil;
        gAWEAlbumMorphCollapseGestureWindow = nil;
        gAWEAlbumMorphCollapseGestureDelegate = nil;
        if (gAWEAlbumMorphController && gAWEAlbumMorphCompact) {
            gAWEAlbumMorphCompact = NO;
            [gAWEAlbumMorphController setCompactMode:NO animated:NO];
        }
        return;
    }
    if (gAWEAlbumMorphCollapseGestureWindow == sourceWindow &&
        gAWEAlbumMorphCollapseGesture.view == sourceWindow) return;
    if (gAWEAlbumMorphCollapseGesture.view) {
        [gAWEAlbumMorphCollapseGesture.view
            removeGestureRecognizer:gAWEAlbumMorphCollapseGesture];
    }
    AWEAlbumMorphCollapseGestureDelegate *delegate =
        [AWEAlbumMorphCollapseGestureDelegate new];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:delegate action:@selector(alb_handleCollapsePan:)];
    pan.cancelsTouchesInView = NO;
    pan.delaysTouchesBegan = NO;
    pan.delaysTouchesEnded = NO;
    pan.maximumNumberOfTouches = 1;
    pan.delegate = delegate;
    [sourceWindow addGestureRecognizer:pan];
    objc_setAssociatedObject(sourceWindow, &kAWEAlbumMorphCollapseGestureKey,
                             pan, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    gAWEAlbumMorphCollapseGestureWindow = sourceWindow;
    gAWEAlbumMorphCollapseGesture = pan;
    gAWEAlbumMorphCollapseGestureDelegate = delegate;
}

static void AWEExpandAlbumMorphBarWithoutAnimation(void) {
    if (!gAWEAlbumMorphController) return;
    gAWEAlbumMorphCompact = NO;
    [gAWEAlbumMorphController setCompactMode:NO animated:NO];
}

static BOOL AWEForwardTopActionOwner(UIView *owner,
                                         AWEHomeTopActionKind kind) {
    if (!owner) return NO;
    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:owner];
    NSUInteger visited = 0;
    while (queue.count > 0 && visited < 48) {
        UIView *view = queue.firstObject;
        [queue removeObjectAtIndex:0];
        visited++;
        if ([view isKindOfClass:UIControl.class]) {
            UIControl *control = (UIControl *)view;
            BOOL hasTouchUp = NO;
            BOOL hasPrimary = NO;
            for (id target in control.allTargets) {
                hasTouchUp = hasTouchUp ||
                    ([control actionsForTarget:target
                               forControlEvent:UIControlEventTouchUpInside].count > 0);
                hasPrimary = hasPrimary ||
                    ([control actionsForTarget:target
                               forControlEvent:UIControlEventPrimaryActionTriggered].count > 0);
            }
            UIControlEvents event = hasTouchUp
                ? UIControlEventTouchUpInside
                : (hasPrimary ? UIControlEventPrimaryActionTriggered : 0);
            if (event != 0) {
                [control sendActionsForControlEvents:event];
                AWEInteractionDiagnosticWrite(
                    @"TOP_FORWARD kind=%@ path=control event=%@ control=%@ targets=%lu",
                    kind == AWEHomeTopActionKindSearch ? @"SEARCH" : @"MENU",
                    event == UIControlEventTouchUpInside ? @"touchUp" : @"primary",
                    AWEInteractionObjectSummary(control),
                    (unsigned long)control.allTargets.count);
                return YES;
            }
        }
        for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
            if (!recognizer.enabled) continue;
            NSString *name = NSStringFromClass(recognizer.class).lowercaseString;
            if (![recognizer isKindOfClass:UITapGestureRecognizer.class] &&
                ![name containsString:@"tap"] && ![name containsString:@"click"]) {
                continue;
            }
            NSInteger oldState = 0;
            BOOL changed = AWESetIntegerIvar(recognizer,
                "_state_DO_NOT_USE_DIRECTLY", UIGestureRecognizerStateEnded,
                &oldState);
            BOOL sent = AWEInvokeGestureRecognizer(recognizer);
            if (changed) {
                AWESetIntegerIvar(recognizer,
                    "_state_DO_NOT_USE_DIRECTLY", oldState, NULL);
            }
            if (sent) {
                AWEInteractionDiagnosticWrite(
                    @"TOP_FORWARD kind=%@ path=gesture recognizer=%@ view=%@",
                    kind == AWEHomeTopActionKindSearch ? @"SEARCH" : @"MENU",
                    NSStringFromClass(recognizer.class),
                    AWEInteractionObjectSummary(view));
                return YES;
            }
        }
        for (UIView *child in view.subviews) [queue addObject:child];
    }
    BOOL activated = NO;
    @try { activated = [owner accessibilityActivate]; }
    @catch (__unused NSException *exception) { activated = NO; }
    AWEInteractionDiagnosticWrite(
        @"TOP_FORWARD kind=%@ path=accessibility result=%d owner=%@ visited=%lu",
        kind == AWEHomeTopActionKindSearch ? @"SEARCH" : @"MENU",
        activated, AWEInteractionObjectSummary(owner), (unsigned long)visited);
    return activated;
}


#pragma mark - Native top-left dynamic Liquid Glass menu

/*
 The early ForceLiquidGlassUnified source only restyled WeChat's already-open
 MainFrameActionFloatView. The latest WCGlass binary instead binds a real
 UIMenu to the source UIButton, builds UIAction children synchronously and
 enables showsMenuAsPrimaryAction. This section follows the latter structure:
 there is no delayed empty deferred provider and no forwarding of the
 original sidebar tap while the menu is opening.
*/

static void AWEClearTopMenuMorph(AWEHomeTopSlotView *slot);
static void AWEInstallTopMenuMorph(AWEHomeTopSlotView *slot);

static NSString *AWETrimQuickMenuText(NSString *text) {
    if (![text isKindOfClass:NSString.class]) return @"";
    return [text stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

static BOOL AWEViewDirectlyMatchesQuickMenuTitle(UIView *view,
                                                  NSString *title) {
    if (!view || !title.length) return NO;
    if ([AWETrimQuickMenuText(view.accessibilityLabel) isEqualToString:title] ||
        [AWETrimQuickMenuText(view.accessibilityValue) isEqualToString:title]) {
        return YES;
    }
    if ([view isKindOfClass:UILabel.class]) {
        if ([AWETrimQuickMenuText(((UILabel *)view).text)
                isEqualToString:title]) return YES;
    }
    if ([view isKindOfClass:UIButton.class]) {
        UIButton *button = (UIButton *)view;
        if ([AWETrimQuickMenuText(button.currentTitle)
                isEqualToString:title] ||
            [AWETrimQuickMenuText(button.titleLabel.text)
                isEqualToString:title]) return YES;
    }
    return NO;
}

static BOOL AWEViewHasUsableTapRecognizer(UIView *view) {
    if (!view) return NO;
    for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
        if (!recognizer.enabled) continue;
        NSString *name = NSStringFromClass(recognizer.class).lowercaseString;
        if ([recognizer isKindOfClass:UITapGestureRecognizer.class] ||
            [name containsString:@"tap"] ||
            [name containsString:@"click"]) return YES;
    }
    return NO;
}

static BOOL AWEQuickMenuExcludedView(UIView *view) {
    if (!view) return YES;
    if ([view isKindOfClass:AWEHomeTopSlotView.class]) return YES;
    for (UIView *cursor = view; cursor; cursor = cursor.superview) {
        NSString *cursorName = NSStringFromClass(cursor.class).lowercaseString;
        if ([cursorName containsString:@"awetopliquidgroupview"] ||
            [cursor.accessibilityIdentifier
                isEqualToString:@"AwemeLiquidBar.TopLiquidCategoryGroup"]) {
            return YES;
        }
        if ([cursorName containsString:@"feedtopbarcontainer"]) break;
    }
    NSString *name = NSStringFromClass(view.class).lowercaseString;
    return [name containsString:@"contextmenu"] ||
           [name containsString:@"menuplatter"] ||
           [name containsString:@"menupresentation"] ||
           [name containsString:@"popover"] ||
           [name containsString:@"alertcontroller"];
}

static UIView *AWEQuickMenuActionOwnerForMatchedView(UIView *matched,
                                                      UIWindow *window) {
    if (!matched || !window) return nil;
    UIView *fallback = matched;
    UIView *cursor = matched;
    for (NSUInteger depth = 0; cursor && cursor != window && depth < 8;
         depth++, cursor = cursor.superview) {
        if (AWEQuickMenuExcludedView(cursor)) continue;
        if ([cursor isKindOfClass:UIControl.class] ||
            AWEViewHasUsableTapRecognizer(cursor)) return cursor;
        NSString *name = NSStringFromClass(cursor.class).lowercaseString;
        if ([name containsString:@"button"] ||
            [name containsString:@"tab"] ||
            [name containsString:@"segment"] ||
            [name containsString:@"channel"] ||
            [name containsString:@"item"] ||
            [name containsString:@"cell"]) {
            fallback = cursor;
        }
    }
    return fallback;
}

static NSInteger AWEQuickMenuCandidateScore(UIView *candidate,
                                             UIWindow *window,
                                             BOOL topOnly) {
    if (!candidate || !window || candidate.hidden || candidate.alpha <= 0.02 ||
        !candidate.window || AWEQuickMenuExcludedView(candidate)) return NSIntegerMin;
    CGRect frame = [candidate convertRect:candidate.bounds toView:window];
    if (CGRectIsEmpty(frame) || CGRectIsNull(frame) ||
        !CGRectIntersectsRect(frame, window.bounds)) return NSIntegerMin;
    CGFloat midY = CGRectGetMidY(frame);
    CGFloat topLimit = MIN(240.0, CGRectGetHeight(window.bounds) * 0.32);
    if (topOnly && midY > topLimit) return NSIntegerMin;

    NSInteger score = 100;
    if ([candidate isKindOfClass:UIControl.class]) score += 130;
    if (AWEViewHasUsableTapRecognizer(candidate)) score += 110;
    NSString *name = NSStringFromClass(candidate.class).lowercaseString;
    if ([name containsString:@"tab"] || [name containsString:@"segment"] ||
        [name containsString:@"channel"] || [name containsString:@"feed"]) {
        score += 90;
    }
    if (midY <= topLimit) score += 220;
    if (CGRectGetWidth(frame) >= 28.0 && CGRectGetWidth(frame) <= 240.0 &&
        CGRectGetHeight(frame) >= 20.0 && CGRectGetHeight(frame) <= 110.0) {
        score += 35;
    }
    return score;
}

static UIView *AWEBestQuickMenuDestinationView(UIWindow *window,
                                                NSString *title,
                                                BOOL topOnly) {
    if (!window || !title.length) return nil;
    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:window];
    NSHashTable<UIView *> *seen = [NSHashTable weakObjectsHashTable];
    UIView *best = nil;
    NSInteger bestScore = NSIntegerMin;
    NSUInteger visited = 0;

    while (queue.count > 0 && visited < 1400) {
        UIView *view = queue.firstObject;
        [queue removeObjectAtIndex:0];
        if (!view || [seen containsObject:view]) continue;
        [seen addObject:view];
        visited++;
        if (view.hidden || view.alpha <= 0.01 || AWEQuickMenuExcludedView(view)) {
            continue;
        }
        if (AWEViewDirectlyMatchesQuickMenuTitle(view, title)) {
            UIView *owner = AWEQuickMenuActionOwnerForMatchedView(view, window);
            NSInteger score = AWEQuickMenuCandidateScore(owner, window, topOnly);
            if (score > bestScore) {
                bestScore = score;
                best = owner;
            }
        }
        for (UIView *child in view.subviews) [queue addObject:child];
    }
    return best;
}

static BOOL AWETriggerQuickMenuDestinationView(UIView *target) {
    if (!target) return NO;

    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:target];
    NSUInteger visited = 0;
    while (queue.count > 0 && visited < 96) {
        UIView *view = queue.firstObject;
        [queue removeObjectAtIndex:0];
        visited++;

        if ([view isKindOfClass:UIControl.class]) {
            UIControl *control = (UIControl *)view;
            UIControlEvents event = 0;
            for (id actionTarget in control.allTargets) {
                if ([control actionsForTarget:actionTarget
                              forControlEvent:UIControlEventPrimaryActionTriggered].count) {
                    event = UIControlEventPrimaryActionTriggered;
                    break;
                }
                if ([control actionsForTarget:actionTarget
                              forControlEvent:UIControlEventTouchUpInside].count) {
                    event = UIControlEventTouchUpInside;
                }
            }
            if (event) {
                [control sendActionsForControlEvents:event];
                return YES;
            }
        }

        for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
            if (!recognizer.enabled) continue;
            NSString *name = NSStringFromClass(recognizer.class).lowercaseString;
            if (![recognizer isKindOfClass:UITapGestureRecognizer.class] &&
                ![name containsString:@"tap"] && ![name containsString:@"click"]) {
                continue;
            }
            NSInteger oldState = 0;
            BOOL changed = AWESetIntegerIvar(recognizer,
                "_state_DO_NOT_USE_DIRECTLY", UIGestureRecognizerStateEnded,
                &oldState);
            BOOL sent = AWEInvokeGestureRecognizer(recognizer);
            if (changed) {
                AWESetIntegerIvar(recognizer,
                    "_state_DO_NOT_USE_DIRECTLY", oldState, NULL);
            }
            if (sent) return YES;
        }
        for (UIView *child in view.subviews) [queue addObject:child];
    }

    BOOL activated = NO;
    @try { activated = [target accessibilityActivate]; }
    @catch (__unused NSException *exception) { activated = NO; }
    return activated;
}

static BOOL AWEActivateQuickMenuDestination(NSString *title) {
    UIWindow *window = AWEActiveMainWindow();
    if (!window || !title.length) return NO;

    UIView *target = AWEBestQuickMenuDestinationView(window, title, YES);
    if (!target && [title isEqualToString:@"商城"] &&
        AWESecondTabIsShop() && gAWELastTabBar) {
        BOOL forwarded = AWEForwardToOriginalButton((UIView *)gAWELastTabBar, 1);
        AWEInteractionDiagnosticWrite(
            @"TOP_MENU_ACTION title=%@ result=%d path=bottom-shop-fallback",
            title, forwarded);
        if (forwarded) return YES;
    }
    if (!target) target = AWEBestQuickMenuDestinationView(window, title, NO);
    BOOL result = AWETriggerQuickMenuDestinationView(target);
    AWEInteractionDiagnosticWrite(
        @"TOP_MENU_ACTION title=%@ result=%d target=%@",
        title, result, AWEInteractionObjectSummary(target));
    return result;
}

static NSString *AWEQuickMenuTitleForView(UIView *view) {
    if ([view isKindOfClass:UILabel.class]) {
        return AWETrimQuickMenuText(((UILabel *)view).text);
    }
    if ([view isKindOfClass:UIButton.class]) {
        UIButton *button = (UIButton *)view;
        return AWETrimQuickMenuText(button.currentTitle ?: button.titleLabel.text);
    }
    return @"";
}

static BOOL AWEViewEffectivelyVisibleInsideTopContainer(UIView *view,
                                                         UIView *container) {
    if (!view || !container || !view.window) return NO;
    for (UIView *cursor = view; cursor; cursor = cursor.superview) {
        BOOL hiddenByUs = [objc_getAssociatedObject(
            cursor, &kAWETopCategoryHiddenMarkerKey) boolValue];
        if (cursor.hidden || cursor.alpha <= 0.01) return NO;
        if (!hiddenByUs && cursor.layer.opacity <= 0.01f) return NO;
        if (cursor == container) return YES;
    }
    return NO;
}

static BOOL AWEViewBelongsToTopTabItem(UIView *view, UIView *container) {
    for (UIView *cursor = view; cursor && cursor != container.superview;
         cursor = cursor.superview) {
        NSString *name = NSStringFromClass(cursor.class).lowercaseString;
        if ([name containsString:@"toptabitem"] ||
            [name containsString:@"segmentcontrolscroll"] ||
            [name containsString:@"multitab"] ||
            [name containsString:@"channelitem"] ||
            [name containsString:@"feedtabitem"]) {
            return YES;
        }
        if (cursor == container) break;
    }
    return NO;
}

static NSString *AWEQuickMenuSymbolNameForTitle(NSString *title) {
    NSString *trimmed = AWETrimQuickMenuText(title);
    if ([trimmed containsString:@"直播"]) return @"play.rectangle";
    if ([trimmed containsString:@"商城"] || [trimmed containsString:@"购物"] ||
        [trimmed containsString:@"商店"]) return @"storefront";
    if ([trimmed containsString:@"关注"]) return @"person.2";
    if ([trimmed containsString:@"推荐"]) return @"sparkles";
    if ([trimmed containsString:@"精选"]) return @"checkmark.seal";
    if ([trimmed containsString:@"经验"]) return @"lightbulb";
    if ([trimmed containsString:@"同城"] || [trimmed containsString:@"附近"]) {
        return @"location";
    }
    return @"circle.grid.2x2";
}

static NSArray<NSDictionary<NSString *, id> *> *
AWEDynamicTopQuickMenuDefinitions(AWEHomeTopSlotView *slot) {
    UIView *container = slot.superview;
    if (!container) return @[];
    NSMutableArray<NSDictionary<NSString *, id> *> *candidates =
        [NSMutableArray array];
    NSMutableSet<NSString *> *seenTitles = [NSMutableSet set];
    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:container];
    NSUInteger visited = 0;
    while (queue.count > 0 && visited < 600) {
        UIView *view = queue.firstObject;
        [queue removeObjectAtIndex:0];
        if (!view || [view isKindOfClass:AWEHomeTopSlotView.class]) continue;
        visited++;
        NSString *title = AWEQuickMenuTitleForView(view);
        BOOL hiddenByUs = [objc_getAssociatedObject(
            view, &kAWETopCategoryHiddenMarkerKey) boolValue];
        BOOL externallyVisible =
            AWEViewEffectivelyVisibleInsideTopContainer(view, container);
        if (title.length > 0 && title.length <= 12 &&
            (externallyVisible || hiddenByUs) &&
            AWEViewBelongsToTopTabItem(view, container) &&
            ![seenTitles containsObject:title]) {
            CGRect frame = [view convertRect:view.bounds toView:container];
            BOOL geometry = !CGRectIsEmpty(frame) &&
                CGRectGetHeight(frame) >= 18.0 && CGRectGetHeight(frame) <= 72.0 &&
                CGRectGetMidY(frame) <= MAX(96.0, CGRectGetHeight(container.bounds));
            if (geometry) {
                [seenTitles addObject:title];
                UIView *target = AWEQuickMenuActionOwnerForMatchedView(
                    view, container.window ?: AWEActiveMainWindow());
                NSMutableDictionary *definition = [@{
                    @"title": title,
                    @"route": title,
                    @"symbol": AWEQuickMenuSymbolNameForTitle(title),
                    @"x": @(CGRectGetMidX(frame))
                } mutableCopy];
                if (target) definition[@"target"] = target;
                [candidates addObject:definition];
            }
        }
        for (UIView *child in view.subviews) [queue addObject:child];
    }
    [candidates sortUsingComparator:^NSComparisonResult(NSDictionary *left,
                                                         NSDictionary *right) {
        CGFloat lx = [left[@"x"] doubleValue];
        CGFloat rx = [right[@"x"] doubleValue];
        return lx < rx ? NSOrderedAscending : (lx > rx ? NSOrderedDescending
                                                        : NSOrderedSame);
    }];
    if (candidates.count > 0) return candidates;
    return @[
        @{@"title": @"直播", @"route": @"直播", @"symbol": @"play.rectangle", @"x": @0},
        @{@"title": @"商城", @"route": @"商城", @"symbol": @"storefront", @"x": @1},
        @{@"title": @"关注", @"route": @"关注", @"symbol": @"person.2", @"x": @2},
        @{@"title": @"推荐", @"route": @"推荐", @"symbol": @"sparkles", @"x": @3}
    ];
}

static UIAction *AWECreateTopQuickMenuAction(AWEHomeTopSlotView *slot,
                                              NSString *displayTitle,
                                              NSString *routeTitle,
                                              NSString *symbolName) {
    if (!slot || !displayTitle.length || !routeTitle.length) return nil;
    UIImageSymbolConfiguration *configuration =
        [UIImageSymbolConfiguration configurationWithPointSize:18.0
                                                         weight:UIImageSymbolWeightRegular
                                                          scale:UIImageSymbolScaleMedium];
    UIImage *image = [[UIImage systemImageNamed:symbolName]
        imageWithConfiguration:configuration];
    __weak AWEHomeTopSlotView *weakSlot = slot;
    return [UIAction actionWithTitle:displayTitle
                               image:image
                          identifier:nil
                             handler:^(__unused UIAction *action) {
        AWEHomeTopSlotView *liveSlot = weakSlot;
        if (!liveSlot || !liveSlot.window) return;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(0.16 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            AWEActivateQuickMenuDestination(routeTitle);
        });
    }];
}

static UIMenu *AWECreateTopQuickMenu(
    AWEHomeTopSlotView *slot,
    NSArray<NSDictionary<NSString *, id> *> *definitions) {
    if (!slot || definitions.count == 0) return nil;
    NSMutableArray<UIMenuElement *> *children =
        [NSMutableArray arrayWithCapacity:definitions.count];
    for (NSDictionary<NSString *, id> *definition in definitions) {
        UIAction *action = AWECreateTopQuickMenuAction(
            slot, definition[@"title"], definition[@"route"],
            definition[@"symbol"]);
        if (action) [children addObject:action];
    }
    if (children.count == 0) return nil;
    return [UIMenu menuWithTitle:@"" children:children];
}

static void AWEInstallTopMenuMorph(AWEHomeTopSlotView *slot) {
    if (!slot || slot.topKind != AWEHomeTopActionKindMenu || !slot.hitButton) {
        return;
    }
    if (@available(iOS 26.0, *)) {
        UIButton *button = slot.hitButton;
        NSArray<NSDictionary<NSString *, id> *> *definitions =
            AWEDynamicTopQuickMenuDefinitions(slot);
        NSArray<NSString *> *routeTitles = [definitions valueForKey:@"route"];
        NSString *signature = [routeTitles componentsJoinedByString:@"|"];
        BOOL installed = [objc_getAssociatedObject(
            button, &kAWETopMenuMorphInstalledKey) boolValue];
        NSString *oldSignature = objc_getAssociatedObject(
            button, &kAWETopMenuSignatureKey);
        if (installed && button.menu && button.showsMenuAsPrimaryAction &&
            [oldSignature isEqualToString:signature] &&
            button.menu.children.count == definitions.count) return;

        UIMenu *menu = AWECreateTopQuickMenu(slot, definitions);
        if (!menu) {
            AWEClearTopMenuMorph(slot);
            return;
        }
        button.menu = menu;
        button.showsMenuAsPrimaryAction = YES;
        button.accessibilityLabel = @"快捷菜单";
        objc_setAssociatedObject(button, &kAWETopMenuMorphInstalledKey,
                                 @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(button, &kAWETopMenuSignatureKey,
                                 signature, OBJC_ASSOCIATION_COPY_NONATOMIC);
        AWEInteractionDiagnosticWrite(
            @"TOP_MENU_NATIVE installed button=%@ children=%lu titles=%@",
            AWEInteractionObjectSummary(button),
            (unsigned long)menu.children.count, signature);
    }
}

static void AWEClearTopMenuMorph(AWEHomeTopSlotView *slot) {
    if (!slot || !slot.hitButton) return;
    UIButton *button = slot.hitButton;
    button.showsMenuAsPrimaryAction = NO;
    button.menu = nil;
    objc_setAssociatedObject(button,
                             &kAWETopMenuMorphInstalledKey,
                             nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(button,
                             &kAWETopMenuSignatureKey,
                             nil,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(slot,
                             &kAWETopMenuMorphForwardingKey,
                             nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


void AWEAlbumMorphRegisterContentScrollView(UIViewController *controller,
                                             UIScrollView *scrollView) {
    if (!controller || !scrollView) return;

    NSMutableArray<UIViewController *> *targets = [NSMutableArray array];
    [targets addObject:controller];
    if (controller.parentViewController &&
        controller.parentViewController != controller) {
        [targets addObject:controller.parentViewController];
    }
    if (controller.tabBarController &&
        controller.tabBarController != controller &&
        ![targets containsObject:controller.tabBarController]) {
        [targets addObject:controller.tabBarController];
    }

    NSArray<NSString *> *edgeSelectors = @[
        @"setContentScrollView:forEdge:",
        @"_setContentScrollView:forEdge:"
    ];
    NSArray<NSString *> *singleSelectors = @[
        @"setContentScrollView:",
        @"_setContentScrollView:"
    ];

    for (UIViewController *target in targets) {
        for (NSString *selectorName in edgeSelectors) {
            SEL selector = NSSelectorFromString(selectorName);
            if (![target respondsToSelector:selector]) continue;
            NSUInteger bottomEdge = UIRectEdgeBottom;
            ((void (*)(id, SEL, id, NSUInteger))objc_msgSend)(
                target, selector, scrollView, bottomEdge);
            AWEInteractionDiagnosticWrite(
                @"ALBUM_MORPH_SCROLL_BIND selector=%@ target=%@ scroll=%@",
                selectorName,
                AWEInteractionObjectSummary(target),
                AWEInteractionObjectSummary(scrollView));
            AWEAlbumMorphProbeWrite(
                @"PROXY_BIND selector=%@ target=%@ scroll=%@ content=%@ bounds=%@",
                selectorName, NSStringFromClass(target.class),
                NSStringFromClass(scrollView.class),
                NSStringFromCGSize(scrollView.contentSize),
                NSStringFromCGRect(scrollView.bounds));
            return;
        }
        for (NSString *selectorName in singleSelectors) {
            SEL selector = NSSelectorFromString(selectorName);
            if (![target respondsToSelector:selector]) continue;
            ((void (*)(id, SEL, id))objc_msgSend)(
                target, selector, scrollView);
            AWEInteractionDiagnosticWrite(
                @"ALBUM_MORPH_SCROLL_BIND selector=%@ target=%@ scroll=%@",
                selectorName,
                AWEInteractionObjectSummary(target),
                AWEInteractionObjectSummary(scrollView));
            AWEAlbumMorphProbeWrite(
                @"PROXY_BIND selector=%@ target=%@ scroll=%@ content=%@ bounds=%@",
                selectorName, NSStringFromClass(target.class),
                NSStringFromClass(scrollView.class),
                NSStringFromCGSize(scrollView.contentSize),
                NSStringFromCGRect(scrollView.bounds));
            return;
        }
    }
    AWEAlbumMorphProbeWrite(
        @"PROXY_BIND_UNRESOLVED controller=%@ parent=%@ tabController=%@ scroll=%@",
        NSStringFromClass(controller.class),
        NSStringFromClass(controller.parentViewController.class),
        NSStringFromClass(controller.tabBarController.class),
        NSStringFromClass(scrollView.class));
}

static BOOL AWEInvokeAlbumMorphBoolAnimatedSelector(
    id target,
    NSString *selectorName,
    BOOL value,
    BOOL animated) {
    if (!target || selectorName.length == 0) return NO;
    SEL selector = NSSelectorFromString(selectorName);
    if (![target respondsToSelector:selector]) return NO;

    NSMethodSignature *signature = [target methodSignatureForSelector:selector];
    if (!signature) return NO;
    NSUInteger count = signature.numberOfArguments;
    if (count != 3 && count != 4) return NO;

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector = selector;
    [invocation setArgument:&value atIndex:2];
    if (count == 4) [invocation setArgument:&animated atIndex:3];

    @try {
        [invocation invoke];
        AWEInteractionDiagnosticWrite(
            @"ALBUM_MORPH_NATIVE_MINIMIZE selector=%@ value=%d animated=%d target=%@",
            selectorName, value, animated,
            AWEInteractionObjectSummary(target));
        AWEAlbumMorphProbeWrite(
            @"NATIVE_MINIMIZE selector=%@ value=%d animated=%d target=%@",
            selectorName, value, animated, NSStringFromClass([target class]));
        return YES;
    } @catch (__unused NSException *exception) {
        return NO;
    }
}

int32_t AWEAlbumMorphRequestNativeMinimized(UIViewController *controller,
                                             int32_t minimizedValue,
                                             int32_t animatedValue) {
    if (!controller) return 0;
    BOOL minimized = minimizedValue != 0;
    BOOL animated = animatedValue != 0;

    NSArray<NSString *> *selectors = @[
        @"_setTabBarMinimized:animated:",
        @"setTabBarMinimized:animated:",
        @"_setMinimized:animated:",
        @"_setTabBarCompact:animated:",
        @"setTabBarCompact:animated:",
        @"_setTabBarMinimized:",
        @"setTabBarMinimized:",
        @"_setMinimized:",
        @"_setTabBarCompact:",
        @"setTabBarCompact:"
    ];

    for (NSString *selectorName in selectors) {
        if (AWEInvokeAlbumMorphBoolAnimatedSelector(
                controller, selectorName, minimized, animated)) return 1;
    }

    UITabBarController *tabController =
        [controller isKindOfClass:UITabBarController.class]
            ? (UITabBarController *)controller
            : controller.tabBarController;
    UITabBar *tabBar = tabController.tabBar;
    for (NSString *selectorName in selectors) {
        if (AWEInvokeAlbumMorphBoolAnimatedSelector(
                tabBar, selectorName, minimized, animated)) return 1;
    }

    if (AWEInteractionDiagnosticsEnabled()) {
        NSMutableArray<NSString *> *runtimeNames = [NSMutableArray array];
        Class current = controller.class;
        while (current && current != NSObject.class) {
            unsigned int methodCount = 0;
            Method *methods = class_copyMethodList(current, &methodCount);
            for (unsigned int i = 0; i < methodCount; i++) {
                NSString *name = NSStringFromSelector(method_getName(methods[i]));
                NSString *lower = name.lowercaseString;
                if ([lower containsString:@"minimiz"] ||
                    ([lower containsString:@"compact"] &&
                     [lower containsString:@"tab"])) {
                    [runtimeNames addObject:name];
                }
            }
            free(methods);
            current = class_getSuperclass(current);
        }
        AWEInteractionDiagnosticWrite(
            @"ALBUM_MORPH_NATIVE_MINIMIZE_UNRESOLVED methods=%@",
            runtimeNames);
    }
    AWEAlbumMorphProbeWrite(
        @"NATIVE_MINIMIZE_UNRESOLVED minimized=%d animated=%d controller=%@ tabBar=%@",
        minimized, animated, NSStringFromClass(controller.class),
        NSStringFromClass(tabBar.class));
    return 0;
}

static void AWEApplyAlbumMorphOriginalSuppression(UIView *originalBar,
                                                    BOOL suppress) {
    UIView *previous = gAWEAlbumMorphSuppressedOriginalBar;
    if (previous && previous != originalBar) {
        NSNumber *opacity = objc_getAssociatedObject(
            previous, &kAWEAlbumMorphOriginalOpacityKey);
        NSNumber *interaction = objc_getAssociatedObject(
            previous, &kAWEAlbumMorphOriginalInteractionKey);
        if (opacity) previous.layer.opacity = opacity.floatValue;
        if (interaction) {
            previous.userInteractionEnabled = interaction.boolValue;
        }
        objc_setAssociatedObject(previous,
                                 &kAWEAlbumMorphOriginalOpacityKey,
                                 nil,
                                 OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(previous,
                                 &kAWEAlbumMorphOriginalInteractionKey,
                                 nil,
                                 OBJC_ASSOCIATION_ASSIGN);
    }

    if (!originalBar) {
        gAWEAlbumMorphSuppressedOriginalBar = nil;
        return;
    }

    if (suppress) {
        if (!objc_getAssociatedObject(
                originalBar, &kAWEAlbumMorphOriginalOpacityKey)) {
            objc_setAssociatedObject(
                originalBar,
                &kAWEAlbumMorphOriginalOpacityKey,
                @(originalBar.layer.opacity),
                OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        if (!objc_getAssociatedObject(
                originalBar, &kAWEAlbumMorphOriginalInteractionKey)) {
            objc_setAssociatedObject(
                originalBar,
                &kAWEAlbumMorphOriginalInteractionKey,
                @(originalBar.userInteractionEnabled),
                OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        originalBar.layer.opacity = 0.0f;
        originalBar.userInteractionEnabled = NO;

        /*
         The five-button glass bar shown by the original LiquidBar mode is a
         separate UITabBar retained through kAWENativeBarKey. Hiding only the
         AWENormalModeTabBar leaves that associated bar visible underneath the
         Photos-style controller, and later visibility/layout callbacks can
         make it reappear. Detach it while Album Morph mode owns the bottom
         area. The association keeps the object alive so the stable mode can
         reattach it when this style is disabled.
        */
        UITabBar *legacyNativeBar = objc_getAssociatedObject(
            originalBar, &kAWENativeBarKey);
        if (legacyNativeBar) {
            legacyNativeBar.hidden = YES;
            legacyNativeBar.userInteractionEnabled = NO;
            legacyNativeBar.layer.opacity = 0.0f;
            [legacyNativeBar removeFromSuperview];
        }

        gAWEAlbumMorphSuppressedOriginalBar = originalBar;
    } else {
        NSNumber *opacity = objc_getAssociatedObject(
            originalBar, &kAWEAlbumMorphOriginalOpacityKey);
        NSNumber *interaction = objc_getAssociatedObject(
            originalBar, &kAWEAlbumMorphOriginalInteractionKey);
        if (opacity) originalBar.layer.opacity = opacity.floatValue;
        if (interaction) {
            originalBar.userInteractionEnabled = interaction.boolValue;
        }
        objc_setAssociatedObject(originalBar,
                                 &kAWEAlbumMorphOriginalOpacityKey,
                                 nil,
                                 OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(originalBar,
                                 &kAWEAlbumMorphOriginalInteractionKey,
                                 nil,
                                 OBJC_ASSOCIATION_ASSIGN);
        if (gAWEAlbumMorphSuppressedOriginalBar == originalBar) {
            gAWEAlbumMorphSuppressedOriginalBar = nil;
        }
    }
}

static void AWEAlignAlbumMorphOverlayToOriginalBar(
    UIView *originalBar,
    UIWindow *sourceWindow,
    UIWindow *overlayWindow) {
    (void)originalBar;
    if (!sourceWindow || !overlayWindow || !gAWEAlbumMorphController.tabBar) {
        return;
    }

    /* Keep the overlay window permanently coincident with the host window.
       Moving the whole UIWindow caused UIKit to repeatedly recompute the
       managed UITabBar geometry during navigation and route recovery. The
       user offset now belongs only to the tab bar inside its controller. */
    CGRect targetFrame = sourceWindow.bounds;
    BOOL changed =
        gAWEAlbumMorphLastAlignedSourceWindow != sourceWindow ||
        fabs(CGRectGetMinX(overlayWindow.frame) - CGRectGetMinX(targetFrame)) > 0.25 ||
        fabs(CGRectGetMinY(overlayWindow.frame) - CGRectGetMinY(targetFrame)) > 0.25 ||
        fabs(CGRectGetWidth(overlayWindow.frame) - CGRectGetWidth(targetFrame)) > 0.25 ||
        fabs(CGRectGetHeight(overlayWindow.frame) - CGRectGetHeight(targetFrame)) > 0.25;

    if (changed) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        overlayWindow.transform = CGAffineTransformIdentity;
        overlayWindow.frame = targetFrame;
        [CATransaction commit];
        gAWEAlbumMorphLastAlignedFrame = targetFrame;
        gAWEAlbumMorphLastAlignedSourceWindow = sourceWindow;
    }

    CGFloat savedOffset = AWEStoredVerticalOffset();
    static CGFloat lastAppliedOffset = CGFLOAT_MAX;
    static __weak id lastOffsetController = nil;
    BOOL offsetChanged = lastOffsetController != gAWEAlbumMorphController ||
        fabs(lastAppliedOffset - savedOffset) > 0.01;
    if (offsetChanged) {
        [gAWEAlbumMorphController setVerticalOffset:savedOffset];
        lastAppliedOffset = savedOffset;
        lastOffsetController = gAWEAlbumMorphController;
    }
    if (changed || offsetChanged) {
        AWEAlbumMorphProbeWrite(
            @"HEIGHT_SYNC_FIXED saved=%.2f overlay=%@ tabBar=%@",
            savedOffset,
            NSStringFromCGRect(overlayWindow.frame),
            NSStringFromCGRect(gAWEAlbumMorphController.tabBar.frame));
    }
}

static UIUserInterfaceStyle AWEAlbumMorphResolvedInterfaceStyle(
    UIWindow *sourceWindow,
    NSInteger originalIndex) {
    (void)originalIndex;
    if (AWEIsIOS27OrLater() && AWEHomeForceDarkGlassEnabled()) {
        return UIUserInterfaceStyleDark;
    }
    return AWEAlbumMorphResolvedProbeStyle(
        sourceWindow ?: AWEActiveMainWindow());
}

static void AWEScheduleStableHomeChromeStyle(
    UIUserInterfaceStyle style) {
    if (style != UIUserInterfaceStyleLight &&
        style != UIUserInterfaceStyleDark) return;
    if (gAWEHomeChromeLastStableStyle == UIUserInterfaceStyleUnspecified) {
        gAWEHomeChromeLastStableStyle = style;
        gAWEHomeChromePendingStyle = UIUserInterfaceStyleUnspecified;
        AWERefreshRegisteredAdaptiveGlassButtons();
        return;
    }
    if (gAWEHomeChromeLastStableStyle == style) {
        gAWEHomeChromePendingStyle = UIUserInterfaceStyleUnspecified;
        gAWEHomeChromeStyleGeneration++;
        return;
    }
    gAWEHomeChromePendingStyle = style;
    NSUInteger generation = ++gAWEHomeChromeStyleGeneration;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                 (int64_t)(0.18 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (generation != gAWEHomeChromeStyleGeneration ||
            gAWEHomeChromePendingStyle != style ||
            !AWEOriginalBarSteadyWantsVisible((UIView *)gAWELastTabBar)) {
            return;
        }
        gAWEHomeChromePendingStyle = UIUserInterfaceStyleUnspecified;
        if (gAWEHomeChromeLastStableStyle != style) {
            gAWEHomeChromeLastStableStyle = style;
            AWERefreshRegisteredAdaptiveGlassButtons();
        }
    });
}

static void AWEApplyAlbumMorphResolvedAppearance(
    UIWindow *sourceWindow,
    NSInteger originalIndex) {
    if (!gAWEAlbumMorphController) return;

    UIUserInterfaceStyle style =
        AWEAlbumMorphResolvedInterfaceStyle(sourceWindow, originalIndex);
    if (style != UIUserInterfaceStyleLight &&
        style != UIUserInterfaceStyleDark) {
        style = UIScreen.mainScreen.traitCollection.userInterfaceStyle;
    }
    if (style != UIUserInterfaceStyleLight &&
        style != UIUserInterfaceStyleDark) {
        style = UIUserInterfaceStyleLight;
    }

    BOOL homeChromeActive = AWEOriginalBarSteadyWantsVisible((UIView *)gAWELastTabBar);
    if (homeChromeActive) AWEScheduleStableHomeChromeStyle(style);
    gAWEAlbumMorphLastAppliedStyle = style;
    BOOL changed =
        gAWEAlbumMorphOverlayWindow.overrideUserInterfaceStyle != style ||
        gAWEAlbumMorphController.overrideUserInterfaceStyle != style ||
        gAWEAlbumMorphController.view.overrideUserInterfaceStyle != style ||
        gAWEAlbumMorphController.tabBar.overrideUserInterfaceStyle != style;
    if (!changed) return;

    [UIView performWithoutAnimation:^{
        if (gAWEAlbumMorphOverlayWindow) {
            gAWEAlbumMorphOverlayWindow.overrideUserInterfaceStyle = style;
        }
        [gAWEAlbumMorphController setResolvedInterfaceStyleRaw:(NSInteger)style];
        gAWEAlbumMorphController.overrideUserInterfaceStyle = style;
        gAWEAlbumMorphController.view.overrideUserInterfaceStyle = style;
        gAWEAlbumMorphController.tabBar.overrideUserInterfaceStyle = style;
    }];
    BOOL forcedDark = AWEIsIOS27OrLater() && AWEHomeForceDarkGlassEnabled();
    AWEInteractionDiagnosticWrite(
        @"ALBUM_MORPH_APPEARANCE index=%ld mode=%@ style=%@",
        (long)originalIndex,
        forcedDark ? @"IOS27_FORCE_DARK" : @"SYSTEM_PROBE",
        style == UIUserInterfaceStyleDark ? @"DARK" : @"LIGHT");
}

#pragma mark - Photos-style native four-tab controller

@interface AWEAlbumMorphCoordinator : NSObject
@end

@implementation AWEAlbumMorphCoordinator

- (void)albumMorphDidRequestOriginalIndex:(NSInteger)index {
    AWENormalModeTabBar *originalBar = gAWELastTabBar;
    if (!originalBar && gAWELastController) {
        /* Fresh installs can materialize the transplanted native bar before
           the weak original-bar cache has been populated. Re-acquire the
           source bar from the controller instead of silently dropping taps. */
        originalBar = AWEPrepareBarForController(gAWELastController, NO);
        if (originalBar) gAWELastTabBar = originalBar;
    }

    AWEAlbumMorphOverlayWindow *overlay =
        (AWEAlbumMorphOverlayWindow *)gAWEAlbumMorphOverlayWindow;
    AWEInteractionDiagnosticWrite(
        @"ALBUM_MORPH_TAP_BEGIN index=%ld original=%@ controller=%@ native=%@ overlay=%@ content=%d",
        (long)index,
        AWEInteractionObjectSummary(originalBar),
        AWEInteractionObjectSummary(gAWELastController),
        AWEInteractionObjectSummary(gAWEAlbumMorphController ? gAWEAlbumMorphController.tabBar : nil),
        AWEInteractionObjectSummary(overlay),
        overlay ? overlay.contentVisible : 0);

    if (!originalBar) {
        AWEInteractionDiagnosticWrite(
            @"ALBUM_MORPH_TAP_END index=%ld result=NO reason=no-original-bar",
            (long)index);
        return;
    }

    UIWindow *sourceWindow = originalBar.window ?: AWEActiveMainWindow();
    AWEUpdateFriendsTabLatch(index);
    AWEApplyAlbumMorphResolvedAppearance(sourceWindow, index);

    if (index == 1 && !AWESecondTabIsShop()) {
        /* Preserve the native bar's layout footprint before Friends performs
           its first content layout. The bar stays visually suppressed by our
           layer-opacity path, but captions no longer initially fall under the
           replacement bar. */
        [UIView performWithoutAnimation:^{
            originalBar.hidden = NO;
            originalBar.alpha = 1.0;
        }];
        AWEApplyAlbumMorphOriginalSuppression((UIView *)originalBar, YES);
        [originalBar.superview setNeedsLayout];
        [originalBar.superview layoutIfNeeded];
    }

    if (index == 2) {
        gAWEAlbumMorphPublishLaunchSuppressionUntil =
            CACurrentMediaTime() + 300.0;
        gAWEAlbumMorphPublishSourceController =
            AWETopViewControllerFrom(sourceWindow.rootViewController);
        AWERestoreAlbumMorphSearchGesture();
        /* Restore the proven pre-1.0.46 publish isolation.  The overlay stays
           allocated/warm, but the UIWindow itself is hidden so it cannot own
           any hit-testing or transition snapshot while Douyin's creation flow
           is being presented/dismissed. */
        AWEHardSuspendAlbumMorphOverlay(@"publish.prehide");
        AWEAlbumMorphProbeWrite(@"PUBLISH_PREHIDE hard=1");
    }

    BOOL forwarded = AWEForwardToOriginalButton((UIView *)originalBar, index);
    if (!forwarded && gAWELastController) {
        AWENormalModeTabBar *fresh =
            AWEPrepareBarForController(gAWELastController, NO);
        if (fresh) {
            forwarded = AWEForwardToOriginalButton((UIView *)fresh, index);
        }
    }

    AWEInteractionDiagnosticWrite(
        @"ALBUM_MORPH_FORWARD index=%ld result=%d original=%@ controller=%@",
        (long)index, forwarded,
        AWEInteractionObjectSummary(originalBar),
        AWEInteractionObjectSummary(gAWELastController));

    if (index == 2 && !forwarded) {
        gAWEAlbumMorphPublishLaunchSuppressionUntil = 0.0;
        gAWEAlbumMorphPublishSourceController = nil;
        AWEForceAlbumMorphRouteRecovery(@"publish.forward.failed");
    }

    __weak UIWindow *weakSourceWindow = sourceWindow;
    for (NSNumber *delay in @[@0.0, @0.06, @0.18, @0.45]) {
        dispatch_after(dispatch_time(
            DISPATCH_TIME_NOW,
            (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{
                UIWindow *window = weakSourceWindow ?: AWEActiveMainWindow();
                if (gAWEAlbumMorphController.currentOriginalIndex == index) {
                    AWEApplyAlbumMorphResolvedAppearance(window, index);
                }
            });
    }
}

- (void)albumMorphDidRequestSearch {
    UIWindow *window = AWEActiveMainWindow();
    UIView *topContainer = window
        ? AWEFindViewByExactRuntimeClass(
            window, @"AWEFeedTopBarContainer", 0)
        : nil;
    UIView *owner = topContainer
        ? AWEFindTopOwnerCandidate(topContainer, YES)
        : nil;
    if (!owner && window) {
        owner = AWEFindViewByExactRuntimeClass(
            window, @"AWEHPDiscoverFeedEntranceView", 0);
    }
    if (!owner && window) {
        owner = AWEFindViewByExactRuntimeClass(
            window, @"AWEHPSearchBubbleEntranceView", 0);
    }

    BOOL forwarded = AWEForwardTopActionOwner(
        owner, AWEHomeTopActionKindSearch);
    AWEInteractionDiagnosticWrite(
        @"ALBUM_MORPH_SEARCH owner=%@ result=%d",
        AWEInteractionObjectSummary(owner), forwarded);
}

@end

@implementation AWEAlbumMorphOverlayWindow

/* The resident LiquidBar window is visual/touch chrome only. It must never
   become the app key window; allowing a higher-level overlay window to own key
   status can make Douyin's feed lifecycle treat the real player window as
   inactive, especially after foreground restore. */
- (BOOL)canBecomeKeyWindow {
    return NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (gAWEStableCleanScreenEnabled) return nil;
    AWEExternalBridgeMenuSlotView *downloadSlot = gAWEDownloadMenuSlot;
    if (downloadSlot && downloadSlot.window == self &&
        !downloadSlot.hidden && downloadSlot.alpha > 0.01 &&
        downloadSlot.userInteractionEnabled) {
        CGPoint pointInDownload = [self convertPoint:point toView:downloadSlot];
        if ([downloadSlot pointInside:pointInDownload withEvent:event]) {
            UIView *downloadHit = [downloadSlot hitTest:pointInDownload withEvent:event]
                ?: downloadSlot.menuButton ?: downloadSlot;
            if (AWEInteractionDiagnosticsEnabled() && event.type == UIEventTypeTouches) {
                AWEInteractionDiagnosticWrite(@"DOWNLOAD_BUTTON_HIT point=(%.1f,%.1f) hit=%@",
                    point.x, point.y, AWEInteractionObjectSummary(downloadHit));
            }
            return downloadHit;
        }
    }
    /* Bottom-bar hidden mode is true touch passthrough. The overlay UIWindow
       remains resident for other independent plugin controls, but the entire
       former tab/search footprint contributes no hit target, so controls from
       Douyin or another tweak underneath remain clickable. */
    if (!AWEBottomBarDisplayEnabled()) return nil;
    if (!self.contentVisible) return nil;
    UIView *searchProxy = self.searchTouchProxy;
    if (searchProxy && !searchProxy.hidden &&
        searchProxy.userInteractionEnabled && searchProxy.alpha > 0.01) {
        CGPoint pointInProxy = [self convertPoint:point toView:searchProxy];
        if ([searchProxy pointInside:pointInProxy withEvent:event]) {
            UIView *searchHit = [searchProxy hitTest:pointInProxy withEvent:event]
                ?: searchProxy;
            if (AWEInteractionDiagnosticsEnabled() && event.type == UIEventTypeTouches) {
                AWEInteractionDiagnosticWrite(
                    @"ALBUM_HIT_SEARCH point=(%.1f,%.1f) proxy=%@ hit=%@",
                    point.x, point.y, AWEInteractionObjectSummary(searchProxy),
                    AWEInteractionObjectSummary(searchHit));
            }
            return searchHit;
        }
    }

    UITabBar *tabBar = self.managedTabBar;
    if (!tabBar || tabBar.hidden || tabBar.alpha <= 0.01) return nil;

    CGPoint pointInBar = [self convertPoint:point toView:tabBar];
    if (![tabBar pointInside:pointInBar withEvent:event]) return nil;

    UIView *hit = [tabBar hitTest:pointInBar withEvent:event];
    UIView *resolved = hit ?: tabBar;
    if (AWEInteractionDiagnosticsEnabled() && event.type == UIEventTypeTouches) {
        CFTimeInterval now = CACurrentMediaTime();
        if (now - gAWELastBottomHitDiagnosticTime >= 0.10) {
            gAWELastBottomHitDiagnosticTime = now;
            AWEInteractionDiagnosticWrite(
                @"ALBUM_HIT_TAB point=(%.1f,%.1f) barPoint=(%.1f,%.1f) content=%d barHidden=%d barAlpha=%.3f barUI=%d selected=%ld hit=%@",
                point.x, point.y, pointInBar.x, pointInBar.y, self.contentVisible,
                tabBar.hidden, tabBar.alpha, tabBar.userInteractionEnabled,
                (long)gAWEAlbumMorphController.selectedIndex,
                AWEInteractionObjectSummary(resolved));
        }
    }
    return resolved;
}

@end

static void AWEPrepareAlbumMorphOverlayTransparency(void) {
    UIWindow *overlay = gAWEAlbumMorphOverlayWindow;
    if (!overlay) return;
    [UIView performWithoutAnimation:^{
        overlay.backgroundColor = UIColor.clearColor;
        overlay.opaque = NO;
        overlay.layer.backgroundColor = UIColor.clearColor.CGColor;
        UIViewController *root = overlay.rootViewController;
        root.view.backgroundColor = UIColor.clearColor;
        root.view.opaque = NO;
        root.view.layer.backgroundColor = UIColor.clearColor.CGColor;
        if (gAWEAlbumMorphController.tabBar) {
            gAWEAlbumMorphController.tabBar.backgroundColor = UIColor.clearColor;
            gAWEAlbumMorphController.tabBar.opaque = NO;
            gAWEAlbumMorphController.tabBar.layer.backgroundColor =
                UIColor.clearColor.CGColor;
        }
    }];
}

static UIView *AWEAlbumMorphSearchOwner(UIWindow *window) {
    if (!window) return nil;
    UIView *topContainer = AWEFindViewByExactRuntimeClass(
        window, @"AWEFeedTopBarContainer", 0);
    UIView *owner = topContainer
        ? AWEFindTopOwnerCandidate(topContainer, YES)
        : nil;
    if (!owner) {
        owner = AWEFindViewByExactRuntimeClass(
            window, @"AWEHPDiscoverFeedEntranceView", 0);
    }
    if (!owner) {
        owner = AWEFindViewByExactRuntimeClass(
            window, @"AWEHPSearchBubbleEntranceView", 0);
    }
    return owner;
}

static UIGestureRecognizer *AWEAlbumMorphFindSearchGesture(UIView *root) {
    if (!root) return nil;
    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:root];
    UIGestureRecognizer *fallback = nil;
    NSUInteger visited = 0;
    while (queue.count > 0 && visited < 96) {
        UIView *view = queue.firstObject;
        [queue removeObjectAtIndex:0];
        visited++;
        for (UIGestureRecognizer *recognizer in view.gestureRecognizers) {
            if (!recognizer.enabled) continue;
            NSString *name = NSStringFromClass(recognizer.class).lowercaseString;
            if ([name containsString:@"alphatap"] ||
                [name containsString:@"searchtap"] ||
                [name containsString:@"clickgesture"]) return recognizer;
            if (!fallback &&
                ([recognizer isKindOfClass:UITapGestureRecognizer.class] ||
                 [name containsString:@"tap"] ||
                 [name containsString:@"click"])) fallback = recognizer;
        }
        for (UIView *child in view.subviews) [queue addObject:child];
    }
    return fallback;
}

static UIView *AWEAlbumMorphRightmostTabButton(UITabBar *tabBar) {
    if (!tabBar) return nil;
    NSMutableArray<UIView *> *queue =
        [NSMutableArray arrayWithArray:tabBar.subviews];
    UIView *best = nil;
    CGFloat bestX = -CGFLOAT_MAX;
    NSUInteger visited = 0;
    while (queue.count > 0 && visited < 160) {
        UIView *view = queue.firstObject;
        [queue removeObjectAtIndex:0];
        visited++;
        if (view.hidden || view.alpha <= 0.01) continue;
        NSString *name = NSStringFromClass(view.class);
        BOOL buttonLike = [view isKindOfClass:UIControl.class] ||
            [name containsString:@"TabBarButton"] ||
            [name containsString:@"TabBarItemView"];
        if (buttonLike && CGRectGetWidth(view.bounds) >= 38.0 &&
            CGRectGetHeight(view.bounds) >= 38.0) {
            CGRect inBar = [view convertRect:view.bounds toView:tabBar];
            CGFloat midX = CGRectGetMidX(inBar);
            if (midX > bestX) {
                bestX = midX;
                best = view;
            }
        }
        for (UIView *child in view.subviews) [queue addObject:child];
    }
    return best;
}

static void AWERestoreAlbumMorphSearchGesture(void) {
    UIGestureRecognizer *gesture = gAWEAlbumMorphSearchGesture;
    UIView *originalView = gAWEAlbumMorphSearchGestureOriginalView;
    if (gesture && originalView && gesture.view != originalView) {
        [originalView addGestureRecognizer:gesture];
    } else if (gesture && gesture.view == gAWEAlbumMorphSearchTouchProxy) {
        [gAWEAlbumMorphSearchTouchProxy removeGestureRecognizer:gesture];
    }
    gAWEAlbumMorphSearchGesture = nil;
    gAWEAlbumMorphSearchGestureOriginalView = nil;
    [gAWEAlbumMorphSearchTouchProxy removeFromSuperview];
    gAWEAlbumMorphSearchTouchProxy = nil;
}

static void AWEConfigureAlbumMorphSearchTouchProxy(
    AWEAlbumMorphOverlayWindow *overlay,
    UIWindow *sourceWindow) {
    if (!overlay || !sourceWindow || !gAWEAlbumMorphController.tabBar) return;

    if (![AWEAlbumMorphVisibleItemIdentifiers() containsObject:@"search"]) {
        AWERestoreAlbumMorphSearchGesture();
        overlay.searchTouchProxy = nil;
        return;
    }

    UIView *tabButton = AWEAlbumMorphRightmostTabButton(
        gAWEAlbumMorphController.tabBar);
    CGRect targetFrame = CGRectZero;
    if (tabButton) {
        @try {
            targetFrame = [tabButton convertRect:tabButton.bounds toView:overlay];
        } @catch (__unused NSException *exception) {
            targetFrame = CGRectZero;
        }
    }
    if (CGRectIsEmpty(targetFrame)) {
        CGRect barFrame = [gAWEAlbumMorphController.tabBar
            convertRect:gAWEAlbumMorphController.tabBar.bounds
                  toView:overlay];
        CGFloat side = MIN(MAX(CGRectGetHeight(barFrame), 52.0), 78.0);
        targetFrame = CGRectMake(
            CGRectGetMaxX(barFrame) - side,
            CGRectGetMidY(barFrame) - side * 0.5,
            side,
            side);
    }
    targetFrame = CGRectInset(targetFrame, -3.0, -3.0);

    UIView *proxy = gAWEAlbumMorphSearchTouchProxy;
    if (!proxy) {
        proxy = [[UIView alloc] initWithFrame:targetFrame];
        proxy.backgroundColor = UIColor.clearColor;
        proxy.opaque = NO;
        proxy.userInteractionEnabled = YES;
        proxy.accessibilityIdentifier =
            @"AwemeLiquidBar.AlbumMorph.RealSearchTouchProxy";
        [overlay addSubview:proxy];
        gAWEAlbumMorphSearchTouchProxy = proxy;
    }
    proxy.frame = targetFrame;
    proxy.hidden = NO;
    overlay.searchTouchProxy = proxy;
    [overlay bringSubviewToFront:proxy];

    if (gAWEAlbumMorphSearchGesture &&
        gAWEAlbumMorphSearchGesture.view == proxy) return;

    UIView *owner = AWEAlbumMorphSearchOwner(sourceWindow);
    UIGestureRecognizer *gesture = AWEAlbumMorphFindSearchGesture(owner);
    if (!gesture) {
        proxy.hidden = YES;
        overlay.searchTouchProxy = nil;
        AWEInteractionDiagnosticWrite(
            @"ALBUM_MORPH_SEARCH_PROXY_FAILED owner=%@",
            AWEInteractionObjectSummary(owner));
        return;
    }

    gAWEAlbumMorphSearchGesture = gesture;
    gAWEAlbumMorphSearchGestureOriginalView = gesture.view;
    [proxy addGestureRecognizer:gesture];
    proxy.hidden = NO;
    AWEInteractionDiagnosticWrite(
        @"ALBUM_MORPH_SEARCH_PROXY_BOUND owner=%@ recognizer=%@ frame=%@",
        AWEInteractionObjectSummary(owner),
        NSStringFromClass(gesture.class),
        NSStringFromCGRect(targetFrame));
}

static void AWEUninstallAlbumMorphBar(void) {
    AWEStopAlbumMorphTintDisplayLink();
    AWERestoreAlbumMorphSearchGesture();
    AWEApplyAlbumMorphOriginalSuppression(
        gAWEAlbumMorphSuppressedOriginalBar, NO);
    gAWEAlbumMorphOverlayWindow.transform = CGAffineTransformIdentity;
    gAWEAlbumMorphOverlayWindow.hidden = YES;
    gAWEAlbumMorphOverlayWindow.rootViewController = nil;
    gAWEAlbumMorphOverlayWindow = nil;
    gAWEAlbumMorphController = nil;
    gAWEAlbumMorphCoordinator = nil;
    gAWEAlbumMorphVisible = NO;
    gAWEAlbumMorphLastAlignedFrame = CGRectZero;
    gAWEAlbumMorphLastAlignedSourceWindow = nil;
}

static BOOL AWEEnsureAlbumMorphController(void) {
    if (gAWEAlbumMorphController) return YES;

    void *rawController = AWEAlbumMorphCreateController();
    if (!rawController) {
        AWEInteractionDiagnosticWrite(@"ALBUM_MORPH_FACTORY_FAILED");
        return NO;
    }

    gAWEAlbumMorphController =
        (__bridge_transfer AWEAlbumMorphTabController *)rawController;
    gAWEAlbumMorphCoordinator = [AWEAlbumMorphCoordinator new];
    gAWEAlbumMorphController.actionSink = gAWEAlbumMorphCoordinator;
    [gAWEAlbumMorphController loadViewIfNeeded];
    return gAWEAlbumMorphController.tabBar != nil;
}

static BOOL AWEEnsureAlbumMorphOverlayWindow(UIWindow *sourceWindow) {
    if (!sourceWindow || !sourceWindow.windowScene ||
        !AWEEnsureAlbumMorphController()) {
        return NO;
    }

    AWEAlbumMorphOverlayWindow *overlay =
        (AWEAlbumMorphOverlayWindow *)gAWEAlbumMorphOverlayWindow;
    BOOL created = !overlay || overlay.windowScene != sourceWindow.windowScene;
    if (created) {
        overlay.hidden = YES;
        overlay.rootViewController = nil;

        [gAWEAlbumMorphController loadViewIfNeeded];
        gAWEAlbumMorphController.view.backgroundColor = UIColor.clearColor;
        gAWEAlbumMorphController.view.opaque = NO;
        gAWEAlbumMorphController.tabBar.backgroundColor = UIColor.clearColor;
        gAWEAlbumMorphController.tabBar.opaque = NO;

        overlay = [[AWEAlbumMorphOverlayWindow alloc]
            initWithWindowScene:sourceWindow.windowScene];
        overlay.backgroundColor = UIColor.clearColor;
        overlay.opaque = NO;
        overlay.windowLevel = sourceWindow.windowLevel + 1.0;
        overlay.frame = sourceWindow.bounds;
        overlay.contentVisible = NO;
        gAWEAlbumMorphOverlayWindow = overlay;
        overlay.rootViewController = gAWEAlbumMorphController;
        overlay.managedTabBar = gAWEAlbumMorphController.tabBar;
        [overlay layoutIfNeeded];
        AWEPrepareAlbumMorphOverlayTransparency();
        gAWEAlbumMorphController.tabBar.alpha = 1.0;
        gAWEAlbumMorphController.tabBar.userInteractionEnabled = NO;
        [gAWEAlbumMorphController setVisibleFraction:0.0 animated:NO];
        /* Keep this transparent window resident. Re-hiding/revealing a freshly
           composited UIWindow was the one-frame white flash after comments. */
        overlay.hidden = NO;
        gAWEAlbumMorphLastAlignedFrame = CGRectZero;
        gAWEAlbumMorphLastAlignedSourceWindow = sourceWindow;
    } else {
        CGRect frame = sourceWindow.bounds;
        if (fabs(CGRectGetMinX(overlay.frame) - CGRectGetMinX(frame)) > 0.25 ||
            fabs(CGRectGetMinY(overlay.frame) - CGRectGetMinY(frame)) > 0.25 ||
            fabs(CGRectGetWidth(overlay.frame) - CGRectGetWidth(frame)) > 0.5 ||
            fabs(CGRectGetHeight(overlay.frame) - CGRectGetHeight(frame)) > 0.5) {
            [CATransaction begin];
            [CATransaction setDisableActions:YES];
            overlay.transform = CGAffineTransformIdentity;
            overlay.frame = frame;
            [CATransaction commit];
        }
        if (overlay.rootViewController != gAWEAlbumMorphController) {
            overlay.rootViewController = gAWEAlbumMorphController;
        }
    }

    overlay.managedTabBar = gAWEAlbumMorphController.tabBar;
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanEnforceBottomBarSuppression();
        return YES;
    }
    overlay.userInteractionEnabled = YES;
    overlay.alpha = 1.0;
    overlay.hidden = NO;
    AWEPrepareAlbumMorphOverlayTransparency();
    return YES;
}

static BOOL AWEInstallOrUpdateAlbumMorphBar(UIView *originalBar,
                                             BOOL forceVisible) {
    /* 1.0.56c13: when the visual bottom bar is disabled, LiquidBar no longer
       owns the native tab-bar host at all. Fully tear down our resident
       UITabBar/overlay and restore the original AWENormalModeTabBar so another
       tweak can attach to the same native host. This is deliberately stronger
       than alpha/hidden: there is no LiquidBar tab view left in the hierarchy. */
    if (!AWEBottomBarDisplayEnabled()) {
        AWEUninstallAlbumMorphBar();
        return NO;
    }

    if (!AWEAlbumMorphStyleEnabled() ||
        !AWEPluginFeaturesEnabled() ||
        AWEOperatingSystemMajorVersion() < 26) {
        AWEUninstallAlbumMorphBar();
        return NO;
    }

    UIWindow *sourceWindow = originalBar.window ?: AWEActiveMainWindow();
    if (!AWEEnsureAlbumMorphOverlayWindow(sourceWindow)) {
        AWEInteractionDiagnosticWrite(
            @"ALBUM_MORPH_INSTALL_FAILED sourceWindow=%@ scene=%@ controller=%@",
            AWEInteractionObjectSummary(sourceWindow),
            AWEInteractionObjectSummary(sourceWindow.windowScene),
            AWEInteractionObjectSummary(gAWEAlbumMorphController));
        return NO;
    }

    AWEAlbumMorphOverlayWindow *overlay =
        (AWEAlbumMorphOverlayWindow *)gAWEAlbumMorphOverlayWindow;
    overlay.windowLevel = sourceWindow.windowLevel + 1.0;
    overlay.managedTabBar = gAWEAlbumMorphController.tabBar;

    [gAWEAlbumMorphController configureSecondTabAsShop:AWESecondTabIsShop()];
    [gAWEAlbumMorphController
        configureVisibleItemIdentifiers:AWEAlbumMorphVisibleItemIdentifiers()];
    [gAWEAlbumMorphController updateAccentColor:AWEStoredAccentColor()];
    AWEUpdateAlbumMorphMessageBadge();

    AWEApplyAlbumMorphOriginalSuppression(originalBar, YES);
    AWEAlignAlbumMorphOverlayToOriginalBar(
        originalBar, sourceWindow, overlay);
    AWEConfigureAlbumMorphSearchTouchProxy(overlay, sourceWindow);

    NSInteger selected = [gAWEAlbumMorphController currentOriginalIndex];
    NSInteger originalSelected = AWECurrentOriginalMainTabIndex();
    AWEUpdateFriendsTabLatch(originalSelected);
    if (selected == NSNotFound &&
        (originalSelected == 0 || originalSelected == 1 ||
         originalSelected == 3 || originalSelected == 4)) {
        selected = originalSelected;
        [gAWEAlbumMorphController syncSelectedOriginalIndex:selected];
    }
    if (selected == NSNotFound) selected = 0;
    AWEApplyAlbumMorphResolvedAppearance(sourceWindow, selected);

    BOOL settledOriginalVisible =
        originalBar && AWEAlbumMorphSteadyWantsVisible(originalBar);
    BOOL routeSuppresses = AWECurrentRouteSuppressesBar();
    (void)forceVisible;

    /*
     Keep the real tab bar and its glass renderer alive permanently.  The
     visible area is driven exclusively by the 1.0.10b-style mask, including
     interactive return progress.  Never toggle alpha/hidden here: doing so
     forces the compositor to recreate the glass surface and causes the white
     flash/disappear-reappear cycle.
    */
    AWEPrepareAlbumMorphOverlayTransparency();
    if (gAWEStableCleanScreenEnabled) {
        AWEApplyAlbumMorphVisibleFraction(0.0, @"install.clean-guard", NO);
        return YES;
    }
    [UIView performWithoutAnimation:^{
        overlay.hidden = NO;
        overlay.alpha = 1.0;
        gAWEAlbumMorphController.view.hidden = NO;
        gAWEAlbumMorphController.view.alpha = 1.0;
        gAWEAlbumMorphController.tabBar.hidden = NO;
        gAWEAlbumMorphController.tabBar.alpha = 1.0;
    }];
    AWEUpdateAlbumMorphVisibility(originalBar, @"install.original-state");

    BOOL visible = gAWEBarLastVisibleFraction > 0.001;
    AWEEnsureAlbumMorphTintProbe(sourceWindow);
    if (visible) {
        AWEStartAlbumMorphTintDisplayLink();
        AWERefreshAlbumMorphTintFromSystemProbe();
    } else {
        AWEHideAlbumMorphTintProbe();
    }

    static NSString *lastOverlayDiagnosticSignature = nil;
    NSString *overlayDiagnosticSignature = [NSString stringWithFormat:
        @"%d|%d|%d|%d|%d|%@|%@",
        forceVisible, settledOriginalVisible, routeSuppresses,
        gAWESettingsVisible, visible,
        AWEInteractionObjectSummary(overlay),
        AWEInteractionObjectSummary(gAWEAlbumMorphController.tabBar)];
    if (![lastOverlayDiagnosticSignature isEqualToString:overlayDiagnosticSignature]) {
        lastOverlayDiagnosticSignature = [overlayDiagnosticSignature copy];
        AWEInteractionDiagnosticWrite(
            @"ALBUM_MORPH_OVERLAY requestedForce=%d originalLive=%d routeSuppress=%d settings=%d result=%d window=%@ tabBar=%@",
            forceVisible,
            settledOriginalVisible,
            routeSuppresses,
            gAWESettingsVisible,
            visible,
            AWEInteractionObjectSummary(overlay),
            AWEInteractionObjectSummary(gAWEAlbumMorphController.tabBar));
    }
    return YES;
}

/* A simultaneous source-window pan bridge requests UIKit's native compact
   selector first and falls back to a height-derived translation. Neither path
   writes a fixed expanded frame, so the vertical position slider remains safe. */

static AWEHomeTopSlotView *AWEEnsureTopSlot(UIView *container,
                                            AWEHomeTopActionKind kind) {
    if (!container) return nil;
    const void *key = kind == AWEHomeTopActionKindSearch
        ? &kAWETopSearchSlotKey
        : &kAWETopMenuSlotKey;
    AWEHomeTopSlotView *slot = objc_getAssociatedObject(container, key);
    if (!slot) {
        slot = [[AWEHomeTopSlotView alloc] initWithFrame:CGRectZero];
        slot.topKind = kind;
        slot.userInteractionEnabled = YES;
        slot.backgroundColor = UIColor.clearColor;
        slot.opaque = NO;
        slot.accessibilityIdentifier = kind == AWEHomeTopActionKindSearch
            ? @"AwemeLiquidBar.HomeTopSlot.Search"
            : @"AwemeLiquidBar.HomeTopSlot.Menu";

        if (@available(iOS 26.0, *)) {
            UIButton *glassButton = [UIButton buttonWithType:UIButtonTypeCustom];
            glassButton.userInteractionEnabled = NO;
            glassButton.backgroundColor = UIColor.clearColor;
            glassButton.opaque = NO;
            glassButton.clipsToBounds = NO;
            [slot addSubview:glassButton];
            slot.systemGlassButton = glassButton;
        }

        UIButton *hit = [UIButton buttonWithType:UIButtonTypeCustom];
        hit.backgroundColor = UIColor.clearColor;
        hit.opaque = NO;
        [hit addTarget:slot action:@selector(alb_handleTopTap:)
       forControlEvents:UIControlEventTouchUpInside];
        [slot addSubview:hit];
        slot.hitButton = hit;

        objc_setAssociatedObject(container, key, slot,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [container addSubview:slot];
    } else if (slot.superview != container) {
        [slot removeFromSuperview];
        [container addSubview:slot];
    }
    return slot;
}

static BOOL AWETopSourceIsNearExpectedPoint(UIView *container,
                                            UIView *source,
                                            AWEHomeTopActionKind kind) {
    if (!container || !source) return NO;
    CGPoint actual = [source convertPoint:
        CGPointMake(CGRectGetMidX(source.bounds), CGRectGetMidY(source.bounds))
        toView:container];
    CGPoint expected = kind == AWEHomeTopActionKindSearch
        ? CGPointMake(CGRectGetWidth(container.bounds) - 44.0,
                      CGRectGetMidY(container.bounds))
        : CGPointMake(44.0, CGRectGetMidY(container.bounds));
    return isfinite(actual.x) && isfinite(actual.y) &&
           hypot(actual.x - expected.x, actual.y - expected.y) <= 58.0;
}

static void AWEConfigureTopSlot(UIView *container,
                                AWEHomeTopActionKind kind,
                                UIView *owner,
                                UIImageView *source) {
    if (!container) return;
    if (!AWETopGlassEnabled() || !owner) {
        AWEHideTopSlot(container, kind);
        return;
    }
    AWEHomeTopSlotView *slot = AWEEnsureTopSlot(container, kind);
    if (!slot) return;

    const CGFloat diameter = 46.0;
    CGPoint center = kind == AWEHomeTopActionKindSearch
        ? CGPointMake(CGRectGetWidth(container.bounds) - 44.0,
                      CGRectGetMidY(container.bounds))
        : CGPointMake(44.0, CGRectGetMidY(container.bounds));
    if (!isfinite(center.x) || !isfinite(center.y)) return;

    if (!AWETopSourceIsNearExpectedPoint(container, source, kind)) source = nil;

    /*
     Search must receive a real touch sequence.  The private AWEAlphaTapGesture
     recognizer reports a callable target/action, but invoking that action
     programmatically does not enter the search route.  Keep the real search
     owner fully hit-testable, hide only its artwork, and make our visual slot
     ignore touches so UIKit delivers the user's tap to Douyin itself.

     Menu keeps the compatibility proxy because its private recognizer accepts
     the existing forwarding path on the tested builds.
    */
    BOOL directSearchPassthrough = (kind == AWEHomeTopActionKindSearch);
    if (directSearchPassthrough) {
        AWERestoreTopOwnerVisual(slot);
        UIImageView *searchArtwork = source ?: AWEBestTopIconImageView(owner);
        AWEHideTopSourceImage(slot, searchArtwork);
    } else {
        AWEHideTopSourceImage(slot, nil);
        AWEHideTopOwnerVisual(slot, owner, container);
    }

    slot.bounds = CGRectMake(0.0, 0.0, diameter, diameter);
    slot.center = center;
    slot.hidden = NO;
    slot.alpha = 1.0;
    slot.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
    slot.hitButton.frame = slot.bounds;
    slot.systemGlassButton.frame = slot.bounds;

    /* The menu source is now itself a native system-glass UIButton. This keeps
       the source snapshot, press response and source-to-menu morph on one
       UIKit-owned control instead of snapshotting a transparent proxy around
       a separate SwiftUI effect. Search remains a visual-only native button so
       the real Douyin recognizer underneath still receives the touch. */

    NSArray<NSString *> *fallbackNames = kind == AWEHomeTopActionKindSearch
        ? @[@"lasso.badge.sparkles", @"magnifyingglass"]
        : @[@"sidebar.left", @"line.3.horizontal"];
    NSString *symbolKey = AWETopSymbolKey(kind);
    BOOL originalPNG = NO;
    CGFloat iconPointSize = kind == AWEHomeTopActionKindSearch ? 22.5 : 20.0;
    UIImage *image = AWEConfiguredRoleImage(
        symbolKey, fallbackNames, iconPointSize,
        UIImageSymbolWeightMedium, &originalPNG);
    UIColor *foregroundColor = nil;
    if (!originalPNG) {
        AWEConfiguredIconColorMode colorMode = AWEStoredSymbolColorMode(symbolKey);
        if (colorMode != AWEConfiguredIconColorModeAutomatic) {
            /* Fixed/accent/custom always outrank adaptive material colour. */
            foregroundColor = AWEApplyConfiguredIconColorMode(symbolKey, nil);
        } else {
            /* Automatic stays nil. Clear mode samples the pixels beneath this
               exact control; adaptive/tinted mode remains system-owned. */
            foregroundColor = nil;
        }
    }

    if (@available(iOS 26.0, *)) {
        slot.photosGlassHost.hidden = YES;
        UIButton *materialButton = directSearchPassthrough
            ? slot.systemGlassButton
            : slot.hitButton;
        AWEConfigureAdaptiveSystemGlassIconButton(
            materialButton,
            image,
            symbolKey,
            iconPointSize,
            foregroundColor,
            originalPNG,
            AWEHomeTintedGlassEnabled(),
            YES);
        if (directSearchPassthrough) {
            AWEInstallGlassPressFeedback(owner, materialButton);
        }
        slot.systemGlassButton.hidden = !directSearchPassthrough;
    } else {
        slot.hidden = YES;
    }
    if (directSearchPassthrough) {
        /* The whole slot is visual-only; hit testing continues to the real
           AWEHPDiscoverFeedEntranceView underneath. */
        AWEClearTopMenuMorph(slot);
        slot.hitButton.hidden = YES;
        slot.hitButton.userInteractionEnabled = NO;
        slot.userInteractionEnabled = NO;
        AWEInteractionDiagnosticWrite(
            @"TOP_BIND kind=SEARCH mode=direct-passthrough owner=%@ source=%@ slot=%@",
            AWEInteractionObjectSummary(owner),
            AWEInteractionObjectSummary(slot.sourceImageView),
            AWEInteractionObjectSummary(slot));
    } else {
        slot.userInteractionEnabled = owner != nil;
        slot.hitButton.hidden = owner == nil;
        slot.hitButton.userInteractionEnabled = owner != nil;
        if (!slot.hitButton.hidden) {
            if (AWETopMenuMorphEnabled()) {
                AWEInstallTopMenuMorph(slot);
            } else {
                AWEClearTopMenuMorph(slot);
            }
            [slot bringSubviewToFront:slot.hitButton];
        } else {
            AWEClearTopMenuMorph(slot);
        }
    }
    [container bringSubviewToFront:slot];
}


#pragma mark - Home top category visual suppression

static BOOL AWEViewIsInsidePluginTopLiquidGroup(UIView *view) {
    for (UIView *cursor = view; cursor; cursor = cursor.superview) {
        NSString *name = NSStringFromClass(cursor.class).lowercaseString;
        NSString *identifier = cursor.accessibilityIdentifier ?: @"";
        if ([name containsString:@"awetopliquidgroupview"] ||
            [identifier isEqualToString:@"AwemeLiquidBar.TopLiquidCategoryGroup"] ||
            [identifier hasPrefix:@"AwemeLiquidBar.TopCategory."]) {
            return YES;
        }
        if ([name containsString:@"feedtopbarcontainer"]) break;
    }
    return NO;
}

static BOOL AWEIsQuickMenuCategoryTitle(NSString *text) {
    NSString *trimmed = AWETrimQuickMenuText(text);
    return [trimmed isEqualToString:@"直播"] ||
           [trimmed isEqualToString:@"商城"] ||
           [trimmed isEqualToString:@"关注"] ||
           [trimmed isEqualToString:@"推荐"];
}

static BOOL AWEViewIsQuickMenuCategoryTitle(UIView *view) {
    if (AWEViewIsInsidePluginTopLiquidGroup(view)) return NO;
    NSString *title = AWEQuickMenuTitleForView(view);
    if (AWEIsQuickMenuCategoryTitle(title)) return YES;
    if (title.length == 0 || title.length > 12) return NO;
    for (UIView *cursor = view; cursor; cursor = cursor.superview) {
        NSString *name = NSStringFromClass(cursor.class).lowercaseString;
        if ([name containsString:@"toptabitem"] ||
            [name containsString:@"segmentcontrolscroll"] ||
            [name containsString:@"channelitem"] ||
            [name containsString:@"feedtabitem"]) return YES;
        if ([name containsString:@"feedtopbarcontainer"]) break;
    }
    return NO;
}

static void AWERestoreTopCategoryTitleView(UIView *view) {
    if (!view || ![objc_getAssociatedObject(view,
            &kAWETopCategoryHiddenMarkerKey) boolValue]) return;
    NSNumber *opacity = objc_getAssociatedObject(
        view, &kAWETopCategoryOriginalLayerOpacityKey);
    if (opacity) view.layer.opacity = opacity.floatValue;
    objc_setAssociatedObject(view, &kAWETopCategoryHiddenMarkerKey,
                             nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(view, &kAWETopCategoryOriginalLayerOpacityKey,
                             nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void AWEHideTopCategoryTitleView(UIView *view) {
    if (!view || !AWEViewIsQuickMenuCategoryTitle(view)) return;
    if (![objc_getAssociatedObject(view,
            &kAWETopCategoryHiddenMarkerKey) boolValue]) {
        objc_setAssociatedObject(view, &kAWETopCategoryHiddenMarkerKey,
                                 @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(view,
            &kAWETopCategoryOriginalLayerOpacityKey,
            @(view.layer.opacity),
            OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    /* Do not touch hidden or UIView.alpha. The menu router intentionally
       discovers the original title views and their real owners; CALayer
       opacity removes only the pixels while leaving that routing path alive. */
    view.layer.opacity = 0.0f;
}

static void AWERestoreTopCategoryIndicator(UIView *view) {
    if (!view || ![objc_getAssociatedObject(view,
            &kAWETopCategoryIndicatorMarkerKey) boolValue]) return;
    NSNumber *alpha = objc_getAssociatedObject(
        view, &kAWETopCategoryIndicatorOriginalAlphaKey);
    NSNumber *hidden = objc_getAssociatedObject(
        view, &kAWETopCategoryIndicatorOriginalHiddenKey);
    NSNumber *opacity = objc_getAssociatedObject(
        view, &kAWETopCategoryIndicatorOriginalLayerOpacityKey);
    if (alpha) view.alpha = alpha.doubleValue;
    if (hidden) view.hidden = hidden.boolValue;
    if (opacity) view.layer.opacity = opacity.floatValue;
    objc_setAssociatedObject(view, &kAWETopCategoryIndicatorMarkerKey,
                             nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(view,
        &kAWETopCategoryIndicatorOriginalLayerOpacityKey,
        nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void AWEHideTopCategoryIndicator(UIView *view) {
    if (!view || [view isKindOfClass:UILabel.class] ||
        [view isKindOfClass:AWEHomeTopSlotView.class]) return;
    if (![objc_getAssociatedObject(view,
            &kAWETopCategoryIndicatorMarkerKey) boolValue]) {
        objc_setAssociatedObject(view, &kAWETopCategoryIndicatorMarkerKey,
                                 @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(view,
            &kAWETopCategoryIndicatorOriginalAlphaKey, @(view.alpha),
            OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(view,
            &kAWETopCategoryIndicatorOriginalHiddenKey, @(view.hidden),
            OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(view,
            &kAWETopCategoryIndicatorOriginalLayerOpacityKey,
            @(view.layer.opacity), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    view.alpha = 0.0;
    view.layer.opacity = 0.0f;
}

static void AWEMarkTopCategorySuppressionCacheDirty(UIView *container) {
    if (!container) return;
    objc_setAssociatedObject(container, &kAWETopCategorySuppressionCacheDirtyKey,
                             @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static BOOL AWEApplyCachedTopCategorySuppressionIfValid(UIView *container) {
    if (!container) return NO;
    if ([objc_getAssociatedObject(container,
            &kAWETopCategorySuppressionCacheDirtyKey) boolValue]) return NO;
    NSNumber *storedCount = objc_getAssociatedObject(
        container, &kAWETopCategorySuppressionCacheSubviewCountKey);
    if (!storedCount || storedCount.unsignedIntegerValue != container.subviews.count) return NO;
    NSArray<UIView *> *cached = objc_getAssociatedObject(
        container, &kAWETopCategorySuppressionCacheKey);
    if (!cached) return NO;
    for (UIView *view in cached) {
        if (!view || ![view isDescendantOfView:container]) return NO;
        if ([objc_getAssociatedObject(view, &kAWETopCategoryHiddenMarkerKey) boolValue]) {
            AWEHideTopCategoryTitleView(view);
        }
        if ([objc_getAssociatedObject(view, &kAWETopCategoryIndicatorMarkerKey) boolValue]) {
            AWEHideTopCategoryIndicator(view);
        }
    }
    return YES;
}

static void AWEApplyTopCategoryVisualSuppression(UIView *container,
                                                  BOOL suppress) {
    if (!container) return;
    if (suppress && AWEApplyCachedTopCategorySuppressionIfValid(container)) return;

    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:container];
    NSMutableArray<NSValue *> *matchedFrames = [NSMutableArray array];
    NSMutableArray<UIView *> *allViews = [NSMutableArray array];
    NSMutableArray<UIView *> *cachedTargets = [NSMutableArray array];
    NSUInteger visited = 0;
    while (queue.count > 0 && visited < 500) {
        UIView *view = queue.firstObject;
        [queue removeObjectAtIndex:0];
        if (!view || [view isKindOfClass:AWEHomeTopSlotView.class] ||
            AWEViewIsInsidePluginTopLiquidGroup(view)) continue;
        visited++;
        [allViews addObject:view];

        BOOL isTitle = AWEViewIsQuickMenuCategoryTitle(view);
        if ([objc_getAssociatedObject(view,
                &kAWETopCategoryHiddenMarkerKey) boolValue] &&
            (!suppress || !isTitle)) {
            AWERestoreTopCategoryTitleView(view);
        }
        if (isTitle) {
            CGRect frame = [view convertRect:view.bounds toView:container];
            [matchedFrames addObject:[NSValue valueWithCGRect:frame]];
            if (suppress) {
                AWEHideTopCategoryTitleView(view);
                [cachedTargets addObject:view];
            }
        }
        for (UIView *child in view.subviews) [queue addObject:child];
    }

    for (UIView *view in allViews) AWERestoreTopCategoryIndicator(view);
    if (!suppress) {
        objc_setAssociatedObject(container, &kAWETopCategorySuppressionCacheKey,
                                 nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(container, &kAWETopCategorySuppressionCacheDirtyKey,
                                 nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(container, &kAWETopCategorySuppressionCacheSubviewCountKey,
                                 nil, OBJC_ASSOCIATION_ASSIGN);
        return;
    }

    CGRect unionFrame = CGRectNull;
    for (NSValue *value in matchedFrames) {
        CGRect frame = value.CGRectValue;
        unionFrame = CGRectIsNull(unionFrame) ? frame
                                              : CGRectUnion(unionFrame, frame);
    }
    BOOL hasTitleGeometry = !CGRectIsNull(unionFrame);
    CGFloat minX = hasTitleGeometry ? CGRectGetMinX(unionFrame) - 18.0 : 0.0;
    CGFloat maxX = hasTitleGeometry ? CGRectGetMaxX(unionFrame) + 18.0
                                    : CGRectGetWidth(container.bounds);
    CGFloat minY = hasTitleGeometry ? CGRectGetMaxY(unionFrame) - 2.0 : 20.0;
    CGFloat maxY = hasTitleGeometry ? CGRectGetMaxY(unionFrame) + 20.0 : 100.0;
    for (UIView *view in allViews) {
        if (view == container || [view isKindOfClass:UILabel.class] ||
            [view isKindOfClass:UIButton.class] ||
            [view isKindOfClass:AWEHomeTopSlotView.class]) continue;
        CGRect frame = [view convertRect:view.bounds toView:container];
        NSString *className = NSStringFromClass(view.class).lowercaseString;
        BOOL exactIndicator =
            [className containsString:@"multitabselectedcontainer"] ||
            [className containsString:@"segmentselectedcontainer"] ||
            ([className containsString:@"selectedcontainer"] &&
             CGRectGetMidY(frame) <= 100.0);
        BOOL thin = CGRectGetHeight(frame) > 0.0 &&
                    CGRectGetHeight(frame) <= 12.0 &&
                    CGRectGetWidth(frame) >= 8.0 &&
                    CGRectGetWidth(frame) <= 110.0;
        BOOL underTitles = CGRectGetMidX(frame) >= minX &&
                           CGRectGetMidX(frame) <= maxX &&
                           CGRectGetMidY(frame) >= minY - 4.0 &&
                           CGRectGetMidY(frame) <= maxY + 6.0;
        if (exactIndicator || (thin && underTitles)) {
            AWEHideTopCategoryIndicator(view);
            [cachedTargets addObject:view];
            for (UIView *child in view.subviews) {
                AWEHideTopCategoryIndicator(child);
                [cachedTargets addObject:child];
            }
        }
    }
    objc_setAssociatedObject(container, &kAWETopCategorySuppressionCacheKey,
                             [cachedTargets copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(container, &kAWETopCategorySuppressionCacheDirtyKey,
                             @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(container, &kAWETopCategorySuppressionCacheSubviewCountKey,
                             @(container.subviews.count), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static BOOL AWEViewIsInsideActiveSuppressedTopBar(UIView *view) {
    if (!view || !AWETopGlassEnabled() || !AWEPluginFeaturesEnabled()) return NO;
    for (UIView *cursor = view; cursor; cursor = cursor.superview) {
        NSString *name = NSStringFromClass(cursor.class).lowercaseString;
        if ([name containsString:@"feedtopbarcontainer"]) {
            AWEHomeTopSlotView *slot = objc_getAssociatedObject(
                cursor, &kAWETopMenuSlotKey);
            UIView *group = objc_getAssociatedObject(
                cursor, &kAWETopLiquidGroupViewKey);
            BOOL menuActive = AWETopMenuMorphEnabled();
            BOOL groupActive = group && !group.hidden &&
                group.alpha > 0.01;
            return menuActive || groupActive;
        }
    }
    return NO;
}

static void AWEForceExactTopIndicatorSuppression(UIView *indicator) {
    if (!indicator) return;
    if (AWEViewIsInsideActiveSuppressedTopBar(indicator)) {
        AWEHideTopCategoryIndicator(indicator);
        for (UIView *child in indicator.subviews) {
            AWEHideTopCategoryIndicator(child);
        }
    } else {
        AWERestoreTopCategoryIndicator(indicator);
    }
}


#pragma mark - Telegram-style top liquid category group

/*
 One resident system-glass platter, one selected tint pill and at most four
 title buttons. This follows the proven XHSLiquidBar Telegram switcher pattern
 instead of embedding UISegmentedControl (whose own background created the
 two-overlapping-glass result). Accounts with more than four channels shift a
 one-item window with horizontal swipes; tapping an edge item also advances the
 window so the next hidden channel becomes available.
*/
@class AWETopLiquidGroupView;
static void AWELayoutTopLiquidGroup(AWETopLiquidGroupView *group,
                                    BOOL animated);

@interface AWETopLiquidGroupView : UIView
@property(nonatomic, strong) UIButton *backgroundGlass;
@property(nonatomic, strong) UIView *selectionGlass;
@property(nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *definitions;
@property(nonatomic, strong) NSArray<UIButton *> *buttons;
@property(nonatomic, assign) NSInteger selectedIndex;
@property(nonatomic, assign) NSInteger windowStart;
@property(nonatomic, assign) CFTimeInterval selectionAnimationDeadline;
@property(nonatomic, assign) BOOL windowAnimationInFlight;
@property(nonatomic, weak) UIView *nativeIndicator;
@property(nonatomic, strong) CADisplayLink *indicatorDisplayLink;
@property(nonatomic, assign) CFTimeInterval indicatorDisplayLinkDeadline;
@property(nonatomic, assign) CGRect lastSelectionPresentationFrame;
- (NSInteger)alb_visibleCount;
- (void)alb_categoryTapped:(UIButton *)sender;
- (void)alb_swipedLeft:(UISwipeGestureRecognizer *)recognizer;
- (void)alb_swipedRight:(UISwipeGestureRecognizer *)recognizer;
- (void)alb_indicatorTick:(CADisplayLink *)displayLink;
@end

static void AWESyncTopSelectionPillToNativeIndicator(UIView *indicator);

static BOOL AWEActivateTopLiquidDefinition(NSDictionary<NSString *, id> *definition) {
    if (![definition isKindOfClass:NSDictionary.class]) return NO;
    UIView *target = [definition[@"target"] isKindOfClass:UIView.class]
        ? definition[@"target"] : nil;
    if (target && target.window && AWETriggerQuickMenuDestinationView(target)) {
        return YES;
    }
    NSString *route = definition[@"route"] ?: definition[@"title"];
    return route.length ? AWEActivateQuickMenuDestination(route) : NO;
}

static void AWEAnimateTopLiquidWindowShift(AWETopLiquidGroupView *group,
                                           NSInteger newStart,
                                           NSInteger direction) {
    if (!group || group.windowAnimationInFlight) return;
    NSInteger visibleCount=[group alb_visibleCount];
    NSInteger maximumStart=MAX(0,(NSInteger)group.definitions.count-visibleCount);
    newStart=MIN(MAX(0,newStart),maximumStart);
    if (newStart==group.windowStart || direction==0) { group.windowStart=newStart; AWELayoutTopLiquidGroup(group,YES); return; }
    group.windowAnimationInFlight=YES;
    CGFloat distance=CGRectGetWidth(group.bounds)/MAX(1,visibleCount);
    CGFloat dx=direction>0 ? -distance : distance;
    [UIView animateWithDuration:0.24 delay:0 options:UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionCurveEaseInOut animations:^{
        for (UIButton *b in group.buttons) if(!b.hidden) b.transform=CGAffineTransformMakeTranslation(dx,0);
    } completion:^(__unused BOOL finished){
        group.windowStart=newStart;
        [UIView performWithoutAnimation:^{
            for (UIButton *b in group.buttons) b.transform=CGAffineTransformIdentity;
            AWELayoutTopLiquidGroup(group,NO);
        }];
        group.windowAnimationInFlight=NO;
    }];
}

@implementation AWETopLiquidGroupView

- (NSInteger)alb_visibleCount {
    return MIN(AWETopTelegramVisibleCount(),
               (NSInteger)self.definitions.count);
}

- (void)alb_categoryTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < 0 || index >= (NSInteger)self.definitions.count) return;

    self.selectedIndex = index;
    NSInteger visibleCount = [self alb_visibleCount];
    NSInteger maximumStart = MAX(0, (NSInteger)self.definitions.count - visibleCount);
    NSInteger newStart = self.windowStart;
    if (visibleCount > 1 && index == self.windowStart + visibleCount - 1 &&
        self.windowStart < maximumStart) {
        newStart = self.windowStart + 1;
    } else if (index == self.windowStart && self.windowStart > 0) {
        newStart = self.windowStart - 1;
    }
    NSInteger direction = newStart > self.windowStart ? 1 :
                          (newStart < self.windowStart ? -1 : 0);
    if (direction != 0) {
        AWEAnimateTopLiquidWindowShift(self, newStart, direction);
    } else {
        AWELayoutTopLiquidGroup(self, YES);
    }

    AWEActivateTopLiquidDefinition(self.definitions[(NSUInteger)index]);
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)alb_swipedLeft:(UISwipeGestureRecognizer *)recognizer {
    (void)recognizer;
    NSInteger visibleCount = [self alb_visibleCount];
    NSInteger maximumStart = MAX(0, (NSInteger)self.definitions.count - visibleCount);
    if (self.windowStart >= maximumStart) return;
    NSInteger newStart = self.windowStart + 1;
    if (visibleCount == 1) self.selectedIndex = newStart;
    AWEAnimateTopLiquidWindowShift(self, newStart, 1);
    if (visibleCount == 1 && self.selectedIndex < (NSInteger)self.definitions.count) {
        AWEActivateTopLiquidDefinition(self.definitions[(NSUInteger)self.selectedIndex]);
    }
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)alb_swipedRight:(UISwipeGestureRecognizer *)recognizer {
    (void)recognizer;
    NSInteger visibleCount = [self alb_visibleCount];
    if (self.windowStart <= 0) return;
    NSInteger newStart = self.windowStart - 1;
    if (visibleCount == 1) self.selectedIndex = newStart;
    AWEAnimateTopLiquidWindowShift(self, newStart, -1);
    if (visibleCount == 1 && self.selectedIndex < (NSInteger)self.definitions.count) {
        AWEActivateTopLiquidDefinition(self.definitions[(NSUInteger)self.selectedIndex]);
    }
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)alb_indicatorTick:(CADisplayLink *)displayLink {
    UIView *indicator = self.nativeIndicator;
    if (!indicator || !indicator.window || self.hidden ||
        CACurrentMediaTime() > self.indicatorDisplayLinkDeadline) {
        [displayLink invalidate];
        self.indicatorDisplayLink = nil;
        self.nativeIndicator = nil;
        self.lastSelectionPresentationFrame = CGRectZero;
        return;
    }
    AWESyncTopSelectionPillToNativeIndicator(indicator);
    if (indicator.layer.animationKeys.count == 0 &&
        CACurrentMediaTime() + 0.05 < self.indicatorDisplayLinkDeadline) {
        self.indicatorDisplayLinkDeadline = CACurrentMediaTime() + 0.05;
    }
}

@end

static AWETopLiquidGroupView *AWEFindTopLiquidGroupFromView(UIView *view) {
    UIView *cursor = view;
    for (NSInteger depth = 0; cursor && depth < 12; depth++, cursor = cursor.superview) {
        AWETopLiquidGroupView *group = objc_getAssociatedObject(cursor, &kAWETopLiquidGroupViewKey);
        if (group) return group;
    }
    return nil;
}

static void AWESyncTopSelectionPillToNativeIndicator(UIView *indicator) {
    AWETopLiquidGroupView *group = AWEFindTopLiquidGroupFromView(indicator);
    if (!group || group.hidden || group.definitions.count < 2 || group.windowAnimationInFlight) return;
    NSInteger visibleCount = [group alb_visibleCount];
    if (visibleCount < 2) return;
    UIView *container = group.superview;
    if (!container) return;
    CGRect indicatorFrame = CGRectZero;
    CALayer *presentation = indicator.layer.presentationLayer;
    if (presentation && indicator.superview) {
        indicatorFrame = [indicator.superview convertRect:presentation.frame
                                                   toView:container];
    } else {
        indicatorFrame = [indicator convertRect:indicator.bounds toView:container];
    }
    CGFloat x = CGRectGetMidX(indicatorFrame);
    NSInteger left = NSNotFound, right = NSNotFound;
    CGFloat leftX = -CGFLOAT_MAX, rightX = CGFLOAT_MAX;
    for (NSInteger i = 0; i < (NSInteger)group.definitions.count; i++) {
        CGFloat px = [group.definitions[(NSUInteger)i][@"x"] doubleValue];
        if (px <= x && px > leftX) { leftX = px; left = i; }
        if (px >= x && px < rightX) { rightX = px; right = i; }
    }
    if (left == NSNotFound) left = 0;
    if (right == NSNotFound) right = (NSInteger)group.definitions.count - 1;
    CGFloat progress = (right == left || fabs(rightX - leftX) < 0.5) ? 0.0 : MIN(1.0, MAX(0.0, (x - leftX) / (rightX - leftX)));
    CGFloat inset = 4.0;
    CGRect cb = CGRectInset(group.bounds, inset, inset);
    CGFloat iw = CGRectGetWidth(cb) / MAX(1, visibleCount);
    CGFloat slot = ((CGFloat)(left - group.windowStart)) + progress * ((CGFloat)(right - left));
    slot = MIN((CGFloat)visibleCount - 1.0, MAX(0.0, slot));
    CGRect target = CGRectInset(CGRectMake(CGRectGetMinX(cb) + slot * iw, CGRectGetMinY(cb), iw, CGRectGetHeight(cb)), 1.5, 0.5);
    CGRect previous = group.lastSelectionPresentationFrame;
    if (!CGRectIsEmpty(previous) &&
        fabs(CGRectGetMinX(previous) - CGRectGetMinX(target)) < 0.18 &&
        fabs(CGRectGetWidth(previous) - CGRectGetWidth(target)) < 0.18) return;
    group.lastSelectionPresentationFrame = target;
    [group.selectionGlass.layer removeAllAnimations];
    [UIView performWithoutAnimation:^{
        group.selectionGlass.frame = target;
        group.selectionGlass.layer.cornerRadius = CGRectGetHeight(target) * 0.5;
        group.selectionGlass.alpha = 1.0;
    }];
}

static void AWETrackTopSelectionPresentationIfNeeded(UIView *indicator) {
    AWETopLiquidGroupView *group = AWEFindTopLiquidGroupFromView(indicator);
    if (!group || group.hidden || indicator.layer.animationKeys.count == 0) return;
    group.nativeIndicator = indicator;
    group.indicatorDisplayLinkDeadline = CACurrentMediaTime() + 0.34;
    if (group.indicatorDisplayLink) return;
    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:group
        selector:@selector(alb_indicatorTick:)];
    if (@available(iOS 15.0, *)) {
        link.preferredFrameRateRange = CAFrameRateRangeMake(20.0, 30.0, 30.0);
    } else {
        link.preferredFramesPerSecond = 30;
    }
    [link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    group.indicatorDisplayLink = link;
}

static NSInteger AWESelectedTopCategoryIndex(
    UIView *container,
    NSArray<NSDictionary<NSString *, id> *> *definitions) {
    if (!container || definitions.count == 0) return NSNotFound;
    UIView *indicator = AWEFindViewByExactRuntimeClass(
        container, @"AWEFeedMultiTabSelectedContainerView", 0);
    if (!indicator) {
        indicator = AWEFindViewByExactRuntimeClass(
            container, @"AWEHPMultiTabSelectedContainerView", 0);
    }
    if (!indicator) return NSNotFound;
    CGRect frame = [indicator convertRect:indicator.bounds toView:container];
    CGFloat x = CGRectGetMidX(frame);
    NSInteger best = NSNotFound;
    CGFloat bestDistance = CGFLOAT_MAX;
    for (NSUInteger index = 0; index < definitions.count; index++) {
        CGFloat candidateX = [definitions[index][@"x"] doubleValue];
        CGFloat distance = fabs(candidateX - x);
        if (distance < bestDistance) {
            bestDistance = distance;
            best = (NSInteger)index;
        }
    }
    return best;
}

static void AWEConfigureTopSelectionPill(UIView *pill) {
    if (!pill) return;
    UIColor *accent = AWEStoredAccentColor();
    pill.backgroundColor = [accent colorWithAlphaComponent:
        AWEHomeTintedGlassEnabled() ? 0.16 : 0.11];
    pill.layer.borderWidth = 0.5;
    pill.layer.borderColor = [accent colorWithAlphaComponent:0.20].CGColor;
    pill.layer.cornerCurve = kCACornerCurveContinuous;
    pill.userInteractionEnabled = NO;
    pill.accessibilityElementsHidden = YES;
}

static AWETopLiquidGroupView *AWEEnsureTopLiquidGroup(UIView *container) {
    if (!container) return nil;
    AWETopLiquidGroupView *group = objc_getAssociatedObject(
        container, &kAWETopLiquidGroupViewKey);
    if (AWETopMenuMorphEnabled()) {
        if (group) {
            group.hidden = YES;
            group.alpha = 0.0;
            group.userInteractionEnabled = NO;
        }
        return nil;
    }
    if (!group) {
        group = [[AWETopLiquidGroupView alloc] initWithFrame:CGRectZero];
        group.backgroundColor = UIColor.clearColor;
        group.opaque = NO;
        group.clipsToBounds = YES;
        group.layer.cornerCurve = kCACornerCurveContinuous;
        group.accessibilityIdentifier = @"AwemeLiquidBar.TopLiquidCategoryGroup";
        group.layer.zPosition = 1400.0;
        group.selectedIndex = NSNotFound;
        group.windowStart = 0;

        UIButton *background = [UIButton buttonWithType:UIButtonTypeCustom];
        background.userInteractionEnabled = NO;
        background.backgroundColor = UIColor.clearColor;
        background.opaque = NO;
        background.clipsToBounds = NO;
        [group addSubview:background];
        group.backgroundGlass = background;

        UIView *selection = [UIView new];
        selection.userInteractionEnabled = NO;
        selection.backgroundColor = UIColor.clearColor;
        selection.opaque = NO;
        selection.clipsToBounds = YES;
        selection.alpha = 0.0;
        [group addSubview:selection];
        group.selectionGlass = selection;

        NSMutableArray<UIButton *> *buttons = [NSMutableArray arrayWithCapacity:4];
        for (NSInteger index = 0; index < 4; index++) {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.backgroundColor = UIColor.clearColor;
            button.contentHorizontalAlignment =
                UIControlContentHorizontalAlignmentCenter;
            button.titleLabel.font = [UIFont systemFontOfSize:14.5
                                                       weight:UIFontWeightSemibold];
            button.titleLabel.adjustsFontSizeToFitWidth = YES;
            button.titleLabel.minimumScaleFactor = 0.84;
            button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
            button.titleLabel.numberOfLines = 1;
            button.contentEdgeInsets = UIEdgeInsetsMake(0.0, 7.0, 0.0, 7.0);
            button.accessibilityIdentifier = [NSString stringWithFormat:
                @"AwemeLiquidBar.TopCategory.%ld", (long)index];
            button.layer.zPosition = 1402.0;
            [button addTarget:group action:@selector(alb_categoryTapped:)
              forControlEvents:UIControlEventTouchUpInside];
            [group addSubview:button];
            [buttons addObject:button];
        }
        group.buttons = buttons;

        UISwipeGestureRecognizer *left = [[UISwipeGestureRecognizer alloc]
            initWithTarget:group action:@selector(alb_swipedLeft:)];
        left.direction = UISwipeGestureRecognizerDirectionLeft;
        [group addGestureRecognizer:left];
        UISwipeGestureRecognizer *right = [[UISwipeGestureRecognizer alloc]
            initWithTarget:group action:@selector(alb_swipedRight:)];
        right.direction = UISwipeGestureRecognizerDirectionRight;
        [group addGestureRecognizer:right];

        objc_setAssociatedObject(container, &kAWETopLiquidGroupViewKey,
                                 group, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [container addSubview:group];
    } else if (group.superview != container) {
        [group removeFromSuperview];
        [container addSubview:group];
    }
    return group;
}

static void AWEHideTopLiquidGroup(UIView *container) {
    AWETopLiquidGroupView *group = container ? objc_getAssociatedObject(
        container, &kAWETopLiquidGroupViewKey) : nil;
    if (group) {
        group.hidden = YES;
        group.userInteractionEnabled = NO;
    }
}

static CGRect AWEFrameForTopLiquidGroup(UIView *container,
                                           AWETopLiquidGroupView *group,
                                           NSInteger visibleCount) {
    if (!container || !group || visibleCount < 1) return CGRectZero;

    AWEHomeTopSlotView *menuSlot = objc_getAssociatedObject(
        container, &kAWETopMenuSlotKey);
    AWEHomeTopSlotView *searchSlot = objc_getAssociatedObject(
        container, &kAWETopSearchSlotKey);
    BOOL menuVisible = menuSlot && !menuSlot.hidden &&
        menuSlot.alpha > 0.01 && menuSlot.layer.opacity > 0.01f;
    BOOL searchVisible = searchSlot && !searchSlot.hidden &&
        searchSlot.alpha > 0.01 && searchSlot.layer.opacity > 0.01f;

    /* Keep the category group geometrically centered on the screen.
       If only one side action exists, reserve the same clearance on the
       opposite side instead of centering inside an asymmetric free region.
       This also fixes the no-left/no-right case introduced by the old
       hard-coded leftBoundary=82 / rightBoundary=14 calculation. */
    CGFloat sideReserve = (menuVisible || searchVisible) ? 82.0 : 14.0;
    CGFloat availableWidth = MAX(120.0,
        CGRectGetWidth(container.bounds) - sideReserve * 2.0);
    CGFloat perItemWidth = visibleCount == 1 ? 96.0 : 74.0;
    CGFloat desiredWidth = MIN(availableWidth,
        MAX(visibleCount == 1 ? 92.0 : 148.0,
            visibleCount * perItemWidth));
    CGFloat height = 44.0;
    CGFloat centerX = CGRectGetMidX(container.bounds);
    return CGRectMake(centerX - desiredWidth * 0.5,
                      CGRectGetMidY(container.bounds) - height * 0.5,
                      desiredWidth, height);
}

static void AWELayoutTopLiquidGroup(AWETopLiquidGroupView *group,
                                    BOOL animated) {
    if (!group || group.definitions.count < 1 || CGRectIsEmpty(group.bounds)) return;
    if (!animated && group.windowAnimationInFlight) return;
    NSInteger total = (NSInteger)group.definitions.count;
    NSInteger visibleCount = MIN(AWETopTelegramVisibleCount(), total);
    NSInteger maximumStart = MAX(0, total - visibleCount);
    group.windowStart = MIN(MAX(0, group.windowStart), maximumStart);

    if (visibleCount == 1 && group.selectedIndex != NSNotFound) {
        group.windowStart = MIN(MAX(0, group.selectedIndex), maximumStart);
    } else if (visibleCount > 1 && group.selectedIndex != NSNotFound) {
        if (group.selectedIndex < group.windowStart) {
            group.windowStart = group.selectedIndex;
        } else if (group.selectedIndex >= group.windowStart + visibleCount) {
            group.windowStart = group.selectedIndex - visibleCount + 1;
        }
        group.windowStart = MIN(MAX(0, group.windowStart), maximumStart);
    }

    if (!animated && CACurrentMediaTime() < group.selectionAnimationDeadline) {
        return;
    }
    if (animated) {
        group.selectionAnimationDeadline = CACurrentMediaTime() + 0.48;
    }

    CGFloat inset = 4.0;
    CGRect contentBounds = CGRectInset(group.bounds, inset, inset);
    CGFloat itemWidth = CGRectGetWidth(contentBounds) / MAX(1, visibleCount);
    UIUserInterfaceStyle style = gAWEHomeChromeLastStableStyle;
    if (style != UIUserInterfaceStyleLight &&
        style != UIUserInterfaceStyleDark) {
        style = gAWEAlbumMorphLastAppliedStyle;
    }
    if (style != UIUserInterfaceStyleLight &&
        style != UIUserInterfaceStyleDark) {
        style = group.traitCollection.userInterfaceStyle;
    }
    if (style != UIUserInterfaceStyleLight &&
        style != UIUserInterfaceStyleDark) {
        style = UIUserInterfaceStyleDark;
    }
    (void)style;
    UIColor *normalColor = [UIColor.whiteColor colorWithAlphaComponent:0.86];
    UIColor *selectedColor = UIColor.whiteColor;

    CGRect oldSelectionFrame = group.selectionGlass.frame;
    BOOL hadVisibleSelection = group.selectionGlass.alpha > 0.01;
    __block CGRect targetSelectionFrame = CGRectZero;
    __block BOOL hasTargetSelection = NO;

    [UIView performWithoutAnimation:^{
        group.backgroundGlass.frame = group.bounds;
        NSInteger visibleSelectionSlot = NSNotFound;
        for (NSInteger slot = 0; slot < 4; slot++) {
            UIButton *button = group.buttons[(NSUInteger)slot];
            if (slot >= visibleCount) {
                button.hidden = YES;
                continue;
            }
            NSInteger definitionIndex = group.windowStart + slot;
            NSDictionary *definition = group.definitions[(NSUInteger)definitionIndex];
            NSString *title = definition[@"title"] ?: @"";
            button.hidden = NO;
            button.alpha = 1.0;
            button.layer.opacity = 1.0f;
            objc_setAssociatedObject(button, &kAWETopCategoryHiddenMarkerKey,
                                     nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(button, &kAWETopCategoryOriginalLayerOpacityKey,
                                     nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            button.userInteractionEnabled = YES;
            button.tag = definitionIndex;
            button.frame = CGRectMake(
                CGRectGetMinX(contentBounds) + slot * itemWidth,
                CGRectGetMinY(contentBounds), itemWidth,
                CGRectGetHeight(contentBounds));
            [button setTitle:title forState:UIControlStateNormal];
            BOOL selected = definitionIndex == group.selectedIndex;
            UIColor *titleColor = selected ? selectedColor : normalColor;
            if (visibleCount == 1 && selected) {
                titleColor = UIColor.whiteColor;
            }
            [button setTitleColor:titleColor forState:UIControlStateNormal];
            [button setTitleColor:titleColor forState:UIControlStateHighlighted];
            [button setTitleColor:titleColor forState:UIControlStateSelected];
            button.tintColor = titleColor;
            button.titleLabel.hidden = NO;
            button.titleLabel.alpha = 1.0;
            button.titleLabel.layer.opacity = 1.0f;
            if (selected) visibleSelectionSlot = slot;
        }

        if (visibleCount > 1 && visibleSelectionSlot != NSNotFound) {
            targetSelectionFrame = CGRectInset(CGRectMake(
                CGRectGetMinX(contentBounds) + visibleSelectionSlot * itemWidth,
                CGRectGetMinY(contentBounds), itemWidth,
                CGRectGetHeight(contentBounds)), 1.5, 0.5);
            hasTargetSelection = YES;
        }
    }];

    if (!hasTargetSelection) {
        [UIView performWithoutAnimation:^{
            group.selectionGlass.alpha = 0.0;
        }];
    } else if (animated && hadVisibleSelection &&
               !CGRectEqualToRect(oldSelectionFrame, targetSelectionFrame)) {
        group.selectionGlass.frame = oldSelectionFrame;
        group.selectionGlass.alpha = 1.0;
        group.selectionGlass.layer.cornerRadius =
            CGRectGetHeight(oldSelectionFrame) * 0.5;
        [UIView animateWithDuration:0.22
                              delay:0.0
                            options:UIViewAnimationOptionAllowUserInteraction |
                                    UIViewAnimationOptionBeginFromCurrentState |
                                    UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            group.selectionGlass.frame = targetSelectionFrame;
            group.selectionGlass.layer.cornerRadius =
                CGRectGetHeight(targetSelectionFrame) * 0.5;
        } completion:nil];
    } else {
        [UIView performWithoutAnimation:^{
            group.selectionGlass.frame = targetSelectionFrame;
            group.selectionGlass.layer.cornerRadius =
                CGRectGetHeight(targetSelectionFrame) * 0.5;
            group.selectionGlass.alpha = 1.0;
        }];
    }

    [group bringSubviewToFront:group.selectionGlass];
    for (UIButton *button in group.buttons) [group bringSubviewToFront:button];
}

static void AWELayoutExistingTopChrome(UIView *container) {
    if (!container || CGRectIsEmpty(container.bounds)) return;
    AWEHomeTopSlotView *menuSlot = objc_getAssociatedObject(
        container, &kAWETopMenuSlotKey);
    AWEHomeTopSlotView *searchSlot = objc_getAssociatedObject(
        container, &kAWETopSearchSlotKey);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (menuSlot && !menuSlot.hidden) {
        menuSlot.bounds = CGRectMake(0.0, 0.0, 46.0, 46.0);
        menuSlot.center = CGPointMake(44.0, CGRectGetMidY(container.bounds));
        menuSlot.hitButton.frame = menuSlot.bounds;
        menuSlot.systemGlassButton.frame = menuSlot.bounds;
    }
    if (searchSlot && !searchSlot.hidden) {
        searchSlot.bounds = CGRectMake(0.0, 0.0, 46.0, 46.0);
        searchSlot.center = CGPointMake(CGRectGetWidth(container.bounds) - 44.0,
                                        CGRectGetMidY(container.bounds));
        searchSlot.hitButton.frame = searchSlot.bounds;
        searchSlot.systemGlassButton.frame = searchSlot.bounds;
    }
    AWETopLiquidGroupView *group = objc_getAssociatedObject(
        container, &kAWETopLiquidGroupViewKey);
    if (group && !group.hidden && group.definitions.count > 0) {
        NSInteger visibleCount = MIN([group alb_visibleCount],
                                     (NSInteger)group.definitions.count);
        group.frame = AWEFrameForTopLiquidGroup(
            container, group, visibleCount);
        group.layer.cornerRadius = CGRectGetHeight(group.bounds) * 0.5;
        group.backgroundGlass.frame = group.bounds;
        AWELayoutTopLiquidGroup(group, NO);
    }
    [CATransaction commit];
    if (group && !group.hidden) [container bringSubviewToFront:group];
    if (menuSlot && !menuSlot.hidden) [container bringSubviewToFront:menuSlot];
    if (searchSlot && !searchSlot.hidden) [container bringSubviewToFront:searchSlot];
}

static void AWEUpdateTopLiquidGroup(UIView *container,
                                    BOOL bottomSearchVisible) {
    (void)bottomSearchVisible;
    if (!container || !AWETopGlassEnabled()) {
        AWEHideTopLiquidGroup(container);
        return;
    }

    /* The menu-morph setting means this slot belongs to the left menu from
       the first frame.  Do not wait for UIMenu children to populate, otherwise
       a cold launch briefly creates the category group and hides it later. */
    if (AWETopMenuMorphEnabled()) {
        AWEHideTopLiquidGroup(container);
        return;
    }

    AWEHomeTopSlotView *menuSlot = objc_getAssociatedObject(
        container, &kAWETopMenuSlotKey);

    NSArray<NSDictionary<NSString *, id> *> *definitions = menuSlot
        ? AWEDynamicTopQuickMenuDefinitions(menuSlot)
        : @[
            @{@"title": @"直播", @"route": @"直播", @"symbol": @"play.rectangle", @"x": @0},
            @{@"title": @"商城", @"route": @"商城", @"symbol": @"storefront", @"x": @1},
            @{@"title": @"关注", @"route": @"关注", @"symbol": @"person.2", @"x": @2},
            @{@"title": @"推荐", @"route": @"推荐", @"symbol": @"sparkles", @"x": @3}
        ];
    if (definitions.count < 1 || !AWETopTelegramSwitcherEnabled()) {
        AWEHideTopLiquidGroup(container);
        return;
    }

    AWETopLiquidGroupView *group = AWEEnsureTopLiquidGroup(container);
    if (!group) return;
    NSInteger visibleCount = MIN(AWETopTelegramVisibleCount(),
                                 (NSInteger)definitions.count);
    group.frame = AWEFrameForTopLiquidGroup(
        container, group, visibleCount);
    group.layer.cornerRadius = CGRectGetHeight(group.bounds) * 0.5;
    group.hidden = NO;
    group.userInteractionEnabled = YES;
    group.alpha = 1.0;
    UIUserInterfaceStyle groupStyle = gAWEHomeChromeLastStableStyle;
    if (groupStyle != UIUserInterfaceStyleLight &&
        groupStyle != UIUserInterfaceStyleDark) {
        groupStyle = gAWEAlbumMorphLastAppliedStyle;
    }
    if (groupStyle != UIUserInterfaceStyleLight &&
        groupStyle != UIUserInterfaceStyleDark) {
        groupStyle = UIUserInterfaceStyleUnspecified;
    }
    group.overrideUserInterfaceStyle = groupStyle;

    NSString *signature = [[definitions valueForKey:@"route"]
        componentsJoinedByString:@"|"];
    NSString *previous = objc_getAssociatedObject(
        group, &kAWETopTelegramTitlesSignatureKey);
    BOOL changed = ![previous isEqualToString:signature];
    group.definitions = definitions;
    if (changed) {
        group.windowStart = 0;
        objc_setAssociatedObject(group, &kAWETopTelegramTitlesSignatureKey,
                                 signature, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }

    NSInteger selected = AWESelectedTopCategoryIndex(container, definitions);
    BOOL selectionLocked = CACurrentMediaTime() < group.selectionAnimationDeadline ||
                           group.windowAnimationInFlight;
    if (selectionLocked && group.selectedIndex != NSNotFound) {
        selected = group.selectedIndex;
    } else if (selected == NSNotFound) {
        selected = group.selectedIndex;
    }
    if (selected == NSNotFound || selected >= (NSInteger)definitions.count) {
        selected = MAX(0, (NSInteger)definitions.count - 1);
    }
    group.selectedIndex = selected;

    AWEConfigureAdaptiveSystemGlassPlateButton(
        group.backgroundGlass, @"top.category.group.background",
        AWEHomeTintedGlassEnabled());
    AWEConfigureTopSelectionPill(group.selectionGlass);
    AWELayoutTopLiquidGroup(group, NO);
    [container bringSubviewToFront:group];
}

#pragma mark - Top action refresh

static void AWEParkTopSlot(UIView *container, AWEHomeTopActionKind kind) {
    const void *key = kind == AWEHomeTopActionKindSearch
        ? &kAWETopSearchSlotKey : &kAWETopMenuSlotKey;
    AWEHomeTopSlotView *slot = container
        ? objc_getAssociatedObject(container, key) : nil;
    if (!slot) return;
    slot.hidden = YES;
    slot.userInteractionEnabled = NO;
    slot.hitButton.userInteractionEnabled = NO;
    slot.systemGlassButton.hidden = YES;
}

static void AWEHideTopSlot(UIView *container, AWEHomeTopActionKind kind) {
    const void *key = kind == AWEHomeTopActionKindSearch
        ? &kAWETopSearchSlotKey
        : &kAWETopMenuSlotKey;
    AWEHomeTopSlotView *slot = objc_getAssociatedObject(container, key);
    if (!slot) return;
    AWERestoreTopSourceImage(slot);
    AWERestoreTopOwnerVisual(slot);
    if (kind == AWEHomeTopActionKindMenu) AWEClearTopMenuMorph(slot);
    slot.userInteractionEnabled = NO;
    slot.hitButton.userInteractionEnabled = NO;
    slot.hitButton.hidden = YES;
    slot.systemGlassButton.hidden = YES;
    slot.hidden = YES;
}

static void AWEForceHideTopLeftControl(UIView *container,
                                       UIView *owner,
                                       UIImageView *source) {
    if (!container) return;
    AWEHomeTopSlotView *slot = AWEEnsureTopSlot(
        container, AWEHomeTopActionKindMenu);
    if (!slot) return;

    if (owner) {
        AWEHideTopSourceImage(slot, source ?: AWEBestTopIconImageView(owner));
        AWEHideTopOwnerVisual(slot, owner, container);
        if (!objc_getAssociatedObject(owner, &kAWETopOwnerInteractionKey)) {
            objc_setAssociatedObject(owner, &kAWETopOwnerInteractionKey,
                                     @(owner.userInteractionEnabled),
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        owner.userInteractionEnabled = NO;
        owner.layer.opacity = 0.0f;
    } else if (slot.ownerView) {
        slot.ownerView.layer.opacity = 0.0f;
        slot.ownerView.userInteractionEnabled = NO;
    }

    AWEClearTopMenuMorph(slot);
    slot.userInteractionEnabled = NO;
    slot.hitButton.userInteractionEnabled = NO;
    slot.hitButton.hidden = YES;
    slot.systemGlassButton.hidden = YES;
    slot.photosGlassHost.hidden = YES;
    slot.hidden = YES;
    objc_setAssociatedObject(slot, &kAWETopMenuForcedHiddenKey,
                             @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void AWERestoreTopLeftControlAfterForcedHide(UIView *container) {
    AWEHomeTopSlotView *slot = container
        ? objc_getAssociatedObject(container, &kAWETopMenuSlotKey) : nil;
    if (!slot || ![objc_getAssociatedObject(
            slot, &kAWETopMenuForcedHiddenKey) boolValue]) return;
    AWERestoreTopSourceImage(slot);
    AWERestoreTopOwnerVisual(slot);
    objc_setAssociatedObject(slot, &kAWETopMenuForcedHiddenKey,
                             nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void AWERefreshTopActionContainer(UIView *container) {
    if (!AWEPluginFeaturesEnabled() || gAWESettingsVisible) return;
    if (!container || !container.window ||
        CGRectGetWidth(container.bounds) < 100.0 ||
        CGRectGetHeight(container.bounds) < 20.0) {
        if (container) {
            AWEHideTopSlot(container, AWEHomeTopActionKindMenu);
            AWEHideTopSlot(container, AWEHomeTopActionKindSearch);
            AWEHideTopLiquidGroup(container);
        }
        return;
    }
    if (!AWEHomeViewEffectivelyVisible(container)) {
        /* All custom top chrome is parented to this container. Let the parent
           carry it through photo/comment transitions; setting our own hidden
           flags here was why it sometimes never returned. */
        return;
    }
    container.clipsToBounds = NO;
    BOOL bottomSearchVisible = AWEBottomBarSearchIsVisible();
    AWEHomeTopSlotView *existingMenuSlot = objc_getAssociatedObject(
        container, &kAWETopMenuSlotKey);
    AWEHomeTopSlotView *existingSearchSlot = objc_getAssociatedObject(
        container, &kAWETopSearchSlotKey);
    UIView *leftOwner = AWEFindTopOwnerCandidate(container, NO);
    UIView *searchOwner = AWEFindTopOwnerCandidate(container, YES);
    /* Recycled top-bar passes can briefly omit an entrance wrapper. Retain the
       last live owner instead of tearing down the native glass/menu for one
       layout and recreating it on the next frame. */
    if (!leftOwner && existingMenuSlot.ownerView.window == container.window) {
        leftOwner = existingMenuSlot.ownerView;
    }
    if (!searchOwner && existingSearchSlot.ownerView.window == container.window) {
        searchOwner = existingSearchSlot.ownerView;
    }
    UIImageView *leftSource = AWEBestTopIconImageView(leftOwner);
    UIImageView *searchSource = AWEBestTopIconImageView(searchOwner);

    if (AWEHideTopLeftButtonEnabled()) {
        AWEForceHideTopLeftControl(container, leftOwner, leftSource);
    } else {
        AWERestoreTopLeftControlAfterForcedHide(container);
        if (!AWETopGlassEnabled()) {
            AWEHideTopSlot(container, AWEHomeTopActionKindMenu);
        } else if (leftOwner) {
            AWEConfigureTopSlot(container, AWEHomeTopActionKindMenu,
                                leftOwner, leftSource);
        } else if (existingMenuSlot && existingMenuSlot.ownerView.window) {
            existingMenuSlot.hidden = NO;
        } else {
            AWEHideTopSlot(container, AWEHomeTopActionKindMenu);
        }
    }

    if (bottomSearchVisible) {
        /* Bottom search owns the only search entry: remove the top glass,
           original artwork and original hit target together. */
        AWESuppressTopSearchForBottomSearch(
            container, searchOwner, searchSource);
    } else if (searchOwner) {
        /* Search is an independent navigation entry. Disabling the top menu/
           category glass must not remove the right-side search button. */
        AWEConfigureTopSlot(container, AWEHomeTopActionKindSearch,
                            searchOwner, searchSource);
    } else {
        AWEHideTopSlot(container, AWEHomeTopActionKindSearch);
    }
    AWEHomeTopSlotView *menuSlot = objc_getAssociatedObject(
        container, &kAWETopMenuSlotKey);
    AWEHomeTopSlotView *searchSlot = objc_getAssociatedObject(
        container, &kAWETopSearchSlotKey);
    AWEUpdateTopLiquidGroup(container, bottomSearchVisible);
    /* When menu morph is enabled, native/category chrome must be suppressed
       from frame zero. Waiting for the UIMenu children to finish populating
       is exactly what caused the cold-start category flash. */
    BOOL menuOwnsCategorySwitching = AWETopMenuMorphEnabled();
    AWETopLiquidGroupView *activeGroup = objc_getAssociatedObject(
        container, &kAWETopLiquidGroupViewKey);
    BOOL groupOwnsCategorySwitching = activeGroup && !activeGroup.hidden &&
        activeGroup.alpha > 0.01 && activeGroup.userInteractionEnabled;
    AWEApplyTopCategoryVisualSuppression(
        container, menuOwnsCategorySwitching || groupOwnsCategorySwitching);
    if (menuSlot && !menuSlot.hidden) [container bringSubviewToFront:menuSlot];
    if (searchSlot && !searchSlot.hidden) [container bringSubviewToFront:searchSlot];
}

static void AWEScheduleTopActionContainerRefresh(UIView *container) {
    if (!AWEPluginFeaturesEnabled() || !container) return;
    if ([objc_getAssociatedObject(
            container, &kAWETopActionRefreshPendingKey) boolValue]) {
        return;
    }
    objc_setAssociatedObject(container, &kAWETopActionRefreshPendingKey,
                             @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSInteger generation =
        [objc_getAssociatedObject(container, &kAWETopActionRetryGenerationKey)
            integerValue] + 1;
    objc_setAssociatedObject(container, &kAWETopActionRetryGenerationKey,
                             @(generation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSArray<NSNumber *> *delays = @[@0.0, @0.18, @0.55];
    __weak UIView *weakContainer = container;
    for (NSUInteger index = 0; index < delays.count; index++) {
        NSNumber *delay = delays[index];
        BOOL finalPass = index + 1 == delays.count;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            UIView *strongContainer = weakContainer;
            if (!strongContainer) return;
            NSInteger current = [objc_getAssociatedObject(
                strongContainer, &kAWETopActionRetryGenerationKey) integerValue];
            if (current == generation) {
                AWEMarkTopCategorySuppressionCacheDirty(strongContainer);
                AWERefreshTopActionContainer(strongContainer);
            }
            if (finalPass) {
                objc_setAssociatedObject(strongContainer,
                    &kAWETopActionRefreshPendingKey, nil,
                    OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        });
    }
}

static void AWEConfigureTopActionGlass(UIView *view) {
    if (!AWEPluginFeaturesEnabled() || !view) return;
    UIView *container = view;
    while (container &&
           ![NSStringFromClass(container.class) containsString:@"AWEFeedTopBarContainer"]) {
        container = container.superview;
    }
    if (!container && view.window) {
        container = AWEFindViewByExactRuntimeClass(
            view.window, @"AWEFeedTopBarContainer", 0);
    }
    if (container) AWERefreshTopActionContainer(container);
}

static void AWEScheduleTopActionGlass(UIView *view) {
    if (!AWEPluginFeaturesEnabled() || !view) return;
    UIView *container = view;
    while (container &&
           ![NSStringFromClass(container.class) containsString:@"AWEFeedTopBarContainer"]) {
        container = container.superview;
    }
    if (!container && view.window) {
        container = AWEFindViewByExactRuntimeClass(
            view.window, @"AWEFeedTopBarContainer", 0);
    }
    if (container) AWEScheduleTopActionContainerRefresh(container);
}


static void AWECollectVisibleHomeActionStacks(UIView *root,
                                               NSMutableArray<UIView *> *result,
                                               NSUInteger depth) {
    if (!root || !result || depth > 18) return;
    if ([NSStringFromClass(root.class) containsString:@"AWEElementStackView"]) {
        [result addObject:root];
    }
    for (UIView *child in root.subviews) {
        if ([child isKindOfClass:AWEHomeActionSlotView.class]) continue;
        AWECollectVisibleHomeActionStacks(child, result, depth + 1);
    }
}

static void AWERefreshHomeActionStacksInView(UIView *root) {
    if (!AWEPluginFeaturesEnabled() || !root) return;
    NSMutableArray<UIView *> *stacks = [NSMutableArray array];
    AWECollectVisibleHomeActionStacks(root, stacks, 0);
    for (UIView *stack in stacks) AWEScheduleHomeActionStackRefresh(stack);
}

static void AWEScheduleHomeActionStacksInView(UIView *root) {
    if (!AWEPluginFeaturesEnabled() || !root) return;
    NSInteger generation =
        [objc_getAssociatedObject(root, &kAWEHomeActionRetryGenerationKey)
            integerValue] + 1;
    objc_setAssociatedObject(root, &kAWEHomeActionRetryGenerationKey,
                             @(generation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSArray<NSNumber *> *delays = @[@0.0, @0.12, @0.42];
    __weak UIView *weakRoot = root;
    for (NSNumber *delay in delays) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            UIView *strongRoot = weakRoot;
            if (!strongRoot) return;
            NSInteger current = [objc_getAssociatedObject(
                strongRoot, &kAWEHomeActionRetryGenerationKey) integerValue];
            if (current != generation) return;
            AWERefreshHomeActionStacksInView(strongRoot);
        });
    }
}


static void AWERefreshHomeChromeInWindow(UIWindow *window) {
    if (!window) window = AWEActiveMainWindow();
    if (!window) return;
    UIView *top = AWEFindViewByExactRuntimeClass(
        window, @"AWEFeedTopBarContainer", 0);
    if (top) AWERefreshTopActionContainer(top);
    AWERefreshHomeActionStacksInView(window);
}

static BOOL AWEClassNameIsCommentInputOnlyForRightRecovery(NSString *className) {
    if (className.length == 0) return NO;
    NSString *lower = className.lowercaseString;
    return [lower containsString:@"comment"] &&
           [lower containsString:@"input"];
}

static BOOL AWEClassNameIsCommentPanelForRightRecovery(NSString *className) {
    if (className.length == 0) return NO;
    NSString *lower = className.lowercaseString;
    if (![lower containsString:@"comment"] ||
        AWEClassNameIsCommentInputOnlyForRightRecovery(className)) {
        return NO;
    }
    return [lower containsString:@"controller"] ||
           [lower containsString:@"container"] ||
           [lower containsString:@"panel"] ||
           [lower containsString:@"list"];
}

static BOOL AWEAnyVisibleCommentPanelForRightRecovery(void) {
    for (UIViewController *controller in AWESensitiveVisibleControllers()) {
        if (!controller) continue;
        NSString *className = NSStringFromClass(controller.class);
        if (!AWEClassNameIsCommentPanelForRightRecovery(className)) continue;
        UIView *view = controller.viewIfLoaded;
        if (view.window || controller.isBeingPresented ||
            controller.isMovingToParentViewController) {
            return YES;
        }
    }
    return NO;
}

static BOOL AWEAnyBlockingSensitiveDestinationForRightRecovery(void) {
    for (UIViewController *controller in AWESensitiveVisibleControllers()) {
        if (!controller) continue;
        UIView *view = controller.viewIfLoaded;
        BOOL live = view.window || controller.isBeingPresented ||
                    controller.isMovingToParentViewController;
        if (!live) continue;
        NSString *className = NSStringFromClass(controller.class);
        /* AWECommentInputViewController commonly remains attached for several
           seconds after the visible comment sheet has already disappeared.
           It must not keep the feed-side action column suppressed. */
        if (AWEClassNameIsCommentInputOnlyForRightRecovery(className)) continue;
        return YES;
    }
    return NO;
}

static NSArray<UIWindow *> *AWEForegroundNormalWindowsForHomeChrome(void) {
    NSMutableArray<UIWindow *> *windows = [NSMutableArray array];
    UIApplication *application = UIApplication.sharedApplication;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in application.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            if (scene.activationState != UISceneActivationStateForegroundActive &&
                scene.activationState != UISceneActivationStateForegroundInactive) {
                continue;
            }
            for (UIWindow *window in ((UIWindowScene *)scene).windows) {
                if (!window || window.hidden || window.alpha <= 0.01 ||
                    window.windowLevel != UIWindowLevelNormal) {
                    continue;
                }
                if (window == (UIWindow *)gAWEAlbumMorphOverlayWindow ||
                    [NSStringFromClass(window.class) containsString:@"AWEAlbumMorphOverlayWindow"]) {
                    continue;
                }
                [windows addObject:window];
            }
        }
    }
    UIWindow *active = AWEActiveMainWindow();
    if (active && ![windows containsObject:active]) [windows insertObject:active atIndex:0];
    return windows;
}

static BOOL AWEFrameLooksLikeCurrentRightActionStack(UIView *stack) {
    UIWindow *window = stack.window;
    if (!stack || !window) return NO;
    CGRect frame = [stack convertRect:stack.bounds toView:window];
    CGFloat screenW = CGRectGetWidth(window.bounds);
    CGFloat width = CGRectGetWidth(frame);
    CGFloat height = CGRectGetHeight(frame);
    if (screenW < 200.0 || width < 44.0 || width > 140.0 ||
        height < 180.0 || height > 620.0) {
        return NO;
    }
    if (CGRectGetMidX(frame) < screenW * 0.74 ||
        CGRectGetMaxX(frame) < screenW * 0.86) {
        return NO;
    }
    CGRect visible = CGRectIntersection(frame, window.bounds);
    if (CGRectIsNull(visible) || CGRectIsEmpty(visible) ||
        CGRectGetHeight(visible) < 100.0) {
        return NO;
    }
    /* An offscreen/recycled feed cell can remain in the same window. Reject it
       when one of its ancestors is actually removed/hidden; ignore only the
       stack's own alpha because Douyin deliberately fades that to zero while
       the comment sheet is open. */
    for (UIView *ancestor = stack.superview;
         ancestor && ancestor != window;
         ancestor = ancestor.superview) {
        if (ancestor.hidden || ancestor.alpha < 0.01 ||
            ancestor.layer.opacity < 0.01f) {
            return NO;
        }
    }
    return YES;
}

static CGFloat AWECurrentRightStackVisibilityScore(UIView *stack, UIWindow *window) {
    if (!stack || !window) return -CGFLOAT_MAX;
    CGRect frame = [stack convertRect:stack.bounds toView:window];
    CGRect visible = CGRectIntersection(frame, window.bounds);
    if (CGRectIsNull(visible) || CGRectIsEmpty(visible)) return -CGFLOAT_MAX;

    CGFloat visibleRatio = CGRectGetHeight(visible) / MAX(CGRectGetHeight(frame), 1.0);
    CGFloat centerPenalty = fabs(CGRectGetMidY(frame) - CGRectGetMidY(window.bounds));
    CGFloat score = visibleRatio * 4000.0 - centerPenalty * 0.8;
    if (AWEFindViewByExactRuntimeClass(
            stack, @"AWEPlayInteractionUserProfilePictureView", 0) ||
        AWEFindViewByExactRuntimeClass(
            stack, @"AWEPlayInteractionUserProfileContainerView", 0)) {
        score += 700.0;
    }
    /* The pre-comment stack is only a tie-breaker now. Returning it outright
       made a covered/stale profile feed win over the newly visible cell. */
    if (stack == gAWECommentRightStackBefore) score += 80.0;
    return score;
}

static UIView *AWEFindCurrentRightActionStackAcrossWindows(void) {
    UIView *best = nil;
    CGFloat bestScore = -CGFLOAT_MAX;
    for (UIWindow *window in AWEForegroundNormalWindowsForHomeChrome()) {
        NSMutableArray<UIView *> *stacks = [NSMutableArray array];
        AWECollectVisibleHomeActionStacks(window, stacks, 0);
        for (UIView *stack in stacks) {
            if (!AWEFrameLooksLikeCurrentRightActionStack(stack)) continue;
            CGFloat score = AWECurrentRightStackVisibilityScore(stack, window);
            if (score > bestScore) {
                bestScore = score;
                best = stack;
            }
        }
    }
    return best;
}

static BOOL AWEControllerTreeContainsPlayableFeed(UIViewController *controller,
                                                   NSUInteger depth) {
    if (!controller || depth > 12) return NO;
    if (AWEClassNameLooksLikePlayableFeedController(
            NSStringFromClass(controller.class))) return YES;
    UIViewController *presented = controller.presentedViewController;
    if (presented && !presented.isBeingDismissed &&
        AWEControllerTreeContainsPlayableFeed(presented, depth + 1)) return YES;
    for (UIViewController *child in controller.childViewControllers) {
        if (!child.viewIfLoaded.window) continue;
        if (AWEControllerTreeContainsPlayableFeed(child, depth + 1)) return YES;
    }
    return NO;
}

static BOOL AWECurrentRouteHasPlayableFeedController(void) {
    for (UIWindow *window in AWEForegroundNormalWindowsForHomeChrome()) {
        UIViewController *top = AWETopViewControllerFrom(window.rootViewController);
        if (top && AWEControllerTreeContainsPlayableFeed(top, 0)) return YES;
    }
    return NO;
}

static BOOL AWEShouldProtectRightStackFromFullscreenTweak(UIView *stack) {
    if (!stack || !stack.window) return NO;
    if (AWEAnyVisibleCommentPanelForRightRecovery() ||
        AWEAnyBlockingSensitiveDestinationForRightRecovery()) return NO;
    if (!AWEShouldSuppressBarForUserDetailRoute()) return NO;
    if (!AWECurrentRouteHasPlayableFeedController()) return NO;
    return AWEFrameLooksLikeCurrentRightActionStack(stack);
}

static void AWEScheduleFullscreenStackVisibilityProtection(UIView *stack,
                                                            NSString *reason) {
    if (!stack) return;
    __weak UIView *weakStack = stack;
    for (NSNumber *delay in @[@0.08, @0.35]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
            (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{
            UIView *strongStack = weakStack;
            if (!strongStack || !AWEShouldProtectRightStackFromFullscreenTweak(strongStack)) return;
            BOOL restored = AWEForceRestoreRightActionStackAfterComment(strongStack);
            AWERefreshExternalBridgeMenu(strongStack);
            AWEInteractionDiagnosticWrite(
                @"RIGHT_FULLSCREEN_VISIBILITY_GUARD reason=%@ delay=%.2f restored=%d stack=%@",
                reason ?: @"unknown", delay.doubleValue, restored,
                AWEInteractionObjectSummary(strongStack));
        });
    }
}

static BOOL AWEProfileFullscreenRightProtectionActiveForStack(UIView *stack) {
    if (!stack || CACurrentMediaTime() >= gAWEProfileFullscreenRightProtectUntil) {
        return NO;
    }
    if (AWEAnyVisibleCommentPanelForRightRecovery() ||
        AWEAnyBlockingSensitiveDestinationForRightRecovery()) {
        return NO;
    }
    if (!AWEShouldSuppressBarForUserDetailRoute() ||
        !AWECurrentRouteHasPlayableFeedController()) {
        return NO;
    }
    if (gAWEProfileFullscreenProtectedRightStack &&
        stack != gAWEProfileFullscreenProtectedRightStack) {
        return NO;
    }
    return AWEFrameLooksLikeCurrentRightActionStack(stack);
}

static NSUInteger AWECountHomeActionStacksAcrossForegroundWindows(void) {
    NSUInteger count = 0;
    for (UIWindow *window in AWEForegroundNormalWindowsForHomeChrome()) {
        NSMutableArray<UIView *> *stacks = [NSMutableArray array];
        AWECollectVisibleHomeActionStacks(window, stacks, 0);
        count += stacks.count;
    }
    return count;
}

static BOOL AWEForceRestoreRightActionStackAfterComment(UIView *stack) {
    if (!stack || !stack.window || !AWEFrameLooksLikeCurrentRightActionStack(stack)) {
        return NO;
    }
    BOOL changed = NO;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    if (stack.hidden) {
        stack.hidden = NO;
        changed = YES;
    }
    if (stack.alpha < 0.99) {
        stack.alpha = 1.0;
        changed = YES;
    }
    if (stack.layer.opacity < 0.99f) {
        stack.layer.opacity = 1.0f;
        changed = YES;
    }
    [CATransaction commit];

    AWERefreshHomeActionStack(stack);
    AWELayoutBoundHomeActionSlots(stack);
    return changed || !stack.hidden;
}

static NSString *AWECurrentRightActionStackSummary(void) {
    UIWindow *window = AWEActiveMainWindow();
    if (!window) return @"window=nil";
    NSMutableArray<UIView *> *stacks = [NSMutableArray array];
    AWECollectVisibleHomeActionStacks(window, stacks, 0);
    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    for (UIView *stack in stacks) {
        CGRect frame = stack.window
            ? [stack convertRect:stack.bounds toView:stack.window]
            : CGRectZero;
        NSArray<UIView *> *buttons = AWESortedVisibleHomeActionButtons(stack);
        [parts addObject:[NSString stringWithFormat:
            @"%p/%@ frame=%@ window=%d hidden=%d alpha=%.2f buttons=%lu",
            stack, NSStringFromClass(stack.class), NSStringFromCGRect(frame),
            stack.window != nil, stack.hidden, stack.alpha,
            (unsigned long)buttons.count]];
    }
    return parts.count ? [parts componentsJoinedByString:@" || "] : @"none";
}

static void AWESchedulePostCommentRightRebind(NSString *reason) {
    if (!AWEPluginFeaturesEnabled()) return;
    BOOL profileFullscreenRecovery =
        AWEShouldSuppressBarForUserDetailRoute() &&
        AWECurrentRouteHasPlayableFeedController();
    NSUInteger generation = ++gAWECommentRightRebindGeneration;
    NSString *before = gAWECommentRightHostBefore ?: @"unknown";
    UIView *captured = gAWECommentRightStackBefore;
    if (profileFullscreenRecovery) {
        gAWEProfileFullscreenRightProtectUntil = CACurrentMediaTime() + 2.40;
        gAWEProfileFullscreenProtectedRightStack = captured;
        AWEInteractionDiagnosticWrite(
            @"RIGHT_FULLSCREEN_COMMENT_PROTECT until=%.2f captured=%@",
            gAWEProfileFullscreenRightProtectUntil,
            AWEInteractionObjectSummary(captured));
    }
    AWEInteractionDiagnosticWrite(
        @"RIGHT_REBIND_SCHEDULE generation=%lu reason=%@ captured=%@ before=%@",
        (unsigned long)generation, reason ?: @"comment.dismiss",
        AWEInteractionObjectSummary(captured), before);

    /* Important: AWECommentInputViewController can remain attached for 4-8 s
       after the visible panel is gone. 1.0.49c waited for it, so the user saw
       an empty right column immediately after closing comments and some profile
       feeds never reached the rebind at all. Rebind as soon as the last visible
       comment panel disappears. Use a handful of bounded passes rather than a
       display link/timer, and search every foreground normal-level app window
       because the key window can temporarily be a transition/input host. */
    NSArray<NSNumber *> *delays = profileFullscreenRecovery
        ? @[@0.0, @0.08, @0.20, @0.45, @0.80, @1.20, @1.75, @2.25]
        : @[@0.0, @0.08, @0.20, @0.45, @0.80, @1.20];
    for (NSNumber *delay in delays) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
            (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{
            if (generation != gAWECommentRightRebindGeneration) return;
            if (AWEAnyVisibleCommentPanelForRightRecovery() ||
                AWEAnyBlockingSensitiveDestinationForRightRecovery()) {
                AWEInteractionDiagnosticWrite(
                    @"RIGHT_REBIND_PASS generation=%lu delay=%.2f blocked=1",
                    (unsigned long)generation, delay.doubleValue);
                return;
            }

            UIView *target = nil;
            if (captured && AWEFrameLooksLikeCurrentRightActionStack(captured)) {
                target = captured;
            }
            if (!target) target = AWEFindCurrentRightActionStackAcrossWindows();

            BOOL restored = AWEForceRestoreRightActionStackAfterComment(target);
            NSUInteger stacks = AWECountHomeActionStacksAcrossForegroundWindows();
            NSString *after = target
                ? [NSString stringWithFormat:@"%@ alpha=%.2f hidden=%d",
                    AWEInteractionObjectSummary(target), target.alpha, target.hidden]
                : @"none";
            AWEInteractionDiagnosticWrite(
                @"RIGHT_REBIND_PASS generation=%lu delay=%.2f stacks=%lu target=%@ restored=%d",
                (unsigned long)generation, delay.doubleValue,
                (unsigned long)stacks, after, restored);

            if (delay == delays.lastObject &&
                generation == gAWECommentRightRebindGeneration) {
                gAWECommentRightStackBefore = nil;
                gAWECommentRightHostBefore = nil;
            }
        });
    }
}

@interface AWEHomeChromeRecoveryTicker : NSObject
- (void)alb_tick:(CADisplayLink *)displayLink;
@end

static CADisplayLink *gAWEHomeChromeRecoveryDisplayLink = nil;
static AWEHomeChromeRecoveryTicker *gAWEHomeChromeRecoveryTicker = nil;
static CFTimeInterval gAWEHomeChromeRecoveryDeadline = 0.0;

static void AWERefreshHomeChromeImmediately(UIWindow *window) {
    if (!window) window = AWEActiveMainWindow();
    if (!window) return;
    UIView *top = AWEFindViewByExactRuntimeClass(
        window, @"AWEFeedTopBarContainer", 0);
    if (top) AWERefreshTopActionContainer(top);
    NSMutableArray<UIView *> *stacks = [NSMutableArray array];
    AWECollectVisibleHomeActionStacks(window, stacks, 0);
    for (UIView *stack in stacks) AWERefreshHomeActionStack(stack);
}

@implementation AWEHomeChromeRecoveryTicker
- (void)alb_tick:(CADisplayLink *)displayLink {
    if (CACurrentMediaTime() > gAWEHomeChromeRecoveryDeadline) {
        [displayLink invalidate];
        gAWEHomeChromeRecoveryDisplayLink = nil;
        gAWEHomeChromeRecoveryTicker = nil;
        return;
    }
    AWERefreshHomeChromeImmediately(AWEActiveMainWindow());
}
@end

static void AWEStartHomeChromeRecoverySampler(void) {
    /* 1.0.48a: no continuous CADisplayLink. Lifecycle hooks and three bounded
       reconciliation passes are sufficient and avoid the major heat source. */
}

static void AWEScheduleHomeChromeRecovery(UIWindow *window) {
    if (!AWEPluginFeaturesEnabled()) return;
    AWEStartHomeChromeRecoverySampler();
    __weak UIWindow *weakWindow = window ?: AWEActiveMainWindow();
    for (NSNumber *delay in @[@0.0, @0.12, @0.42]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                     (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            UIWindow *strongWindow = weakWindow ?: AWEActiveMainWindow();
            AWERefreshHomeChromeInWindow(strongWindow);
        });
    }
}

static void AWEHomeDiagnosticRefreshVisibleUI(void) {
    UIWindow *window = AWEActiveMainWindow();
    if (!window) {
        AWEHomeDiagnosticWrite(NO, @"REFRESH no-active-window");
        return;
    }
    UIView *topContainer = AWEFindViewByExactRuntimeClass(
        window, @"AWEFeedTopBarContainer", 0);
    AWEHomeDiagnosticWrite(NO,
        @"REFRESH window=%p topContainer=%p mode=%@",
        window, topContainer, AWEHomeDiagnosticModeName());
    if (topContainer) AWEScheduleTopActionContainerRefresh(topContainer);
    AWEScheduleHomeActionStacksInView(window);
}

static void AWEHomeDiagnosticSetMode(
    AWEHomeDiagnosticForegroundMode mode, NSString *phase) {
    gAWEHomeDiagnosticForegroundMode = mode;
    AWEHomeDiagnosticWrite(NO, @"PHASE %@ mode=%@",
                           phase, AWEHomeDiagnosticModeName());
    AWEHomeDiagnosticRefreshVisibleUI();
}

static void AWEHomeDiagnosticStart(NSString *reason) {
    NSUInteger generation = ++gAWEHomeDiagnosticGeneration;
    gAWEHomeDiagnosticEnabled = YES;
    gAWEHomeDiagnosticForegroundMode = AWEHomeDiagnosticForegroundModeAutomatic;
    AWEHomeDiagnosticWrite(YES,
        @"========== LIGHTWEIGHT DIAGNOSTIC START build=1.0.1 reason=%@ image=%@ ==========" ,
        reason ?: @"unknown", AWEHomeDiagnosticLoadedImagePath());
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (generation != gAWEHomeDiagnosticGeneration) return;
        AWEHomeDiagnosticWrite(YES,
            @"========== LIGHTWEIGHT DIAGNOSTIC END build=1.0.1 ==========");
        gAWEHomeDiagnosticEnabled = NO;
    });
}

static AWENormalModeTabBar *AWEPrepareBarForController(id controller,
                                                       BOOL forceVisible) {
    if (!AWEPluginFeaturesEnabled()) return nil;
    NSArray *buttons = AWEControllerButtons(controller);
    BOOL secondRoleChanged = AWEUpdateSecondTabRoleFromButtons(buttons);
    AWENormalModeTabBar *tabBar = AWETabBarFromButtons(buttons);
    if (!tabBar) return nil;

    objc_setAssociatedObject(tabBar, &kAWEControllerKey, controller,
                             OBJC_ASSOCIATION_ASSIGN);

    gAWELastTabBar = tabBar;
    if ([controller isKindOfClass:NSClassFromString(@"AWENormalModeTabBarController")]) {
        gAWELastController = controller;
    }

    AWEAttachNativeBarWithForce(tabBar, forceVisible);
    if (AWEAlbumMorphStyleEnabled()) {
        if (gAWEAlbumMorphController) {
            [gAWEAlbumMorphController
                configureSecondTabAsShop:AWESecondTabIsShop()];
        }
        return tabBar;
    }

    AWEInstallDelegateIfNeeded(tabBar);
    UITabBar *nativeBar = objc_getAssociatedObject((UIView *)tabBar, &kAWENativeBarKey);
    if (nativeBar) {
        if (secondRoleChanged) {
            objc_setAssociatedObject(nativeBar, &kAWETabBarSymbolSignatureKey, nil,
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        AWERefreshNativeBarSymbolItems(nativeBar);
    }
    return tabBar;
}


static BOOL AWEOriginalBarIsBackAtBottom(UIView *tabBar) {
    if (!tabBar || !tabBar.window || !tabBar.superview) return NO;
    if (tabBar.hidden || tabBar.alpha <= 0.01) return NO;

    UIWindow *window = tabBar.window;
    CGRect frameInWindow = [tabBar convertRect:tabBar.bounds toView:window];

    if (CGRectGetWidth(frameInWindow) < 100.0 ||
        CGRectGetHeight(frameInWindow) < 20.0) {
        return NO;
    }

    CGFloat windowHeight = CGRectGetHeight(window.bounds);
    CGFloat barMidY = CGRectGetMidY(frameInWindow);
    CGFloat barMaxY = CGRectGetMaxY(frameInWindow);

    /*
     A real root tab bar lives in the lower portion of the window. This check
     prevents a recovery triggered by a comment/profile controller from
     showing LiquidBar while Douyin's original bar is still intentionally
     offscreen.
    */
    BOOL inLowerRegion = barMidY > windowHeight * 0.68;
    BOOL nearBottom = barMaxY > windowHeight - 150.0 &&
                      barMaxY < windowHeight + 150.0;

    return inLowerRegion && nearBottom;
}

static void AWEScheduleTransitionRecovery(void) {
    if (!AWEPluginFeaturesEnabled()) return;
    /*
     Reconcile once on the next main-run-loop turn.  The old 0/16/80/220 ms
     retry queue is intentionally removed; it was one source of post-return
     disappear/reappear cycles.
    */
    NSUInteger generation = ++gAWERecoveryGeneration;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (generation != gAWERecoveryGeneration) return;
        AWENormalModeTabBar *tabBar = gAWELastTabBar;
        if (!tabBar && gAWELastController) {
            tabBar = AWEPrepareBarForController(gAWELastController, NO);
        }
        if (!tabBar) return;
        AWEAttachNativeBarWithForce((UIView *)tabBar, NO);
        if (AWEAlbumMorphStyleEnabled() && gAWEAlbumMorphController) {
            AWEUpdateAlbumMorphVisibility((UIView *)tabBar,
                                          @"next-run-loop.recovery");
            AWEStartBarVisibilityDriver();
        } else {
            AWEInstallDelegateIfNeeded((UIView *)tabBar);
        }
    });
}


static void AWEForceAlbumMorphRouteRecovery(NSString *reason) {
    if (!AWEAlbumMorphStyleEnabled() || !AWEPluginFeaturesEnabled()) return;

    NSUInteger generation = ++gAWEAlbumMorphRouteRecoveryGeneration;
    AWEAlbumMorphProbeWrite(@"RECOVERY_SCHEDULE generation=%lu reason=%@",
        (unsigned long)generation, reason ?: @"unknown");

    /* One next-run-loop reconciliation only.  Repeated delayed installs were
       rebuilding/reconfiguring the overlay around the transition boundary and
       are intentionally removed, matching the stable 1.0.10b architecture. */
    dispatch_async(dispatch_get_main_queue(), ^{
        if (generation != gAWEAlbumMorphRouteRecoveryGeneration) return;
        AWENormalModeTabBar *tabBar = gAWELastTabBar;
        if (!tabBar && gAWELastController) {
            tabBar = AWEPrepareBarForController(gAWELastController, NO);
        }
        BOOL result = NO;
        if (tabBar) {
            result = AWEInstallOrUpdateAlbumMorphBar((UIView *)tabBar, NO);
            AWEUpdateAlbumMorphVisibility((UIView *)tabBar,
                reason ?: @"route.recovery");
        }
        AWEStartBarVisibilityDriver();
        AWEAlbumMorphProbeWrite(
            @"RECOVERY_ONCE generation=%lu reason=%@ tab=%d result=%d fraction=%.3f",
            (unsigned long)generation, reason ?: @"unknown",
            tabBar != nil, result, gAWEBarLastVisibleFraction);
    });
}

#pragma mark - Settings

static void AWEApplyStoredAccentToCurrentBar(void) {
    if (!AWEPluginFeaturesEnabled()) return;
    if (AWEAlbumMorphStyleEnabled() && gAWEAlbumMorphController) {
        [gAWEAlbumMorphController updateAccentColor:AWEStoredAccentColor()];
        return;
    }

    AWENormalModeTabBar *tabBar = gAWELastTabBar;
    if (!tabBar) return;

    UITabBar *nativeBar =
        objc_getAssociatedObject((UIView *)tabBar, &kAWENativeBarKey);
    if (!nativeBar) return;

    AWEConfigureNativeBarAppearance(nativeBar, AWEStoredAccentColor());
}

static void AWERefreshCurrentBarLayout(void) {
    if (!AWEPluginFeaturesEnabled()) return;
    AWENormalModeTabBar *tabBar = gAWELastTabBar;
    if (!tabBar) return;

    if (AWEAlbumMorphStyleEnabled()) {
        AWEInstallOrUpdateAlbumMorphBar((UIView *)tabBar, NO);
        return;
    }

    objc_setAssociatedObject((UIView *)tabBar, &kAWELastFrameKey, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    AWEAttachNativeBarWithForce((UIView *)tabBar, NO);
}

static UIViewController *AWETopViewControllerFrom(UIViewController *controller) {
    if (!controller) return nil;

    UIViewController *current = controller;

    while (current.presentedViewController &&
           !current.presentedViewController.isBeingDismissed) {
        current = current.presentedViewController;
    }

    if ([current isKindOfClass:[UINavigationController class]]) {
        UIViewController *visible =
            ((UINavigationController *)current).visibleViewController;
        if (visible && visible != current) {
            return AWETopViewControllerFrom(visible);
        }
    }

    if ([current isKindOfClass:[UITabBarController class]]) {
        UIViewController *selected =
            ((UITabBarController *)current).selectedViewController;
        if (selected && selected != current) {
            return AWETopViewControllerFrom(selected);
        }
    }

    for (UIViewController *child in
         current.childViewControllers.reverseObjectEnumerator) {
        if (child.viewIfLoaded.window) {
            UIViewController *candidate = AWETopViewControllerFrom(child);
            if (candidate) return candidate;
        }
    }

    return current;
}

static UIWindow *AWEActiveMainWindow(void) {
    UIApplication *application = UIApplication.sharedApplication;
    UIWindow *fallbackWindow = nil;

    if (@available(iOS 13.0, *)) {
        NSArray<UIScene *> *scenes = application.connectedScenes.allObjects;

        /* Prefer an active foreground scene, but also accept foreground-inactive
           while a system sheet or transition is taking focus. */
        for (NSNumber *wantedState in @[
                 @(UISceneActivationStateForegroundActive),
                 @(UISceneActivationStateForegroundInactive)]) {
            for (UIScene *scene in scenes) {
                if (![scene isKindOfClass:[UIWindowScene class]]) continue;
                if (scene.activationState != wantedState.integerValue) continue;

                UIWindowScene *windowScene = (UIWindowScene *)scene;
                NSArray<UIWindow *> *windows = windowScene.windows;

                for (UIWindow *window in windows.reverseObjectEnumerator) {
                    if (window.windowLevel != UIWindowLevelNormal ||
                        window.hidden ||
                        window.alpha <= 0.01) {
                        continue;
                    }

                    if (window.isKeyWindow) return window;
                    if (!fallbackWindow) fallbackWindow = window;
                }
            }
        }
    }

    /* This tweak targets scene-based iOS versions. Avoid UIApplication.windows
       and UIApplication.keyWindow because the project treats deprecations as
       build errors. */
    return fallbackWindow;
}

static UIButtonConfiguration *AWECreateSystemGlassButtonConfiguration(BOOL prominent) {
    Class configurationClass = NSClassFromString(@"UIButtonConfiguration");
    SEL selector = NSSelectorFromString(prominent
        ? @"prominentGlassButtonConfiguration"
        : @"glassButtonConfiguration");

    if (configurationClass &&
        [configurationClass respondsToSelector:selector]) {
        return ((id (*)(id, SEL))objc_msgSend)(configurationClass, selector);
    }

    /* Build-time fallback for an older SDK. The target iOS 26 runtime uses
       the branch above and receives the actual Liquid Glass material. */
    return prominent
        ? [UIButtonConfiguration filledButtonConfiguration]
        : [UIButtonConfiguration tintedButtonConfiguration];
}

static void AWEConfigureGlassTextButton(UIButton *button,
                                         NSString *title,
                                         UIColor *tintColor,
                                         BOOL prominent) {
    if (!button) return;
    if (!tintColor) tintColor = UIColor.systemBlueColor;

    UIButtonConfiguration *configuration =
        AWECreateSystemGlassButtonConfiguration(prominent);
    configuration.title = title;
    configuration.baseBackgroundColor = tintColor;

    UIColor *buttonForeground = UIColor.labelColor;
    if (prominent) {
        UIColor *resolvedTint = tintColor;
        if (@available(iOS 13.0, *)) {
            resolvedTint = [tintColor resolvedColorWithTraitCollection:
                [UITraitCollection traitCollectionWithUserInterfaceStyle:
                    UIUserInterfaceStyleLight]];
        }
        CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
        CGFloat luminance = 0.0;
        BOOL readable = [resolvedTint getRed:&red green:&green blue:&blue alpha:&alpha];
        if (!readable) {
            CGFloat white = 0.0;
            readable = [resolvedTint getWhite:&white alpha:&alpha];
            red = green = blue = white;
        }
        if (readable) {
            luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue;
        }
        buttonForeground = (readable && luminance >= 0.68)
            ? UIColor.blackColor
            : UIColor.whiteColor;
    }
    configuration.baseForegroundColor = buttonForeground;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(0.0, 12.0,
                                                               0.0, 12.0);

    button.configuration = configuration;
    button.tintColor = tintColor;
}

static UIButton *AWECreateGlassTextButton(NSString *title,
                                           UIColor *tintColor,
                                           BOOL prominent) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    AWEConfigureGlassTextButton(button, title, tintColor, prominent);

    [button.heightAnchor constraintEqualToConstant:40.0].active = YES;
    return button;
}

static UIUserInterfaceStyle AWESystemInterfaceStyle(void) {
    if (@available(iOS 13.0, *)) {
        /* Prefer the physical screen trait. Douyin can override a window or
           controller locally, but the settings sheet must follow the user's
           actual system appearance rather than that app-local override. */
        UIUserInterfaceStyle screenStyle =
            UIScreen.mainScreen.traitCollection.userInterfaceStyle;
        if (screenStyle != UIUserInterfaceStyleUnspecified) return screenStyle;

        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            if (scene.activationState != UISceneActivationStateForegroundActive &&
                scene.activationState != UISceneActivationStateForegroundInactive) {
                continue;
            }
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                UIUserInterfaceStyle style =
                    window.traitCollection.userInterfaceStyle;
                if (style != UIUserInterfaceStyleUnspecified) return style;
            }
        }
    }

    return UIUserInterfaceStyleLight;
}


#pragma mark - Fixed icon refresh

static void AWERefreshAllConfiguredIcons(void) {
    if (!AWEPluginFeaturesEnabled()) return;
    gAWEConfiguredIconGeneration++;
    if (gAWEConfiguredIconGeneration == 0) gAWEConfiguredIconGeneration = 1;
    if (gAWEAlbumMorphController) {
        [gAWEAlbumMorphController configureSecondTabAsShop:AWESecondTabIsShop()];
        [gAWEAlbumMorphController
            configureVisibleItemIdentifiers:AWEAlbumMorphVisibleItemIdentifiers()];
        [gAWEAlbumMorphController reloadConfiguredImages];
        [gAWEAlbumMorphController updateAccentColor:AWEStoredAccentColor()];
        [gAWEAlbumMorphController setForcedDark:
            (AWEIsIOS27OrLater() && AWEHomeForceDarkGlassEnabled())];
    }
    UITabBar *live = gAWELastTabBar
        ? objc_getAssociatedObject((UIView *)gAWELastTabBar, &kAWENativeBarKey)
        : nil;
    if (live) {
        objc_setAssociatedObject(live, &kAWETabBarSymbolSignatureKey, nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        AWERefreshNativeBarSymbolItems(live);
    }
    if (gAWEStagedNativeBar && gAWEStagedNativeBar != live) {
        objc_setAssociatedObject(gAWEStagedNativeBar, &kAWETabBarSymbolSignatureKey, nil,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        AWERefreshNativeBarSymbolItems(gAWEStagedNativeBar);
    }
    UIWindow *window = AWEActiveMainWindow();
    if (!window) return;
    UIView *top = AWEFindViewByExactRuntimeClass(window, @"AWEFeedTopBarContainer", 0);
    if (top) AWERefreshTopActionContainer(top);
    AWERefreshHomeActionStacksInView(window);
}


#pragma mark - Rebuilt real-time icon center

static NSArray<NSDictionary *> *AWEIconDefinitionsForSection(NSInteger section) {
    if (section == 0) return @[
        @{@"key":@"top.menu", @"title":@"菜单", @"default":@"sidebar.left",
          @"candidates":@[@"sidebar.left", @"line.3.horizontal", @"rectangle.leftthird.inset.filled", @"square.grid.2x2"]},
        @{@"key":@"top.search", @"title":@"搜索", @"default":@"lasso.badge.sparkles",
          @"candidates":@[@"lasso.badge.sparkles", @"magnifyingglass", @"sparkle.magnifyingglass", @"scope"]}
    ];
    if (section == 1) return @[
        @{@"key":@"right.like.normal", @"title":@"点赞 · 未选中", @"default":@"hand.thumbsup",
          @"candidates":@[@"hand.thumbsup", @"heart", @"heart.circle", @"hands.clap"]},
        @{@"key":@"right.like.selected", @"title":@"点赞 · 已选中", @"default":@"hand.thumbsup.fill",
          @"candidates":@[@"hand.thumbsup.fill", @"heart.fill", @"heart.circle.fill", @"hands.clap.fill"]},
        @{@"key":@"right.comment.normal", @"title":@"评论", @"default":@"quote.closing",
          @"candidates":@[@"quote.closing", @"bubble.left", @"ellipsis.message", @"text.bubble"]},
        @{@"key":@"right.favorite.normal", @"title":@"收藏 · 未选中", @"default":@"star",
          @"candidates":@[@"star", @"bookmark", @"heart", @"tray"]},
        @{@"key":@"right.favorite.selected", @"title":@"收藏 · 已选中", @"default":@"star.fill",
          @"candidates":@[@"star.fill", @"bookmark.fill", @"heart.fill", @"tray.fill"]},
        @{@"key":@"right.share.normal", @"title":@"分享", @"default":@"square.and.arrow.up",
          @"candidates":@[@"square.and.arrow.up", @"arrowshape.turn.up.right", @"paperplane", @"link"]}
    ];
    return @[
        @{@"key":@"bottom.home.normal", @"title":@"首页", @"default":@"sparkles",
          @"candidates":@[@"sparkles", @"house", @"house.fill", @"house.circle", @"play.rectangle"]},
        @{@"key":@"bottom.friends.normal", @"title":@"第二项·朋友", @"default":@"hands.and.sparkles",
          @"candidates":@[@"hands.and.sparkles", @"hands.and.sparkles.fill", @"person.2", @"person.2.fill", @"figure.2"]},
        @{@"key":@"bottom.shop.normal", @"title":@"第二项·商城", @"default":@"storefront",
          @"candidates":@[@"storefront", @"storefront.fill", @"bag", @"bag.fill", @"cart"]},
        @{@"key":@"bottom.publish.normal", @"title":@"发布", @"default":@"pencil.and.outline",
          @"candidates":@[@"pencil.and.outline", @"plus.circle.fill", @"plus", @"camera.fill"]},
        @{@"key":@"bottom.messages.normal", @"title":@"消息", @"default":@"ellipsis.message",
          @"candidates":@[@"ellipsis.message", @"ellipsis.message.fill", @"message", @"message.fill", @"envelope"]},
        @{@"key":@"bottom.profile.normal", @"title":@"我", @"default":@"touchid",
          @"candidates":@[@"touchid", @"person", @"person.fill", @"person.crop.circle", @"person.crop.circle.fill"]}
    ];
}

static NSArray<NSDictionary *> *AWENewBarIconDefinitions(void) {
    return @[
        @{@"key":@"newbar.home.normal", @"title":@"首页", @"default":@"photo.on.rectangle.angled",
          @"candidates":@[@"photo.on.rectangle.angled", @"sparkles", @"house", @"house.fill", @"play.rectangle"]},
        @{@"key":@"newbar.friends.normal", @"title":@"朋友", @"default":@"hands.and.sparkles",
          @"candidates":@[@"hands.and.sparkles", @"hands.and.sparkles.fill", @"person.2", @"person.2.fill", @"figure.2"]},
        @{@"key":@"newbar.shop.normal", @"title":@"商城", @"default":@"storefront",
          @"candidates":@[@"storefront", @"storefront.fill", @"bag", @"bag.fill", @"cart"]},
        @{@"key":@"newbar.publish.normal", @"title":@"发布", @"default":@"plus",
          @"candidates":@[@"plus", @"pencil.and.outline", @"plus.circle.fill", @"camera.fill"]},
        @{@"key":@"newbar.messages.normal", @"title":@"消息", @"default":@"message",
          @"candidates":@[@"message", @"message.fill", @"ellipsis.message", @"ellipsis.message.fill", @"envelope"]},
        @{@"key":@"newbar.profile.normal", @"title":@"我", @"default":@"person.crop.circle",
          @"candidates":@[@"person.crop.circle", @"person.crop.circle.fill", @"touchid", @"person", @"person.fill"]},
        @{@"key":@"newbar.search.normal", @"title":@"搜索", @"default":@"magnifyingglass",
          @"candidates":@[@"magnifyingglass", @"sparkle.magnifyingglass", @"scope", @"text.magnifyingglass"]}
    ];
}

static NSArray<NSString *> *AWEIconSectionTitles(void) {
    return @[@"顶部", @"右侧", @"旧底栏配置（不再用于显示）"];
}

static BOOL AWEIconDefinitionUsesUnifiedBottomColour(NSDictionary *definition) {
    NSString *key = [definition[@"key"] isKindOfClass:NSString.class]
        ? definition[@"key"] : @"";
    return [key hasPrefix:@"newbar."] || [key hasPrefix:@"bottom."];
}

static BOOL AWEIconDefinitionRepresentsSelectedState(NSDictionary *definition) {
    NSString *key = [definition[@"key"] isKindOfClass:NSString.class]
        ? definition[@"key"] : @"";
    return [key hasSuffix:@".selected"];
}

static void AWEClearStoredIconConfigurationForDefinitions(
    NSArray<NSDictionary *> *definitions) {
    NSMutableDictionary *overrides = [AWEStoredSymbolOverrides() mutableCopy]
        ?: [NSMutableDictionary dictionary];
    NSMutableDictionary *modes = [AWEStoredSymbolColorModes() mutableCopy]
        ?: [NSMutableDictionary dictionary];
    NSMutableDictionary *colours = [AWEStoredSymbolCustomColors() mutableCopy]
        ?: [NSMutableDictionary dictionary];
    for (NSDictionary *definition in definitions) {
        NSString *key = definition[@"key"];
        if (![key isKindOfClass:NSString.class] || !key.length) continue;
        [overrides removeObjectForKey:key];
        [modes removeObjectForKey:key];
        [colours removeObjectForKey:key];
    }
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setObject:overrides forKey:kAWESymbolOverridesDefaultsKey];
    [defaults setObject:modes forKey:kAWESymbolColorModesDefaultsKey];
    [defaults setObject:colours forKey:kAWESymbolCustomColorsDefaultsKey];
    [defaults synchronize];
}

@interface AWEIconCenterCell : UITableViewCell
@property(nonatomic, strong) UIView *previewPlate;
@property(nonatomic, strong) UIImageView *previewImage;
@property(nonatomic, strong) UILabel *roleLabel;
@property(nonatomic, strong) UILabel *detailLabel2;
@end

@implementation AWEIconCenterCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (!self) return nil;
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    _previewPlate = [UIView new];
    _previewPlate.translatesAutoresizingMaskIntoConstraints = NO;
    _previewPlate.backgroundColor = UIColor.tertiarySystemFillColor;
    _previewPlate.layer.cornerRadius = 12.0;
    _previewPlate.layer.cornerCurve = kCACornerCurveContinuous;
    _previewImage = [UIImageView new];
    _previewImage.translatesAutoresizingMaskIntoConstraints = NO;
    _previewImage.contentMode = UIViewContentModeScaleAspectFit;
    [_previewPlate addSubview:_previewImage];
    _roleLabel = [UILabel new];
    _roleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _roleLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    _roleLabel.numberOfLines = 1;
    _detailLabel2 = [UILabel new];
    _detailLabel2.translatesAutoresizingMaskIntoConstraints = NO;
    _detailLabel2.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    _detailLabel2.textColor = UIColor.secondaryLabelColor;
    _detailLabel2.numberOfLines = 1;
    UIStackView *labels = [[UIStackView alloc] initWithArrangedSubviews:@[_roleLabel, _detailLabel2]];
    labels.translatesAutoresizingMaskIntoConstraints = NO;
    labels.axis = UILayoutConstraintAxisVertical;
    labels.spacing = 3.0;
    [self.contentView addSubview:_previewPlate];
    [self.contentView addSubview:labels];
    [NSLayoutConstraint activateConstraints:@[
        [_previewPlate.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16.0],
        [_previewPlate.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [_previewPlate.widthAnchor constraintEqualToConstant:44.0],
        [_previewPlate.heightAnchor constraintEqualToConstant:44.0],
        [_previewImage.centerXAnchor constraintEqualToAnchor:_previewPlate.centerXAnchor],
        [_previewImage.centerYAnchor constraintEqualToAnchor:_previewPlate.centerYAnchor],
        [_previewImage.widthAnchor constraintEqualToConstant:25.0],
        [_previewImage.heightAnchor constraintEqualToConstant:25.0],
        [labels.leadingAnchor constraintEqualToAnchor:_previewPlate.trailingAnchor constant:14.0],
        [labels.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-10.0],
        [labels.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor]
    ]];
    return self;
}
@end

@class AWEIconEditorController;
@interface AWEIconCenterController : UITableViewController
@property(nonatomic, assign) BOOL newBarOnly;
- (instancetype)initWithNewBarOnly:(BOOL)newBarOnly;
@end

@interface AWEIconEditorController : UIViewController <UIColorPickerViewControllerDelegate, UITextFieldDelegate>
@property(nonatomic, strong) NSDictionary *definition;
@property(nonatomic, strong) UIImageView *previewImage;
@property(nonatomic, strong) UIView *previewPlate;
@property(nonatomic, strong) UITextField *symbolField;
@property(nonatomic, strong) UISegmentedControl *colorSegments;
@property(nonatomic, strong) UIButton *customColorButton;
@property(nonatomic, strong) UIColor *pendingCustomColor;
@property(nonatomic, assign) BOOL usesUnifiedBottomColour;
- (instancetype)initWithDefinition:(NSDictionary *)definition;
@end

@implementation AWEIconCenterController
- (instancetype)init {
    return [self initWithNewBarOnly:NO];
}
- (instancetype)initWithNewBarOnly:(BOOL)newBarOnly {
    self = [super initWithStyle:UITableViewStyleInsetGrouped];
    if (self) _newBarOnly = newBarOnly;
    return self;
}
- (NSArray<NSDictionary *> *)definitionsForSection:(NSInteger)section {
    return self.newBarOnly ? AWENewBarIconDefinitions()
                           : AWEIconDefinitionsForSection(section);
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.newBarOnly ? @"新底栏图标中心" : @"顶部与右侧图标中心";
    self.tableView.rowHeight = 72.0;
    self.tableView.estimatedRowHeight = 72.0;
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    [self.tableView registerClass:AWEIconCenterCell.class forCellReuseIdentifier:@"IconCell"];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:@"全部恢复" style:UIBarButtonItemStylePlain
              target:self action:@selector(resetAll:)];
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.newBarOnly ? 1 : 2;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)[self definitionsForSection:section].count;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.newBarOnly ? @"原生液态底栏" : AWEIconSectionTitles()[(NSUInteger)section];
}
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (self.newBarOnly && section == 0) {
        return [NSString stringWithFormat:@"第二项当前识别为“%@”；搜索按钮是否显示仍由底栏按钮配置决定。每个入口只使用一个图标，选中/未选中共用同一图形，状态仅由前景色/强调色表达。",
            AWESecondTabIsShop() ? @"商城" : @"朋友"];
    }
    return nil;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AWEIconCenterCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IconCell" forIndexPath:indexPath];
    NSDictionary *definition = [self definitionsForSection:indexPath.section][(NSUInteger)indexPath.row];
    NSString *key = definition[@"key"];
    NSString *fallback = definition[@"default"];
    NSString *name = AWEConfiguredSymbolName(key, fallback);
    cell.roleLabel.text = definition[@"title"];
    BOOL unifiedBottomColour = AWEIconDefinitionUsesUnifiedBottomColour(definition);
    if (unifiedBottomColour) {
        cell.detailLabel2.text = name;
    } else {
        NSString *colorName = @[@"自动", @"白", @"黑", @"强调色", @"自定义"][(NSUInteger)AWEStoredSymbolColorMode(key)];
        cell.detailLabel2.text = [NSString stringWithFormat:@"%@ · %@", name, colorName];
    }
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration
        configurationWithPointSize:22.0 weight:UIImageSymbolWeightMedium];
    UIImage *image = [[UIImage systemImageNamed:name] imageWithConfiguration:configuration];
    UIColor *previewColor = unifiedBottomColour
        ? (AWEIconDefinitionRepresentsSelectedState(definition)
            ? AWEStoredAccentColor() : UIColor.labelColor)
        : AWEApplyConfiguredIconColorMode(key, UIColor.labelColor);
    cell.previewImage.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.previewImage.tintColor = previewColor;
    AWEConfiguredIconColorMode mode = unifiedBottomColour
        ? AWEConfiguredIconColorModeAutomatic
        : AWEStoredSymbolColorMode(key);
    if (!unifiedBottomColour && mode == AWEConfiguredIconColorModeWhite) {
        cell.previewPlate.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    } else if (!unifiedBottomColour && mode == AWEConfiguredIconColorModeBlack) {
        cell.previewPlate.backgroundColor = [UIColor colorWithWhite:0.90 alpha:1.0];
    } else {
        cell.previewPlate.backgroundColor = UIColor.tertiarySystemFillColor;
    }
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *definition = [self definitionsForSection:indexPath.section][(NSUInteger)indexPath.row];
    AWEIconEditorController *editor = [[AWEIconEditorController alloc] initWithDefinition:definition];
    [self.navigationController pushViewController:editor animated:YES];
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}
- (void)resetAll:(id)sender {
    (void)sender;
    NSString *message = self.newBarOnly
        ? @"恢复新底栏所有图标名称。每个入口只有一个图标，强调色设置不会改变。"
        : @"恢复顶部与右侧所有 SF Symbols 名称、颜色模式和自定义颜色。透明 PNG 文件不会被删除。";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"恢复全部图标"
        message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"恢复" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        NSMutableArray<NSDictionary *> *definitions = [NSMutableArray array];
        if (self.newBarOnly) {
            [definitions addObjectsFromArray:AWENewBarIconDefinitions()];
        } else {
            [definitions addObjectsFromArray:AWEIconDefinitionsForSection(0)];
            [definitions addObjectsFromArray:AWEIconDefinitionsForSection(1)];
        }
        AWEClearStoredIconConfigurationForDefinitions(definitions);
        AWERefreshAllConfiguredIcons();
        [self.tableView reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end

@implementation AWEIconEditorController
- (instancetype)initWithDefinition:(NSDictionary *)definition {
    self = [super init];
    if (self) {
        _definition = definition;
        _usesUnifiedBottomColour =
            AWEIconDefinitionUsesUnifiedBottomColour(definition);
    }
    return self;
}
- (UILabel *)sectionLabel:(NSString *)text {
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    label.textColor = UIColor.labelColor;
    return label;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.definition[@"title"];
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    NSString *key = self.definition[@"key"];
    NSString *fallback = self.definition[@"default"];
    self.pendingCustomColor = AWEStoredSymbolCustomColor(key);

    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = YES;
    scroll.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    UIStackView *stack = [UIStackView new];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12.0;
    [self.view addSubview:scroll];
    [scroll addSubview:stack];
    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:guide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:20.0],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-20.0],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:18.0],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-24.0],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-40.0]
    ]];

    UIView *previewCard = [UIView new];
    previewCard.translatesAutoresizingMaskIntoConstraints = NO;
    previewCard.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    previewCard.layer.cornerRadius = 26.0;
    previewCard.layer.cornerCurve = kCACornerCurveContinuous;
    [previewCard.heightAnchor constraintEqualToConstant:150.0].active = YES;
    _previewPlate = [UIView new];
    _previewPlate.translatesAutoresizingMaskIntoConstraints = NO;
    _previewPlate.backgroundColor = UIColor.tertiarySystemFillColor;
    _previewPlate.layer.cornerRadius = 30.0;
    _previewPlate.layer.cornerCurve = kCACornerCurveContinuous;
    _previewImage = [UIImageView new];
    _previewImage.translatesAutoresizingMaskIntoConstraints = NO;
    _previewImage.contentMode = UIViewContentModeScaleAspectFit;
    [_previewPlate addSubview:_previewImage];
    [previewCard addSubview:_previewPlate];
    [NSLayoutConstraint activateConstraints:@[
        [_previewPlate.centerXAnchor constraintEqualToAnchor:previewCard.centerXAnchor],
        [_previewPlate.centerYAnchor constraintEqualToAnchor:previewCard.centerYAnchor],
        [_previewPlate.widthAnchor constraintEqualToConstant:96.0],
        [_previewPlate.heightAnchor constraintEqualToConstant:96.0],
        [_previewImage.centerXAnchor constraintEqualToAnchor:_previewPlate.centerXAnchor],
        [_previewImage.centerYAnchor constraintEqualToAnchor:_previewPlate.centerYAnchor],
        [_previewImage.widthAnchor constraintEqualToConstant:58.0],
        [_previewImage.heightAnchor constraintEqualToConstant:58.0]
    ]];
    [stack addArrangedSubview:previewCard];

    [stack addArrangedSubview:[self sectionLabel:@"SF Symbol 名称"]];
    _symbolField = [UITextField new];
    _symbolField.translatesAutoresizingMaskIntoConstraints = NO;
    _symbolField.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
    _symbolField.layer.cornerRadius = 14.0;
    _symbolField.layer.cornerCurve = kCACornerCurveContinuous;
    _symbolField.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightRegular];
    _symbolField.autocorrectionType = UITextAutocorrectionTypeNo;
    _symbolField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _symbolField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _symbolField.returnKeyType = UIReturnKeyDone;
    _symbolField.delegate = self;
    UIView *padding = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 14, 1)];
    _symbolField.leftView = padding;
    _symbolField.leftViewMode = UITextFieldViewModeAlways;
    _symbolField.text = AWEConfiguredSymbolName(key, fallback);
    [_symbolField.heightAnchor constraintEqualToConstant:48.0].active = YES;
    [_symbolField addTarget:self action:@selector(fieldChanged:) forControlEvents:UIControlEventEditingChanged];
    [stack addArrangedSubview:_symbolField];

    [stack addArrangedSubview:[self sectionLabel:@"常用图标"]];
    for (NSString *candidate in self.definition[@"candidates"]) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        button.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;
        button.layer.cornerRadius = 16.0;
        button.layer.cornerCurve = kCACornerCurveContinuous;
        button.accessibilityIdentifier = candidate;
        [button addTarget:self action:@selector(candidateTapped:)
         forControlEvents:UIControlEventTouchUpInside];

        UIView *iconPlate = [UIView new];
        iconPlate.translatesAutoresizingMaskIntoConstraints = NO;
        iconPlate.userInteractionEnabled = NO;
        iconPlate.backgroundColor = UIColor.tertiarySystemFillColor;
        iconPlate.layer.cornerRadius = 11.0;
        iconPlate.layer.cornerCurve = kCACornerCurveContinuous;

        UIImageView *candidateIcon = [UIImageView new];
        candidateIcon.translatesAutoresizingMaskIntoConstraints = NO;
        candidateIcon.userInteractionEnabled = NO;
        candidateIcon.contentMode = UIViewContentModeScaleAspectFit;
        candidateIcon.image = [[UIImage systemImageNamed:candidate]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        candidateIcon.tintColor = UIColor.labelColor;
        [iconPlate addSubview:candidateIcon];

        UILabel *candidateName = [UILabel new];
        candidateName.translatesAutoresizingMaskIntoConstraints = NO;
        candidateName.userInteractionEnabled = NO;
        candidateName.text = candidate;
        candidateName.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
        candidateName.textColor = UIColor.labelColor;
        candidateName.numberOfLines = 1;
        candidateName.adjustsFontSizeToFitWidth = YES;
        candidateName.minimumScaleFactor = 0.72;
        candidateName.lineBreakMode = NSLineBreakByTruncatingMiddle;

        [button addSubview:iconPlate];
        [button addSubview:candidateName];
        [NSLayoutConstraint activateConstraints:@[
            [button.heightAnchor constraintEqualToConstant:58.0],
            [iconPlate.leadingAnchor constraintEqualToAnchor:button.leadingAnchor constant:10.0],
            [iconPlate.centerYAnchor constraintEqualToAnchor:button.centerYAnchor],
            [iconPlate.widthAnchor constraintEqualToConstant:38.0],
            [iconPlate.heightAnchor constraintEqualToConstant:38.0],
            [candidateIcon.centerXAnchor constraintEqualToAnchor:iconPlate.centerXAnchor],
            [candidateIcon.centerYAnchor constraintEqualToAnchor:iconPlate.centerYAnchor],
            [candidateIcon.widthAnchor constraintEqualToConstant:23.0],
            [candidateIcon.heightAnchor constraintEqualToConstant:23.0],
            [candidateName.leadingAnchor constraintEqualToAnchor:iconPlate.trailingAnchor constant:12.0],
            [candidateName.trailingAnchor constraintEqualToAnchor:button.trailingAnchor constant:-14.0],
            [candidateName.centerYAnchor constraintEqualToAnchor:button.centerYAnchor]
        ]];
        [stack addArrangedSubview:button];
    }

    if (self.usesUnifiedBottomColour) {
        UILabel *colourHint = [self sectionLabel:
            AWEIconDefinitionRepresentsSelectedState(self.definition)
                ? @"颜色由全局强调色统一控制"
                : @"未选中颜色由系统材质自动控制"];
        colourHint.textColor = UIColor.secondaryLabelColor;
        [stack addArrangedSubview:colourHint];
    } else {
        [stack addArrangedSubview:[self sectionLabel:@"图标颜色"]];
        _colorSegments = [[UISegmentedControl alloc] initWithItems:@[@"自动", @"白", @"黑", @"强调", @"自定"]];
        _colorSegments.selectedSegmentIndex = AWEStoredSymbolColorMode(key);
        [_colorSegments addTarget:self action:@selector(colorModeChanged:) forControlEvents:UIControlEventValueChanged];
        [_colorSegments.heightAnchor constraintEqualToConstant:38.0].active = YES;
        [stack addArrangedSubview:_colorSegments];

        _customColorButton = AWECreateGlassTextButton(@"选择自定义颜色", self.pendingCustomColor, YES);
        [_customColorButton addTarget:self action:@selector(openCustomColor:) forControlEvents:UIControlEventTouchUpInside];
        [stack addArrangedSubview:_customColorButton];
    }

    UIButton *apply = AWECreateGlassTextButton(@"应用并立即刷新", AWEStoredAccentColor(), YES);
    [apply addTarget:self action:@selector(applyChanges:) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:apply];
    UIButton *reset = AWECreateGlassTextButton(@"恢复该项默认", UIColor.systemGrayColor, NO);
    [reset addTarget:self action:@selector(resetCurrent:) forControlEvents:UIControlEventTouchUpInside];
    [stack addArrangedSubview:reset];
    [self updatePreview];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField { [textField resignFirstResponder]; return YES; }
- (void)fieldChanged:(UITextField *)field { (void)field; [self updatePreview]; }
- (void)candidateTapped:(UIButton *)button {
    self.symbolField.text = button.accessibilityIdentifier;
    [self updatePreview];
}
- (void)colorModeChanged:(UISegmentedControl *)sender {
    if (self.usesUnifiedBottomColour) return;
    self.customColorButton.hidden = sender.selectedSegmentIndex != AWEConfiguredIconColorModeCustom;
    [self updatePreview];
}
- (void)openCustomColor:(id)sender {
    (void)sender;
    UIColorPickerViewController *picker = [UIColorPickerViewController new];
    picker.delegate = self;
    picker.supportsAlpha = NO;
    picker.selectedColor = self.pendingCustomColor ?: AWEStoredAccentColor();
    picker.title = @"选择图标颜色";
    [self presentViewController:picker animated:YES completion:nil];
}
- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)viewController {
    self.pendingCustomColor = viewController.selectedColor;
    AWEConfigureGlassTextButton(self.customColorButton, @"选择自定义颜色", self.pendingCustomColor, YES);
    [self updatePreview];
}
- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController {
    self.pendingCustomColor = viewController.selectedColor ?: self.pendingCustomColor;
    AWEConfigureGlassTextButton(self.customColorButton, @"选择自定义颜色", self.pendingCustomColor, YES);
    [self updatePreview];
}
- (UIColor *)previewColor {
    if (self.usesUnifiedBottomColour) {
        return AWEIconDefinitionRepresentsSelectedState(self.definition)
            ? AWEStoredAccentColor() : UIColor.labelColor;
    }
    switch (self.colorSegments.selectedSegmentIndex) {
        case AWEConfiguredIconColorModeWhite: return UIColor.whiteColor;
        case AWEConfiguredIconColorModeBlack: return UIColor.blackColor;
        case AWEConfiguredIconColorModeAccent: return AWEStoredAccentColor();
        case AWEConfiguredIconColorModeCustom: return self.pendingCustomColor ?: AWEStoredAccentColor();
        default: return UIColor.labelColor;
    }
}
- (void)updatePreview {
    NSString *name = [self.symbolField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration
        configurationWithPointSize:54.0 weight:UIImageSymbolWeightMedium];
    UIImage *image = [[UIImage systemImageNamed:name] imageWithConfiguration:configuration];
    self.previewImage.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.previewImage.tintColor = [self previewColor];
    BOOL whiteMode = !self.usesUnifiedBottomColour &&
        self.colorSegments.selectedSegmentIndex == AWEConfiguredIconColorModeWhite;
    self.previewPlate.backgroundColor = whiteMode
        ? [UIColor colorWithWhite:0.12 alpha:1.0]
        : UIColor.tertiarySystemFillColor;
    if (self.customColorButton) {
        self.customColorButton.hidden = self.colorSegments.selectedSegmentIndex !=
            AWEConfiguredIconColorModeCustom;
    }
}
- (void)applyChanges:(id)sender {
    (void)sender;
    NSString *key = self.definition[@"key"];
    NSString *fallback = self.definition[@"default"];
    NSString *name = [self.symbolField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!AWESystemSymbolNameIsValid(name)) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"图标名称无效"
            message:@"当前系统找不到这个 SF Symbol。请检查拼写，或选择下方常用图标。"
            preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    AWESetStoredSymbolOverride(key, [name isEqualToString:fallback] ? @"" : name);
    if (self.usesUnifiedBottomColour) {
        /* Bottom bar foregrounds are owned globally by system/adaptive and
           accent colours; remove stale per-icon colour settings. */
        AWESetStoredSymbolColorMode(key, AWEConfiguredIconColorModeAutomatic);
        AWESetStoredSymbolCustomColor(key, nil);
    } else {
        AWESetStoredSymbolColorMode(key,
            (AWEConfiguredIconColorMode)self.colorSegments.selectedSegmentIndex);
        if (self.colorSegments.selectedSegmentIndex ==
            AWEConfiguredIconColorModeCustom) {
            AWESetStoredSymbolCustomColor(key, self.pendingCustomColor);
        }
    }
    AWERefreshAllConfiguredIcons();
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
}
- (void)resetCurrent:(id)sender {
    (void)sender;
    NSString *key = self.definition[@"key"];
    AWESetStoredSymbolOverride(key, @"");
    AWESetStoredSymbolColorMode(key, AWEConfiguredIconColorModeAutomatic);
    AWESetStoredSymbolCustomColor(key, nil);
    self.symbolField.text = self.definition[@"default"];
    if (self.colorSegments) {
        self.colorSegments.selectedSegmentIndex = AWEConfiguredIconColorModeAutomatic;
    }
    AWERefreshAllConfiguredIcons();
    [self updatePreview];
}
@end


@interface AWEAlbumMorphButtonSettingsController : UITableViewController
@property(nonatomic, strong) NSMutableArray<NSString *> *orderedIdentifiers;
@property(nonatomic, strong) NSMutableSet<NSString *> *enabledIdentifiers;
@end

@implementation AWEAlbumMorphButtonSettingsController

- (instancetype)init {
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"新底栏按钮";
    self.tableView.backgroundColor = UIColor.systemGroupedBackgroundColor;
    self.orderedIdentifiers = [AWEStoredAlbumMorphItemOrder() mutableCopy];
    self.enabledIdentifiers = [AWEStoredAlbumMorphEnabledItemIdentifiers() mutableCopy];
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return (NSInteger)self.orderedIdentifiers.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return @"显示与顺序";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    (void)tableView; (void)section;
    return @"最多开启五个底栏入口；当已开启五个时，其余开关会自动变灰。至少保留两个页面按钮。点右上角“编辑”可拖动普通按钮；搜索始终固定为右侧独立圆钮。";
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *reuse = @"AlbumMorphButtonCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuse];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:reuse];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }

    NSString *identifier = self.orderedIdentifiers[(NSUInteger)indexPath.row];
    cell.textLabel.text = AWEAlbumMorphItemTitle(identifier);
    cell.detailTextLabel.text = AWEAlbumMorphItemDetail(identifier);
    cell.imageView.image = [UIImage systemImageNamed:AWEAlbumMorphItemSymbol(identifier)];

    UISwitch *toggle = [UISwitch new];
    BOOL currentlyEnabled = [self.enabledIdentifiers containsObject:identifier];
    BOOL canEnable = currentlyEnabled || self.enabledIdentifiers.count < 5;
    toggle.on = currentlyEnabled;
    toggle.enabled = canEnable;
    toggle.onTintColor = AWEStoredAccentColor();
    toggle.accessibilityIdentifier = identifier;
    [toggle addTarget:self action:@selector(itemSwitchChanged:)
      forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = toggle;
    cell.showsReorderControl = ![identifier isEqualToString:@"search"];
    if (@available(iOS 13.0, *)) {
        cell.textLabel.textColor = canEnable ? UIColor.labelColor : UIColor.tertiaryLabelColor;
        cell.detailTextLabel.textColor = canEnable ? UIColor.secondaryLabelColor : UIColor.tertiaryLabelColor;
        cell.imageView.tintColor = canEnable ? UIColor.labelColor : UIColor.tertiaryLabelColor;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    (void)tableView;
    NSString *identifier = self.orderedIdentifiers[(NSUInteger)indexPath.row];
    return ![identifier isEqualToString:@"search"];
}

- (NSIndexPath *)tableView:(UITableView *)tableView
 targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
       toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    (void)tableView; (void)sourceIndexPath;
    NSInteger searchIndex = [self.orderedIdentifiers indexOfObject:@"search"];
    if (searchIndex != NSNotFound && proposedDestinationIndexPath.row >= searchIndex) {
        return [NSIndexPath indexPathForRow:MAX(0, searchIndex - 1) inSection:0];
    }
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView
 moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath
        toIndexPath:(NSIndexPath *)destinationIndexPath {
    (void)tableView;
    NSString *identifier = self.orderedIdentifiers[(NSUInteger)sourceIndexPath.row];
    [self.orderedIdentifiers removeObjectAtIndex:(NSUInteger)sourceIndexPath.row];
    NSUInteger destination = MIN((NSUInteger)destinationIndexPath.row,
                                 self.orderedIdentifiers.count);
    [self.orderedIdentifiers insertObject:identifier atIndex:destination];
    [self normalizeSearchPosition];
    [self persistAndApply];
}

- (void)normalizeSearchPosition {
    if ([self.orderedIdentifiers containsObject:@"search"] &&
        ![[self.orderedIdentifiers lastObject] isEqualToString:@"search"]) {
        [self.orderedIdentifiers removeObject:@"search"];
        [self.orderedIdentifiers addObject:@"search"];
    }
}

- (NSUInteger)enabledSelectablePageCount {
    NSUInteger count = 0;
    for (NSString *identifier in self.enabledIdentifiers) {
        if (AWEAlbumMorphItemIsSelectablePage(identifier)) count++;
    }
    return count;
}

- (void)itemSwitchChanged:(UISwitch *)sender {
    NSString *identifier = sender.accessibilityIdentifier;
    if (!identifier.length) return;

    if (sender.isOn) {
        if (![self.enabledIdentifiers containsObject:identifier] &&
            self.enabledIdentifiers.count >= 5) {
            sender.on = NO;
            UINotificationFeedbackGenerator *feedback = [UINotificationFeedbackGenerator new];
            [feedback notificationOccurred:UINotificationFeedbackTypeWarning];
            UIAlertController *alert = [UIAlertController
                alertControllerWithTitle:@"最多开启五个入口"
                message:@"请先关闭一个已经启用的底栏入口，再开启当前项目。"
                preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"知道了"
                style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            [self.tableView reloadData];
            return;
        }
        [self.enabledIdentifiers addObject:identifier];
    } else {
        [self.enabledIdentifiers removeObject:identifier];
        if (AWEAlbumMorphItemIsSelectablePage(identifier) &&
            [self enabledSelectablePageCount] < 2) {
            [self.enabledIdentifiers addObject:identifier];
            sender.on = YES;
            UINotificationFeedbackGenerator *feedback = [UINotificationFeedbackGenerator new];
            [feedback notificationOccurred:UINotificationFeedbackTypeWarning];
            UIAlertController *alert = [UIAlertController
                alertControllerWithTitle:@"至少保留两个页面按钮"
                message:@"首页、朋友／商城、消息、我中至少需要开启两个，发布和搜索不计入页面按钮。"
                preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"知道了"
                style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
    }

    [self persistAndApply];
    [self.tableView reloadData];
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)persistAndApply {
    [self normalizeSearchPosition];
    AWESaveAlbumMorphItemConfiguration(self.orderedIdentifiers,
                                        self.enabledIdentifiers);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

@end

@interface AWELiquidSettingsController : UIViewController <UIColorPickerViewControllerDelegate>
@property (nonatomic, retain) UIView *previewView;
@property (nonatomic, retain) UIButton *applyButton;
@property (nonatomic, retain) UIColor *pendingAccentColor;
@property (nonatomic, retain) NSArray<UIView *> *themeCards;
@property (nonatomic, retain) NSArray<UILabel *> *themePrimaryLabels;
@property (nonatomic, retain) NSArray<UILabel *> *themeSecondaryLabels;
@property (nonatomic, retain) UISwitch *lowerHalfCommentSwitch;
@property (nonatomic, retain) UISwitch *settingsGestureMineOnlySwitch;
@property (nonatomic, retain) UISlider *verticalOffsetSlider;
@property (nonatomic, retain) UILabel *verticalOffsetValueLabel;
@property (nonatomic, retain) UISwitch *collapseSwitch;
@property (nonatomic, retain) UISlider *doubleTapSplitSlider;
@property (nonatomic, retain) UILabel *doubleTapSplitValueLabel;
@property (nonatomic, retain) UISwitch *wanToWSwitch;
@property (nonatomic, retain) UISwitch *customPNGModeSwitch;
@property (nonatomic, retain) UISwitch *topGlassSwitch;
@property (nonatomic, retain) UISwitch *hideTopLeftButtonSwitch;
@property (nonatomic, retain) UISwitch *topCategoryGroupSwitch;
@property (nonatomic, retain) UISegmentedControl *topCategoryVisibleCountControl;
@property (nonatomic, retain) UISwitch *topMenuMorphSwitch;
@property (nonatomic, retain) UISwitch *transparentGlassSwitch;
@property (nonatomic, retain) UISwitch *albumMorphStyleSwitch;
@property (nonatomic, retain) UISwitch *hideBottomTitlesSwitch;
@property (nonatomic, retain) UISwitch *bottomBarDisplaySwitch;
@property (nonatomic, retain) UISwitch *internalFullscreenSwitch;
@property (nonatomic, retain) UISwitch *messageBadgeSwitch;
@property (nonatomic, retain) UISwitch *avatarMenuDownloadSwitch;
@property (nonatomic, retain) UISwitch *preferHighestPlaybackSwitch;
@property (nonatomic, retain) UISwitch *forceDarkBottomBarSwitch;
@property (nonatomic, retain) UISwitch *chatCapsuleSwitch;
@property (nonatomic, retain) UISwitch *chatSeparateLeftSwitch;
@property (nonatomic, retain) UISwitch *masterSwitch;
@property (nonatomic, retain) UISwitch *interactionDiagnosticSwitch;
@property (nonatomic, retain) UILabel *authorizationFooter;
@property (nonatomic, retain) NSTimer *systemThemeTimer;
@property (nonatomic, assign) UIUserInterfaceStyle lastAppliedSystemStyle;
- (void)applyCurrentTheme;
- (void)updateApplyButtonTint:(UIColor *)colour;
- (void)refreshAuthorizationUI;
- (void)manualAuthorizationCheck:(UIButton *)sender;
@end

@implementation AWELiquidSettingsController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"LiquidBar 设置 · 1.0.56c13";
    if (@available(iOS 13.0, *)) {
        self.view.backgroundColor = UIColor.systemGroupedBackgroundColor;
    } else {
        self.view.backgroundColor = UIColor.whiteColor;
    }

    BOOL nativeSettingsPush =
        [objc_getAssociatedObject(self, &kAWELiquidSettingsNativePushKey) boolValue];
    if (!nativeSettingsPush) {
        self.navigationItem.rightBarButtonItem =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                         target:self
                                                         action:@selector(closeSettings)];
    }

    self.pendingAccentColor = AWEStoredAccentColor();

    UIView *masterCard = [UIView new];
    masterCard.translatesAutoresizingMaskIntoConstraints = NO;
    masterCard.layer.cornerRadius = 24.0;
    masterCard.layer.cornerCurve = kCACornerCurveContinuous;
    masterCard.clipsToBounds = YES;
    masterCard.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;

    UILabel *masterTitle = [UILabel new];
    masterTitle.text = @"LiquidBar 总开关";
    masterTitle.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];

    UISwitch *masterSwitch = [UISwitch new];
    masterSwitch.onTintColor = AWEStoredAccentColor();
    [masterSwitch addTarget:self action:@selector(masterSwitchChanged:)
           forControlEvents:UIControlEventValueChanged];
    self.masterSwitch = masterSwitch;

    UIButton *albumButtonsButton = AWECreateGlassTextButton(
        @"调整底栏按钮布局", AWEStoredAccentColor(), YES);
    [albumButtonsButton addTarget:self
                           action:@selector(openAlbumMorphButtonSettings:)
                 forControlEvents:UIControlEventTouchUpInside];

    UIStackView *masterRow = [[UIStackView alloc] initWithArrangedSubviews:@[masterTitle, masterSwitch]];
    masterRow.axis = UILayoutConstraintAxisHorizontal;
    masterRow.alignment = UIStackViewAlignmentCenter;
    masterRow.spacing = 12.0;

    UIButton *authorizationCheckButton =
        AWECreateGlassTextButton(@"重新检测授权", UIColor.systemGrayColor, NO);
    [authorizationCheckButton addTarget:self
                                 action:@selector(manualAuthorizationCheck:)
                       forControlEvents:UIControlEventTouchUpInside];

    UIStackView *masterStack = [[UIStackView alloc]
        initWithArrangedSubviews:@[masterRow, albumButtonsButton]];
    masterStack.translatesAutoresizingMaskIntoConstraints = NO;
    masterStack.axis = UILayoutConstraintAxisVertical;
    masterStack.spacing = 10.0;
    [masterCard addSubview:masterStack];
    [NSLayoutConstraint activateConstraints:@[
        [masterStack.leadingAnchor constraintEqualToAnchor:masterCard.leadingAnchor constant:14.0],
        [masterStack.trailingAnchor constraintEqualToAnchor:masterCard.trailingAnchor constant:-14.0],
        [masterStack.topAnchor constraintEqualToAnchor:masterCard.topAnchor constant:14.0],
        [masterStack.bottomAnchor constraintEqualToAnchor:masterCard.bottomAnchor constant:-14.0]
    ]];

    UIView *accentCard = [UIView new];
    accentCard.translatesAutoresizingMaskIntoConstraints = NO;
    accentCard.layer.cornerRadius = 24.0;
    accentCard.layer.cornerCurve = kCACornerCurveContinuous;
    accentCard.clipsToBounds = YES;
    accentCard.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;

    UILabel *headline = [UILabel new];
    headline.text = @"强调色";
    headline.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];

    UIView *preview = [UIView new];
    preview.translatesAutoresizingMaskIntoConstraints = NO;
    preview.backgroundColor = self.pendingAccentColor;
    preview.layer.cornerRadius = 18.0;
    preview.layer.cornerCurve = kCACornerCurveContinuous;
    preview.layer.borderWidth = 1.0;
    preview.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.24].CGColor;
    [NSLayoutConstraint activateConstraints:@[
        [preview.widthAnchor constraintEqualToConstant:36.0],
        [preview.heightAnchor constraintEqualToConstant:36.0]
    ]];
    self.previewView = preview;

    UIButton *pickerButton = AWECreateGlassTextButton(@"调色盘", UIColor.systemGrayColor, NO);
    [pickerButton addTarget:self action:@selector(openAccentPicker:)
           forControlEvents:UIControlEventTouchUpInside];

    UIButton *applyButton = AWECreateGlassTextButton(@"确认并应用", self.pendingAccentColor, YES);
    [applyButton addTarget:self action:@selector(confirmAccentColor:)
          forControlEvents:UIControlEventTouchUpInside];
    self.applyButton = applyButton;

    UIStackView *accentRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[preview, pickerButton, applyButton]];
    accentRow.axis = UILayoutConstraintAxisHorizontal;
    accentRow.alignment = UIStackViewAlignmentCenter;
    accentRow.spacing = 8.0;

    // Activate sibling constraints only after both buttons belong to the same
    // stack-view hierarchy. Activating this before accentRow exists raises
    // NSGenericException (anchors have no common ancestor).
    [pickerButton.widthAnchor constraintEqualToAnchor:applyButton.widthAnchor].active = YES;

    UIStackView *accentStack = [[UIStackView alloc]
        initWithArrangedSubviews:@[headline, accentRow]];
    accentStack.translatesAutoresizingMaskIntoConstraints = NO;
    accentStack.axis = UILayoutConstraintAxisVertical;
    accentStack.spacing = 10.0;
    [accentCard addSubview:accentStack];
    [NSLayoutConstraint activateConstraints:@[
        [accentStack.leadingAnchor constraintEqualToAnchor:accentCard.leadingAnchor constant:14.0],
        [accentStack.trailingAnchor constraintEqualToAnchor:accentCard.trailingAnchor constant:-14.0],
        [accentStack.topAnchor constraintEqualToAnchor:accentCard.topAnchor constant:14.0],
        [accentStack.bottomAnchor constraintEqualToAnchor:accentCard.bottomAnchor constant:-14.0]
    ]];

    UIView *positionCard = [UIView new];
    positionCard.translatesAutoresizingMaskIntoConstraints = NO;
    positionCard.layer.cornerRadius = 24.0;
    positionCard.layer.cornerCurve = kCACornerCurveContinuous;
    positionCard.clipsToBounds = YES;
    if (@available(iOS 13.0, *)) {
        positionCard.backgroundColor =
            UIColor.secondarySystemGroupedBackgroundColor;
    } else {
        positionCard.backgroundColor =
            [UIColor colorWithWhite:0.94 alpha:1.0];
    }

    UILabel *positionTitle = [UILabel new];
    positionTitle.text = @"底栏垂直位置";
    positionTitle.font =
        [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];

    UILabel *positionValue = [UILabel new];
    positionValue.font =
        [UIFont monospacedDigitSystemFontOfSize:13.0 weight:UIFontWeightMedium];
    positionValue.textColor = UIColor.secondaryLabelColor;
    self.verticalOffsetValueLabel = positionValue;

    UISlider *positionSlider = [UISlider new];
    positionSlider.minimumValue = -24.0;
    positionSlider.maximumValue = 80.0;
    positionSlider.value = AWEStoredVerticalOffset();
    positionSlider.minimumTrackTintColor = AWEStoredAccentColor();
    [positionSlider addTarget:self
                       action:@selector(verticalOffsetSliderChanged:)
             forControlEvents:UIControlEventValueChanged];
    self.verticalOffsetSlider = positionSlider;

    UIStackView *positionStack =
        [[UIStackView alloc] initWithArrangedSubviews:@[
            positionTitle, positionValue, positionSlider
        ]];
    positionStack.translatesAutoresizingMaskIntoConstraints = NO;
    positionStack.axis = UILayoutConstraintAxisVertical;
    positionStack.spacing = 7.0;
    [positionCard addSubview:positionStack];
    [NSLayoutConstraint activateConstraints:@[
        [positionStack.leadingAnchor
            constraintEqualToAnchor:positionCard.leadingAnchor constant:14.0],
        [positionStack.trailingAnchor
            constraintEqualToAnchor:positionCard.trailingAnchor constant:-14.0],
        [positionStack.topAnchor
            constraintEqualToAnchor:positionCard.topAnchor constant:14.0],
        [positionStack.bottomAnchor
            constraintEqualToAnchor:positionCard.bottomAnchor constant:-14.0]
    ]];

    UIView *gestureCard = [UIView new];
    gestureCard.translatesAutoresizingMaskIntoConstraints = NO;
    gestureCard.layer.cornerRadius = 24.0;
    gestureCard.layer.cornerCurve = kCACornerCurveContinuous;
    gestureCard.clipsToBounds = YES;
    if (@available(iOS 13.0, *)) {
        gestureCard.backgroundColor =
            UIColor.secondarySystemGroupedBackgroundColor;
    } else {
        gestureCard.backgroundColor =
            [UIColor colorWithWhite:0.94 alpha:1.0];
    }

    UILabel *gestureTitle = [UILabel new];
    gestureTitle.text = @"分区双击";
    gestureTitle.font =
        [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];

    UIStackView *gestureTextStack =
        [[UIStackView alloc] initWithArrangedSubviews:@[
            gestureTitle
        ]];
    gestureTextStack.axis = UILayoutConstraintAxisVertical;
    gestureTextStack.spacing = 4.0;

    UISwitch *gestureSwitch = [UISwitch new];
    gestureSwitch.on =
        [[NSUserDefaults standardUserDefaults]
            boolForKey:kAWELowerHalfDoubleTapCommentDefaultsKey];
    gestureSwitch.onTintColor = AWEStoredAccentColor();
    [gestureSwitch addTarget:self
                      action:@selector(lowerHalfCommentSwitchChanged:)
            forControlEvents:UIControlEventValueChanged];
    self.lowerHalfCommentSwitch = gestureSwitch;

    UIStackView *gestureHeader =
        [[UIStackView alloc] initWithArrangedSubviews:@[
            gestureTextStack, gestureSwitch
        ]];
    gestureHeader.axis = UILayoutConstraintAxisHorizontal;
    gestureHeader.alignment = UIStackViewAlignmentCenter;
    gestureHeader.spacing = 12.0;

    UILabel *splitValue = [UILabel new];
    splitValue.font =
        [UIFont monospacedDigitSystemFontOfSize:13.0 weight:UIFontWeightMedium];
    splitValue.textColor = UIColor.secondaryLabelColor;
    self.doubleTapSplitValueLabel = splitValue;

    UISlider *splitSlider = [UISlider new];
    splitSlider.minimumValue = 0.20;
    splitSlider.maximumValue = 0.80;
    splitSlider.value = AWEStoredDoubleTapLikeFraction();
    splitSlider.minimumTrackTintColor = AWEStoredAccentColor();
    splitSlider.enabled = gestureSwitch.isOn;
    [splitSlider addTarget:self
                    action:@selector(doubleTapSplitSliderChanged:)
          forControlEvents:UIControlEventValueChanged];
    self.doubleTapSplitSlider = splitSlider;

    UILabel *settingsGestureMineOnlyLabel = [UILabel new];
    settingsGestureMineOnlyLabel.text = @"双指长按仅在‘我’页面触发（未启用‘我’时自动全局兜底）";
    settingsGestureMineOnlyLabel.font =
        [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    UISwitch *settingsGestureMineOnlySwitch = [UISwitch new];
    settingsGestureMineOnlySwitch.on = AWESettingsGestureMineOnlyEnabled();
    settingsGestureMineOnlySwitch.onTintColor = AWEStoredAccentColor();
    [settingsGestureMineOnlySwitch addTarget:self
        action:@selector(settingsGestureMineOnlySwitchChanged:)
        forControlEvents:UIControlEventValueChanged];
    self.settingsGestureMineOnlySwitch = settingsGestureMineOnlySwitch;
    UIStackView *settingsGestureMineOnlyRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[settingsGestureMineOnlyLabel,
                                  settingsGestureMineOnlySwitch]];
    settingsGestureMineOnlyRow.axis = UILayoutConstraintAxisHorizontal;
    settingsGestureMineOnlyRow.alignment = UIStackViewAlignmentCenter;
    settingsGestureMineOnlyRow.distribution = UIStackViewDistributionEqualSpacing;

    UIStackView *gestureStack =
        [[UIStackView alloc] initWithArrangedSubviews:@[
            gestureHeader, splitValue, splitSlider, settingsGestureMineOnlyRow
        ]];
    gestureStack.translatesAutoresizingMaskIntoConstraints = NO;
    gestureStack.axis = UILayoutConstraintAxisVertical;
    gestureStack.spacing = 9.0;
    [gestureCard addSubview:gestureStack];
    [NSLayoutConstraint activateConstraints:@[
        [gestureStack.leadingAnchor
            constraintEqualToAnchor:gestureCard.leadingAnchor constant:14.0],
        [gestureStack.trailingAnchor
            constraintEqualToAnchor:gestureCard.trailingAnchor constant:-14.0],
        [gestureStack.topAnchor
            constraintEqualToAnchor:gestureCard.topAnchor constant:14.0],
        [gestureStack.bottomAnchor
            constraintEqualToAnchor:gestureCard.bottomAnchor constant:-14.0]
    ]];

    UIView *chatCard = [UIView new];
    chatCard.translatesAutoresizingMaskIntoConstraints = NO;
    chatCard.layer.cornerRadius = 24.0;
    chatCard.layer.cornerCurve = kCACornerCurveContinuous;
    chatCard.clipsToBounds = YES;
    if (@available(iOS 13.0, *)) {
        chatCard.backgroundColor =
            UIColor.secondarySystemGroupedBackgroundColor;
    } else {
        chatCard.backgroundColor =
            [UIColor colorWithWhite:0.94 alpha:1.0];
    }

    UILabel *chatTitle = [UILabel new];
    chatTitle.text = @"聊天输入框（实验）";
    chatTitle.font =
        [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];

    UILabel *capsuleLabel = [UILabel new];
    capsuleLabel.text = @"启用圆角胶囊";
    capsuleLabel.font =
        [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];

    UISwitch *capsuleSwitch = [UISwitch new];
    capsuleSwitch.on = AWEChatCapsuleEnabled();
    capsuleSwitch.onTintColor = AWEStoredAccentColor();
    [capsuleSwitch addTarget:self
                      action:@selector(chatCapsuleSwitchChanged:)
            forControlEvents:UIControlEventValueChanged];
    self.chatCapsuleSwitch = capsuleSwitch;

    UIStackView *capsuleRow =
        [[UIStackView alloc] initWithArrangedSubviews:@[
            capsuleLabel, capsuleSwitch
        ]];
    capsuleRow.axis = UILayoutConstraintAxisHorizontal;
    capsuleRow.alignment = UIStackViewAlignmentCenter;
    capsuleRow.distribution = UIStackViewDistributionEqualSpacing;

    UILabel *separateLabel = [UILabel new];
    separateLabel.text = @"左侧按钮与背景分离";
    separateLabel.font =
        [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];

    UISwitch *separateSwitch = [UISwitch new];
    separateSwitch.on = AWEChatSeparateLeftEnabled();
    separateSwitch.enabled = capsuleSwitch.isOn;
    separateSwitch.onTintColor = AWEStoredAccentColor();
    [separateSwitch addTarget:self
                       action:@selector(chatSeparateLeftSwitchChanged:)
             forControlEvents:UIControlEventValueChanged];
    self.chatSeparateLeftSwitch = separateSwitch;

    UIStackView *separateRow =
        [[UIStackView alloc] initWithArrangedSubviews:@[
            separateLabel, separateSwitch
        ]];
    separateRow.axis = UILayoutConstraintAxisHorizontal;
    separateRow.alignment = UIStackViewAlignmentCenter;
    separateRow.distribution = UIStackViewDistributionEqualSpacing;

    UIStackView *chatStack =
        [[UIStackView alloc] initWithArrangedSubviews:@[
            chatTitle, capsuleRow, separateRow
        ]];
    chatStack.translatesAutoresizingMaskIntoConstraints = NO;
    chatStack.axis = UILayoutConstraintAxisVertical;
    chatStack.spacing = 10.0;

    [chatCard addSubview:chatStack];
    [NSLayoutConstraint activateConstraints:@[
        [chatStack.leadingAnchor
            constraintEqualToAnchor:chatCard.leadingAnchor constant:14.0],
        [chatStack.trailingAnchor
            constraintEqualToAnchor:chatCard.trailingAnchor constant:-14.0],
        [chatStack.topAnchor
            constraintEqualToAnchor:chatCard.topAnchor constant:14.0],
        [chatStack.bottomAnchor
            constraintEqualToAnchor:chatCard.bottomAnchor constant:-14.0]
    ]];

    UIView *wanCard = [UIView new];
    wanCard.translatesAutoresizingMaskIntoConstraints = NO;
    wanCard.layer.cornerRadius = 24.0;
    wanCard.layer.cornerCurve = kCACornerCurveContinuous;
    wanCard.clipsToBounds = YES;
    if (@available(iOS 13.0, *)) {
        wanCard.backgroundColor =
            UIColor.secondarySystemGroupedBackgroundColor;
    } else {
        wanCard.backgroundColor =
            [UIColor colorWithWhite:0.94 alpha:1.0];
    }

    UILabel *wanTitle = [UILabel new];
    wanTitle.text = @"数字计数：万 → W";
    wanTitle.font =
        [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];

    UIStackView *wanTextStack =
        [[UIStackView alloc] initWithArrangedSubviews:@[
            wanTitle
        ]];
    wanTextStack.axis = UILayoutConstraintAxisVertical;
    wanTextStack.spacing = 4.0;

    UISwitch *wanSwitch = [UISwitch new];
    wanSwitch.on = AWEWanToWEnabled();
    wanSwitch.onTintColor = AWEStoredAccentColor();
    [wanSwitch addTarget:self
                  action:@selector(wanToWSwitchChanged:)
        forControlEvents:UIControlEventValueChanged];
    self.wanToWSwitch = wanSwitch;

    UIStackView *wanRow =
        [[UIStackView alloc] initWithArrangedSubviews:@[
            wanTextStack, wanSwitch
        ]];
    wanRow.translatesAutoresizingMaskIntoConstraints = NO;
    wanRow.axis = UILayoutConstraintAxisHorizontal;
    wanRow.alignment = UIStackViewAlignmentCenter;
    wanRow.spacing = 12.0;
    [wanCard addSubview:wanRow];
    [NSLayoutConstraint activateConstraints:@[
        [wanRow.leadingAnchor
            constraintEqualToAnchor:wanCard.leadingAnchor constant:14.0],
        [wanRow.trailingAnchor
            constraintEqualToAnchor:wanCard.trailingAnchor constant:-14.0],
        [wanRow.topAnchor
            constraintEqualToAnchor:wanCard.topAnchor constant:14.0],
        [wanRow.bottomAnchor
            constraintEqualToAnchor:wanCard.bottomAnchor constant:-14.0]
    ]];

    UIView *homeVisualCard = [UIView new];
    homeVisualCard.translatesAutoresizingMaskIntoConstraints = NO;
    homeVisualCard.layer.cornerRadius = 24.0;
    homeVisualCard.layer.cornerCurve = kCACornerCurveContinuous;
    homeVisualCard.clipsToBounds = YES;
    homeVisualCard.backgroundColor = UIColor.secondarySystemGroupedBackgroundColor;

    UILabel *albumStyleLabel = [UILabel new];
    albumStyleLabel.text = @"原生液态底栏";
    albumStyleLabel.font =
        [UIFont systemFontOfSize:14.0 weight:UIFontWeightSemibold];
    UIStackView *albumStyleRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[albumStyleLabel]];
    albumStyleRow.axis = UILayoutConstraintAxisHorizontal;
    albumStyleRow.alignment = UIStackViewAlignmentCenter;

    UIButton *newBarIconCenterButton = AWECreateGlassTextButton(
        @"打开新底栏图标中心", AWEStoredAccentColor(), YES);
    [newBarIconCenterButton addTarget:self
                               action:@selector(openNewBarIconCenter:)
                     forControlEvents:UIControlEventTouchUpInside];

    UILabel *internalFullscreenLabel = [UILabel new];
    internalFullscreenLabel.text = @"全屏播放";
    internalFullscreenLabel.font =
        [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    UISwitch *internalFullscreenSwitch = [UISwitch new];
    internalFullscreenSwitch.on = AWEInternalFullscreenEnabled();
    internalFullscreenSwitch.onTintColor = AWEStoredAccentColor();
    [internalFullscreenSwitch addTarget:self
        action:@selector(internalFullscreenSwitchChanged:)
        forControlEvents:UIControlEventValueChanged];
    self.internalFullscreenSwitch = internalFullscreenSwitch;
    UIStackView *internalFullscreenRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[internalFullscreenLabel, internalFullscreenSwitch]];
    internalFullscreenRow.axis = UILayoutConstraintAxisHorizontal;
    internalFullscreenRow.alignment = UIStackViewAlignmentCenter;
    internalFullscreenRow.distribution = UIStackViewDistributionEqualSpacing;

    UILabel *bottomBarDisplayLabel = [UILabel new];
    bottomBarDisplayLabel.text = @"显示液态底栏";
    bottomBarDisplayLabel.font =
        [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    UISwitch *bottomBarDisplaySwitch = [UISwitch new];
    bottomBarDisplaySwitch.on = AWEBottomBarDisplayEnabled();
    bottomBarDisplaySwitch.onTintColor = AWEStoredAccentColor();
    [bottomBarDisplaySwitch addTarget:self
        action:@selector(bottomBarDisplaySwitchChanged:)
        forControlEvents:UIControlEventValueChanged];
    self.bottomBarDisplaySwitch = bottomBarDisplaySwitch;
    UIStackView *bottomBarDisplayRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[bottomBarDisplayLabel, bottomBarDisplaySwitch]];
    bottomBarDisplayRow.axis = UILayoutConstraintAxisHorizontal;
    bottomBarDisplayRow.alignment = UIStackViewAlignmentCenter;
    bottomBarDisplayRow.distribution = UIStackViewDistributionEqualSpacing;

    UILabel *bottomBarDisplayHint = [UILabel new];
    bottomBarDisplayHint.text = @"关闭后会直接卸载 LiquidBar 底栏与搜索，并归还抖音原生底栏宿主；顶部/右侧液态按钮、头像菜单、设置手势等功能继续工作。";
    bottomBarDisplayHint.font =
        [UIFont systemFontOfSize:11.5 weight:UIFontWeightRegular];
    bottomBarDisplayHint.textColor = UIColor.tertiaryLabelColor;
    bottomBarDisplayHint.numberOfLines = 0;

    UILabel *hideTitlesLabel = [UILabel new];
    hideTitlesLabel.text = @"隐藏底栏标题";
    hideTitlesLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    UISwitch *hideTitlesSwitch = [UISwitch new];
    hideTitlesSwitch.on = AWEHideBottomTitlesEnabled();
    hideTitlesSwitch.onTintColor = AWEStoredAccentColor();
    [hideTitlesSwitch addTarget:self
                         action:@selector(hideBottomTitlesSwitchChanged:)
               forControlEvents:UIControlEventValueChanged];
    self.hideBottomTitlesSwitch = hideTitlesSwitch;
    UIStackView *hideTitlesRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[hideTitlesLabel, hideTitlesSwitch]];
    hideTitlesRow.axis = UILayoutConstraintAxisHorizontal;
    hideTitlesRow.alignment = UIStackViewAlignmentCenter;
    hideTitlesRow.distribution = UIStackViewDistributionEqualSpacing;

    UILabel *messageBadgeLabel = [UILabel new];
    messageBadgeLabel.text = @"显示朋友/消息未读角标";
    messageBadgeLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    UISwitch *messageBadgeSwitch = [UISwitch new];
    messageBadgeSwitch.on = AWEMessageBadgeEnabled();
    messageBadgeSwitch.onTintColor = AWEStoredAccentColor();
    [messageBadgeSwitch addTarget:self
        action:@selector(messageBadgeSwitchChanged:)
        forControlEvents:UIControlEventValueChanged];
    self.messageBadgeSwitch = messageBadgeSwitch;
    UIStackView *messageBadgeRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[messageBadgeLabel, messageBadgeSwitch]];
    messageBadgeRow.axis = UILayoutConstraintAxisHorizontal;
    messageBadgeRow.alignment = UIStackViewAlignmentCenter;
    messageBadgeRow.distribution = UIStackViewDistributionEqualSpacing;

    UILabel *avatarMenuDownloadLabel = [UILabel new];
    avatarMenuDownloadLabel.text = @"头像菜单显示下载功能";
    avatarMenuDownloadLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    UISwitch *avatarMenuDownloadSwitch = [UISwitch new];
    avatarMenuDownloadSwitch.on = AWEAvatarMenuDownloadEnabled();
    avatarMenuDownloadSwitch.onTintColor = AWEStoredAccentColor();
    [avatarMenuDownloadSwitch addTarget:self
        action:@selector(avatarMenuDownloadSwitchChanged:)
        forControlEvents:UIControlEventValueChanged];
    self.avatarMenuDownloadSwitch = avatarMenuDownloadSwitch;
    UIStackView *avatarMenuDownloadRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[avatarMenuDownloadLabel, avatarMenuDownloadSwitch]];
    avatarMenuDownloadRow.axis = UILayoutConstraintAxisHorizontal;
    avatarMenuDownloadRow.alignment = UIStackViewAlignmentCenter;
    avatarMenuDownloadRow.distribution = UIStackViewDistributionEqualSpacing;

    UILabel *preferHighestPlaybackLabel = [UILabel new];
    preferHighestPlaybackLabel.text = @"优先最高画质播放（最高码率，可能增加流量）";
    preferHighestPlaybackLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    UISwitch *preferHighestPlaybackSwitch = [UISwitch new];
    preferHighestPlaybackSwitch.on = AWEPreferHighestPlaybackEnabled();
    preferHighestPlaybackSwitch.onTintColor = AWEStoredAccentColor();
    [preferHighestPlaybackSwitch addTarget:self
        action:@selector(preferHighestPlaybackSwitchChanged:)
        forControlEvents:UIControlEventValueChanged];
    self.preferHighestPlaybackSwitch = preferHighestPlaybackSwitch;
    UIStackView *preferHighestPlaybackRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[preferHighestPlaybackLabel, preferHighestPlaybackSwitch]];
    preferHighestPlaybackRow.axis = UILayoutConstraintAxisHorizontal;
    preferHighestPlaybackRow.alignment = UIStackViewAlignmentCenter;
    preferHighestPlaybackRow.distribution = UIStackViewDistributionEqualSpacing;

    UILabel *forceDarkBottomBarLabel = [UILabel new];
    forceDarkBottomBarLabel.text = @"iOS 27 底栏强制深色";
    forceDarkBottomBarLabel.font =
        [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    UISwitch *forceDarkBottomBarSwitch = [UISwitch new];
    forceDarkBottomBarSwitch.on = AWEHomeForceDarkGlassEnabled();
    forceDarkBottomBarSwitch.enabled = AWEIsIOS27OrLater();
    forceDarkBottomBarSwitch.onTintColor = AWEStoredAccentColor();
    [forceDarkBottomBarSwitch addTarget:self
        action:@selector(forceDarkBottomBarSwitchChanged:)
        forControlEvents:UIControlEventValueChanged];
    self.forceDarkBottomBarSwitch = forceDarkBottomBarSwitch;
    UIStackView *forceDarkBottomBarRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[
            forceDarkBottomBarLabel, forceDarkBottomBarSwitch
        ]];
    forceDarkBottomBarRow.axis = UILayoutConstraintAxisHorizontal;
    forceDarkBottomBarRow.alignment = UIStackViewAlignmentCenter;
    forceDarkBottomBarRow.distribution = UIStackViewDistributionEqualSpacing;

    UILabel *topLabel = [UILabel new];
    topLabel.text = @"顶部菜单/分类液态玻璃（搜索独立保留）";
    topLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    UISwitch *topSwitch = [UISwitch new];
    topSwitch.on = AWETopGlassEnabled();
    topSwitch.onTintColor = AWEStoredAccentColor();
    [topSwitch addTarget:self action:@selector(topGlassSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.topGlassSwitch = topSwitch;
    UIStackView *topRow = [[UIStackView alloc] initWithArrangedSubviews:@[topLabel, topSwitch]];
    topRow.axis = UILayoutConstraintAxisHorizontal;
    topRow.alignment = UIStackViewAlignmentCenter;
    topRow.distribution = UIStackViewDistributionEqualSpacing;

    UILabel *hideTopLeftButtonLabel = [UILabel new];
    hideTopLeftButtonLabel.text = @"完全隐藏左上角按钮";
    hideTopLeftButtonLabel.font =
        [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    UISwitch *hideTopLeftButtonSwitch = [UISwitch new];
    hideTopLeftButtonSwitch.on = AWEHideTopLeftButtonEnabled();
    hideTopLeftButtonSwitch.onTintColor = AWEStoredAccentColor();
    [hideTopLeftButtonSwitch addTarget:self
        action:@selector(hideTopLeftButtonSwitchChanged:)
        forControlEvents:UIControlEventValueChanged];
    self.hideTopLeftButtonSwitch = hideTopLeftButtonSwitch;
    UIStackView *hideTopLeftButtonRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[hideTopLeftButtonLabel,
                                  hideTopLeftButtonSwitch]];
    hideTopLeftButtonRow.axis = UILayoutConstraintAxisHorizontal;
    hideTopLeftButtonRow.alignment = UIStackViewAlignmentCenter;
    hideTopLeftButtonRow.distribution = UIStackViewDistributionEqualSpacing;

    UILabel *topCategoryGroupLabel = [UILabel new];
    topCategoryGroupLabel.text = @"顶部分类液态分组（默认）";
    topCategoryGroupLabel.font = [UIFont systemFontOfSize:14.0
                                                   weight:UIFontWeightMedium];
    UISwitch *topCategoryGroupSwitch = [UISwitch new];
    topCategoryGroupSwitch.on = AWETopTelegramSwitcherEnabled();
    topCategoryGroupSwitch.onTintColor = AWEStoredAccentColor();
    [topCategoryGroupSwitch addTarget:self
                               action:@selector(topCategoryGroupSwitchChanged:)
                     forControlEvents:UIControlEventValueChanged];
    self.topCategoryGroupSwitch = topCategoryGroupSwitch;
    UIStackView *topCategoryGroupRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[topCategoryGroupLabel,
                                  topCategoryGroupSwitch]];
    topCategoryGroupRow.axis = UILayoutConstraintAxisHorizontal;
    topCategoryGroupRow.alignment = UIStackViewAlignmentCenter;
    topCategoryGroupRow.distribution = UIStackViewDistributionEqualSpacing;

    UILabel *topCategoryCountLabel = [UILabel new];
    topCategoryCountLabel.text = @"顶部分组同时显示数量";
    topCategoryCountLabel.font = [UIFont systemFontOfSize:14.0
                                                  weight:UIFontWeightMedium];
    UISegmentedControl *topCategoryCountControl =
        [[UISegmentedControl alloc] initWithItems:@[@"1", @"2", @"3", @"4"]];
    topCategoryCountControl.selectedSegmentIndex =
        AWETopTelegramVisibleCount() - 1;
    [topCategoryCountControl addTarget:self
        action:@selector(topCategoryVisibleCountChanged:)
        forControlEvents:UIControlEventValueChanged];
    self.topCategoryVisibleCountControl = topCategoryCountControl;
    UIStackView *topCategoryCountRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[topCategoryCountLabel,
                                  topCategoryCountControl]];
    topCategoryCountRow.axis = UILayoutConstraintAxisHorizontal;
    topCategoryCountRow.alignment = UIStackViewAlignmentCenter;
    topCategoryCountRow.spacing = 10.0;
    [topCategoryCountLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow
                                                           forAxis:UILayoutConstraintAxisHorizontal];
    [topCategoryCountControl.widthAnchor constraintEqualToConstant:168.0].active = YES;

    UILabel *topMenuMorphLabel = [UILabel new];
    topMenuMorphLabel.text = @"左上按钮展开分类菜单（开启时替代顶部分组）";
    topMenuMorphLabel.font = [UIFont systemFontOfSize:14.0
                                               weight:UIFontWeightMedium];
    UISwitch *topMenuMorphSwitch = [UISwitch new];
    topMenuMorphSwitch.on = AWETopMenuMorphEnabled();
    topMenuMorphSwitch.onTintColor = AWEStoredAccentColor();
    [topMenuMorphSwitch addTarget:self
                           action:@selector(topMenuMorphSwitchChanged:)
                 forControlEvents:UIControlEventValueChanged];
    self.topMenuMorphSwitch = topMenuMorphSwitch;
    UIStackView *topMenuMorphRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[topMenuMorphLabel, topMenuMorphSwitch]];
    topMenuMorphRow.axis = UILayoutConstraintAxisHorizontal;
    topMenuMorphRow.alignment = UIStackViewAlignmentCenter;
    topMenuMorphRow.distribution = UIStackViewDistributionEqualSpacing;

    UILabel *adaptiveGlassHint = [UILabel new];
    adaptiveGlassHint.text = @"iOS 26 默认：系统自适应材质（跟随系统透明度/色调，开销较低）";
    adaptiveGlassHint.font =
        [UIFont systemFontOfSize:11.5 weight:UIFontWeightRegular];
    adaptiveGlassHint.textColor = UIColor.tertiaryLabelColor;
    adaptiveGlassHint.numberOfLines = 0;

    UILabel *transparentGlassLabel = [UILabel new];
    transparentGlassLabel.text = @"纯透明材质（无额外描边，局部黑白自适应）";
    transparentGlassLabel.font =
        [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    UISwitch *transparentGlassSwitch = [UISwitch new];
    transparentGlassSwitch.on = AWEHomeTransparentGlassEnabled();
    transparentGlassSwitch.onTintColor = AWEStoredAccentColor();
    [transparentGlassSwitch addTarget:self
                               action:@selector(transparentGlassSwitchChanged:)
                     forControlEvents:UIControlEventValueChanged];
    self.transparentGlassSwitch = transparentGlassSwitch;
    UIStackView *transparentGlassRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[transparentGlassLabel, transparentGlassSwitch]];
    transparentGlassRow.axis = UILayoutConstraintAxisHorizontal;
    transparentGlassRow.alignment = UIStackViewAlignmentCenter;
    transparentGlassRow.distribution = UIStackViewDistributionEqualSpacing;


    AWEEnsureHomeCustomIconsDirectory();
    UILabel *pngLabel = [UILabel new];
    pngLabel.text = @"自定义 PNG 图标";
    pngLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    UISwitch *pngSwitch = [UISwitch new];
    pngSwitch.on = AWEHomeCustomPNGModeEnabled();
    pngSwitch.onTintColor = AWEStoredAccentColor();
    [pngSwitch addTarget:self action:@selector(customPNGModeSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.customPNGModeSwitch = pngSwitch;
    UIStackView *pngRow = [[UIStackView alloc] initWithArrangedSubviews:@[pngLabel, pngSwitch]];
    pngRow.axis = UILayoutConstraintAxisHorizontal;
    pngRow.alignment = UIStackViewAlignmentCenter;
    pngRow.distribution = UIStackViewDistributionEqualSpacing;

    UILabel *pngHint = [UILabel new];
    pngHint.text = @"玻璃按钮本体固定为 46×46 pt。PNG 按源文件像素以 @3x 显示：30×30 px 约为 10×10 pt，100×100 px 约为 33.3×33.3 pt；小图不放大，任一边超过 100 px 时才等比例缩小。透明留白也会计入尺寸。";
    pngHint.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightRegular];
    pngHint.textColor = UIColor.tertiaryLabelColor;
    pngHint.numberOfLines = 0;

    UIButton *reloadPNG = AWECreateGlassTextButton(@"重新读取 PNG", UIColor.systemGrayColor, NO);
    [reloadPNG addTarget:self action:@selector(reloadCustomPNGIcons:) forControlEvents:UIControlEventTouchUpInside];

    UIButton *iconCenterButton = AWECreateGlassTextButton(@"打开顶部与右侧图标中心", AWEStoredAccentColor(), YES);
    [iconCenterButton addTarget:self action:@selector(openIconCenter:) forControlEvents:UIControlEventTouchUpInside];

    UILabel *diagnosticLabel = [UILabel new];
    diagnosticLabel.text = @"交互诊断日志（反馈用）";
    diagnosticLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
    UISwitch *diagnosticSwitch = [UISwitch new];
    diagnosticSwitch.on = AWEInteractionDiagnosticsEnabled();
    diagnosticSwitch.onTintColor = AWEStoredAccentColor();
    [diagnosticSwitch addTarget:self
                         action:@selector(interactionDiagnosticSwitchChanged:)
               forControlEvents:UIControlEventValueChanged];
    self.interactionDiagnosticSwitch = diagnosticSwitch;
    UIStackView *diagnosticRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[diagnosticLabel, diagnosticSwitch]];
    diagnosticRow.axis = UILayoutConstraintAxisHorizontal;
    diagnosticRow.alignment = UIStackViewAlignmentCenter;
    diagnosticRow.distribution = UIStackViewDistributionEqualSpacing;

    UIButton *snapshotButton = AWECreateGlassTextButton(@"写入当前交互/底栏状态", UIColor.systemGrayColor, NO);
    [snapshotButton addTarget:self action:@selector(writeInteractionSnapshot:)
             forControlEvents:UIControlEventTouchUpInside];
    UIButton *clearLogButton = AWECreateGlassTextButton(@"清空全部日志", UIColor.systemGrayColor, NO);
    [clearLogButton addTarget:self action:@selector(clearInteractionDiagnosticLog:)
              forControlEvents:UIControlEventTouchUpInside];
    UIStackView *diagnosticButtons = [[UIStackView alloc]
        initWithArrangedSubviews:@[snapshotButton, clearLogButton]];
    diagnosticButtons.axis = UILayoutConstraintAxisHorizontal;
    diagnosticButtons.distribution = UIStackViewDistributionFillEqually;
    diagnosticButtons.spacing = 8.0;

    UIButton *exportLogButton = AWECreateGlassTextButton(@"导出探针日志", AWEStoredAccentColor(), YES);
    [exportLogButton addTarget:self action:@selector(exportProbeLogs:)
              forControlEvents:UIControlEventTouchUpInside];

    NSMutableArray<UIView *> *visualItems = [NSMutableArray arrayWithObjects:
        albumStyleRow, newBarIconCenterButton, nil];
    if (AWECustomBottomBarReleaseAllowed()) {
        [visualItems addObject:bottomBarDisplayRow];
        [visualItems addObject:bottomBarDisplayHint];
    }
    [visualItems addObjectsFromArray:@[
        internalFullscreenRow,
        hideTitlesRow, messageBadgeRow, avatarMenuDownloadRow, preferHighestPlaybackRow, forceDarkBottomBarRow,
        topRow, hideTopLeftButtonRow, topCategoryGroupRow, topCategoryCountRow, topMenuMorphRow,
        adaptiveGlassHint, transparentGlassRow,
        pngRow, pngHint, reloadPNG,
        iconCenterButton, diagnosticRow, diagnosticButtons,
        exportLogButton
    ]];
    UIStackView *visualStack = [[UIStackView alloc] initWithArrangedSubviews:visualItems];
    visualStack.translatesAutoresizingMaskIntoConstraints = NO;
    visualStack.axis = UILayoutConstraintAxisVertical;
    visualStack.spacing = 10.0;
    [homeVisualCard addSubview:visualStack];
    [NSLayoutConstraint activateConstraints:@[
        [visualStack.leadingAnchor constraintEqualToAnchor:homeVisualCard.leadingAnchor constant:14.0],
        [visualStack.trailingAnchor constraintEqualToAnchor:homeVisualCard.trailingAnchor constant:-14.0],
        [visualStack.topAnchor constraintEqualToAnchor:homeVisualCard.topAnchor constant:14.0],
        [visualStack.bottomAnchor constraintEqualToAnchor:homeVisualCard.bottomAnchor constant:-14.0]
    ]];

    UILabel *authorizationFooter = [UILabel new];
    authorizationFooter.font = [UIFont systemFontOfSize:11.0 weight:UIFontWeightRegular];
    authorizationFooter.textColor = UIColor.tertiaryLabelColor;
    authorizationFooter.textAlignment = NSTextAlignmentCenter;
    self.authorizationFooter = authorizationFooter;

    UIStackView *stack =
        [[UIStackView alloc] initWithArrangedSubviews:@[
            masterCard, accentCard, positionCard, gestureCard, chatCard, wanCard,
            homeVisualCard, authorizationCheckButton, authorizationFooter
        ]];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 14.0;
    stack.alignment = UIStackViewAlignmentFill;

    UIScrollView *scrollView = [UIScrollView new];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.alwaysBounceVertical = YES;
    scrollView.keyboardDismissMode =
        UIScrollViewKeyboardDismissModeInteractive;

    [self.view addSubview:scrollView];
    [scrollView addSubview:stack];

    UILayoutGuide *guide = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scrollView.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
        [scrollView.topAnchor constraintEqualToAnchor:guide.topAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],

        [stack.leadingAnchor
            constraintEqualToAnchor:scrollView.contentLayoutGuide.leadingAnchor
                           constant:22.0],
        [stack.trailingAnchor
            constraintEqualToAnchor:scrollView.contentLayoutGuide.trailingAnchor
                           constant:-22.0],
        [stack.topAnchor
            constraintEqualToAnchor:scrollView.contentLayoutGuide.topAnchor
                           constant:22.0],
        [stack.bottomAnchor
            constraintEqualToAnchor:scrollView.contentLayoutGuide.bottomAnchor
                           constant:-22.0],
        [stack.widthAnchor
            constraintEqualToAnchor:scrollView.frameLayoutGuide.widthAnchor
                           constant:-44.0]
    ]];

    self.themeCards = @[
        masterCard, accentCard, positionCard, gestureCard, chatCard, wanCard, homeVisualCard
    ];
    self.themePrimaryLabels = @[
        masterTitle, headline, positionTitle, gestureTitle, chatTitle,
        capsuleLabel, separateLabel, wanTitle, settingsGestureMineOnlyLabel,
        albumStyleLabel, hideTitlesLabel, messageBadgeLabel, preferHighestPlaybackLabel,
        forceDarkBottomBarLabel, topLabel, topCategoryGroupLabel,
        topMenuMorphLabel, pngLabel, diagnosticLabel
    ];
    self.themeSecondaryLabels = @[
        positionValue, splitValue, pngHint, authorizationFooter
    ];

    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(authorizationStateChanged:)
        name:AWEAuthorizationNotificationName() object:nil];
    [self updateVerticalOffsetLabel];
    [self updateDoubleTapSplitLabel];
    [self refreshAuthorizationUI];
    [self applyCurrentTheme];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    gAWESettingsVisible = YES;
    AWETrySilentAuthorization(self);
    [self refreshAuthorizationUI];
    [self updateVerticalOffsetLabel];
    [self applyCurrentTheme];
    self.lastAppliedSystemStyle = AWESystemInterfaceStyle();
    [self.systemThemeTimer invalidate];
    self.systemThemeTimer = [NSTimer scheduledTimerWithTimeInterval:0.50
                                                            target:self
                                                          selector:@selector(pollSystemTheme:)
                                                          userInfo:nil
                                                           repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    /* Restore the invisible native bar's layout footprint before the settings
       dismissal snapshot. Without this, the Home feed can perform one layout
       pass with a zero bottom reserve and its caption briefly touches the
       screen edge underneath the resident LiquidBar. */
    BOOL nativeSettingsPush =
        [objc_getAssociatedObject(self, &kAWELiquidSettingsNativePushKey) boolValue];
    if (!nativeSettingsPush && AWEAlbumMorphStyleEnabled() && gAWELastTabBar) {
        UIView *bar = (UIView *)gAWELastTabBar;
        AWESetApplying(bar, YES);
        [UIView performWithoutAnimation:^{
            bar.hidden = NO;
            bar.alpha = 1.0;
        }];
        AWESetApplying(bar, NO);
        AWEApplyAlbumMorphOriginalSuppression(bar, YES);
        [bar.superview setNeedsLayout];
        [bar.superview layoutIfNeeded];
    }
    [super viewWillDisappear:animated];
    gAWESettingsVisible = NO;
    [self.systemThemeTimer invalidate];
    self.systemThemeTimer = nil;

    dispatch_async(dispatch_get_main_queue(), ^{
        AWERefreshAllConfiguredIcons();
        if (AWEAlbumMorphStyleEnabled() && gAWELastTabBar) {
            AWEInstallOrUpdateAlbumMorphBar((UIView *)gAWELastTabBar, NO);
        }
    });
}

- (void)pollSystemTheme:(NSTimer *)timer {
    (void)timer;
    UIUserInterfaceStyle style = AWESystemInterfaceStyle();
    if (style == UIUserInterfaceStyleUnspecified) style = UIUserInterfaceStyleLight;
    if (style == self.lastAppliedSystemStyle) return;
    self.lastAppliedSystemStyle = style;
    [self applyCurrentTheme];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) [self applyCurrentTheme];
    }
}

- (void)applyCurrentTheme {
    UIUserInterfaceStyle style = AWESystemInterfaceStyle();
    if (style == UIUserInterfaceStyleUnspecified) style = UIUserInterfaceStyleLight;
    BOOL dark = style == UIUserInterfaceStyleDark;
    UIColor *background = dark ? [UIColor colorWithWhite:0.055 alpha:1.0] : [UIColor colorWithWhite:0.965 alpha:1.0];
    UIColor *card = dark ? [UIColor colorWithWhite:0.115 alpha:1.0] : UIColor.whiteColor;
    UIColor *primary = dark ? UIColor.whiteColor : UIColor.blackColor;
    UIColor *secondary = dark ? [UIColor colorWithWhite:1.0 alpha:0.56] : [UIColor colorWithWhite:0.0 alpha:0.46];
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = style;
        self.navigationController.overrideUserInterfaceStyle = style;
    }
    self.view.backgroundColor = background;
    self.navigationController.view.backgroundColor = background;
    for (UIView *themeCard in self.themeCards) themeCard.backgroundColor = card;
    for (UILabel *label in self.themePrimaryLabels) label.textColor = primary;
    for (UILabel *label in self.themeSecondaryLabels) label.textColor = secondary;
    UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
    [appearance configureWithTransparentBackground];
    appearance.backgroundColor = background;
    appearance.titleTextAttributes = @{NSForegroundColorAttributeName: primary};
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.standardAppearance = appearance;
    navigationBar.scrollEdgeAppearance = appearance;
    navigationBar.compactAppearance = appearance;
    navigationBar.tintColor = primary;
    navigationBar.barStyle = dark ? UIBarStyleBlack : UIBarStyleDefault;
    UIColor *accent = self.pendingAccentColor ?: AWEStoredAccentColor();
    self.previewView.backgroundColor = accent;
    self.lowerHalfCommentSwitch.onTintColor = accent;
    self.settingsGestureMineOnlySwitch.onTintColor = accent;
    self.verticalOffsetSlider.minimumTrackTintColor = accent;
    self.collapseSwitch.onTintColor = accent;
    self.doubleTapSplitSlider.minimumTrackTintColor = accent;
    self.wanToWSwitch.onTintColor = accent;
    self.chatCapsuleSwitch.onTintColor = accent;
    self.chatSeparateLeftSwitch.onTintColor = accent;
    self.customPNGModeSwitch.onTintColor = accent;
    self.topGlassSwitch.onTintColor = accent;
    self.topCategoryGroupSwitch.onTintColor = accent;
    self.topMenuMorphSwitch.onTintColor = accent;
    self.transparentGlassSwitch.onTintColor = accent;
    self.hideBottomTitlesSwitch.onTintColor = accent;
    self.messageBadgeSwitch.onTintColor = accent;
    self.avatarMenuDownloadSwitch.onTintColor = accent;
    self.preferHighestPlaybackSwitch.onTintColor = accent;
    self.albumMorphStyleSwitch.onTintColor = accent;
    self.masterSwitch.onTintColor = accent;
    self.interactionDiagnosticSwitch.onTintColor = accent;
    [self updateApplyButtonTint:accent];
}

- (void)updateApplyButtonTint:(UIColor *)colour {
    AWEConfigureGlassTextButton(self.applyButton, @"确认并应用", colour ?: AWEStoredAccentColor(), YES);
}

- (void)manualAuthorizationCheck:(UIButton *)sender {
    sender.enabled = NO;
    self.authorizationFooter.text = @"正在检测授权…";

    UIViewController *sourceController = self.presentingViewController ?: self;
    BOOL authorized = AWEAttemptAuthorizationFromVisiblePage(sourceController);

    if (!authorized) {
        UIWindow *window = AWEActiveMainWindow();
        UIViewController *top = AWETopViewControllerFrom(window.rootViewController);
        authorized = AWEAttemptAuthorizationFromVisiblePage(top ?: sourceController);
    }

    [self refreshAuthorizationUI];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        sender.enabled = YES;
        [self refreshAuthorizationUI];
    });
}

- (void)authorizationStateChanged:(NSNotification *)notification {
    (void)notification;
    [self refreshAuthorizationUI];
}

- (void)refreshAuthorizationUI {
    BOOL authorized = AWEAuthorizationValid();
    self.masterSwitch.enabled = authorized;
    self.masterSwitch.on = authorized && AWEMasterEnabledStored();
    self.authorizationFooter.text = authorized ? @"● 已授权" : @"○ 未授权";
}

- (void)masterSwitchChanged:(UISwitch *)sender {
    BOOL authorized = AWEAuthorizationValid();
    if (!authorized) {
        sender.on = NO;
        sender.enabled = NO;
        return;
    }
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:AWEAuthorizationDefaultsKey(3)];
    [NSUserDefaults.standardUserDefaults synchronize];
    [self refreshAuthorizationUI];
}

- (void)dealloc {
    [self.systemThemeTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)closeSettings {
    BOOL nativeSettingsPush =
        [objc_getAssociatedObject(self, &kAWELiquidSettingsNativePushKey) boolValue];
    if (nativeSettingsPush && self.navigationController &&
        self.navigationController.topViewController == self) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)openAccentPicker:(UIButton *)sender {
    (void)sender;
    UIColorPickerViewController *picker = [UIColorPickerViewController new];
    picker.delegate = self;
    picker.supportsAlpha = NO;
    picker.selectedColor = self.pendingAccentColor ?: AWEStoredAccentColor();
    picker.title = @"选择强调色";
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)colorPickerViewControllerDidSelectColor:(UIColorPickerViewController *)viewController {
    self.pendingAccentColor = viewController.selectedColor ?: AWEStoredAccentColor();
    self.previewView.backgroundColor = self.pendingAccentColor;
    [self updateApplyButtonTint:self.pendingAccentColor];
}

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController {
    self.pendingAccentColor = viewController.selectedColor ?: self.pendingAccentColor;
    self.previewView.backgroundColor = self.pendingAccentColor;
    [self updateApplyButtonTint:self.pendingAccentColor];
}

- (void)confirmAccentColor:(UIButton *)sender {
    (void)sender;
    UIColor *colour = self.pendingAccentColor ?: AWEStoredAccentColor();
    CGFloat r=0,g=0,b=0,a=1;
    UIColor *resolved = colour;
    if (@available(iOS 13.0, *)) resolved = [colour resolvedColorWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]];
    if (![resolved getRed:&r green:&g blue:&b alpha:&a]) return;
    NSString *hex = [NSString stringWithFormat:@"#%02X%02X%02X", (int)lround(r*255.0), (int)lround(g*255.0), (int)lround(b*255.0)];
    [NSUserDefaults.standardUserDefaults setObject:hex forKey:kAWEAccentHexDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    AWEApplyStoredAccentToCurrentBar();
    AWERefreshAllConfiguredIcons();
    [self applyCurrentTheme];
    [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
}

- (void)updateVerticalOffsetLabel {
    CGFloat value = self.verticalOffsetSlider.value;
    if (fabs(value) < 0.01) {
        self.verticalOffsetValueLabel.text = @"默认位置";
    } else if (value < 0.0) {
        self.verticalOffsetValueLabel.text =
            [NSString stringWithFormat:@"向上 %.1f pt", fabs(value)];
    } else {
        self.verticalOffsetValueLabel.text =
            [NSString stringWithFormat:@"向下 %.1f pt", value];
    }
}

- (void)updateDoubleTapSplitLabel {
    NSInteger likePercent =
        (NSInteger)lround(self.doubleTapSplitSlider.value * 100.0);
    NSInteger commentPercent = 100 - likePercent;
    self.doubleTapSplitValueLabel.text =
        [NSString stringWithFormat:@"点赞区域 %ld%% · 评论区域 %ld%%",
                                   (long)likePercent,
                                   (long)commentPercent];
}

- (void)verticalOffsetSliderChanged:(UISlider *)sender {
    CGFloat snapped = round(sender.value * 2.0) / 2.0;
    sender.value = snapped;

    [[NSUserDefaults standardUserDefaults]
        setDouble:snapped
           forKey:kAWEVerticalOffsetDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self updateVerticalOffsetLabel];

    if (AWEAlbumMorphStyleEnabled() && gAWEAlbumMorphController) {
        [gAWEAlbumMorphController setVerticalOffset:snapped];
        AWEAlbumMorphProbeWrite(
            @"HEIGHT_SLIDER_FIXED value=%.2f tabBar=%@",
            snapped,
            NSStringFromCGRect(gAWEAlbumMorphController.tabBar.frame));
        return;
    }

    /* The original five-button style keeps its existing carrier-frame path. */
    AWERefreshCurrentBarLayout();
}

- (void)collapseSwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:kAWEAlbumMorphCollapseEnabledDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    if (sender.isOn) {
        UIWindow *window = gAWEAlbumMorphSuppressedOriginalBar.window ?:
            AWEActiveMainWindow();
        AWEInstallAlbumMorphCollapseGesture(window);
    } else {
        AWEExpandAlbumMorphBarWithoutAnimation();
    }
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)doubleTapSplitSliderChanged:(UISlider *)sender {
    [[NSUserDefaults standardUserDefaults]
        setDouble:sender.value
           forKey:kAWEDoubleTapLikeFractionDefaultsKey];
    [self updateDoubleTapSplitLabel];
}

- (void)settingsGestureMineOnlySwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:kAWESettingsGestureMineOnlyDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)messageBadgeSwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:kAWEMessageBadgeEnabledDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    AWEUpdateAlbumMorphMessageBadge();
}

- (void)avatarMenuDownloadSwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:kAWEAvatarMenuDownloadEnabledDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    UIWindow *window = AWEActiveMainWindow();
    if (window) AWEScheduleHomeActionStacksInView(window);
}

- (void)preferHighestPlaybackSwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:kAWEPreferHighestPlaybackDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    /* The preference is consumed on the next native AWEVideoModel selection.
       Do not refresh feed UI or touch a live player when toggling it. */
}

- (void)lowerHalfCommentSwitchChanged:(UISwitch *)sender {
    [[NSUserDefaults standardUserDefaults]
        setBool:sender.isOn
         forKey:kAWELowerHalfDoubleTapCommentDefaultsKey];
    self.doubleTapSplitSlider.enabled = sender.isOn;
    [[NSUserDefaults standardUserDefaults] synchronize];

    UIImpactFeedbackGenerator *feedback =
        [[UIImpactFeedbackGenerator alloc]
            initWithStyle:UIImpactFeedbackStyleLight];
    [feedback prepare];
    [feedback impactOccurred];
}

- (void)chatCapsuleSwitchChanged:(UISwitch *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sender.isOn
               forKey:kAWEChatCapsuleEnabledDefaultsKey];
    [defaults synchronize];

    self.chatSeparateLeftSwitch.enabled = sender.isOn;

    UISelectionFeedbackGenerator *feedback =
        [[UISelectionFeedbackGenerator alloc] init];
    [feedback prepare];
    [feedback selectionChanged];
}

- (void)chatSeparateLeftSwitchChanged:(UISwitch *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:sender.isOn
               forKey:kAWEChatSeparateLeftDefaultsKey];
    [defaults synchronize];

    UISelectionFeedbackGenerator *feedback =
        [[UISelectionFeedbackGenerator alloc] init];
    [feedback prepare];
    [feedback selectionChanged];
}



- (void)forceDarkBottomBarSwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:kAWEHomeForceDarkGlassDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];

    BOOL forceDark = AWEIsIOS27OrLater() && sender.isOn;
    if (gAWEAlbumMorphController) {
        [gAWEAlbumMorphController setForcedDark:forceDark];
        AWEApplyAlbumMorphResolvedAppearance(
            AWEActiveMainWindow(),
            [gAWEAlbumMorphController currentOriginalIndex]);
        [gAWEAlbumMorphController.tabBar setNeedsLayout];
        [gAWEAlbumMorphController.tabBar layoutIfNeeded];
        [gAWEAlbumMorphController.tabBar setNeedsDisplay];
    }
    AWERefreshAllConfiguredIcons();
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)bottomBarDisplaySwitchChanged:(UISwitch *)sender {
    if (!AWECustomBottomBarReleaseAllowed()) {
        sender.on = YES;
        [NSUserDefaults.standardUserDefaults setBool:YES
            forKey:kAWEBottomBarDisplayEnabledDefaultsKey];
        [NSUserDefaults.standardUserDefaults synchronize];
        return;
    }
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:kAWEBottomBarDisplayEnabledDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];

    if (!sender.isOn) {
        /* Release mode: physically remove our UITabBar/overlay and restore the
           original Douyin tab-bar host. Do not leave a transparent controller
           or hit region behind. Top/right/avatar/clean/fullscreen features live
           outside this overlay and continue to work. */
        AWEUninstallAlbumMorphBar();
        if (gAWELastTabBar) {
            AWEApplyAlbumMorphOriginalSuppression((UIView *)gAWELastTabBar, NO);
            AWERestoreOriginalTabBarContents((UIView *)gAWELastTabBar);
            [gAWELastTabBar setNeedsLayout];
            [gAWELastTabBar.superview setNeedsLayout];
        }
    } else if (gAWELastTabBar) {
        /* Recreate LiquidBar from the native host only when the user explicitly
           enables it again. */
        AWEAttachNativeBarWithForce((UIView *)gAWELastTabBar, YES);
    }

    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)internalFullscreenSwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:kAWEInternalFullscreenDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];

    /* The fullscreen module only owns forward geometry. When disabling, request
       a relayout immediately; a cold app restart is recommended to fully rebuild
       Douyin-owned tab backgrounds that were hidden while fullscreen was active. */
    UIWindow *window = AWEActiveMainWindow();
    [window setNeedsLayout];
    [window layoutIfNeeded];
    if (gAWELastTabBar) {
        [(UIView *)gAWELastTabBar setNeedsLayout];
        [(UIView *)gAWELastTabBar layoutIfNeeded];
    }
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)hideBottomTitlesSwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:kAWEHideBottomTitlesDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    AWERefreshAllConfiguredIcons();
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)albumMorphStyleSwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:kAWEAlbumMorphStyleDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];

    if (sender.isOn) {
        if (gAWELastTabBar) {
            AWEInstallOrUpdateAlbumMorphBar((UIView *)gAWELastTabBar, NO);
            dispatch_async(dispatch_get_main_queue(), ^{
                if (AWEAlbumMorphStyleEnabled() && gAWELastTabBar) {
                    AWEInstallOrUpdateAlbumMorphBar(
                        (UIView *)gAWELastTabBar, NO);
                }
            });
        }
    } else {
        AWEUninstallAlbumMorphBar();
        if (gAWELastTabBar) {
            AWEAttachNativeBarWithForce((UIView *)gAWELastTabBar, YES);
            UITabBar *nativeBar = objc_getAssociatedObject(
                (UIView *)gAWELastTabBar, &kAWENativeBarKey);
            if (nativeBar) {
                [UIView performWithoutAnimation:^{
                    AWEConfigureNativeBarAppearance(
                        nativeBar, AWEStoredAccentColor());
                    [nativeBar setNeedsLayout];
                    [nativeBar layoutIfNeeded];
                    [nativeBar setNeedsDisplay];
                }];
            }
        }
    }
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)topGlassSwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn forKey:kAWETopGlassEnabledDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    AWERefreshAllConfiguredIcons();
    AWEScheduleHomeChromeRecovery(AWEActiveMainWindow());
}

- (void)hideTopLeftButtonSwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:kAWEHideTopLeftButtonDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    AWEScheduleHomeChromeRecovery(AWEActiveMainWindow());
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)topCategoryGroupSwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:kAWETopTelegramSwitcherEnabledDefaultsKey];
    if (sender.isOn) {
        [NSUserDefaults.standardUserDefaults setBool:NO
            forKey:kAWETopMenuMorphEnabledDefaultsKey];
        self.topMenuMorphSwitch.on = NO;
    }
    [NSUserDefaults.standardUserDefaults synchronize];
    AWEScheduleHomeChromeRecovery(AWEActiveMainWindow());
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)topCategoryVisibleCountChanged:(UISegmentedControl *)sender {
    NSInteger count = MIN(4, MAX(1, sender.selectedSegmentIndex + 1));
    [NSUserDefaults.standardUserDefaults setInteger:count
        forKey:kAWETopTelegramVisibleCountDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    AWEScheduleHomeChromeRecovery(AWEActiveMainWindow());
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)topMenuMorphSwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:kAWETopMenuMorphEnabledDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    AWEScheduleHomeChromeRecovery(AWEActiveMainWindow());
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}

- (void)transparentGlassSwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:kAWEHomeTransparentGlassDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    AWERefreshAllConfiguredIcons();
    [[[UISelectionFeedbackGenerator alloc] init] selectionChanged];
}


- (void)openNewBarIconCenter:(UIButton *)sender {
    (void)sender;
    AWEIconCenterController *controller =
        [[AWEIconCenterController alloc] initWithNewBarOnly:YES];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)openAlbumMorphButtonSettings:(UIButton *)sender {
    (void)sender;
    AWEAlbumMorphButtonSettingsController *controller =
        [AWEAlbumMorphButtonSettingsController new];
    [self.navigationController pushViewController:controller animated:YES];
}

- (void)openIconCenter:(UIButton *)sender {
    (void)sender;
    AWEIconCenterController *controller = [AWEIconCenterController new];
    [self.navigationController pushViewController:controller animated:YES];
}


- (void)customPNGModeSwitchChanged:(UISwitch *)sender {
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn forKey:kAWEHomeCustomPNGModeDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    AWEEnsureHomeCustomIconsDirectory();
    AWEInvalidateHomeCustomPNGCache();
    AWERefreshAllConfiguredIcons();
}

- (void)reloadCustomPNGIcons:(UIButton *)sender {
    AWEEnsureHomeCustomIconsDirectory();
    AWEInvalidateHomeCustomPNGCache();
    AWERefreshAllConfiguredIcons();
    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [feedback impactOccurred];
}


- (void)interactionDiagnosticSwitchChanged:(UISwitch *)sender {
    if (sender.isOn) AWEInteractionDiagnosticClear();
    [NSUserDefaults.standardUserDefaults setBool:sender.isOn
        forKey:kAWEInteractionDiagnosticEnabledDefaultsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
    if (sender.isOn) {
        AWEInteractionDiagnosticWrite(
            @"========== START build=1.0.56c13 image=%@ ==========" ,
            AWEHomeDiagnosticLoadedImagePath());
    }
}

- (void)writeInteractionSnapshot:(UIButton *)sender {
    (void)sender;
    if (!AWEInteractionDiagnosticsEnabled()) return;
    NSArray *buttons = AWEControllerButtons(gAWELastController);
    UIWindow *window = AWEActiveMainWindow();
    UIView *top = AWEFindViewByExactRuntimeClass(
        window, @"AWEFeedTopBarContainer", 0);
    UIView *menu = top ? AWEFindTopOwnerCandidate(top, NO) : nil;
    UIView *search = top ? AWEFindTopOwnerCandidate(top, YES) : nil;
    AWEAlbumMorphOverlayWindow *albumOverlay =
        (AWEAlbumMorphOverlayWindow *)gAWEAlbumMorphOverlayWindow;
    UITabBar *albumBar = gAWEAlbumMorphController ? gAWEAlbumMorphController.tabBar : nil;
    AWEInteractionDiagnosticWrite(
        @"SNAPSHOT controller=%@ tab=%@ native=%@ buttons=%lu top=%@ menu=%@ search=%@ albumController=%@ albumBar=%@ albumItems=%lu albumSelected=%ld albumUI=%d overlay=%@ overlayContent=%d",
        AWEInteractionObjectSummary(gAWELastController),
        AWEInteractionObjectSummary(gAWELastTabBar),
        AWEInteractionObjectSummary(gAWELastTabBar ?
            objc_getAssociatedObject((UIView *)gAWELastTabBar, &kAWENativeBarKey) : nil),
        (unsigned long)buttons.count,
        AWEInteractionObjectSummary(top),
        AWEInteractionObjectSummary(menu),
        AWEInteractionObjectSummary(search),
        AWEInteractionObjectSummary(gAWEAlbumMorphController),
        AWEInteractionObjectSummary(albumBar),
        (unsigned long)albumBar.items.count,
        (long)gAWEAlbumMorphController.selectedIndex,
        albumBar.userInteractionEnabled,
        AWEInteractionObjectSummary(albumOverlay),
        albumOverlay ? albumOverlay.contentVisible : 0);
    [[[UIImpactFeedbackGenerator alloc]
        initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
}

- (void)clearInteractionDiagnosticLog:(UIButton *)sender {
    (void)sender;
    AWEInteractionDiagnosticClear();
    AWEAlbumMorphProbeClear();
    [[[UIImpactFeedbackGenerator alloc]
        initWithStyle:UIImpactFeedbackStyleLight] impactOccurred];
}

- (void)exportProbeLogs:(UIButton *)sender {
    sender.enabled = NO;
    AWEAlbumMorphProbeWrite(@"EXPORT_REQUEST settings=%@", NSStringFromClass(self.class));
    if (AWEInteractionDiagnosticsEnabled()) {
        AWEInteractionDiagnosticWrite(@"EXPORT_REQUEST settings=%@", NSStringFromClass(self.class));
    }

    __weak typeof(self) weakSelf = self;
    dispatch_async(AWEAlbumMorphProbeQueue(), ^{
        NSString *probePath = AWEAlbumMorphProbePath();
        NSString *probeText = [NSString stringWithContentsOfFile:probePath
                                                        encoding:NSUTF8StringEncoding
                                                           error:nil] ?: @"<probe log empty>\n";

        dispatch_async(AWEInteractionDiagnosticQueue(), ^{
            NSString *interactionPath = AWEInteractionDiagnosticPath();
            NSString *interactionText = [NSString stringWithContentsOfFile:interactionPath
                                                                   encoding:NSUTF8StringEncoding
                                                                      error:nil] ?: @"<interaction log empty or disabled>\n";

            NSString *header = [NSString stringWithFormat:
                @"AwemeLiquidBar 1.0.56c13 diagnostic export\n"
                 "System: %@\n"
                 "Device: %@\n"
                 "Generated: %@\n\n",
                UIDevice.currentDevice.systemVersion ?: @"unknown",
                UIDevice.currentDevice.model ?: @"unknown",
                NSDate.date];
            NSString *combined = [NSString stringWithFormat:
                @"%@========== PROBE LOG ==========\n%@\n"
                 "========== INTERACTION LOG ==========\n%@",
                header, probeText, interactionText];

            NSString *documents = NSSearchPathForDirectoriesInDomains(
                NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
            NSString *exportPath = [documents stringByAppendingPathComponent:
                @"AwemeLiquidBar_1.0.56c13_diagnostic_export.txt"];
            NSError *writeError = nil;
            BOOL wrote = [combined writeToFile:exportPath
                                    atomically:YES
                                      encoding:NSUTF8StringEncoding
                                         error:&writeError];

            dispatch_async(dispatch_get_main_queue(), ^{
                AWELiquidSettingsController *strongSelf = weakSelf;
                sender.enabled = YES;
                if (!strongSelf) return;

                if (!wrote) {
                    UIAlertController *alert = [UIAlertController
                        alertControllerWithTitle:@"日志导出失败"
                        message:writeError.localizedDescription ?: @"无法写入导出文件。"
                        preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                                             style:UIAlertActionStyleDefault
                                                           handler:nil]];
                    [strongSelf presentViewController:alert animated:YES completion:nil];
                    return;
                }

                NSURL *fileURL = [NSURL fileURLWithPath:exportPath];
                UIActivityViewController *activity = [[UIActivityViewController alloc]
                    initWithActivityItems:@[fileURL]
                    applicationActivities:nil];
                UIPopoverPresentationController *popover = activity.popoverPresentationController;
                if (popover) {
                    popover.sourceView = sender;
                    popover.sourceRect = sender.bounds;
                }
                [strongSelf presentViewController:activity animated:YES completion:nil];
            });
        });
    });
}

- (void)wanToWSwitchChanged:(UISwitch *)sender {
    AWESetWanToWEnabled(sender.isOn);
    [[NSUserDefaults standardUserDefaults] synchronize];

    UIImpactFeedbackGenerator *feedback =
        [[UIImpactFeedbackGenerator alloc]
            initWithStyle:UIImpactFeedbackStyleLight];
    [feedback prepare];
    [feedback impactOccurred];
}


@end


#pragma mark - Native Douyin settings shortcut

/*
 DYYY's current public implementation does not mutate Douyin's settings-table
 model.  Instead it hooks the two known layouts that host the native "设置"
 shortcut in the left sidebar, adds a sibling button, and opens its own settings
 controller from there.  Keep the same narrow strategy here: no global UIView
 hook, no tab-bar routing changes, and no dependency on the profile-only gesture.
*/
static const NSInteger kAWELiquidNativeSettingsShortcutTag = 561564;

static void AWEPresentLiquidSettingsFromNativeEntry(UIViewController *host) {
    if (gAWESettingsVisible) return;

    UIWindow *window = host.view.window ?: AWEActiveMainWindow();
    UIViewController *top = host;
    if (!top && window) top = window.rootViewController;
    if (top) top = AWETopViewControllerFrom(top);
    if (!top && window) top = AWETopViewControllerFrom(window.rootViewController);
    if (!top) return;

    if ([top isKindOfClass:[AWELiquidSettingsController class]] ||
        [top.navigationController.topViewController
            isKindOfClass:[AWELiquidSettingsController class]]) {
        return;
    }

    UIImpactFeedbackGenerator *feedback =
        [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [feedback prepare];
    [feedback impactOccurred];

    AWELiquidSettingsController *settings = [AWELiquidSettingsController new];
    if (@available(iOS 13.0, *)) {
        settings.overrideUserInterfaceStyle = AWESystemInterfaceStyle();
    }

    /* Follow DYKiller's stable Settings integration: when the entry is tapped
       from Douyin Settings, push the plugin controller onto the existing native
       navigation stack. This is full-screen by construction and, importantly,
       does not create a transient modal sheet that can leave the hidden native
       tab bridge in a stale route state after dismissal. */
    UINavigationController *nativeNavigation = host.navigationController ?: top.navigationController;
    if ([top isKindOfClass:UINavigationController.class]) {
        nativeNavigation = (UINavigationController *)top;
    }
    if (nativeNavigation) {
        objc_setAssociatedObject(settings, &kAWELiquidSettingsNativePushKey,
                                 @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        AWELogBarSnapshot(@"plugin-settings.native-push", top, YES);
        [nativeNavigation pushViewController:settings animated:YES];
        return;
    }

    /* Rare compatibility fallback for a Douyin build whose Settings host is
       not embedded in a navigation controller. Still use full-screen rather
       than the old medium/large sheet. */
    UINavigationController *navigation =
        [[UINavigationController alloc] initWithRootViewController:settings];
    navigation.modalPresentationStyle = UIModalPresentationFullScreen;
    if (@available(iOS 13.0, *)) {
        navigation.overrideUserInterfaceStyle = AWESystemInterfaceStyle();
    }
    AWELogBarSnapshot(@"plugin-settings.native-fullscreen-fallback", top, YES);
    [top presentViewController:navigation animated:YES completion:nil];
}

/* The Settings-page entry below calls AWEPresentLiquidSettingsFromNativeEntry
   directly through AWESettingsViewModel.controllerDelegate. */

@interface AWESettingsGestureTarget : NSObject <UIGestureRecognizerDelegate>
@end

@implementation AWESettingsGestureTarget

+ (instancetype)sharedTarget {
    static AWESettingsGestureTarget *target = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        target = [AWESettingsGestureTarget new];
    });
    return target;
}

- (void)openSettingsFromGesture:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    if (gAWESettingsVisible || !AWECurrentPageAllowsSettingsGesture()) {
        AWEInteractionDiagnosticWrite(
            @"SETTINGS_GESTURE_BLOCKED mineOnly=%d mainTab=%ld resolvedTab=%ld",
            AWESettingsGestureMineOnlyEnabled(),
            (long)AWECurrentOriginalMainTabIndex(),
            (long)AWECurrentMainTabIndex());
        return;
    }

    UIWindow *window = AWEActiveMainWindow();
    UIViewController *top =
        AWETopViewControllerFrom(window.rootViewController);
    if (!top) return;

    if ([top isKindOfClass:[AWELiquidSettingsController class]] ||
        [top.navigationController.topViewController
            isKindOfClass:[AWELiquidSettingsController class]]) {
        return;
    }

    UIImpactFeedbackGenerator *feedback =
        [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [feedback prepare];
    [feedback impactOccurred];

    AWELiquidSettingsController *settings =
        [AWELiquidSettingsController new];
    UINavigationController *navigation =
        [[UINavigationController alloc] initWithRootViewController:settings];
    navigation.modalPresentationStyle = UIModalPresentationPageSheet;
    if (@available(iOS 13.0, *)) {
        /*
         Do not inherit Douyin's app-local appearance. Seed the sheet from the
         device-level screen trait, then keep it updated while it is visible.
        */
        UIUserInterfaceStyle systemStyle = AWESystemInterfaceStyle();
        navigation.overrideUserInterfaceStyle = systemStyle;
        settings.overrideUserInterfaceStyle = systemStyle;
    }

    if (@available(iOS 15.0, *)) {
        UISheetPresentationController *sheet =
            navigation.sheetPresentationController;
        sheet.detents = @[
            [UISheetPresentationControllerDetent mediumDetent],
            [UISheetPresentationControllerDetent largeDetent]
        ];
        sheet.selectedDetentIdentifier =
            UISheetPresentationControllerDetentIdentifierMedium;
        sheet.prefersGrabberVisible = YES;
        sheet.prefersScrollingExpandsWhenScrolledToEdge = NO;
    }

    AWELogBarSnapshot(@"plugin-settings.open", top, YES);
    [top presentViewController:navigation animated:YES completion:nil];
}


- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    (void)gestureRecognizer;
    return AWECurrentPageAllowsSettingsGesture();
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
        shouldRecognizeSimultaneouslyWithGestureRecognizer:
            (UIGestureRecognizer *)otherGestureRecognizer {
    (void)gestureRecognizer; (void)otherGestureRecognizer;
    return AWECurrentPageAllowsSettingsGesture();
}

@end

static void AWEInstallSettingsGesture(UIWindow *window) {
    if (!window || window.windowLevel != UIWindowLevelNormal) return;
    if (objc_getAssociatedObject(window, &kAWESettingsGestureKey)) return;

    AWESettingsGestureTarget *target =
        [AWESettingsGestureTarget sharedTarget];

    UILongPressGestureRecognizer *gesture =
        [[UILongPressGestureRecognizer alloc]
            initWithTarget:target
                    action:@selector(openSettingsFromGesture:)];
    gesture.minimumPressDuration = 0.65;
    gesture.numberOfTouchesRequired = 2;
    gesture.allowableMovement = 28.0;
    gesture.cancelsTouchesInView = NO;
    gesture.delaysTouchesBegan = NO;
    gesture.delaysTouchesEnded = NO;
    gesture.delegate = target;

    [window addGestureRecognizer:gesture];
    objc_setAssociatedObject(window, &kAWESettingsGestureKey, gesture,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}


#pragma mark - Hooks

static BOOL AWEGetDoubleTapLocation(id sender,
                                    UIView *fallbackView,
                                    CGPoint *location,
                                    UIView **coordinateView) {
    UIView *referenceView = fallbackView.window ?: fallbackView;
    if (!referenceView || !location) return NO;

    if ([sender isKindOfClass:[UIGestureRecognizer class]]) {
        *location =
            [(UIGestureRecognizer *)sender locationInView:referenceView];
        if (coordinateView) *coordinateView = referenceView;
        return YES;
    }

    if ([sender isKindOfClass:[UITouch class]]) {
        *location = [(UITouch *)sender locationInView:referenceView];
        if (coordinateView) *coordinateView = referenceView;
        return YES;
    }

    return NO;
}


/* 0.0.22d: stable slots + XHS-style native adaptive glass. */
%hook AWEFeedVideoButton

- (void)didMoveToWindow {
    %orig;
    AWEHomeDiagnosticWrite(NO, @"HOOK AWEFeedVideoButton.didMoveToWindow self=%p window=%p", self, ((UIView *)self).window);
    AWEScheduleHomeActionRefreshForButton((UIView *)self);
}

- (void)didMoveToSuperview {
    %orig;
    AWEScheduleHomeActionRefreshForButton((UIView *)self);
}

- (void)layoutSubviews {
    %orig;
    /* The parent AWEElementStackView owns slot geometry. Avoid enqueueing a
       multi-pass refresh for every child layout frame. */
}

- (void)setHidden:(BOOL)hidden {
    BOOL changed = ((UIView *)self).hidden != hidden;
    %orig(hidden);
    if (changed) AWEScheduleHomeActionRefreshForButton((UIView *)self);
}

- (void)setAlpha:(CGFloat)alpha {
    BOOL changed = fabs(((UIView *)self).alpha - alpha) > 0.01;
    %orig(alpha);
    if (changed) AWEScheduleHomeActionRefreshForButton((UIView *)self);
}

- (void)setAccessibilityLabel:(NSString *)label {
    NSString *before = ((UIView *)self).accessibilityLabel;
    BOOL changed = !((before == label) || [before isEqualToString:label]);
    %orig(label);
    if (changed) AWEScheduleHomeActionRefreshForButton((UIView *)self);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    %orig(previousTraitCollection);
    AWEScheduleHomeActionRefreshForButton((UIView *)self);
}

%end


#pragma mark - 1.0.56c13 internal fullscreen (validated 0.5.1 geometry)

static BOOL AWEInternalFullscreenActive(void) {
    if (!AWEPluginFeaturesEnabled() || !AWEInternalFullscreenEnabled()) return NO;
    /* Search result/detail navigation and IM forwarded-media viewers have
       their own bottom input/navigation footprints. Do not apply feed-height
       fullscreen geometry inside those routes. */
    if (AWEShouldSuppressBarForSearch() || AWECurrentMessagingComposerVisible()) {
        return NO;
    }
    return YES;
}

static UIViewController *AWEFSViewControllerForView(UIView *view) {
    UIResponder *responder = view;
    while (responder) {
        responder = [responder nextResponder];
        if ([responder isKindOfClass:UIViewController.class]) {
            return (UIViewController *)responder;
        }
    }
    return nil;
}

static id AWEFSSafeValue(id object, NSString *key) {
    if (!object || key.length == 0) return nil;
    @try {
        return [object valueForKey:key];
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static BOOL AWEFSIsKindOfNamedClass(id object, NSString *name) {
    Class cls = NSClassFromString(name);
    return cls && object && [object isKindOfClass:cls];
}

static void AWEFSCaptureTabBarHeight(UIView *tabBar) {
    if (!tabBar) return;
    CGFloat height = CGRectGetHeight(tabBar.frame);
    if (height >= 30.0) {
        if (gAWEFSOriginalTabBarHeight <= 0.0) gAWEFSOriginalTabBarHeight = height;
        gAWEFSCurrentTabBarHeight = height;
        return;
    }
    UIWindow *window = tabBar.window ?: AWEActiveMainWindow();
    CGFloat fallback = 49.0 + (window ? window.safeAreaInsets.bottom : 0.0);
    if (gAWEFSOriginalTabBarHeight <= 0.0) gAWEFSOriginalTabBarHeight = fallback;
    if (gAWEFSCurrentTabBarHeight <= 0.0) gAWEFSCurrentTabBarHeight = fallback;
}

static CGFloat AWEFSTabBarHeight(void) {
    if (gAWEFSCurrentTabBarHeight > 0.0) return gAWEFSCurrentTabBarHeight;
    if (gAWEFSOriginalTabBarHeight > 0.0) return gAWEFSOriginalTabBarHeight;
    UIWindow *window = AWEActiveMainWindow();
    return 49.0 + (window ? window.safeAreaInsets.bottom : 0.0);
}

static BOOL AWEFSIsTabButton(UIView *view) {
    if (!view) return NO;
    Class general = NSClassFromString(@"AWENormalModeTabBarGeneralButton");
    Class plus = NSClassFromString(@"AWENormalModeTabBarGeneralPlusButton");
    Class uiTabButton = NSClassFromString(@"UITabBarButton");
    return (general && [view isKindOfClass:general]) ||
           (plus && [view isKindOfClass:plus]) ||
           (uiTabButton && [view isKindOfClass:uiTabButton]);
}

static void AWEFSHideTabBackgrounds(UIView *tabBar) {
    if (!tabBar || !AWEInternalFullscreenActive()) return;
    AWEFSCaptureTabBarHeight(tabBar);
    id skin = AWEFSSafeValue(tabBar, @"skinContainerView");
    if ([skin isKindOfClass:UIView.class]) ((UIView *)skin).hidden = YES;

    Class barBackgroundClass = NSClassFromString(@"_UIBarBackground");
    CGFloat tabHeight = AWEFSTabBarHeight();
    for (UIView *subview in [tabBar.subviews copy]) {
        if (AWEFSIsTabButton(subview)) continue;
        BOOL barBackground = barBackgroundClass && [subview isKindOfClass:barBackgroundClass];
        BOOL fullHeightPlain = ([subview class] == UIView.class &&
                                fabs(CGRectGetHeight(subview.frame) - tabHeight) < 0.5);
        BOOL hairline = CGRectGetHeight(subview.frame) > 0.0 &&
                        CGRectGetHeight(subview.frame) < 1.0 &&
                        CGRectGetWidth(subview.frame) > 300.0;
        if (barBackground || fullHeightPlain || hairline) {
            subview.hidden = YES;
            subview.backgroundColor = UIColor.clearColor;
            subview.layer.backgroundColor = UIColor.clearColor.CGColor;
            subview.opaque = NO;
        }
    }
}

static void AWEInternalFSTabBarUpdate(UIView *tabBar) {
    if (!tabBar) return;
    AWEFSCaptureTabBarHeight(tabBar);
    if (AWEInternalFullscreenActive()) AWEFSHideTabBackgrounds(tabBar);
}

static void AWEInternalFSLayoutInteractionController(UIViewController *vc) {
    if (!AWEInternalFullscreenActive() || !vc || !vc.view.superview) return;
    UIWindow *window = vc.view.window ?: AWEActiveMainWindow();
    if (window && window.safeAreaInsets.bottom == 0.0) return;

    UIViewController *parent = vc.parentViewController;
    for (int depth = 0; parent && depth < 3; depth++, parent = parent.parentViewController) {
        if (AWEFSIsKindOfNamedClass(parent, @"AFDPlayRemoteFeedTableViewController")) return;
    }

    CGRect frame = vc.view.frame;
    CGFloat screenWidth = CGRectGetWidth(UIScreen.mainScreen.bounds);
    CGFloat superHeight = CGRectGetHeight(vc.view.superview.frame);
    if (CGRectGetWidth(frame) != screenWidth && CGRectGetHeight(frame) < superHeight) return;

    NSString *refer = AWEFSSafeValue(vc, @"referString");
    BOOL useFullHeight = (refer == nil ||
                          [refer isEqualToString:@"general_search"] ||
                          [refer isEqualToString:@"search_result"] ||
                          [refer isEqualToString:@"search_ecommerce"] ||
                          [refer isEqualToString:@"close_friends_moment"] ||
                          [refer isEqualToString:@"offline_mode"] ||
                          [refer isEqualToString:@"challenge"] ||
                          [refer isEqualToString:@"general_search_scan"]);
    CGFloat targetHeight = useFullHeight ? superHeight : (superHeight - AWEFSTabBarHeight());
    if (targetHeight > 0.0 && fabs(CGRectGetHeight(frame) - targetHeight) > 0.5) {
        frame.size.height = targetHeight;
        vc.view.frame = frame;
    }
}

static void AWEFSExpandContentViewOfController(id controller) {
    if (!AWEInternalFullscreenActive()) return;
    id value = AWEFSSafeValue(controller, @"contentView");
    if (![value isKindOfClass:UIView.class]) return;
    UIView *content = (UIView *)value;
    if (!content.superview) return;

    CGRect frame = content.frame;
    CGFloat parentHeight = CGRectGetHeight(content.superview.frame);
    CGFloat tabHeight = AWEFSTabBarHeight();
    if (fabs(CGRectGetHeight(frame) - (parentHeight - tabHeight)) < 0.75) {
        frame.size.height = parentHeight;
        content.frame = frame;
    } else if (fabs(CGRectGetHeight(frame) - (parentHeight - tabHeight * 2.0)) < 0.75) {
        frame.size.height = parentHeight - tabHeight;
        content.frame = frame;
    }
}

/* 1.0.56c13 performance cleanup: the standalone fullscreen prototype used a
   process-wide UIView::setFrame hook to catch player-owned surfaces. That
   path is very hot in Douyin. Re-assert the same one-tab-short correction
   only while known player controllers lay out, and only inside their small
   local view tree. */
static void AWEFSExpandPlayerOwnedViewTree(UIView *root, int depth) {
    if (!AWEInternalFullscreenActive() || !root || depth > 3) return;
    CGFloat parentHeight = CGRectGetHeight(root.bounds);
    CGFloat tabHeight = AWEFSTabBarHeight();
    if (parentHeight <= 0.0 || tabHeight <= 0.0) return;

    NSArray<UIView *> *children = [root.subviews copy];
    for (UIView *child in children) {
        CGRect frame = child.frame;
        CGFloat height = CGRectGetHeight(frame);
        BOOL originEligible = fabs(frame.origin.x) < 0.5 || fabs(frame.origin.y) < 0.5;
        BOOL oneTabShort = height > 0.0 && height < parentHeight &&
            fabs((parentHeight - height) - tabHeight) < 1.0;
        if (originEligible && oneTabShort) {
            frame.size.height = parentHeight;
            if (!CGRectEqualToRect(child.frame, frame)) child.frame = frame;
        }
        if (depth < 3) AWEFSExpandPlayerOwnedViewTree(child, depth + 1);
    }
}

static BOOL AWEFSViewIsInDetailContext(UIView *view);

static void AWEFSLayoutKnownPlayerController(UIViewController *controller) {
    if (!AWEInternalFullscreenActive() || !controller || !controller.view) return;

    UIView *root = controller.view;

    /* Keep the older stable feed behavior: only expand the explicit player
       contentView during normal Home/Friends playback. 1.0.56c2 moved the
       root and descendant one-tab-short correction into viewDidLayoutSubviews,
       which means every foreground restore and Friends-page relayout can fight
       Douyin immediately after its native player reconciles pause/play state.
       The deeper local-tree correction is only needed for profile/detail media. */
    AWEFSExpandContentViewOfController(controller);

    if (!AWEFSViewIsInDetailContext(root)) return;

    if (root.superview) {
        CGRect frame = root.frame;
        CGFloat parentHeight = CGRectGetHeight(root.superview.frame);
        CGFloat height = CGRectGetHeight(frame);
        CGFloat tabHeight = AWEFSTabBarHeight();
        BOOL originEligible = fabs(frame.origin.x) < 0.5 || fabs(frame.origin.y) < 0.5;
        if (originEligible && parentHeight > 0.0 && height > 0.0 && height < parentHeight &&
            fabs((parentHeight - height) - tabHeight) < 1.0) {
            frame.size.height = parentHeight;
            if (!CGRectEqualToRect(root.frame, frame)) root.frame = frame;
        }
    }
    AWEFSExpandPlayerOwnedViewTree(root, 0);
}

static BOOL AWEFSControllerNameLooksDetail(UIViewController *vc) {
    if (!vc) return NO;
    NSString *name = NSStringFromClass(vc.class);
    return [name containsString:@"AWEAwemeDetailTableViewController"] ||
           [name containsString:@"AWEAwemeDetailCellViewController"] ||
           [name containsString:@"AWEMixVideoPanelDetailTableViewController"] ||
           [name containsString:@"AWECommentInputViewController"] ||
           [name containsString:@"AwemeDetail"] ||
           [name containsString:@"MixVideoPanelDetail"];
}

static BOOL AWEFSViewIsInDetailContext(UIView *view) {
    UIResponder *responder = view;
    int responderDepth = 0;
    while (responder && responderDepth++ < 40) {
        if ([responder isKindOfClass:UIViewController.class]) {
            UIViewController *vc = (UIViewController *)responder;
            UIViewController *current = vc;
            for (int depth = 0; current && depth < 10; depth++, current = current.parentViewController) {
                if (AWEFSControllerNameLooksDetail(current)) return YES;
            }
            if (AWEFSControllerNameLooksDetail(vc.presentingViewController)) return YES;
        }
        responder = [responder nextResponder];
    }
    return NO;
}

static void AWEFSClearBarLikePlainSubviews(UIView *root,
                                            CGFloat referenceWidth,
                                            CGFloat referenceHeight,
                                            int depth) {
    if (!root || depth > 7) return;
    for (UIView *subview in [root.subviews copy]) {
        CGFloat width = CGRectGetWidth(subview.bounds);
        CGFloat height = CGRectGetHeight(subview.bounds);
        BOOL plain = ([subview class] == UIView.class);
        BOOL fullWidth = referenceWidth > 0.0 && width >= referenceWidth * 0.88;
        BOOL barHeight = referenceHeight > 0.0 &&
                         height >= referenceHeight * 0.72 &&
                         height <= referenceHeight * 1.20;
        if (plain && fullWidth && barHeight) {
            subview.backgroundColor = UIColor.clearColor;
            subview.layer.backgroundColor = UIColor.clearColor.CGColor;
            subview.opaque = NO;
        }
        AWEFSClearBarLikePlainSubviews(subview, referenceWidth, referenceHeight, depth + 1);
    }
}

static BOOL AWEFSIsLivePrestreamView(UIView *view) {
    return AWEFSIsKindOfNamedClass(AWEFSViewControllerForView(view),
                                   @"AWELiveNewPreStreamViewController");
}

static CGFloat AWEFSLiveShiftHeight(void) {
    UIWindow *window = AWEActiveMainWindow();
    CGFloat current = AWEFSTabBarHeight();
    if (window && window.safeAreaInsets.bottom == 0.0 && gAWEFSOriginalTabBarHeight > 0.0) {
        return MAX(0.0, current - gAWEFSOriginalTabBarHeight);
    }
    return MAX(0.0, current);
}

static void AWEInternalFSHandleElementStackLayout(UIView *stack) {
    if (!stack) return;
    NSValue *stored = objc_getAssociatedObject(stack, &kAWEFSLiveElementBaseTransformKey);
    BOOL activeLive = AWEInternalFullscreenActive() && AWEFSIsLivePrestreamView(stack);
    if (!activeLive) {
        if (stored) {
            CGAffineTransform base = stored.CGAffineTransformValue;
            if (!CGAffineTransformEqualToTransform(stack.transform, base)) stack.transform = base;
            objc_setAssociatedObject(stack, &kAWEFSLiveElementBaseTransformKey, nil,
                                     OBJC_ASSOCIATION_ASSIGN);
        }
        return;
    }
    if (!stored) {
        stored = [NSValue valueWithCGAffineTransform:stack.transform];
        objc_setAssociatedObject(stack, &kAWEFSLiveElementBaseTransformKey, stored,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    CGAffineTransform base = stored.CGAffineTransformValue;
    CGAffineTransform target = CGAffineTransformTranslate(base, 0.0, -AWEFSLiveShiftHeight());
    if (!CGAffineTransformEqualToTransform(stack.transform, target)) stack.transform = target;
}

static void AWEFSHandleIESLiveStackLayout(UIView *stack) {
    if (!stack) return;
    NSValue *stored = objc_getAssociatedObject(stack, &kAWEFSLiveIESBaseTransformKey);
    BOOL activeLive = AWEInternalFullscreenActive() && AWEFSIsLivePrestreamView(stack);
    if (!activeLive) {
        if (stored) {
            CGAffineTransform base = stored.CGAffineTransformValue;
            if (!CGAffineTransformEqualToTransform(stack.transform, base)) stack.transform = base;
            objc_setAssociatedObject(stack, &kAWEFSLiveIESBaseTransformKey, nil,
                                     OBJC_ASSOCIATION_ASSIGN);
        }
        return;
    }
    if (!stored) {
        stored = [NSValue valueWithCGAffineTransform:stack.transform];
        objc_setAssociatedObject(stack, &kAWEFSLiveIESBaseTransformKey, stored,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    CGAffineTransform base = stored.CGAffineTransformValue;
    CGAffineTransform target = CGAffineTransformTranslate(base, 0.0, -20.0);
    if (!CGAffineTransformEqualToTransform(stack.transform, target)) stack.transform = target;
}

static void AWEFSAdjustMetalCenterIfNeeded(UIView *view, CGPoint *center) {
    if (!AWEInternalFullscreenActive() || !view || !center) return;
    CGFloat screenWidth = CGRectGetWidth(UIScreen.mainScreen.bounds);
    if (CGRectGetWidth(view.bounds) + 0.5 < screenWidth) return;
    UIViewController *vc = AWEFSViewControllerForView(view);
    if (!AWEFSIsKindOfNamedClass(vc, @"AWEPlayVideoViewController")) return;
    id model = AWEFSSafeValue(vc, @"model");
    id landscape = AWEFSSafeValue(model, @"isShowLandscapeEntryView");
    if ([landscape respondsToSelector:@selector(boolValue)] && [landscape boolValue]) {
        center->y -= AWEFSTabBarHeight() * 0.5;
    }
}



/* Fullscreen feed/media hooks. These mirror the independently validated 0.5.1
   behavior and are entirely gated by the internal fullscreen preference. */
%hook AWEFeedTableView
- (void)layoutSubviews {
    %orig;
    if (!AWEInternalFullscreenActive()) return;

    UIView *view = (UIView *)self;
    UIView *superview = view.superview;
    if (!superview) return;

    if ([view isKindOfClass:UIScrollView.class]) {
        UIScrollView *scrollView = (UIScrollView *)view;
        UIGestureRecognizerState panState = scrollView.panGestureRecognizer.state;
        if (scrollView.isTracking || scrollView.isDragging || scrollView.isDecelerating ||
            panState == UIGestureRecognizerStateBegan ||
            panState == UIGestureRecognizerStateChanged) {
            return;
        }
    }

    CGRect frame = view.frame;
    CGFloat targetHeight = CGRectGetHeight(superview.frame);
    CGFloat currentHeight = CGRectGetHeight(frame);
    CGFloat delta = targetHeight - currentHeight;
    CGFloat tabHeight = AWEFSTabBarHeight();
    BOOL oneTabShort = delta > 0.5 &&
        ((tabHeight > 0.0 && fabs(delta - tabHeight) <= 14.0) ||
         (delta >= 38.0 && delta <= 110.0));
    if (targetHeight > 0.0 && oneTabShort) {
        frame.size.height = targetHeight;
        view.frame = frame;
    }
}
%end

%hook AWEDPlayerFeedPlayerViewController
- (void)viewDidLayoutSubviews {
    %orig;
    AWEFSLayoutKnownPlayerController((UIViewController *)self);
}
%end

%hook AWEDPlayerViewController_Merge
- (void)viewDidLayoutSubviews {
    %orig;
    AWEFSLayoutKnownPlayerController((UIViewController *)self);
}
%end

%hook AWEAwemePlayVideoViewController
- (void)viewDidLayoutSubviews {
    %orig;
    AWEFSLayoutKnownPlayerController((UIViewController *)self);
}
%end

%hook AWEPlayVideoViewController
- (void)viewDidLayoutSubviews {
    %orig;
    AWEFSLayoutKnownPlayerController((UIViewController *)self);
}
%end

/* 1.0.56c13 intentionally has no process-wide %hook UIView. Detail comment
   background cleanup remains on AWECommentInputBackgroundView and Douyin's
   Swift CommentInputContainerView below; clean-screen persistence remains on
   its explicit target hooks plus bounded rescans. */

/* 0.3.1 live-prestream behavior, retained exactly while fullscreen is active. */
%hook IESLiveStackView
- (void)layoutSubviews {
    %orig;
    AWEFSHandleIESLiveStackLayout((UIView *)self);
}
%end

%hook AWEStoryContainerCollectionView
- (void)layoutSubviews {
    %orig;
    if (!AWEInternalFullscreenActive()) return;
    UIView *collection = (UIView *)self;
    if (collection.subviews.count == 2) return;

    id enableEnterProfile = AWEFSSafeValue(self, @"enableEnterProfile");
    BOOL isHome = [enableEnterProfile respondsToSelector:@selector(boolValue)] &&
                  [enableEnterProfile boolValue];
    if (!isHome) return;

    for (UIView *subview in [collection.subviews copy]) {
        UIResponder *next = [subview nextResponder];
        if (!AWEFSIsKindOfNamedClass(next, @"AWEPlayInteractionViewController")) continue;
        id base = AWEFSSafeValue(next, @"awemeBaseViewController");
        if (!AWEFSIsKindOfNamedClass(base, @"AWEFeedCellViewController") || !subview.superview) continue;
        CGRect frame = subview.frame;
        frame.size.height = CGRectGetHeight(subview.superview.frame) - AWEFSTabBarHeight();
        subview.frame = frame;
    }
}
%end

%hook TTMetalView
- (void)setCenter:(CGPoint)center {
    AWEFSAdjustMetalCenterIfNeeded((UIView *)self, &center);
    %orig(center);
}
%end

%hook TTMetalViewNew
- (void)setCenter:(CGPoint)center {
    AWEFSAdjustMetalCenterIfNeeded((UIView *)self, &center);
    %orig(center);
}
%end

%hook AWEStoryProgressContainerView
- (void)setCenter:(CGPoint)center {
    if (AWEInternalFullscreenActive()) {
        UIViewController *vc = AWEFSViewControllerForView((UIView *)self);
        if ([NSStringFromClass(vc.class) isEqualToString:@"AWEFeedPlayControlImpl.PureModePageCellViewController"]) {
            center.y -= AWEFSTabBarHeight();
        }
    }
    %orig(center);
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
}
- (void)layoutSubviews {
    %orig;
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
}
- (void)didMoveToWindow {
    %orig;
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
}
- (void)setAlpha:(CGFloat)alpha {
    %orig(alpha);
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
}
%end

%hook AWEAwemeDetailTableView
- (void)setFrame:(CGRect)frame {
    if (AWEInternalFullscreenActive()) {
        CGFloat screenHeight = CGRectGetHeight(UIScreen.mainScreen.bounds);
        if (screenHeight > 0.0 && frame.size.height > 0.0) {
            CGFloat remainder = fmod(frame.size.height, screenHeight);
            if (remainder > 0.5 && (screenHeight - remainder) > 0.5) {
                frame.size.height += (screenHeight - remainder);
            }
        }
    }
    %orig(frame);
}
%end

%hook AWEMixVideoPanelMoreView
- (void)setFrame:(CGRect)frame {
    if (AWEInternalFullscreenActive()) {
        CGFloat tabHeight = AWEFSTabBarHeight();
        CGFloat screenHeight = CGRectGetHeight(UIScreen.mainScreen.bounds);
        if (tabHeight > 0.0 && screenHeight > 0.0) {
            CGFloat targetY = frame.origin.y - tabHeight;
            CGFloat expected = screenHeight - tabHeight;
            if (fabs(targetY - expected) <= 10.0) frame.origin.y = targetY;
        }
    }
    %orig(frame);
}
- (void)layoutSubviews {
    %orig;
    if (AWEInternalFullscreenActive()) ((UIView *)self).backgroundColor = UIColor.clearColor;
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
}
%end

%hook AWEPlayInteractionProgressContainerView
- (void)layoutSubviews {
    %orig;
    if (AWEInternalFullscreenActive()) {
        for (UIView *subview in [(UIView *)self subviews]) {
            if ([subview class] == UIView.class) subview.backgroundColor = UIColor.clearColor;
        }
    }
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
}
- (void)didMoveToWindow {
    %orig;
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
}
- (void)setAlpha:(CGFloat)alpha {
    %orig(alpha);
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
}
%end

%hook AWEDPlayerProgressContainerView
- (void)layoutSubviews {
    %orig;
    if (AWEInternalFullscreenActive()) {
        for (UIView *subview in [(UIView *)self subviews]) {
            UIColor *background = subview.backgroundColor;
            if (!background) continue;
            CGFloat white = 0.0, alpha = 0.0;
            if ([background getWhite:&white alpha:&alpha] && white < 0.2) {
                subview.backgroundColor = UIColor.clearColor;
            }
        }
    }
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
}
- (void)didMoveToWindow {
    %orig;
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
}
- (void)setAlpha:(CGFloat)alpha {
    %orig(alpha);
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
}
%end

%hook AWECommentInputBackgroundView
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (AWEInternalFullscreenActive() && AWEFSViewIsInDetailContext((UIView *)self)) {
        %orig(UIColor.clearColor);
        return;
    }
    %orig(backgroundColor);
}
- (void)layoutSubviews {
    %orig;
    UIView *view = (UIView *)self;
    if (!AWEInternalFullscreenActive() || !AWEFSViewIsInDetailContext(view)) return;
    CGFloat tabHeight = AWEFSTabBarHeight();
    view.backgroundColor = UIColor.clearColor;
    view.layer.backgroundColor = UIColor.clearColor.CGColor;
    view.opaque = NO;
    AWEFSClearBarLikePlainSubviews(view, CGRectGetWidth(view.bounds), tabHeight, 0);
}
%end

/* The validated 0.5.1 profile/detail path also directly hooks Douyin's Swift
   comment-input container. Keep this exact cleanup in the integrated build so
   the 83pt opaque blocker cannot reappear when that Swift subtree rebuilds. */
%group AWEInternalFSCommentInputGroup
%hook AWEInternalFSCommentInputContainerView
- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (AWEInternalFullscreenActive() && AWEFSViewIsInDetailContext((UIView *)self)) {
        %orig(UIColor.clearColor);
        return;
    }
    %orig(backgroundColor);
}
- (void)layoutSubviews {
    %orig;
    UIView *container = (UIView *)self;
    if (!AWEInternalFullscreenActive() || !AWEFSViewIsInDetailContext(container)) return;
    CGFloat tabHeight = AWEFSTabBarHeight();
    CGFloat width = CGRectGetWidth(container.bounds);
    if (tabHeight <= 0.0 || width <= 0.0) return;

    container.backgroundColor = UIColor.clearColor;
    container.layer.backgroundColor = UIColor.clearColor.CGColor;
    container.opaque = NO;

    UIView *target = objc_getAssociatedObject(container, &kAWEFSCommentDirectBackgroundKey);
    if (!target || target.superview != container) {
        target = nil;
        for (UIView *subview in [container.subviews copy]) {
            if ([subview class] == UIView.class) {
                target = subview;
                objc_setAssociatedObject(container, &kAWEFSCommentDirectBackgroundKey,
                                         target, OBJC_ASSOCIATION_ASSIGN);
                break;
            }
        }
    }
    if (target) {
        target.backgroundColor = UIColor.clearColor;
        target.layer.backgroundColor = UIColor.clearColor.CGColor;
        target.opaque = NO;
    }
    AWEFSClearBarLikePlainSubviews(container, width, tabHeight, 0);
}
%end
%end

static BOOL AWEPlaybackPreferenceCanBiasNow(void) {
    UIApplication *application = UIApplication.sharedApplication;
    if (application.applicationState != UIApplicationStateActive) return NO;
    return CACurrentMediaTime() >= gAWEPlaybackPreferenceResumeGraceUntil;
}

/* Highest-quality preference is now advisory rather than destructive: preserve
   Douyin's complete adaptive set, order the best advertised bitrate first, and
   never rewrite playURL or force-switch a live private player. */
%hook AWEVideoModel
- (NSArray *)bitrateModels {
    NSArray *originalModels = %orig;
    if (!AWEPreferHighestPlaybackEnabled() || !AWEPlaybackPreferenceCanBiasNow() ||
        originalModels.count < 2) {
        return originalModels;
    }

    /* Stability-first highest-quality preference. Older builds replaced the
       whole adaptive set with a single model (and overrode playURL). After an
       app background/foreground cycle Douyin may need the previously selected
       adaptive model to reconcile playback; removing it can produce a second
       native pause immediately after the user's tap. Preserve every model and
       only bias native selection by ordering the highest bitrate first. */
    return [originalModels sortedArrayUsingComparator:^NSComparisonResult(id lhs, id rhs) {
        long long left = AWEInteger64FromValue(
            AWEFirstSafeValue(lhs, @[@"bitrate", @"bitRate", @"videoBitrate",
                                    @"avgBitrate", @"bitrateInBps", @"bitRateInBps"]));
        long long right = AWEInteger64FromValue(
            AWEFirstSafeValue(rhs, @[@"bitrate", @"bitRate", @"videoBitrate",
                                    @"avgBitrate", @"bitrateInBps", @"bitRateInBps"]));
        if (left > right) return NSOrderedAscending;
        if (left < right) return NSOrderedDescending;
        return NSOrderedSame;
    }];
}
%end

/* Clean-screen status-bar ownership follows the same feed/detail/live roots
   used by Douyin/DYYY.  Outside clean mode every controller returns its exact
   original status-bar decision. */
%hook AWEFeedRootViewController
- (BOOL)prefersStatusBarHidden {
    if (gAWEStableCleanScreenEnabled) return YES;
    return %orig;
}
%end
%hook IESLiveAudienceViewController
- (BOOL)prefersStatusBarHidden {
    if (gAWEStableCleanScreenEnabled) return YES;
    return %orig;
}
%end
%hook AWEAwemeDetailTableViewController
- (BOOL)prefersStatusBarHidden {
    if (gAWEStableCleanScreenEnabled) return YES;
    return %orig;
}
%end
%hook AWEAwemeHotSpotTableViewController
- (BOOL)prefersStatusBarHidden {
    if (gAWEStableCleanScreenEnabled) return YES;
    return %orig;
}
%end
%hook AWEFullPageFeedNewContainerViewController
- (BOOL)prefersStatusBarHidden {
    if (gAWEStableCleanScreenEnabled) return YES;
    return %orig;
}
%end
%hook AFDPureModePageContainerViewController
- (BOOL)prefersStatusBarHidden {
    if (gAWEStableCleanScreenEnabled) return YES;
    return %orig;
}
%end

/* Clean-screen transition guards: newly reused cells and new aweme models get
   a short bounded re-scan instead of a permanent 0.2s timer. */
%hook AWEFeedTableViewCell
- (void)prepareForReuse {
    %orig;
    if (gAWEStableCleanScreenEnabled) AWEScheduleCleanScreenReapply(@"cell.prepareForReuse");
}
- (void)layoutSubviews {
    %orig;
}
%end

%hook AWEFeedViewCell
- (void)layoutSubviews {
    %orig;
}
- (void)setModel:(id)model {
    %orig(model);
    if (gAWEStableCleanScreenEnabled) AWEScheduleCleanScreenReapply(@"feedViewCell.model");
}
%end

%hook AWEFeedContainerViewController
- (void)aweme:(id)aweme currentIndexWillChange:(NSInteger)index {
    %orig(aweme, index);
    if (gAWEStableCleanScreenEnabled) AWEScheduleCleanScreenReapply(@"index.willChange");
}
- (void)aweme:(id)aweme currentIndexDidChange:(NSInteger)index {
    %orig(aweme, index);
    if (gAWEStableCleanScreenEnabled) AWEScheduleCleanScreenReapply(@"index.didChange");
    if (gAWEAlbumMorphVisible) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.06 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            AWERefreshAlbumMorphTintFromSystemProbe();
        });
    }
    /* A few Home article/feed models leave the native bar hidden after reuse.
       Re-evaluate once after the item switch; the Home-feed visibility rule
       above decides whether the replacement should be restored. */
    if (AWEAlbumMorphStyleEnabled()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.08 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            AWEScheduleTransitionRecovery();
        });
    }
}
- (void)viewWillLayoutSubviews {
    %orig;
}
%end

/* Native elements specifically called out by clean-screen regressions. */
%hook AWELandscapeFeedEntryView
- (void)layoutSubviews {
    %orig;
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanSuppressView((UIView *)self, YES);
    }
}
- (void)didMoveToWindow {
    %orig;
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanSuppressView((UIView *)self, YES);
    }
}
- (void)setAlpha:(CGFloat)alpha {
    %orig(alpha);
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanSuppressView((UIView *)self, YES);
    }
}
%end

%hook AWEVideoPlayDanmakuContainerView
- (void)layoutSubviews {
    %orig;
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanSuppressView((UIView *)self, YES);
    }
}
- (void)setAlpha:(CGFloat)alpha {
    %orig(alpha);
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanSuppressView((UIView *)self, YES);
    }
}
%end

%hook AWEDanmakuContainerView
- (void)layoutSubviews {
    %orig;
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanSuppressView((UIView *)self, YES);
    }
}
- (void)setAlpha:(CGFloat)alpha {
    %orig(alpha);
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanSuppressView((UIView *)self, YES);
    }
}
%end

%hook AWEStoryProgressSlideView
- (void)layoutSubviews {
    %orig;
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanSuppressView((UIView *)self, YES);
    }
}
- (void)setAlpha:(CGFloat)alpha {
    %orig(alpha);
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanSuppressView((UIView *)self, YES);
    }
}
%end

%hook AWEDemaciaChapterProgressSlider
- (void)layoutSubviews {
    %orig;
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanSuppressView((UIView *)self, YES);
    }
}
- (void)setAlpha:(CGFloat)alpha {
    %orig(alpha);
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanSuppressView((UIView *)self, YES);
    }
}
%end

%hook AFDAIbumFolioView
- (void)layoutSubviews {
    %orig;
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanSuppressView((UIView *)self, YES);
    }
}
- (void)setAlpha:(CGFloat)alpha {
    %orig(alpha);
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanSuppressView((UIView *)self, YES);
    }
}
%end

%hook AFDAlbumFolioView
- (void)layoutSubviews {
    %orig;
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanSuppressView((UIView *)self, YES);
    }
}
- (void)setAlpha:(CGFloat)alpha {
    %orig(alpha);
    if (gAWEStableCleanScreenEnabled) {
        AWEStableCleanSuppressView((UIView *)self, YES);
    }
}
%end


%hook AWEElementStackView

- (void)didMoveToWindow {
    %orig;
    AWEHomeDiagnosticWrite(NO, @"HOOK AWEElementStackView.didMoveToWindow self=%p window=%p", self, ((UIView *)self).window);
    if (((UIView *)self).window) AWEScheduleHomeActionStackRefresh((UIView *)self);
    else AWERefreshHomeActionStack((UIView *)self);
    if (((UIView *)self).window && AWEStableCleanShouldSuppressElementStack((UIView *)self)) {
        gAWEStableCleanScreenStack = (UIView *)self;
        AWEStableCleanSuppressRightStack((UIView *)self);
    }
}

- (void)didMoveToSuperview {
    %orig;
    AWEScheduleHomeActionStackRefresh((UIView *)self);
    if (((UIView *)self).superview && AWEStableCleanShouldSuppressElementStack((UIView *)self)) {
        gAWEStableCleanScreenStack = (UIView *)self;
        AWEStableCleanSuppressRightStack((UIView *)self);
    }
}

- (void)removeFromSuperview {
    UIView *stack = (UIView *)self;
    if (AWEProfileFullscreenRightProtectionActiveForStack(stack)) {
        AWEForceRestoreRightActionStackAfterComment(stack);
        AWERefreshExternalBridgeMenu(stack);
        AWEInteractionDiagnosticWrite(
            @"RIGHT_FULLSCREEN_BLOCK_REMOVE stack=%@",
            AWEInteractionObjectSummary(stack));
        return;
    }
    %orig;
}

- (void)layoutSubviews {
    %orig;
    AWEInternalFSHandleElementStackLayout((UIView *)self);
    /* Geometry-only pass. The source buttons and cached glass children move
       together with the stack, so a full hierarchy scan on every video frame
       only causes heat and material flashes. */
    AWELayoutBoundHomeActionSlots((UIView *)self);
    if (AWEStableCleanShouldSuppressElementStack((UIView *)self)) {
        gAWEStableCleanScreenStack = (UIView *)self;
        AWEStableCleanSuppressRightStack((UIView *)self);
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    %orig(previousTraitCollection);
    AWERefreshHomeActionStack((UIView *)self);
}

- (void)setHidden:(BOOL)hidden {
    UIView *stack = (UIView *)self;
    if (AWEStableCleanShouldSuppressElementStack((UIView *)self)) {
        %orig(NO);
        gAWEStableCleanScreenStack = stack;
        AWEStableCleanSuppressRightStack(stack);
        return;
    }
    if (hidden && AWEProfileFullscreenRightProtectionActiveForStack(stack)) {
        %orig(NO);
        AWEForceRestoreRightActionStackAfterComment(stack);
        AWERefreshExternalBridgeMenu(stack);
        AWEInteractionDiagnosticWrite(
            @"RIGHT_FULLSCREEN_BLOCK_HIDE stack=%@",
            AWEInteractionObjectSummary(stack));
        return;
    }
    BOOL changed = stack.hidden != hidden;
    %orig(hidden);
    if (!changed) return;
    if (!hidden) {
        AWEScheduleHomeActionStackRefresh(stack);
    } else {
        AWEScheduleFullscreenStackVisibilityProtection(stack, @"stack.hidden");
    }
}

- (void)setAlpha:(CGFloat)alpha {
    UIView *stack = (UIView *)self;
    if (AWEStableCleanShouldSuppressElementStack((UIView *)self)) {
        %orig(1.0);
        gAWEStableCleanScreenStack = stack;
        AWEStableCleanSuppressRightStack(stack);
        return;
    }
    if (alpha <= 0.01 && AWEProfileFullscreenRightProtectionActiveForStack(stack)) {
        %orig(1.0);
        AWEForceRestoreRightActionStackAfterComment(stack);
        AWERefreshExternalBridgeMenu(stack);
        AWEInteractionDiagnosticWrite(
            @"RIGHT_FULLSCREEN_BLOCK_ALPHA stack=%@",
            AWEInteractionObjectSummary(stack));
        return;
    }
    CGFloat before = stack.alpha;
    BOOL changed = fabs(before - alpha) > 0.01;
    %orig(alpha);
    if (!changed) return;
    if (alpha > 0.01) {
        AWEScheduleHomeActionStackRefresh(stack);
    } else {
        AWEScheduleFullscreenStackVisibilityProtection(stack, @"stack.alpha");
    }
}

- (void)didAddSubview:(UIView *)subview {
    %orig(subview);
    AWEScheduleHomeActionStackRefresh((UIView *)self);
    if (AWEStableCleanShouldSuppressElementStack((UIView *)self)) {
        gAWEStableCleanScreenStack = (UIView *)self;
        AWEStableCleanSuppressRightStack((UIView *)self);
    }
}

- (void)setFrame:(CGRect)frame {
    %orig(frame);
    AWELayoutBoundHomeActionSlots((UIView *)self);
}

- (void)setCenter:(CGPoint)center {
    %orig(center);
}

- (void)setBounds:(CGRect)bounds {
    %orig(bounds);
    AWELayoutBoundHomeActionSlots((UIView *)self);
}

- (void)setTransform:(CGAffineTransform)transform {
    /* Children inherit the stack transform. Do not rebuild their glass while
       the paging gesture is in flight. */
    %orig(transform);
}

%end

/* Keep the currently bound solid PNG suppressed when Douyin swaps/reuses it. */
%hook UIImageView

- (void)setImage:(UIImage *)image {
    %orig(image);
    UIView *owner = objc_getAssociatedObject((UIImageView *)self,
                                              &kAWEHomeActionSourceOwnerKey);
    if (owner) AWEScheduleHomeActionRefreshForButton(owner);
    AWEHomeTopSlotView *topSlot = objc_getAssociatedObject(
        (UIImageView *)self, &kAWETopSourceSlotKey);
    if (topSlot.superview) AWEScheduleTopActionContainerRefresh(topSlot.superview);
}

- (void)setTintColor:(UIColor *)tintColor {
    %orig(tintColor);
    UIView *owner = objc_getAssociatedObject((UIImageView *)self,
                                              &kAWEHomeActionSourceOwnerKey);
    if (owner) AWEScheduleHomeActionRefreshForButton(owner);
    AWEHomeTopSlotView *topSlot = objc_getAssociatedObject(
        (UIImageView *)self, &kAWETopSourceSlotKey);
    if (topSlot.superview) AWEScheduleTopActionContainerRefresh(topSlot.superview);
}

- (void)setHidden:(BOOL)hidden {
    UIView *owner = objc_getAssociatedObject((UIImageView *)self,
                                              &kAWEHomeActionSourceOwnerKey);
    if (owner && !hidden) {
        %orig(YES);
        AWEScheduleHomeActionRefreshForButton(owner);
        return;
    }
    AWEHomeTopSlotView *topSlot = objc_getAssociatedObject(
        (UIImageView *)self, &kAWETopSourceSlotKey);
    if (topSlot && !hidden) {
        %orig(YES);
        if (topSlot.superview) AWEScheduleTopActionContainerRefresh(topSlot.superview);
        return;
    }
    %orig(hidden);
}

- (void)setAlpha:(CGFloat)alpha {
    UIView *owner = objc_getAssociatedObject((UIImageView *)self,
                                              &kAWEHomeActionSourceOwnerKey);
    if (owner) {
        %orig(0.0);
        return;
    }
    AWEHomeTopSlotView *topSlot = objc_getAssociatedObject(
        (UIImageView *)self, &kAWETopSourceSlotKey);
    if (topSlot) {
        %orig(0.0);
        return;
    }
    %orig(alpha);
}

%end

%hook AWEFeedTopBarContainer

- (void)didMoveToWindow {
    %orig;
    UIView *container = (UIView *)self;
    if (container.window) gAWEHomeFeedTopContainer = container;
    else if (gAWEHomeFeedTopContainer == container) gAWEHomeFeedTopContainer = nil;
    AWEMarkTopCategorySuppressionCacheDirty(container);
    if (AWETopMenuMorphEnabled())
        AWEApplyTopCategoryVisualSuppression((UIView *)self, YES);
    AWEHomeDiagnosticWrite(NO, @"HOOK AWEFeedTopBarContainer.didMoveToWindow self=%p window=%p", self, ((UIView *)self).window);
    AWEScheduleTopActionContainerRefresh((UIView *)self);
}

- (void)didMoveToSuperview {
    %orig;
    UIView *container = (UIView *)self;
    if (container.window) gAWEHomeFeedTopContainer = container;
    AWEMarkTopCategorySuppressionCacheDirty(container);
    if (AWETopMenuMorphEnabled())
        AWEApplyTopCategoryVisualSuppression((UIView *)self, YES);
    AWEScheduleTopActionContainerRefresh((UIView *)self);
}

- (void)layoutSubviews {
    %orig;
    if (AWETopMenuMorphEnabled())
        AWEApplyTopCategoryVisualSuppression((UIView *)self, YES);
    AWELayoutExistingTopChrome((UIView *)self);
    if (!objc_getAssociatedObject((UIView *)self, &kAWETopMenuSlotKey) &&
        !objc_getAssociatedObject((UIView *)self, &kAWETopSearchSlotKey) &&
        !objc_getAssociatedObject((UIView *)self, &kAWETopLiquidGroupViewKey)) {
        AWEScheduleTopActionContainerRefresh((UIView *)self);
    }
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
}

- (void)setHidden:(BOOL)hidden {
    %orig(hidden);
    if (!hidden) AWEScheduleTopActionContainerRefresh((UIView *)self);
}

- (void)setAlpha:(CGFloat)alpha {
    %orig(alpha);
    if (alpha > 0.01) AWEScheduleTopActionContainerRefresh((UIView *)self);
}

- (void)setTransform:(CGAffineTransform)transform {
    %orig(transform);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    %orig(previousTraitCollection);
    AWEMarkTopCategorySuppressionCacheDirty((UIView *)self);
    AWERefreshTopActionContainer((UIView *)self);
}

%end

/* Douyin recreates/moves this 24 x 9 selected underline after the parent top
   bar has laid out. Re-assert layer-only suppression on the exact runtime
   class so a selected tab cannot flash its small horizontal marker back. */
%hook AWEFeedMultiTabSelectedContainerView

- (void)didMoveToWindow {
    %orig;
    AWEForceExactTopIndicatorSuppression((UIView *)self);
    AWEScheduleTopActionGlass((UIView *)self);
}

- (void)didMoveToSuperview {
    %orig;
    AWEForceExactTopIndicatorSuppression((UIView *)self);
    AWEScheduleTopActionGlass((UIView *)self);
}

- (void)layoutSubviews {
    %orig;
    AWEForceExactTopIndicatorSuppression((UIView *)self);
    AWESyncTopSelectionPillToNativeIndicator((UIView *)self);
    AWETrackTopSelectionPresentationIfNeeded((UIView *)self);
}

- (void)setFrame:(CGRect)frame {
    %orig(frame);
    AWEForceExactTopIndicatorSuppression((UIView *)self);
    AWESyncTopSelectionPillToNativeIndicator((UIView *)self);
    AWETrackTopSelectionPresentationIfNeeded((UIView *)self);
}

- (void)setCenter:(CGPoint)center {
    %orig(center);
    AWESyncTopSelectionPillToNativeIndicator((UIView *)self);
    AWETrackTopSelectionPresentationIfNeeded((UIView *)self);
}

- (void)setBounds:(CGRect)bounds {
    %orig(bounds);
    AWESyncTopSelectionPillToNativeIndicator((UIView *)self);
}

- (void)setTransform:(CGAffineTransform)transform {
    %orig(transform);
    AWESyncTopSelectionPillToNativeIndicator((UIView *)self);
    AWETrackTopSelectionPresentationIfNeeded((UIView *)self);
}

%end


/* Native Douyin Settings-page entry. DYKiller hooks AWESettingsViewModel's
   sectionDataArray, recognizes the real main Settings page by its “账号”
   section, and inserts a normal AWESettingItemModel section. Mirror that
   model-level route rather than depending on sidebar accessibility layouts. */
%hook AWESettingsViewModel

- (NSArray *)sectionDataArray {
    NSArray *sections = %orig;
    if (![sections isKindOfClass:NSArray.class]) return sections;

    BOOL isMainSettingsPage = NO;
    BOOL alreadyInserted = NO;
    for (id obj in sections) {
        if (![obj isKindOfClass:%c(AWESettingSectionModel)]) continue;
        AWESettingSectionModel *section = (AWESettingSectionModel *)obj;
        NSString *header = section.sectionHeaderTitle;
        if ([header isEqualToString:@"账号"]) isMainSettingsPage = YES;
        if ([header isEqualToString:@"LiquidBar"]) alreadyInserted = YES;
    }
    if (!isMainSettingsPage || alreadyInserted) return sections;

    AWESettingItemModel *entry = [[%c(AWESettingItemModel) alloc] init];
    entry.identifier = @"AwemeLiquidBar.Settings";
    entry.title = @"LiquidBar";
    entry.detail = @"1.0.56c13";
    entry.type = 0;
    entry.svgIconImageName = @"ic_gearsimplify_outlined_20";
    entry.cellType = 26;
    entry.colorStyle = 0;
    entry.isEnable = YES;

    __weak AWESettingsViewModel *weakSelf = self;
    entry.cellTappedBlock = ^{
        AWESettingsViewModel *strongSelf = weakSelf;
        if (!strongSelf) return;
        UIViewController *host = (UIViewController *)strongSelf.controllerDelegate;
        if (!host) host = AWETopViewControllerFrom(AWEActiveMainWindow().rootViewController);
        AWEPresentLiquidSettingsFromNativeEntry(host);
    };

    AWESettingSectionModel *liquidSection = [[%c(AWESettingSectionModel) alloc] init];
    liquidSection.itemArray = @[entry];
    liquidSection.type = 0;
    liquidSection.sectionHeaderHeight = 40.0;
    liquidSection.sectionHeaderTitle = @"LiquidBar";

    NSMutableArray *result = [NSMutableArray arrayWithArray:sections];
    [result insertObject:liquidSection atIndex:0];
    return result;
}

%end

%hook AWELeftSideBarEntranceView

- (void)didMoveToWindow {
    %orig;
    AWEHomeDiagnosticWrite(
        NO,
        @"HOOK %@.didMoveToWindow self=%p frame=%@",
        NSStringFromClass([self class]),
        self,
        NSStringFromCGRect(((UIView *)self).frame));
    AWEScheduleTopActionGlass((UIView *)self);
}
- (void)didMoveToSuperview {
    %orig;
    AWEHomeDiagnosticWrite(
        NO,
        @"HOOK %@.didMoveToSuperview self=%p",
        NSStringFromClass([self class]),
        self);
    AWEScheduleTopActionGlass((UIView *)self);
}
- (void)layoutSubviews {
    %orig;
    AWEHomeDiagnosticWrite(
        NO,
        @"HOOK %@.layout self=%p frame=%@",
        NSStringFromClass([self class]),
        self,
        NSStringFromCGRect(((UIView *)self).frame));
    AWEConfigureTopActionGlass((UIView *)self);
}
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    %orig(previousTraitCollection);
    AWEConfigureTopActionGlass((UIView *)self);
}

%end

%hook AWEHPDiscoverFeedEntranceView

- (void)didMoveToWindow {
    %orig;
    AWEScheduleTopActionGlass((UIView *)self);
}
- (void)didMoveToSuperview {
    %orig;
    AWEScheduleTopActionGlass((UIView *)self);
}
- (void)layoutSubviews {
    %orig;
    AWEConfigureTopActionGlass((UIView *)self);
}

%end

%hook AWEHPSearchBubbleEntranceView

- (void)didMoveToWindow {
    %orig;
    AWEHomeDiagnosticWrite(
        NO,
        @"HOOK %@.didMoveToWindow self=%p frame=%@",
        NSStringFromClass([self class]),
        self,
        NSStringFromCGRect(((UIView *)self).frame));
    AWEScheduleTopActionGlass((UIView *)self);
}
- (void)didMoveToSuperview {
    %orig;
    AWEHomeDiagnosticWrite(
        NO,
        @"HOOK %@.didMoveToSuperview self=%p",
        NSStringFromClass([self class]),
        self);
    AWEScheduleTopActionGlass((UIView *)self);
}
- (void)layoutSubviews {
    %orig;
    AWEHomeDiagnosticWrite(
        NO,
        @"HOOK %@.layout self=%p frame=%@",
        NSStringFromClass([self class]),
        self,
        NSStringFromCGRect(((UIView *)self).frame));
    AWEConfigureTopActionGlass((UIView *)self);
}
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    %orig(previousTraitCollection);
    AWEConfigureTopActionGlass((UIView *)self);
}

%end


%hook AWEPlayInteractionViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);
    AWEScheduleHomeActionStacksInView(self.view);
}

- (void)viewDidLayoutSubviews {
    %orig;
    AWEInternalFSLayoutInteractionController((UIViewController *)self);
    AWEScheduleHomeActionStacksInView(self.view);
    if (gAWEStableCleanScreenEnabled) {
        AWEScheduleCleanScreenReapply(@"interaction.layout");
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    AWEScheduleHomeActionStacksInView(self.view);
}

- (void)onVideoPlayerViewDoubleClicked:(id)sender {
    if (!AWEPluginFeaturesEnabled()) {
        %orig(sender);
        return;
    }
    BOOL enabled =
        [[NSUserDefaults standardUserDefaults]
            boolForKey:kAWELowerHalfDoubleTapCommentDefaultsKey];

    if (!enabled) {
        %orig(sender);
        return;
    }

    CGPoint location = CGPointZero;
    UIView *coordinateView = nil;
    if (!AWEGetDoubleTapLocation(sender, self.view,
                                 &location, &coordinateView) ||
        !coordinateView) {
        /*
         Unknown sender type in an untested Douyin build: preserve the native
         action rather than swallowing double-tap.
        */
        %orig(sender);
        return;
    }

    CGFloat splitY = CGRectGetMinY(coordinateView.bounds) +
                     CGRectGetHeight(coordinateView.bounds) *
                         AWEStoredDoubleTapLikeFraction();
    if (location.y < splitY) {
        /* Upper configured region: preserve native like and animation. */
        %orig(sender);
        return;
    }

    BOOL commentShowing = NO;
    @try {
        commentShowing =
            [[self valueForKey:@"isCommentVCShowing"] boolValue];
    } @catch (__unused NSException *exception) {
        commentShowing = NO;
    }

    if (!commentShowing &&
        [self respondsToSelector:@selector(performCommentAction)]) {
        [self performCommentAction];
        return;
    }

    /*
     If the private comment route is unavailable, fall back to the original
     double-tap so the gesture never becomes a dead zone.
    */
    if (![self respondsToSelector:@selector(performCommentAction)]) {
        %orig(sender);
    }
}

%end

/*
 FLEX identified this exact hierarchy:

 IESIMGrowingTextView
   └─ IESIMTextViewInternal  frame {{39, 3.5}, {251, 44}}
        └─ _UITextContainerView
             └─ _UITextLayoutCanvasView

 Moving IESIMTextViewInternal therefore moves the placeholder, cursor and
 entered text together. Douyin reapplies the original frame after the input
 controller's layout pass, so enforce the offset at the class's own frame
 boundary rather than trying to patch it from the controller.
*/
%hook IESIMTextViewInternal

- (void)setFrame:(CGRect)frame {
    UIView *internalView = (UIView *)self;
    BOOL shouldShift =
        AWEChatCapsuleEnabled() && AWEChatSeparateLeftEnabled();

    NSValue *baseValue =
        objc_getAssociatedObject(internalView, &kAWEChatTextBaseFrameKey);
    NSValue *appliedValue =
        objc_getAssociatedObject(internalView, &kAWEChatTextAppliedFrameKey);

    CGRect baseFrame = frame;

    if (shouldShift) {
        /*
         When UIKit/Douyin passes our already-adjusted frame back through the
         setter, retain the stored original instead of adding another 10 pt.
         Any genuinely new layout frame becomes the new base.
        */
        if (baseValue && appliedValue &&
            AWEFrameNearEqual(frame, appliedValue.CGRectValue)) {
            baseFrame = baseValue.CGRectValue;
        } else {
            objc_setAssociatedObject(internalView,
                                     &kAWEChatTextBaseFrameKey,
                                     [NSValue valueWithCGRect:frame],
                                     OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }

        CGRect adjustedFrame = baseFrame;
        CGFloat shift = MIN(10.0,
                            MAX(0.0,
                                CGRectGetWidth(baseFrame) - 20.0));
        adjustedFrame.origin.x += shift;
        adjustedFrame.size.width =
            MAX(20.0, adjustedFrame.size.width - shift);

        objc_setAssociatedObject(internalView,
                                 &kAWEChatTextAppliedFrameKey,
                                 [NSValue valueWithCGRect:adjustedFrame],
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        %orig(adjustedFrame);
        return;
    }

    /*
     When separation is disabled, restore the pre-adjustment frame if the
     current incoming value is our last adjusted result.
    */
    if (baseValue && appliedValue &&
        AWEFrameNearEqual(frame, appliedValue.CGRectValue)) {
        frame = baseValue.CGRectValue;
    }

    objc_setAssociatedObject(internalView,
                             &kAWEChatTextAppliedFrameKey,
                             nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    %orig(frame);
}

- (void)layoutSubviews {
    %orig;

    UIView *internalView = (UIView *)self;
    BOOL shouldShift =
        AWEChatCapsuleEnabled() && AWEChatSeparateLeftEnabled();

    NSValue *baseValue =
        objc_getAssociatedObject(internalView, &kAWEChatTextBaseFrameKey);
    NSValue *appliedValue =
        objc_getAssociatedObject(internalView, &kAWEChatTextAppliedFrameKey);

    CGRect current = internalView.frame;

    if (shouldShift) {
        if (!appliedValue ||
            !AWEFrameNearEqual(current, appliedValue.CGRectValue)) {
            /*
             A late Auto Layout pass has restored x=39/width=251. Re-enter the
             intercepted setter once; it will store that frame as the new base
             and publish x+10/width-10 without cumulative drift.
            */
            internalView.frame = current;
        }
        return;
    }

    if (baseValue && appliedValue &&
        AWEFrameNearEqual(current, appliedValue.CGRectValue)) {
        internalView.frame = baseValue.CGRectValue;
    }
}

%end

%hook IESIMGrowingTextView

- (void)layoutSubviews {
    if (!AWEPluginFeaturesEnabled()) {
        %orig;
        return;
    }
    UIView *composerView = (UIView *)self;

    NSNumber *countValue = objc_getAssociatedObject(
        composerView, &kAWEComposerProbeCountKey);
    NSUInteger count = countValue.unsignedIntegerValue;
    BOOL detailed = count < 8;

    if (count < 32) {
        AWELogComposerSnapshot(
            [NSString stringWithFormat:@"composer.layout.before[%lu]",
                                       (unsigned long)count],
            composerView, detailed && count == 0, YES);
    }

    %orig;

    /* Re-resolve the painted sibling from the growing text view itself.  This
       survives the multiline hierarchy used by newer Douyin builds where the
       input controller no longer exposes the background as a direct child. */
    AWEApplyChatPillNearGrowingTextView(composerView,
                                        @"growingText.layout");

    /*
     The probe proved this view is transparent. The visible gray fill is a
     separate sibling container, so do not clip the text/cursor hierarchy.
    */

    if (count < 32) {
        AWELogComposerSnapshot(
            [NSString stringWithFormat:@"composer.layout.after[%lu]",
                                       (unsigned long)count],
            composerView, detailed, YES);
    }

    objc_setAssociatedObject(composerView,
                             &kAWEComposerProbeCountKey,
                             @(count + 1),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if (count < 6) {
        __weak UIView *weakComposer = composerView;
        for (NSNumber *delayValue in @[@0.05, @0.25, @0.75]) {
            NSTimeInterval delay = delayValue.doubleValue;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                                          (int64_t)(delay * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                UIView *strongComposer = weakComposer;
                if (!strongComposer) return;
                AWELogComposerSnapshot(
                    [NSString stringWithFormat:
                        @"composer.delayed+%.2f[%lu]",
                        delay, (unsigned long)count],
                    strongComposer, delay >= 0.75, YES);
            });
        }
    }
}

- (void)didMoveToWindow {
    %orig;
    UIView *composerView = (UIView *)self;
    AWETrackMessagingComposer(composerView);
    if (!AWEPluginFeaturesEnabled()) return;
    AWELogComposerSnapshot(@"composer.didMoveToWindow",
                           composerView, YES, YES);
    [composerView setNeedsLayout];
    if (composerView.window && AWEAlbumMorphStyleEnabled() &&
        gAWEAlbumMorphController) {
        AWEApplyAlbumMorphVisibleFraction(0.0, @"im.composer.visible", NO);
    } else {
        AWEScheduleTransitionRecovery();
    }
    AWEStartBarVisibilityDriver();
}

- (void)didMoveToSuperview {
    %orig;
    if (!AWEPluginFeaturesEnabled()) return;
    UIView *composerView = (UIView *)self;
    AWELogComposerSnapshot(@"composer.didMoveToSuperview",
                           composerView, YES, YES);
}

- (void)setFrame:(CGRect)frame {
    if (!AWEPluginFeaturesEnabled()) {
        %orig(frame);
        return;
    }
    UIView *composerView = (UIView *)self;
    CGRect previous = composerView.frame;
    %orig(frame);
    if (!CGRectEqualToRect(previous, frame)) {
        AWEComposerLog(@"composer.setFrame old=%@ new=%@ %@",
                       NSStringFromCGRect(previous),
                       NSStringFromCGRect(frame),
                       AWEComposerViewSignature(composerView));
    }
}

- (void)setBounds:(CGRect)bounds {
    if (!AWEPluginFeaturesEnabled()) {
        %orig(bounds);
        return;
    }
    UIView *composerView = (UIView *)self;
    CGRect previous = composerView.bounds;
    %orig(bounds);
    if (!CGRectEqualToRect(previous, bounds)) {
        AWEComposerLog(@"composer.setBounds old=%@ new=%@ %@",
                       NSStringFromCGRect(previous),
                       NSStringFromCGRect(bounds),
                       AWEComposerViewSignature(composerView));
    }
    [composerView setNeedsLayout];
    __weak UIView *weakComposer = composerView;
    dispatch_async(dispatch_get_main_queue(), ^{
        AWEApplyChatPillNearGrowingTextView(weakComposer,
                                            @"growingText.bounds");
    });
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (!AWEPluginFeaturesEnabled()) {
        %orig(backgroundColor);
        return;
    }
    UIView *composerView = (UIView *)self;
    NSString *oldColor =
        AWEComposerColorDescription(composerView.backgroundColor);
    %orig(backgroundColor);
    AWEComposerLog(@"composer.setBackgroundColor old={%@} new={%@} %@",
                   oldColor,
                   AWEComposerColorDescription(backgroundColor),
                   AWEComposerViewSignature(composerView));
}

%end

%hook AWEIMOptimizeAudioInputTouchView

- (void)layoutSubviews {
    %orig;
    if (!AWEPluginFeaturesEnabled()) return;
    UIView *voiceView = (UIView *)self;
    NSNumber *countValue = objc_getAssociatedObject(
        voiceView, &kAWEComposerProbeCountKey);
    NSUInteger count = countValue.unsignedIntegerValue;
    AWEApplyChatCornerToView(
        voiceView,
        [NSString stringWithFormat:@"voiceTouch.layout[%lu]",
                                   (unsigned long)count],
        count < 20);
    objc_setAssociatedObject(voiceView,
                             &kAWEComposerProbeCountKey,
                             @(count + 1),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)didMoveToWindow {
    %orig;
    UIView *voiceView = (UIView *)self;
    AWETrackMessagingComposer(voiceView);
    AWEApplyChatCornerToView(voiceView,
                             @"voiceTouch.didMoveToWindow",
                             YES);
    if (AWEPluginFeaturesEnabled()) {
        if (voiceView.window && AWEAlbumMorphStyleEnabled() &&
            gAWEAlbumMorphController) {
            AWEApplyAlbumMorphVisibleFraction(0.0, @"im.voiceComposer.visible", NO);
        } else {
            AWEScheduleTransitionRecovery();
        }
        AWEStartBarVisibilityDriver();
    }
}

- (void)setFrame:(CGRect)frame {
    %orig(frame);
    UIView *voiceView = (UIView *)self;
    AWEApplyChatCornerToView(voiceView,
                             @"voiceTouch.setFrame",
                             NO);
}

- (void)setBounds:(CGRect)bounds {
    %orig(bounds);
    UIView *voiceView = (UIView *)self;
    AWEApplyChatCornerToView(voiceView,
                             @"voiceTouch.setBounds",
                             NO);
}

%end

%hook IESIMInputViewController

- (void)viewDidLoad {
    %orig;
    if (!AWEPluginFeaturesEnabled()) return;
    UIViewController *controller = (UIViewController *)self;
    AWEComposerLog(@"inputVC.viewDidLoad class=%@ ptr=%p view=%@",
                   NSStringFromClass(controller.class),
                   (__bridge void *)controller,
                   AWEComposerViewSignature(controller.view));
    AWELogComposerTree(@"inputVC.viewDidLoad.tree", controller.view, 4);
}

- (void)viewDidLayoutSubviews {
    %orig;
    if (!AWEPluginFeaturesEnabled()) return;
    UIViewController *controller = (UIViewController *)self;
    NSNumber *countValue = objc_getAssociatedObject(
        controller, &kAWEInputControllerProbeCountKey);
    NSUInteger count = countValue.unsignedIntegerValue;

    NSString *event = [NSString
        stringWithFormat:@"inputVC.paintedPill[%lu]",
                         (unsigned long)count];
    BOOL applied =
        AWEApplyPaintedChatInputPill(controller, event, count < 20);
    AWEApplyChatTextGeometry(controller.view);

    UIView *voiceTouch = AWEFindViewByRuntimeClassName(
        controller.view, @"AWEIMOptimizeAudioInputTouchView");
    if (voiceTouch) {
        AWEApplyChatCornerToView(
            voiceTouch,
            [NSString stringWithFormat:@"inputVC.voiceCorner[%lu]",
                                       (unsigned long)count],
            count < 20);
    }

    if (count < 20) {
        AWEComposerLog(@"inputVC.viewDidLayout[%lu] applied=%d class=%@ view=%@",
                       (unsigned long)count,
                       applied,
                       NSStringFromClass(controller.class),
                       AWEComposerViewSignature(controller.view));
        if (count < 5) {
            AWELogComposerTree(
                [NSString stringWithFormat:@"inputVC.layout.tree[%lu]",
                                           (unsigned long)count],
                controller.view, 4);
        }
    }

    /*
     Some input configurations add the painted sibling one run-loop later.
     Retry only during the first few layouts; this is bounded and main-thread
     only, not a permanent timer.
    */
    if (count < 6) {
        __weak UIViewController *weakController = controller;
        dispatch_async(dispatch_get_main_queue(), ^{
            UIViewController *strongController = weakController;
            if (!strongController) return;
            AWEApplyPaintedChatInputPill(
                strongController,
                [NSString stringWithFormat:@"inputVC.asyncPill[%lu]",
                                           (unsigned long)count],
                YES);
            AWEApplyChatTextGeometry(strongController.view);
            UIView *voiceTouch = AWEFindViewByRuntimeClassName(
                strongController.view,
                @"AWEIMOptimizeAudioInputTouchView");
            if (voiceTouch) {
                AWEApplyChatCornerToView(
                    voiceTouch,
                    [NSString stringWithFormat:@"inputVC.asyncVoice[%lu]",
                                               (unsigned long)count],
                    YES);
            }
        });
    }

    objc_setAssociatedObject(controller,
                             &kAWEInputControllerProbeCountKey,
                             @(count + 1),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%end

%hook UILabel

- (void)setText:(NSString *)text {
    if (!AWEWanToWEnabled() ||
        objc_getAssociatedObject(self, &kAWEWanStylingKey)) {
        %orig(text);
        return;
    }

    NSString *replacement = AWECountStringByReplacingWan(text);
    if (replacement == text || [replacement isEqualToString:text]) {
        %orig(text);
        return;
    }

    NSRange wRange =
        [replacement rangeOfString:@"W" options:NSBackwardsSearch];
    UIFont *compactFont = AWECompactWFont(self.font);
    if (!compactFont || wRange.location == NSNotFound) {
        %orig(replacement);
        return;
    }

    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    if (self.font) attributes[NSFontAttributeName] = self.font;
    if (self.textColor) attributes[NSForegroundColorAttributeName] = self.textColor;

    NSMutableAttributedString *styled =
        [[NSMutableAttributedString alloc] initWithString:replacement
                                               attributes:attributes];
    AWEApplyCompactWStyle(styled, wRange, self);

    objc_setAssociatedObject(self, &kAWEWanStylingKey, @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.attributedText = styled;
    objc_setAssociatedObject(self, &kAWEWanStylingKey, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setAttributedText:(NSAttributedString *)attributedText {
    if (!AWEWanToWEnabled() || !attributedText ||
        objc_getAssociatedObject(self, &kAWEWanStylingKey)) {
        %orig(attributedText);
        return;
    }

    NSString *originalString = attributedText.string;
    NSString *replacementString = AWECountStringByReplacingWan(originalString);
    if (replacementString == originalString ||
        [replacementString isEqualToString:originalString]) {
        %orig(attributedText);
        return;
    }

    NSRange wanRange =
        [originalString rangeOfString:@"万" options:NSBackwardsSearch];
    if (wanRange.location == NSNotFound || wanRange.length != 1) {
        %orig(attributedText);
        return;
    }

    NSMutableAttributedString *replacement =
        [attributedText mutableCopy];
    [replacement replaceCharactersInRange:wanRange withString:@"W"];
    AWEApplyCompactWStyle(replacement, wanRange, self);
    %orig(replacement);
}

%end

/* Mirror Douyin's message badge only when its dedicated tab badge container
   lays out. This avoids polling and naturally follows count/dot updates. */
%hook AWENormalModeTabBarBadgeContainerView

- (void)layoutSubviews {
    %orig;
    if (AWEMessageBadgeEnabled()) {
        AWEUpdateAlbumMorphMessageBadge();
    }
}

- (void)didMoveToWindow {
    %orig;
    if (AWEMessageBadgeEnabled()) {
        AWEUpdateAlbumMorphMessageBadge();
    }
}

%end

%hook UITabBar

- (void)layoutSubviews {
    %orig;
    if (AWEIsOurNativeBar(self)) {
        if (gAWENativeDarkBootstrapActive) {
            AWEApplyNativeDarkBootstrap(self);
        } else {
            AWEApplyHomeOnlyGlassStyleToNativeBar(self);
        }
        AWEClearDirectNativeBarBackground(self);
    }
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    %orig(previousTraitCollection);

    if (!AWEIsOurNativeBar(self)) return;

    UIUserInterfaceStyle previousStyle =
        previousTraitCollection.userInterfaceStyle;
    UIUserInterfaceStyle currentStyle = self.traitCollection.userInterfaceStyle;

    if (previousStyle == currentStyle &&
        previousStyle != UIUserInterfaceStyleUnspecified) {
        return;
    }

    [UIView performWithoutAnimation:^{
        AWEConfigureNativeBarAppearance(self, AWEStoredAccentColor());
        AWEApplyHomeOnlyGlassStyleToNativeBar(self);
        [self setNeedsLayout];
        [self layoutIfNeeded];
        [self setNeedsDisplay];
    }];

    AWETransitionLog(@"NATIVE_ITEM_APPEARANCE trait previous=%ld current=%ld screen=%ld bootstrap=%d",
                     (long)previousStyle,
                     (long)currentStyle,
                     (long)UIScreen.mainScreen.traitCollection.userInterfaceStyle,
                     gAWENativeDarkBootstrapActive);
}

- (void)didMoveToWindow {
    %orig;
    if (AWEIsOurNativeBar(self)) {
        AWELogBarSnapshot(@"native.didMoveToWindow", nil, YES);
    }
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
}

- (void)didMoveToSuperview {
    %orig;
    if (AWEIsOurNativeBar(self)) {
        AWELogBarSnapshot(@"native.didMoveToSuperview", nil, YES);
    }
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
}

- (void)setFrame:(CGRect)frame {
    CGRect before = self.frame;
    %orig(frame);
    if (AWEIsOurNativeBar(self) && !AWEFrameEqualEnough(before, frame)) {
        AWELogBarSnapshot(@"native.setFrame", nil, YES);
    }
}

- (void)setHidden:(BOOL)hidden {
    BOOL changed = self.hidden != hidden;
    %orig(hidden);
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
    if (AWEIsOurNativeBar(self) && changed) {
        AWELogBarSnapshot(hidden ? @"native.hidden.YES" :
                                   @"native.hidden.NO", nil, YES);
    }
}

- (void)setAlpha:(CGFloat)alpha {
    BOOL changed = fabs(self.alpha - alpha) > 0.0001;
    %orig(alpha);
    if (gAWEStableCleanScreenEnabled) AWEStableCleanSuppressView((UIView *)self, YES);
    if (AWEIsOurNativeBar(self) && changed) {
        AWELogBarSnapshot([NSString stringWithFormat:@"native.alpha.%.4f",
                                                    alpha],
                          nil, YES);
    }
}

%end

%hook AWENormalModeTabBar

- (void)layoutSubviews {
    %orig;
    AWEAttachNativeBar((UIView *)self);
    AWEInstallDelegateIfNeeded((UIView *)self);
    AWEInternalFSTabBarUpdate((UIView *)self);
    if (gAWEStableCleanScreenEnabled) AWEStableCleanEnforceBottomBarSuppression();
}

- (void)didMoveToWindow {
    %orig;
    gAWELastTabBar = self;
    AWEAttachNativeBar((UIView *)self);
    AWEInstallDelegateIfNeeded((UIView *)self);
    AWEInternalFSTabBarUpdate((UIView *)self);
    if (gAWEStableCleanScreenEnabled) AWEStableCleanEnforceBottomBarSuppression();
    AWELogBarSnapshot(@"original.didMoveToWindow", nil, YES);
    AWEScheduleTransitionRecovery();
}

- (void)didMoveToSuperview {
    %orig;
    gAWELastTabBar = self;
    AWEAttachNativeBar((UIView *)self);
    AWEInstallDelegateIfNeeded((UIView *)self);
    AWEInternalFSTabBarUpdate((UIView *)self);
    if (gAWEStableCleanScreenEnabled) AWEStableCleanEnforceBottomBarSuppression();
    AWELogBarSnapshot(@"original.didMoveToSuperview", nil, YES);
    AWEScheduleTransitionRecovery();
}

- (void)setFrame:(CGRect)frame {
    CGRect before = self.frame;
    %orig(frame);
    if (!AWEIsApplying((UIView *)self)) {
        AWEAttachNativeBar((UIView *)self);
    }
    if (!AWEFrameEqualEnough(before, frame)) {
        AWELogBarSnapshot(@"original.setFrame", nil, YES);
    }
}

- (void)setBounds:(CGRect)bounds {
    CGRect before = self.bounds;
    %orig(bounds);
    if (!AWEIsApplying((UIView *)self)) {
        AWEAttachNativeBar((UIView *)self);
    }
    if (!AWEFrameEqualEnough(before, bounds)) {
        AWELogBarSnapshot(@"original.setBounds", nil, YES);
    }
}

- (void)setCenter:(CGPoint)center {
    CGPoint before = self.center;
    %orig(center);
    if (!AWEIsApplying((UIView *)self)) {
        AWEAttachNativeBar((UIView *)self);
    }
    if (fabs(before.x - center.x) > 0.25 ||
        fabs(before.y - center.y) > 0.25) {
        AWELogBarSnapshot(@"original.setCenter", nil, YES);
    }
}

- (void)setTransform:(CGAffineTransform)transform {
    CGAffineTransform before = self.transform;
    %orig(transform);
    if (!AWEIsApplying((UIView *)self)) {
        AWEAttachNativeBar((UIView *)self);
    }
    if (!CGAffineTransformEqualToTransform(before, transform)) {
        AWELogBarSnapshot(@"original.setTransform", nil, YES);
    }
}

- (void)setHidden:(BOOL)hidden {
    BOOL changed = self.hidden != hidden;

    /* 1.0.56c13: never veto Douyin's native hidden transition on Friends.
       Blocking hidden here was an old layout-footprint workaround, but it also
       changes the native tab-bar state exactly while the Friends feed decides
       whether its player is visible/active. The replacement bar already stays
       visible on Friends through gAWEFriendsTabLatched, while caption clearance
       is maintained independently by AWEApplyFriendsCaptionBottomReserve(). */
    %orig(hidden);

    AWEInternalFSTabBarUpdate((UIView *)self);
    if (gAWEStableCleanScreenEnabled) AWEStableCleanEnforceBottomBarSuppression();
    if (!AWEIsApplying((UIView *)self)) {
        AWEStartBarVisibilityDriver();
        AWEAttachNativeBar((UIView *)self);
        AWEScheduleTransitionRecovery();
    }
    if (changed) {
        AWELogBarSnapshot(hidden ? @"original.hidden.YES" :
                                   @"original.hidden.NO", nil, YES);
    }
}

- (void)setAlpha:(CGFloat)alpha {
    BOOL changed = fabs(self.alpha - alpha) > 0.0001;
    %orig(alpha);
    if (gAWEStableCleanScreenEnabled) AWEStableCleanEnforceBottomBarSuppression();
    if (!AWEIsApplying((UIView *)self)) {
        AWEStartBarVisibilityDriver();
        AWEAttachNativeBar((UIView *)self);
        AWEScheduleTransitionRecovery();
    }
    if (changed) {
        AWELogBarSnapshot([NSString stringWithFormat:@"original.alpha.%.4f",
                                                    alpha],
                          nil, YES);
    }
}

- (void)setBackgroundColor:(UIColor *)color {
    if (!AWEPluginFeaturesEnabled()) {
        %orig(color);
        return;
    }
    if (!AWEIsApplying((UIView *)self)) {
        AWESetApplying((UIView *)self, YES);
        %orig(UIColor.clearColor);
        ((UIView *)self).layer.backgroundColor = UIColor.clearColor.CGColor;
        AWESetApplying((UIView *)self, NO);
        return;
    }
    %orig(color);
}

%end


/*
 The verified 0.0.13 lifecycle intentionally accepts a small return delay, but
 its force-visible preparation calls can expose LiquidBar underneath the home
 search keyboard. Suppress only the known AWESearch route and keep the native
 bar parked below its host until that route has actually disappeared.
*/
%hook AWESearchViewController

- (void)viewWillAppear:(BOOL)animated {
    gAWESearchPageVisible = YES;
    if (gAWELastTabBar) {
        AWEAttachNativeBarWithForce((UIView *)gAWELastTabBar, NO);
    }
    %orig(animated);
}

- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);
    gAWESearchPageVisible = YES;
    if (gAWELastTabBar) {
        AWEAttachNativeBarWithForce((UIView *)gAWELastTabBar, NO);
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig(animated);
    gAWESearchPageVisible = NO;
    AWEScheduleTransitionRecovery();
}

%end

/*
 FLEX confirmed that a Douyin Shop product-detail page owns the exact view
 class IESECPdpHeaderLynxPendantView. This marker is specific to the PDP
 header, unlike generic LynxView/BDXLynxView classes that also appear in Shop
 lists and many unrelated pages.

 Track only this marker while it is attached to a window. The existing
 0.0.13 parking path then moves LiquidBar below the host instead of allowing
 it to overlay the product purchase controls.
*/
%hook IESECPdpHeaderLynxPendantView

- (void)didMoveToWindow {
    %orig;

    UIView *marker = (UIView *)self;

    if (marker.window != nil) {
        AWERegisterCommerceProductDetailMarker(marker);

        if (gAWELastTabBar) {
            AWEAttachNativeBarWithForce((UIView *)gAWELastTabBar, NO);
        }
    } else {
        AWEUnregisterCommerceProductDetailMarker(marker);
        AWEScheduleTransitionRecovery();
    }
}

%end

static BOOL AWEClassNameLooksLikePlayableFeedController(NSString *className) {
    NSString *lower = className.lowercaseString;
    if (lower.length == 0 || [lower containsString:@"comment"] ||
        [lower containsString:@"search"] || [lower containsString:@"setting"]) return NO;
    return [lower containsString:@"playvideo"] ||
           [lower containsString:@"player"] ||
           [lower containsString:@"feedcell"] ||
           [lower containsString:@"familiar"] ||
           [lower containsString:@"richcontent"];
}

static void AWEScheduleFullscreenRightCompatibilityRecovery(UIViewController *controller) {
    if (!controller || !AWEClassNameLooksLikePlayableFeedController(
            NSStringFromClass(controller.class))) return;
    __weak UIViewController *weakController = controller;
    for (NSNumber *delay in @[@0.05, @0.30, @0.85]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
            (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
            dispatch_get_main_queue(), ^{
            UIViewController *strongController = weakController;
            if (!strongController || !strongController.view.window ||
                AWEAnyVisibleCommentPanelForRightRecovery()) return;
            UIView *stack = AWEFindCurrentRightActionStackAcrossWindows();
            if (!stack) { AWEHideGlobalDownloadMenu(); return; }
            AWEForceRestoreRightActionStackAfterComment(stack);
            AWERefreshExternalBridgeMenu(stack);
            AWEInteractionDiagnosticWrite(@"RIGHT_FULLSCREEN_RECOVERY class=%@ delay=%.2f stack=%@",
                NSStringFromClass(strongController.class), delay.doubleValue,
                AWEInteractionObjectSummary(stack));
        });
    }
}

static BOOL AWEClassNameLooksLikeFriendsFeedContentController(NSString *className) {
    if (className.length == 0 || AWESecondTabIsShop()) return NO;
    return [className containsString:@"AWEFeedTableViewController"];
}

static void AWEApplyFriendsCaptionBottomReserve(UIViewController *controller,
                                                 BOOL enabled,
                                                 NSString *reason) {
    if (!controller || !AWEClassNameLooksLikeFriendsFeedContentController(
            NSStringFromClass(controller.class))) return;

    NSValue *stored = objc_getAssociatedObject(
        controller, &kAWEFriendsOriginalAdditionalSafeAreaInsetsKey);
    if (!enabled) {
        if (stored) {
            controller.additionalSafeAreaInsets = stored.UIEdgeInsetsValue;
            objc_setAssociatedObject(controller,
                &kAWEFriendsOriginalAdditionalSafeAreaInsetsKey,
                nil, OBJC_ASSOCIATION_ASSIGN);
            AWEAlbumMorphProbeWrite(@"FRIENDS_CAPTION_RESERVE state=restore class=%@ reason=%@",
                NSStringFromClass(controller.class), reason ?: @"unknown");
        }
        return;
    }

    if (!stored) {
        stored = [NSValue valueWithUIEdgeInsets:controller.additionalSafeAreaInsets];
        objc_setAssociatedObject(controller,
            &kAWEFriendsOriginalAdditionalSafeAreaInsetsKey,
            stored, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    UIWindow *window = controller.view.window ?: AWEActiveMainWindow();
    CGFloat systemBottom = window ? window.safeAreaInsets.bottom : 0.0;
    CGFloat barHeight = gAWEAlbumMorphController
        ? CGRectGetHeight(gAWEAlbumMorphController.tabBar.bounds) : 0.0;
    if (barHeight < 40.0 && gAWELastTabBar) {
        barHeight = CGRectGetHeight(((UIView *)gAWELastTabBar).bounds);
    }
    if (barHeight < 40.0) barHeight = 83.0;
    CGFloat reserve = MAX(0.0, barHeight - systemBottom);

    UIEdgeInsets base = stored.UIEdgeInsetsValue;
    UIEdgeInsets target = base;
    target.bottom = MAX(base.bottom, reserve);
    if (fabs(controller.additionalSafeAreaInsets.bottom - target.bottom) > 0.5) {
        controller.additionalSafeAreaInsets = target;
        [controller.view setNeedsLayout];
        AWEAlbumMorphProbeWrite(
            @"FRIENDS_CAPTION_RESERVE state=apply class=%@ bottom=%.1f bar=%.1f system=%.1f reason=%@",
            NSStringFromClass(controller.class), target.bottom, barHeight,
            systemBottom, reason ?: @"unknown");
    }
}

static BOOL AWEClassNameLooksLikeFriendsRootController(NSString *className) {
    if (className.length == 0 || AWESecondTabIsShop()) return NO;
    return [className containsString:@"AFDContainerViewController"] ||
           [className containsString:@"AWEFamiliarTabSlidingViewController"] ||
           [className containsString:@"AFDFamiliarViewController"] ||
           [className containsString:@"AWEFamiliarSkylightViewController"];
}


/*
 Every completed page appearance is a useful, low-frequency recovery signal.
 Unlike the old global UIView layout hook, this runs only on navigation/
 presentation transitions and therefore does not create a per-frame workload.
*/
%hook UIViewController

- (void)presentViewController:(UIViewController *)controller
                      animated:(BOOL)animated
                    completion:(void (^)(void))completion {
    NSString *className = NSStringFromClass(controller.class);
    BOOL sensitive = AWEClassNameIsSensitiveDestination(className);
    BOOL hardSuspend = AWEClassNameRequiresHardOverlaySuppression(className);
    AWEInteractionDiagnosticWrite(
        @"VC_PRESENT class=%@ sensitive=%d hard=%d style=%ld",
        className, sensitive, hardSuspend,
        (long)controller.modalPresentationStyle);
    if (sensitive) {
        AWERegisterSensitiveDestination(controller);
    }
    if (hardSuspend) {
        AWEHardSuspendAlbumMorphOverlay(
            [NSString stringWithFormat:@"present.%@", className]);
        AWEInteractionDiagnosticWrite(@"HARD_ROUTE_PRESENT class=%@", className);
    }
    %orig(controller, animated, completion);
    AWEStartBarVisibilityDriver();
}

- (void)viewWillAppear:(BOOL)animated {
    NSString *className = NSStringFromClass(self.class);
    if (gAWEStableCleanScreenEnabled) {
        AWEStableEnsureStatusBarHookForClass(self.class);
        [self setNeedsStatusBarAppearanceUpdate];
    }
    BOOL friendsRootController = AWEClassNameLooksLikeFriendsRootController(className);
    if (friendsRootController) {
        /* Keep only the logical Friends latch. Do not force the native tab-bar
           visible or relayout the Friends root while Douyin is activating its
           player. The custom LiquidBar already has an explicit Friends steady-
           visibility rule, and caption clearance is handled separately via
           additionalSafeAreaInsets. */
        gAWEFriendsTabLatched = YES;
    }
    BOOL sensitive = AWEClassNameIsSensitiveDestination(className);
    if (self.presentingViewController || sensitive) {
        AWEAlbumMorphProbeWrite(
            @"VC_WILL_APPEAR class=%@ sensitive=%d presented=%d style=%ld",
            className, sensitive, self.presentingViewController != nil,
            (long)self.modalPresentationStyle);
    }

    if (sensitive) {
        AWEHideGlobalDownloadMenu();
        AWERegisterSensitiveDestination(self);
        BOOL transientCommerce =
            AWEClassNameLooksLikeTransientCommerceDestination(className);
        BOOL hardRoute = AWEClassNameRequiresHardOverlaySuppression(className);
        /* Share/forward/publish routes are hard-suspended whether presented or
           pushed. Commerce matching is intentionally restricted to presented
           sheets so the main Shop tab can still own the normal bottom bar. */
        if (hardRoute && (!transientCommerce || self.presentingViewController)) {
            AWEHardSuspendAlbumMorphOverlay(
                [NSString stringWithFormat:@"willAppear.%@", className]);
        } else if (gAWELastTabBar) {
            AWEAttachNativeBarWithForce((UIView *)gAWELastTabBar, NO);
        }
    }

    BOOL friendsFeedContent = AWEClassNameLooksLikeFriendsFeedContentController(className);
    if (friendsFeedContent && !AWESecondTabIsShop() &&
        (AWECurrentOriginalMainTabIndex() == 1 || gAWEFriendsTabLatched)) {
        AWEApplyFriendsCaptionBottomReserve(self, YES, @"viewWillAppear.before");
    }

    %orig(animated);
    if (friendsFeedContent && !AWESecondTabIsShop() &&
        (AWECurrentOriginalMainTabIndex() == 1 || gAWEFriendsTabLatched)) {
        AWEApplyFriendsCaptionBottomReserve(self, YES, @"viewWillAppear.after");
    }
    AWEStartBarVisibilityDriver();
    AWELogBarSnapshot(@"vc.viewWillAppear", self, YES);
    AWEProbeStartSampling(
        [NSString stringWithFormat:@"willAppear.%@", className],
        self);
}

- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);
    AWEInstallSettingsGesture(self.view.window ?: AWEActiveMainWindow());
    AWETrySilentAuthorization((UIViewController *)self);
    __weak UIViewController *weakAuthorizationController = (UIViewController *)self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.60 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        UIViewController *strongAuthorizationController = weakAuthorizationController;
        if (strongAuthorizationController.view.window) {
            AWETrySilentAuthorization(strongAuthorizationController);
        }
    });

    NSString *authorizationClassName = NSStringFromClass(self.class).lowercaseString;
    BOOL couldBeProfilePage = AWECurrentMainTabAppearsToBeMe() ||
        [authorizationClassName containsString:@"userdetail"] ||
        [authorizationClassName containsString:@"mine"] ||
        [authorizationClassName containsString:@"personal"];
    if (couldBeProfilePage) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.60 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            UIViewController *strongAuthorizationController = weakAuthorizationController;
            if (strongAuthorizationController.view.window && !AWEAuthorizationValid()) {
                AWETrySilentAuthorization(strongAuthorizationController);
            }
        });
    }
    AWEStartBarVisibilityDriver();
    AWELogBarSnapshot(@"vc.viewDidAppear", self, YES);

    NSString *className = NSStringFromClass(self.class);
    if (AWEClassNameLooksLikeFriendsRootController(className)) {
        gAWEFriendsTabLatched = YES;
    }
    if (AWEClassNameLooksLikeFriendsFeedContentController(className) &&
        !AWESecondTabIsShop() &&
        (AWECurrentOriginalMainTabIndex() == 1 || gAWEFriendsTabLatched)) {
        AWEApplyFriendsCaptionBottomReserve(self, YES, @"viewDidAppear");
    }
    if (AWEDownloadMenuRouteBlocked()) {
        AWEHideGlobalDownloadMenu();
    }
    if (self == gAWEAlbumMorphPublishSourceController &&
        CACurrentMediaTime() < gAWEAlbumMorphPublishLaunchSuppressionUntil) {
        gAWEAlbumMorphPublishLaunchSuppressionUntil = 0.0;
        gAWEAlbumMorphPublishSourceController = nil;
        AWEAlbumMorphProbeWrite(@"PUBLISH_SOURCE_RETURN class=%@", className);
        AWEForceAlbumMorphRouteRecovery(@"publish.source.return");
    }
    if (AWEClassNameIsSensitiveDestination(className) ||
        AWECurrentRouteSuppressesBar()) {
        /*
         Covers an interactive return that was cancelled: the destination is
         visible again, so remove reveal grace and return the bar to its warm
         parked position.
        */
        gAWETransitionPrewarmUntil = 0.0;
        gAWEReturnRevealGraceUntil = 0.0;
    }

    AWEScheduleFullscreenRightCompatibilityRecovery(self);
    AWEScheduleTransitionRecovery();
    AWEScheduleHomeChromeRecovery(self.view.window ?: AWEActiveMainWindow());
    if (AWEAlbumMorphStyleEnabled() && !AWECurrentRouteSuppressesBar() &&
        gAWEBarLastVisibleFraction < 0.999) {
        AWEForceAlbumMorphRouteRecovery(
            [NSString stringWithFormat:@"appear.hidden.%@", className]);
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    NSString *departingClassName = NSStringFromClass(self.class);
    if (objc_getAssociatedObject(self, &kAWEFriendsOriginalAdditionalSafeAreaInsetsKey)) {
        AWEApplyFriendsCaptionBottomReserve(self, NO, @"viewWillDisappear");
    }
    AWELogBarSnapshot(@"vc.viewWillDisappear", self, YES);
    AWEProbeStartSampling(
        [NSString stringWithFormat:@"willDisappear.%@",
                                   departingClassName],
        self);
    if (AWEClassNameIsSensitiveDestination(departingClassName)) {
        AWEAlbumMorphProbeWrite(@"ROUTE_WILL_EXIT class=%@",
            departingClassName);
        BOOL commentRoute = [departingClassName.lowercaseString containsString:@"comment"];
        if (commentRoute) {
            gAWECommentRightRebindPending = YES;
            if (!gAWECommentRightStackBefore || !gAWECommentRightStackBefore.window) {
                gAWECommentRightStackBefore = AWEFindCurrentRightActionStackAcrossWindows();
            }
            if (!gAWECommentRightHostBefore.length) {
                gAWECommentRightHostBefore = [AWECurrentRightActionStackSummary() copy];
            }
            AWEInteractionDiagnosticWrite(
                @"RIGHT_HOST_BEFORE_COMMENT class=%@ target=%@ hosts=%@",
                departingClassName,
                AWEInteractionObjectSummary(gAWECommentRightStackBefore),
                gAWECommentRightHostBefore ?: @"none");
        } else {
            /* Non-comment sheets retain the historical pre-dismiss recovery.
               Comment panels are nested, so recovering here only churns the
               same generation three times before the actual feed cell exists. */
            AWEForceAlbumMorphRouteRecovery(
                [NSString stringWithFormat:@"willDismiss.%@",
                                           departingClassName]);
        }
    }

    /*
     Prime the already-created bar before UIKit/custom containers snapshot and
     animate the departing page. This is intentionally before %orig.
    */
    AWEBeginReturnPrewarm(self);
    %orig(animated);
    AWEStartBarVisibilityDriver();
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig(animated);
    AWEStartBarVisibilityDriver();

    NSString *className = NSStringFromClass(self.class);
    if (AWEClassNameIsSensitiveDestination(className)) {
        NSString *lowerClassName = className.lowercaseString;
        if ([lowerClassName containsString:@"publish"] ||
            [lowerClassName containsString:@"record"] ||
            [lowerClassName containsString:@"shoot"] ||
            [lowerClassName containsString:@"camera"] ||
            [lowerClassName containsString:@"creation"] ||
            [lowerClassName containsString:@"composer"] ||
            [lowerClassName containsString:@"videoedit"]) {
            gAWEAlbumMorphPublishLaunchSuppressionUntil = 0.0;
            gAWEAlbumMorphPublishSourceController = nil;
        }
        BOOL remainingSensitive = AWEUnregisterSensitiveDestination(self);
        AWEScheduleTransitionRecovery();
        BOOL commentRoute = [className.lowercaseString containsString:@"comment"];
        if (!commentRoute || !remainingSensitive) {
            AWEForceAlbumMorphRouteRecovery(
                [NSString stringWithFormat:@"dismiss.%@", className]);
        }

        /* The visible comment panel and AWECommentInputViewController have
           different lifetimes. On profile-video feeds the input controller can
           remain registered for several seconds after the sheet is already
           gone (and may survive until the app resigns active). Restore the
           right-side action column when the last *visible panel* disappears,
           not when the input helper finally tears down. */
        if (commentRoute && gAWECommentRightRebindPending) {
            BOOL inputOnly = AWEClassNameIsCommentInputOnlyForRightRecovery(className);
            BOOL panelStillVisible = AWEAnyVisibleCommentPanelForRightRecovery();
            BOOL shouldRebindNow = (!inputOnly && !panelStillVisible) ||
                                   !remainingSensitive;
            if (shouldRebindNow) {
                gAWECommentRightRebindPending = NO;
                AWESchedulePostCommentRightRebind(
                    [NSString stringWithFormat:@"panelDismiss.%@", className]);
            }
        }
    }

    AWELogBarSnapshot(@"vc.viewDidDisappear", self, YES);
    AWEProbeLogExpandedSnapshot(@"vc.viewDidDisappear", self, YES);
    AWEScheduleHomeChromeRecovery(AWEActiveMainWindow());
}

%end

%hook AWENormalModeTabBarController

- (void)setButtons:(id)buttons {
    %orig(buttons);
    gAWELastController = (AWENormalModeTabBarController *)self;
    AWELogBarSnapshot(@"normal-controller.setButtons", self, YES);

    /*
     This is normally the earliest reliable moment at which all five original
     Douyin button objects share their AWENormalModeTabBar superview.
    */
    AWEPrepareBarForController(self, YES);
    AWEScheduleTransitionRecovery();
}

- (void)viewDidLoad {
    %orig;
    gAWELastController = (AWENormalModeTabBarController *)self;
    AWELogBarSnapshot(@"normal-controller.viewDidLoad", self, YES);
    /*
     At this stage buttons may already exist on warm launch. Creating the
     native UITabBar here lets UIKit prepare its Liquid Glass before the first
     visible frame.
    */
    AWEPrepareBarForController(self, YES);
}

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    AWELogBarSnapshot(@"normal-controller.viewWillAppear", self, YES);
    AWEPrepareBarForController(self, YES);
    AWEScheduleTransitionRecovery();
}

- (void)viewWillLayoutSubviews {
    %orig;
    AWEPrepareBarForController(self, YES);
}

- (void)viewDidLayoutSubviews {
    %orig;
    AWEPrepareBarForController(self, YES);
}

- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);
    gAWELastController = (AWENormalModeTabBarController *)self;
    AWELogBarSnapshot(@"normal-controller.viewDidAppear", self, YES);
    AWEProbeLogExpandedSnapshot(@"normal-controller.viewDidAppear", self, YES);
    AWEInstallSettingsGesture(self.view.window ?: AWEActiveMainWindow());
    AWEPrepareBarForController(self, YES);
    AWEScheduleTransitionRecovery();
}

- (void)updateTabBarButtonStatusesWithSelectedButton:(id)selectedButton {
    %orig(selectedButton);

    NSArray *buttons = AWEControllerButtons(self);
    AWENormalModeTabBar *tabBar = AWEPrepareBarForController(self, YES);
    if (!tabBar) return;

    NSInteger index = AWEIndexOfButton(selectedButton, buttons);
    if (index != NSNotFound) {
        if (AWEAlbumMorphStyleEnabled() && gAWEAlbumMorphController) {
            if (index == 0 || index == 1 || index == 3 || index == 4) {
                [gAWEAlbumMorphController syncSelectedOriginalIndex:index];
                AWEApplyAlbumMorphResolvedAppearance(
                    ((UIView *)tabBar).window ?: AWEActiveMainWindow(), index);
            }
        } else {
            AWESetNativeSelectedIndex(tabBar, index);
        }
    }
}

- (void)updateUIByCurrentSelected {
    %orig;
    AWEPrepareBarForController(self, YES);
    AWEScheduleTransitionRecovery();
}

%end

%ctor {
    @autoreleasepool {
        /* A custom dynamic hook group is used for Douyin's Swift comment-input
           class, so initialize the ordinary implicit Logos group explicitly. */
        %init;
        Class fsCommentInputClass = objc_getClass("AWECommentInputViewSwiftImpl.CommentInputContainerView");
        if (fsCommentInputClass) {
            %init(AWEInternalFSCommentInputGroup,
                  AWEInternalFSCommentInputContainerView = fsCommentInputClass);
        }

        AWEAlbumMorphProbeClear();
        AWEAlbumMorphProbeWrite(@"SESSION_START build=1.0.56c13 os=%@",
            NSProcessInfo.processInfo.operatingSystemVersionString);
        /* Preserve the user's grouped-top and iOS 27 force-dark choices
           across upgrades. Defaults are resolved lazily by their getters. */
        dispatch_async(dispatch_get_main_queue(), ^{
            AWEEnsureHomeCustomIconsDirectory();
            if (AWEPluginFeaturesEnabled() && !AWEAlbumMorphStyleEnabled()) {
                AWEScheduleActualNativeBarWarmup();
            }
            [[NSNotificationCenter defaultCenter]
                addObserverForName:UIApplicationDidBecomeActiveNotification
                            object:nil
                             queue:[NSOperationQueue mainQueue]
                        usingBlock:^(__unused NSNotification *notification) {
                /* 1.0.56c13 foreground rule: Douyin owns player recovery.
                   During DidBecomeActive do not reattach the native tab bar,
                   force route recovery, relayout Feed chrome, or steal key
                   window state. Those operations used to run in the same
                   lifecycle window as Douyin's native resume decision and can
                   provoke a second visibility/pause reconciliation. */
                gAWEPlaybackPreferenceResumeGraceUntil = CACurrentMediaTime() + 5.0;

                if (AWEPluginFeaturesEnabled()) {
                    if (!AWEAlbumMorphStyleEnabled()) {
                        /* Native-bar mode keeps its original lightweight warmup.
                           The LiquidBar overlay path below intentionally avoids
                           touching the native bar host while playback resumes. */
                        AWEScheduleActualNativeBarWarmup();
                    } else {
                        __weak UIView *weakOriginalBar = (UIView *)gAWELastTabBar;
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                            (int64_t)(0.45 * NSEC_PER_SEC)),
                            dispatch_get_main_queue(), ^{
                            UIView *originalBar = weakOriginalBar;
                            if (!originalBar || !originalBar.window ||
                                !AWEPluginFeaturesEnabled() ||
                                !AWEAlbumMorphStyleEnabled()) return;

                            /* Overlay-only reconciliation: update our visual
                               visibility/material after the player has resumed,
                               without mutating the feed controller, native bar
                               geometry, or route state. */
                            AWEUpdateAlbumMorphVisibility(
                                originalBar, @"applicationDidBecomeActive.overlayOnly");
                            AWEUpdateAlbumMorphMessageBadge();
                            AWEApplyHomeOnlyGlassStyleToExistingSurfaces();
                        });
                    }
                }
            }];
        });
    }
}
