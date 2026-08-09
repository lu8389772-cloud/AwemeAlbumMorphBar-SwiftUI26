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
    ('control', control, 'Version: 1.0.51a'),
    ('workflow', workflow, 'AwemeLiquidBar-1.0.51a-Xcode27-rootless'),
    ('build', build_script, "EXPECTED_VERSION='1.0.51a'"),
    ('build', build_script, 'LiquidBar 设置 · 1.0.51a'),
    ('build', build_script, 'AwemeLiquidBar_1.0.51a_interaction.log'),
    ('makefile', makefile, 'UIKit QuartzCore Foundation SwiftUI Photos'),
]
for name, text, token in checks:
    if token not in text:
        raise SystemExit(f'missing {name} token: {token}')

for token in [
    'tabBarMinimizeBehavior = .never', 'let search = UISearchTab',
    '@objc(updateMessageBadgeValue:)', 'applyMessageBadge()',
    'setResolvedInterfaceStyleRaw', 'setVerticalOffset(_ offset: CGFloat)',
    '@objc(setVisibleFraction:animated:)', 'visibilityMaskView',
]:
    if token not in swift: raise SystemExit(f'missing Swift token: {token}')

for token in [
    'AwemeLiquidBar 1.0.51a', 'LiquidBar 设置 · 1.0.51a',
    '#import <Photos/Photos.h>',
    'AWECurrentAwemeModelForStack', 'awelistkit_cellContext',
    'AWEVideoVariantsForVideo', 'bitrateModels_origin', 'bitrateModels',
    'AWEChooseSmartDownloadVariant', '保存当前视频（智能高清）',
    'AWEDownloadAllImagesForAweme', 'AWEDownloadAudioForAweme',
    'AWECopyCompleteTextForAweme', 'NATIVE_DOWNLOAD_READY', 'DOWNLOAD_VIDEO',
    'AWEPreferHighestPlaybackEnabled', '优先最高画质播放（可能增加流量）',
    'switchStreamBitrate:type:completionHandler:',
    'setResolutionWithIndex:isManual:beginChange:completion:',
    'PLAYBACK_HIGHEST', 'AwemeLiquidBar.NativeDownloadMenuSlot',
    'hostWindow addSubview:slot', 'gAWEFriendsTabLatched',
    'AWEUpdateFriendsTabLatch', 'AWEAlbumMorphSteadyWantsVisible',
    'AWEInvokeCompatibleTabTapGesture', 'TAB_COMPAT_GESTURE',
    'AWEInvokeControllerTabRoute', 'TAB_CONTROLLER_ROUTE',
    'AwemeLiquidBarSettingsGestureMineOnlyV1',
    '双指长按仅在‘我’页面触发', 'AWECurrentPageAllowsSettingsGesture',
    '显示消息未读角标', 'AWEUpdateAlbumMorphMessageBadge',
    '%hook AWENormalModeTabBarBadgeContainerView',
    'AWEInstallGlassPressFeedback', 'AWEGlassPressFeedbackTarget',
    'button.showsMenuAsPrimaryAction = YES;',
    'RIGHT_REBIND_PASS', 'AWEFrameForTopLiquidGroup',
    'sideReserve = (menuVisible || searchVisible) ? 82.0 : 14.0',
]:
    if token not in objc: raise SystemExit(f'missing Objective-C token: {token}')

for forbidden in [
    'AWEExternalBridgePluginImageLoaded', 'AWEExternalBridgeRuntimeHasSelector',
    'AWEExternalBridgeInvokeSelectorName', 'BRIDGE_PLUGIN_FOUND', 'BRIDGE_ACTION',
    'saveCurrentVideo', 'tcShowDownloadOptions',
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

print('AwemeLiquidBar 1.0.51a native downloader/quality/Friends preflight passed')
PY2
