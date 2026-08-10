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
    ('control', control, 'Version: 1.0.52m'),
    ('workflow', workflow, 'AwemeLiquidBar-1.0.52m-Xcode27-rootless'),
    ('build', build_script, "EXPECTED_VERSION='1.0.52m'"),
    ('build', build_script, 'LiquidBar 设置 · 1.0.52m'),
    ('build', build_script, 'AwemeLiquidBar_1.0.52m_interaction.log'),
    ('makefile', makefile, 'UIKit QuartzCore Foundation SwiftUI Photos'),
]
for name, text, token in checks:
    if token not in text:
        raise SystemExit(f'missing {name} token: {token}')

for token in [
    'tabBarMinimizeBehavior = .never', 'let search = UISearchTab',
    '@objc(updateMessageBadgeValue:)', '@objc(updateSecondBadgeValue:)', 'applyUnreadBadges()',
    'messageBadgeOverlay', 'secondBadgeOverlay', 'let height: CGFloat = dotOnly ? 8.0 : 16.0',
    'clearSystemBadge(Identifier.second)', 'clearSystemBadge(Identifier.messages)',
    'setResolvedInterfaceStyleRaw', 'setVerticalOffset(_ offset: CGFloat)',
    '@objc(setVisibleFraction:animated:)', 'visibilityMaskView',
]:
    if token not in swift: raise SystemExit(f'missing Swift token: {token}')

for token in [
    'AwemeLiquidBar 1.0.52m', 'LiquidBar 设置 · 1.0.52m',
    '#import <Photos/Photos.h>',
    'AWECurrentAwemeModelForStack', 'awelistkit_cellContext',
    'AWERobustVideoURLForAweme', '@"h264URL"', '@"originURLList"',
    'AWEDownloadCurrentImageForAweme', 'AWECurrentAlbumImageModelForAweme',
    'AWEDownloadAllImagesForAweme', 'AWEDownloadAudioForAweme',
    'AWECopyCompleteTextForAweme', '保存当前视频', '保存当前图片',
    'gAWEDownloadMenuSlot', 'AWEHideGlobalDownloadMenu',
    'DOWNLOAD_BUTTON_HIT', 'DOWNLOAD_MENU_READY', 'DOWNLOAD_ACTION',
    'DOWNLOAD_VIDEO_HTTP', 'DOWNLOAD_IMAGE_HTTP',
    'button.showsMenuAsPrimaryAction = YES;',
    'AWEPreferHighestPlaybackEnabled', '优先最高画质播放（可能增加流量）',
    'AwemeLiquidBarDownloadButtonEnabledV1', '显示下载按钮',
    'AWEDownloadStackIsStronglyCurrent', 'AWEDownloadFixedScreenCenter',
    'return stack.window;', 'DOWNLOAD_SLOT state=fixed',
    'updateSecondBadgeValue',
    'kAWETopCategoryItemHiddenMarkerKey', 'AWEHideLeakedTopLiveBadges',
    'externalFullscreen=%d',
    'return [stored isKindOfClass:NSNumber.class] ? [(NSNumber *)stored boolValue] : NO;',
    'gAWEFriendsTabLatched', 'AWEUpdateFriendsTabLatch',
    "Preserve the native bar's layout footprint before Friends performs",
    'AWECurrentRightStackVisibilityScore', 'AWECurrentRouteHasPlayableFeedController',
    'RIGHT_FULLSCREEN_RECOVERY', 'RIGHT_FULLSCREEN_VISIBILITY_GUARD',
    'AWEInvokeCompatibleTabTapGesture', 'TAB_COMPAT_GESTURE',
    'AWEInvokeControllerTabRoute', 'TAB_CONTROLLER_ROUTE',
    'AwemeLiquidBarSettingsGestureMineOnlyV1',
    '双指长按仅在‘我’页面触发', 'AWECurrentPageAllowsSettingsGesture',
    '显示朋友/消息未读角标', 'AWEUpdateAlbumMorphMessageBadge',
    '%hook AWENormalModeTabBarBadgeContainerView',
    'AWEInstallGlassPressFeedback', 'AWEGlassPressFeedbackTarget',
    'RIGHT_REBIND_PASS', 'AWEFrameForTopLiquidGroup',
    'sideReserve = (menuVisible || searchVisible) ? 82.0 : 14.0',
]:
    if token not in objc: raise SystemExit(f'missing Objective-C token: {token}')

