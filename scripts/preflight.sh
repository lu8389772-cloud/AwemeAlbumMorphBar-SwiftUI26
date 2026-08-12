#!/bin/bash
set -euo pipefail

swiftc -frontend -parse AwemeAlbumMorphBar.swift
bash -n build_no_install.sh

python3 - <<'PY2'
from pathlib import Path
from collections import Counter

swift = Path('AwemeAlbumMorphBar.swift').read_text()
objc = Path('Tweak.x').read_text()
control = Path('control').read_text()
workflow = Path('.github/workflows/build.yml').read_text()
build_script = Path('build_no_install.sh').read_text()
makefile = Path('Makefile').read_text()

checks = [
    ('control', control, 'Version: 1.0.56a'),
    ('workflow', workflow, 'AwemeLiquidBar-1.0.56a-Xcode27-rootless'),
    ('build', build_script, "EXPECTED_VERSION='1.0.56a'"),
    ('build', build_script, 'LiquidBar 设置 · 1.0.56a'),
    ('build', build_script, 'AwemeLiquidBar_1.0.56a_interaction.log'),
    ('makefile', makefile, 'UIKit QuartzCore Foundation SwiftUI Photos'),
]
for name, text, token in checks:
    if token not in text:
        raise SystemExit(f'missing {name} token: {token}')

for token in [
    'tabBarMinimizeBehavior = .never', 'let search = UISearchTab',
    '@objc(updateMessageBadgeValue:)', '@objc(updateSecondBadgeValue:)',
    'applyUnreadBadges()', 'applyCompactUnreadBadgeScale(in: tabBar)',
    'setResolvedInterfaceStyleRaw', 'setVerticalOffset(_ offset: CGFloat)',
    '@objc(setVisibleFraction:animated:)', 'visibilityMaskView',
]:
    if token not in swift:
        raise SystemExit(f'missing Swift token: {token}')

required_objc = [
    'AwemeLiquidBar 1.0.56a', 'LiquidBar 设置 · 1.0.56a',
    '#import <Photos/Photos.h>',
    'AWECurrentAwemeModelForStack', 'AWERobustVideoURLForAweme',
    'AWEDownloadCurrentImageForAweme', 'AWEDownloadAllImagesForAweme',
    'AWEDownloadAudioForAweme', 'AWECopyCompleteTextForAweme',
    'AWEAvatarBaseMenuForStack', '@"进入主页"', '@"一键清屏"', '@"退出清屏"',
    '@"头像菜单显示下载功能"', 'AWEAvatarMenuDownloadEnabled',
    'slot.menuButton.menu = AWEAvatarBaseMenuForStack(stack, pictureHost);',
    'slot.menuButton.showsMenuAsPrimaryAction = YES;',
    'AWEInstallGlassPressFeedback(slot.menuButton, slot.glassButton);',
    'AWEStableEnterCleanScreenFromStack', 'AWEStableExitCleanScreen',
    'AWEStableApplyCleanScreenGlobal', 'AWEStableCleanEnforceBottomBarSuppression',
    'AWEStableCleanClassIsExplicitTarget', 'AWEScheduleCleanScreenReapply',
    'CLEAN_STABLE exit',
    'AWECurrentOriginalSecondBadgeValue', 'AWECurrentOriginalMessagesBadgeValue',
    'BOTTOM_BADGES_NATIVE', 'if (![scanner scanInteger:&count] || count <= 0) return nil;',
    '[gAWEAlbumMorphController updateSecondBadgeValue:secondValue];',
    '%hook AWENormalModeTabBarBadgeContainerView',
    # internal fullscreen, using validated 0.5.1 media/overlay separation
    'AwemeLiquidBarInternalFullscreenV1', 'AWEInternalFullscreenEnabled',
    'AWEInternalFSLayoutInteractionController', 'AWEInternalFSHandleElementStackLayout',
    '%hook AWEFeedTableView', '%hook AWEDPlayerFeedPlayerViewController',
    '%hook AWEDPlayerViewController_Merge', '%hook IESLiveStackView',
    '%hook AWEAwemeDetailTableView', '%hook AWEMixVideoPanelMoreView',
    '%hook AWECommentInputBackgroundView', '%group AWEInternalFSCommentInputGroup',
    'AWECommentInputViewSwiftImpl.CommentInputContainerView',
    # clean-v2 explicit controls and transition guards
    '%hook AWELandscapeFeedEntryView', '%hook AWEVideoPlayDanmakuContainerView',
    '%hook AWEDanmakuContainerView', '%hook AWEStoryProgressSlideView',
    '%hook AWEDemaciaChapterProgressSlider', '%hook AFDAIbumFolioView',
    '%hook AFDAlbumFolioView', '%hook AWEFeedTableViewCell',
    '%hook AWEFeedViewCell', '%hook AWEFeedContainerViewController',
]
for token in required_objc:
    if token not in objc:
        raise SystemExit(f'missing Objective-C token: {token}')

