#!/bin/bash
set -euo pipefail

swiftc -frontend -parse AwemeAlbumMorphBar.swift
bash -n build_no_install.sh

python3 - <<'PY2'
from pathlib import Path
swift = Path('AwemeAlbumMorphBar.swift').read_text()
objc = Path('Tweak.x').read_text()
control = Path('control').read_text()
workflow = Path('.github/workflows/build.yml').read_text()
build_script = Path('build_no_install.sh').read_text()
makefile = Path('Makefile').read_text()

checks = [
    ('control', control, 'Version: 1.0.53b'),
    ('workflow', workflow, 'AwemeLiquidBar-1.0.53b-Xcode27-rootless'),
    ('workflow', workflow, 'chmod 755 layout/DEBIAN/postinst'),
    ('build', build_script, "EXPECTED_VERSION='1.0.53b'"),
    ('build', build_script, 'LiquidBar 设置 · 1.0.53b'),
    ('build', build_script, 'AwemeLiquidBar_1.0.53b_interaction.log'),
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
    'AwemeLiquidBar 1.0.53b', 'LiquidBar 设置 · 1.0.53b',
    '#import <Photos/Photos.h>',
    'AWECurrentAwemeModelForStack', 'AWERobustVideoURLForAweme',
    'AWEDownloadCurrentImageForAweme', 'AWEDownloadAllImagesForAweme',
    'AWEDownloadAudioForAweme', 'AWECopyCompleteTextForAweme',
    'AWEAvatarBaseMenuForStack', '@"进入主页"', '@"一键清屏"', '@"退出清屏"',
    '@"头像菜单显示下载功能"', 'AWEAvatarMenuDownloadEnabled',
    'AwemeLiquidBar.HomeAction.ProfileMenu',
    '[profileHost addSubview:button];',
    'AWE53ConfigureNestedAvatarMenu', 'AWERefreshAvatarMenuOverlayForStack',
    'AVATAR_MENU_NESTED',
    'CLEAN_SCREEN enter nested_menu', 'CLEAN_SCREEN avatar_reveal real_avatar',
    'if (gAWECleanScreenEnabled) fraction = 0.0;',
    'RIGHT_FLEX_ARM', 'RIGHT_FLEX_RESCAN', 'RIGHT_FLEX_REPAIR',
    'AWE53RebindNativeHomeActionsInForegroundWindows',
    'AWE53BindFallbackActionOwners',
    'gAWE53PostCommentFlexibleRepairUntil',
    'NESTED_FEED_BAR_RECOVERY_SKIPPED',
    '%hook AWEFeedVideoButton', 'AWEScheduleHomeActionRefreshForButton',
    '%hook AWEElementStackView',
    'RIGHT_INPUT_HELPER_TRANSPARENT',
    'AWECurrentOriginalMessagesBadgeValue', 'if (![scanner scanInteger:&count] || count <= 0) return nil;',
    '[gAWEAlbumMorphController updateSecondBadgeValue:secondValue];',
    '%hook AWENormalModeTabBarBadgeContainerView',
]
for token in required_objc:
    if token not in objc:
        raise SystemExit(f'missing Objective-C token: {token}')

# The menu hit view may live under the native profile host, but never as a
# direct AWEElementStackView child and never in a separate window-level menu
# host. The old profile-stack pinning experiments also stay deleted.
for forbidden in [
    '[stack addSubview:menuButton]',
    'AwemeLiquidBar.AvatarMenu.WindowAnchor',
    '[window addSubview:gAWEAvatarMenuOverlayButton];',
    'UIContextMenuInteraction',
    'RIGHT_FULLSCREEN_COMMENT_PROTECT',
    'RIGHT_FULLSCREEN_BLOCK_HIDE',
    'RIGHT_FULLSCREEN_BLOCK_ALPHA',
    'RIGHT_FULLSCREEN_BLOCK_REMOVE',
    'gAWEProfileFullscreenRightProtectUntil',
    'gAWEProfileFullscreenProtectedRightStack',
    'AWEForceRestoreRightActionStackAfterComment',
]:
    if forbidden in objc:
        raise SystemExit(f'forbidden old profile/menu path remains: {forbidden}')

# Independent floating download button remains retired; downloads live in the
# avatar menu. Legacy helper may exist only as its own unused definition.
if objc.count('AWEEnsureExternalBridgeMenuSlot(') != 1:
    raise SystemExit('independent download slot still has a live caller')
for snippet in [
    'static void AWELayoutExternalBridgeMenuForStack(UIView *stack) {\n    (void)stack;',
    'static void AWERefreshExternalBridgeMenu(UIView *stack) {\n    (void)stack;\n    AWEHideGlobalDownloadMenu();',
]:
    if snippet not in objc:
        raise SystemExit('floating download disable guard missing')

for forbidden in [
    'AWEExternalBridgePluginImageLoaded', 'AWEExternalBridgeRuntimeHasSelector',
    'AWEExternalBridgeInvokeSelectorName', 'BRIDGE_PLUGIN_FOUND', 'BRIDGE_ACTION',
    'saveCurrentVideo', 'tcShowDownloadOptions', 'NATIVE_DOWNLOAD_READY',
    '上滑收缩底栏（动态高度）',
]:
    if forbidden in objc or forbidden in swift:
        raise SystemExit(f'forbidden regression/bridge remains: {forbidden}')

if objc.count('%hook') != objc.count('%end'):
    raise SystemExit('Logos hook/end count mismatch')
for left, right, name in [('{','}','brace'),('(',')','parenthesis'),('[',']','bracket')]:
    if objc.count(left) != objc.count(right):
        raise SystemExit(f'Objective-C {name} count mismatch')

if 'kAWEAuthorizationDigests[34]' not in objc:
    raise SystemExit('auth34 digest table declaration missing')
start = objc.index('kAWEAuthorizationDigests[34]')
end = objc.index('};', start)
rows = [line for line in objc[start:end].splitlines()
        if line.strip().startswith('{') and 'kAWEAuthorizationDigests' not in line]
if len(rows) != 34:
    raise SystemExit(f'auth digest row count is {len(rows)}, expected 34')

for token in [
    '[PHPhotoLibrary sharedPhotoLibrary] performChanges:',
    '[PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL]',
    '[PHAssetChangeRequest creationRequestForAssetFromImage:image]',
    'NSURLSessionDownloadTask *task', 'NSURLSessionDataTask *task',
]:
    if token not in objc:
        raise SystemExit(f'native downloader API token missing: {token}')

print('AwemeLiquidBar 1.0.53b flexible-right/nested-menu/paging-safe clean-screen preflight passed')
PY2