for forbidden in [
    'AWEExternalBridgePluginImageLoaded', 'AWEExternalBridgeRuntimeHasSelector',
    'AWEExternalBridgeInvokeSelectorName', 'BRIDGE_PLUGIN_FOUND', 'BRIDGE_ACTION',
    'saveCurrentVideo', 'tcShowDownloadOptions',
    '保存当前视频（智能高清）', 'NATIVE_DOWNLOAD_READY',
    'newbar.home.selected', 'newbar.messages.selected', 'newbar.profile.selected',
    'bottom.home.selected', 'bottom.messages.selected', 'bottom.profile.selected',
    '上滑收缩底栏（动态高度）',
]:
    if forbidden in objc or forbidden in swift:
        raise SystemExit(f'forbidden regression/bridge remains: {forbidden}')

if objc.count('%hook') != objc.count('%end'):
    raise SystemExit('Logos hook/end count mismatch')
for left, right, name in [('{','}','brace'),('(',')','parenthesis'),('[',']','bracket')]:
    if objc.count(left) != objc.count(right):
        raise SystemExit(f'Objective-C {name} count mismatch')

if 'kAWEAuthorizationDigests[29]' not in objc:
    raise SystemExit('auth29 digest table declaration missing')
start = objc.index('kAWEAuthorizationDigests[29]')
end = objc.index('};', start)
rows = [line for line in objc[start:end].splitlines()
        if line.strip().startswith('{') and 'kAWEAuthorizationDigests' not in line]
if len(rows) != 29:
    raise SystemExit(f'auth digest row count is {len(rows)}, expected 29')

if 'menuWithTitle:@"" options:UIMenuOptionsDisplayInline' in objc:
    raise SystemExit('invalid UIMenu selector menuWithTitle:options:children: remains')

# Public API hardening for the new native downloader.
for token in [
    '[PHPhotoLibrary sharedPhotoLibrary] performChanges:',
    '[PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:fileURL]',
    '[PHAssetChangeRequest creationRequestForAssetFromImage:image]',
    'NSURLSessionDownloadTask *task', 'NSURLSessionDataTask *task',
]:
    if token not in objc:
        raise SystemExit(f'native downloader API token missing: {token}')


# Guard against Objective-C++ switch/case lifetime regression in glass press feedback.
if "case UIGestureRecognizerStateFailed: {" not in objc:
    raise SystemExit('glass press switch-case scope guard missing')

# The floating downloader must be a true singleton. Per-cell allocations caused
# duplicate/jumping buttons over comments and profile pages.
if objc.count('[[AWEExternalBridgeMenuSlotView alloc] initWithFrame:CGRectZero]') != 1:
    raise SystemExit('download menu slot is not singleton')
if 'if (AWEShouldSuppressBarForUserDetailRoute() &&' not in objc:
    raise SystemExit('normal profile route download suppression missing')
if 'slot.menuButton.menu = downloadMenu;' not in objc or \
   'slot.menuButton.showsMenuAsPrimaryAction = YES;' not in objc:
    raise SystemExit('native download UIMenu install path missing')

for token in [
    'AWEDownloadMenuOverlayHostView',
    'DOWNLOAD_SLOT state=fixed',
    'AWEDownloadStackIsStronglyCurrent',
    'RIGHT_FULLSCREEN_COMMENT_PROTECT',
    'RIGHT_FULLSCREEN_BLOCK_HIDE',
    'RIGHT_FULLSCREEN_BLOCK_ALPHA',
    'RIGHT_FULLSCREEN_BLOCK_REMOVE',
    'AWEPrimeFriendsNativeLayoutFootprint',
    'FRIENDS_LAYOUT_PRIME',
    'AWEFriendsExternalFullscreenActive',
    '%hook AWEFeedTableViewController',
    'feed.layout.async',
    'AWEApplyFriendsCaptionBottomReserve',
    'FRIENDS_CAPTION_RESERVE',
    'if (!AWEControllerShouldBeginReturnPrewarm(controller)) return;',
]:
    if token not in objc:
        raise SystemExit(f'1.0.52m recovery token missing: {token}')

print('AwemeLiquidBar 1.0.52m stability preflight passed')
PY2
