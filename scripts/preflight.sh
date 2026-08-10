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
    ('control', control, 'Version: 1.0.52s'),
    ('workflow', workflow, 'AwemeLiquidBar-1.0.52s-Xcode27-rootless'),
    ('build', build_script, "EXPECTED_VERSION='1.0.52s'"),
    ('build', build_script, 'LiquidBar 设置 · 1.0.52s'),
    ('build', build_script, 'AwemeLiquidBar_1.0.52s_interaction.log'),
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
    'AwemeLiquidBar 1.0.52s', 'LiquidBar 设置 · 1.0.52s',
    '#import <Photos/Photos.h>',
    'AWECurrentAwemeModelForStack', 'AWERobustVideoURLForAweme',
    'AWEDownloadCurrentImageForAweme', 'AWEDownloadAllImagesForAweme',
    'AWEDownloadAudioForAweme', 'AWECopyCompleteTextForAweme',
    'AWEAvatarBaseMenuForStack', '@"进入主页"',
    '@"头像菜单显示下载功能"', 'AWEAvatarMenuDownloadEnabled',
    'slot.menuButton.menu = AWEAvatarBaseMenuForStack(stack, pictureHost);',
    'slot.menuButton.showsMenuAsPrimaryAction = YES;',
    'AWEInstallGlassPressFeedback(slot.menuButton, slot.glassButton);',
    'AWECurrentOriginalSecondBadgeValue', 'BOTTOM_BADGES_NATIVE',
    '[gAWEAlbumMorphController updateSecondBadgeValue:secondValue];',
    'RIGHT_REBIND_PASS', 'RIGHT_FULLSCREEN_COMMENT_REACQUIRE',
    'RIGHT_FULLSCREEN_BLOCK_HIDE_IMAGE', 'RIGHT_FULLSCREEN_BLOCK_ALPHA_IMAGE',
    'RIGHT_FULLSCREEN_BLOCK_REMOVE_IMAGE', 'AWECurrentRouteHasPlayableFeedController',
    '%hook AWENormalModeTabBarBadgeContainerView',
    'AWEPrimeFriendsNativeLayoutFootprint', 'AWEApplyFriendsCaptionBottomReserve',
    '@"一键清屏"', '@"退出清屏"', 'AWEEnterCleanScreenFromStack',
    'AWERefreshCleanScreenRecoveryButton',
    'setBottomAreaHidden:', 'setTabBarHiddenForPureMode:',
    'setTimesHiddenForPureMode:', 'AWECleanScreenConfigureRealAvatarMenuButton',
    'AWEFindCurrentRightActionStackExcluding',
    'AWEFrameGeometryLooksLikeCurrentRightActionStack',
    'AWEFindCurrentRightActionStackAcrossWindowsAllowSuppressedAncestors',
    'PROFILE_COMMENT_SKIP_BAR_RECOVERY', 'PROFILE_COMMENT_LAYOUT_RESTORE',
]
for token in required_objc:
    if token not in objc:
        raise SystemExit(f'missing Objective-C token: {token}')

# The independent floating download control is retired. Its legacy helper may
# remain for source compatibility, but it must have no callers other than its
# own definition, and both refresh/layout entry points must hard-hide it.
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

if 'kAWEAuthorizationDigests[33]' not in objc:
    raise SystemExit('auth33 digest table declaration missing')
start = objc.index('kAWEAuthorizationDigests[33]')
end = objc.index('};', start)
rows = [line for line in objc[start:end].splitlines()
        if line.strip().startswith('{') and 'kAWEAuthorizationDigests' not in line]
if len(rows) != 33:
    raise SystemExit(f'auth digest row count is {len(rows)}, expected 33')

for token in [
    '[PHPhotoLibrary sharedPhotoLibrary] performChanges:',
    '[PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL]',
    '[PHAssetChangeRequest creationRequestForAssetFromImage:image]',
    'NSURLSessionDownloadTask *task', 'NSURLSessionDataTask *task',
]:
    if token not in objc:
        raise SystemExit(f'native downloader API token missing: {token}')


# 1.0.52s clean-screen/video-comment regressions
for forbidden in [
    'gAWECleanScreenRecoveryButton', 'gAWECleanScreenRecoveryWindow',
    'gAWECleanScreenAvatarImage', 'gAWECleanScreenAvatarFrameInWindow',
    'NSSelectorFromString(@"setPureMode:animated:")',
]:
    if forbidden in objc:
        raise SystemExit(f'1.0.52s forbidden replacement/full-pure-mode path remains: {forbidden}')

for token in [
    'button.menu = AWEAvatarBaseMenuForStack(stack, slot.profileHost);',
    'cleanEnabled ? @"退出清屏" : @"一键清屏"',
    'if (gAWECleanScreenEnabled) fraction = 0.0;',
    'AWECleanScreenSuppressStatusBarViews',
    'setStatusBarHidden:withAnimation:',
    'stack.layer.opacity = 1.0f;',
    'AWECleanScreenSuppressKnownChromeTree(stack, stack.window, 0);',
    'gAWECleanScreenAvatarRevealed &&',
    'gAWEProfileFullscreenProtectedRightStack = profileVideoRecovery',
    'AWEFindCurrentRightActionStackExcluding(captured, NO)',
]:
    if token not in objc:
        raise SystemExit(f'1.0.52s required token missing: {token}')

# 1.0.52s linker/badge regressions
assert 'AWEPlayInteractionViewController.class' not in objc, 'static private-class reference would reintroduce linker failure'
assert 'NSClassFromString(@"AWEPlayInteractionViewController")' in objc, 'runtime private-class lookup missing'
assert 'if (![scanner scanInteger:&count] || count <= 0) return nil;' in objc, 'zero-count Messages badge guard missing'

print('AwemeLiquidBar 1.0.52s live-stack clean recovery/video reacquire preflight passed')
PY2
