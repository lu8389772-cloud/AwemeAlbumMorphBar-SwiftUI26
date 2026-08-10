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

for name, text, token in [
    ('control', control, 'Version: 1.0.52k'),
    ('workflow', workflow, 'AwemeLiquidBar-1.0.52k-Xcode27-rootless'),
    ('build', build_script, "EXPECTED_VERSION='1.0.52k'"),
    ('build', build_script, 'LiquidBar 设置 · 1.0.52k'),
    ('build', build_script, 'AwemeLiquidBar_1.0.52k_interaction.log'),
    ('makefile', makefile, 'UIKit QuartzCore Foundation SwiftUI Photos'),
]:
    if token not in text:
        raise SystemExit(f'missing {name} token: {token}')

# Badge is deliberately rolled back to the original mirroring path.
for token in [
    '@objc(updateMessageBadgeValue:)',
    'items[index].badgeValue = normalized',
    'items[index].badgeColor = .systemRed',
    'self?.applyMessageBadge()',
]:
    if token not in swift:
        raise SystemExit(f'missing badge rollback token: {token}')
if 'badgePositionAdjustment' in swift:
    raise SystemExit('custom badge position adjustment must be absent in 1.0.52k')

for token in [
    'AwemeLiquidBar 1.0.52k', 'LiquidBar 设置 · 1.0.52k',
    '#import <Photos/Photos.h>',
    'AWECurrentAwemeModelForStack', 'awelistkit_cellContext',
    'AWERobustVideoURLForAweme', '@"h264URL"', '@"originURLList"',
    'AWEDownloadCurrentImageForAweme', 'AWEDownloadAllImagesForAweme',
    'AWEDownloadAudioForAweme', 'AWECopyCompleteTextForAweme',
    'gAWEDownloadMenuSlot', 'AWEHideGlobalDownloadMenu',
    'DOWNLOAD_BUTTON_HIT', 'DOWNLOAD_MENU_READY', 'DOWNLOAD_ACTION',
    'button.showsMenuAsPrimaryAction = YES;',
    '显示右侧下载按钮', 'AWEDownloadButtonEnabled', 'downloadButtonSwitchChanged:',
    'AWEApplyFriendsCaptionBottomReserve', 'FRIENDS_CAPTION_RESERVE',
    'AWECurrentRouteHasPlayableFeedController',
]:
    if token not in objc:
        raise SystemExit(f'missing Objective-C token: {token}')

# 1.0.52k download stability contract.
for token in [
    'gAWEAlbumMorphController.viewIfLoaded',
    'gAWEAlbumMorphOverlayWindow',
    'Deliberately do not fall back into the main feed hierarchy',
    'use ONE geometry source only',
    'const CGFloat profileDiameter = 54.0;',
    'const CGFloat edgeGap = 8.0;',
    '[CATransaction setDisableActions:YES]',
    'no timeout-based hide/show loop',
    'Keep the current owner until its single stable profile-glass anchor',
    'AWEHoldVisibleDownloadDuringOwnerGap',
]:
    if token not in objc:
        raise SystemExit(f'missing 1.0.52k download token: {token}')

# No regression to the feed/root UIMenu source that can push captions down.
for forbidden in [
    'UIViewController *rootController = window.rootViewController;',
    'return highest ?: stack.superview;',
    'avatarVisualDiameter',
    'callerAvatar = stack ? AWEDownloadMenuProfileAnchorForStack(stack) : nil;',
    'kAWEDownloadOwnerGapGrace = 0.58',
    'DOWNLOAD_OWNER_GAP_HOLD',
]:
    if forbidden in objc:
        raise SystemExit(f'forbidden 1.0.52j regression remains: {forbidden}')

if objc.count('[[AWEExternalBridgeMenuSlotView alloc] initWithFrame:CGRectZero]') != 1:
    raise SystemExit('download menu slot is not singleton')
if 'if (AWEShouldSuppressBarForUserDetailRoute() &&' not in objc:
    raise SystemExit('normal profile route download suppression missing')
if 'slot.menuButton.menu = downloadMenu;' not in objc or \
   'slot.menuButton.showsMenuAsPrimaryAction = YES;' not in objc:
    raise SystemExit('native download UIMenu install path missing')

if objc.count('%hook') != objc.count('%end'):
    raise SystemExit('Logos hook/end count mismatch')
for left, right, name in [('{','}','brace'),('(',')','parenthesis'),('[',']','bracket')]:
    if objc.count(left) != objc.count(right):
        raise SystemExit(f'Objective-C {name} count mismatch')

if 'kAWEAuthorizationDigests[30]' not in objc:
    raise SystemExit('auth30 digest table declaration missing')
start = objc.index('kAWEAuthorizationDigests[30]')
end = objc.index('};', start)
rows = [line for line in objc[start:end].splitlines()
        if line.strip().startswith('{') and 'kAWEAuthorizationDigests' not in line]
if len(rows) != 30:
    raise SystemExit(f'auth digest row count is {len(rows)}, expected 30')

print('AwemeLiquidBar 1.0.52k badge rollback + sticky overlay downloader preflight passed')
PY2