# Standalone validation depended on keeping profile/detail interaction geometry
# separate from media geometry. The old cumulative author-profile image shift is
# intentionally not part of this merge.
for forbidden in [
    'AWEExternalBridgePluginImageLoaded', 'AWEExternalBridgeRuntimeHasSelector',
    'AWEExternalBridgeInvokeSelectorName', 'BRIDGE_PLUGIN_FOUND', 'BRIDGE_ACTION',
    'saveCurrentVideo', 'tcShowDownloadOptions', 'NATIVE_DOWNLOAD_READY',
    '上滑收缩底栏（动态高度）',
    'AWEDYYYFullscreenEnabled', 'DYYY_INTERACTION_GEOMETRY',
    'RIGHT_FLEX_REPAIR', 'PROFILE_VSYNC_REPAIR', 'BOTTOM_FOOTPRINT_ANOMALY',
    'AWE53RebindNativeHomeActionsInForegroundWindows', 'AWE53RightGlassLooksHealthy',
    'AWEStableCleanScreenRecoveryTarget',
    'origin.y += AWEFSTabBarHeight()',
]:
    if forbidden in objc or forbidden in swift:
        raise SystemExit(f'forbidden regression/bridge remains: {forbidden}')

# Independent floating download control remains retired.
if objc.count('AWEEnsureExternalBridgeMenuSlot(') != 1:
    raise SystemExit('independent download slot still has a live caller')
for snippet in [
    'static void AWELayoutExternalBridgeMenuForStack(UIView *stack) {\n    (void)stack;',
    'static void AWERefreshExternalBridgeMenu(UIView *stack) {\n    (void)stack;\n    AWEHideGlobalDownloadMenu();',
]:
    if snippet not in objc:
        raise SystemExit('floating download disable guard missing')

# Logos structural audit. 1.0.56a intentionally has one custom group for the
# runtime-resolved Swift CommentInputContainerView; all other hooks are ungrouped.
hooks = []
groups = []
for line in objc.splitlines():
    stripped = line.strip()
    if stripped.startswith('%hook '):
        hooks.append(stripped.split(None, 1)[1])
    elif stripped.startswith('%group '):
        groups.append(stripped.split(None, 1)[1])
expected_groups = ['AWEInternalFSCommentInputGroup']
if groups != expected_groups:
    raise SystemExit(f'unexpected Logos groups: {groups}')
if len(hooks) + len(groups) != objc.count('%end'):
    raise SystemExit(f'Logos hook/group/end mismatch: hooks={len(hooks)} groups={len(groups)} end={objc.count("%end")}')
if '%init;' not in objc or '%init(AWEInternalFSCommentInputGroup,' not in objc:
    raise SystemExit('dynamic Logos group initialization missing')
dups = [name for name, count in Counter(hooks).items() if count > 1]
if dups:
    raise SystemExit('duplicate Logos hook classes: ' + ', '.join(dups))

# Loose delimiter count is useful here because the pre-existing 1.0.55a source
# was already balanced; the merge should not change that property.
for left, right, name in [('{','}','brace'),('(',')','parenthesis'),('[',']','bracket')]:
    if objc.count(left) != objc.count(right):
        raise SystemExit(f'Objective-C {name} count mismatch')

if 'kAWEAuthorizationDigests[36]' not in objc:
    raise SystemExit('auth36 digest table declaration missing')
start = objc.index('kAWEAuthorizationDigests[36]')
end = objc.index('};', start)
rows = [line for line in objc[start:end].splitlines()
        if line.strip().startswith('{') and 'kAWEAuthorizationDigests' not in line]
if len(rows) != 36:
    raise SystemExit(f'auth digest row count is {len(rows)}, expected 36')

for token in [
    '[PHPhotoLibrary sharedPhotoLibrary] performChanges:',
    '[PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL]',
    '[PHAssetChangeRequest creationRequestForAssetFromImage:image]',
    'NSURLSessionDownloadTask *task', 'NSURLSessionDataTask *task',
]:
    if token not in objc:
        raise SystemExit(f'native downloader API token missing: {token}')

# Clean-screen v2 must not use a permanent polling timer. Short dispatch_after
# passes are expected, but there should be no NSTimer in the clean subsystem.
clean_start = objc.index('#pragma mark - 1.0.56a clean screen v2 (display-only, persistent across reuse)')
clean_end = objc.index('static UIMenu *AWEAvatarBaseMenuForStack', clean_start)
clean_chunk = objc[clean_start:clean_end]
if 'scheduledTimerWithTimeInterval' in clean_chunk or 'NSTimer' in clean_chunk:
    raise SystemExit('clean-screen v2 unexpectedly contains a permanent timer')

print('AwemeLiquidBar 1.0.56a internal-fullscreen/clean-v2/native-badges preflight passed')
PY2
