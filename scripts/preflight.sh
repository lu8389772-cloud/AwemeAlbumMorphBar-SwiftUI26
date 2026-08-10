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
    ('control', control, 'Version: 1.0.52l'),
    ('workflow', workflow, 'AwemeLiquidBar-1.0.52l-Xcode27-rootless'),
    ('build', build_script, "EXPECTED_VERSION='1.0.52l'"),
    ('build', build_script, 'LiquidBar 设置 · 1.0.52l'),
    ('build', build_script, 'AwemeLiquidBar_1.0.52l_interaction.log'),
    ('makefile', makefile, 'UIKit QuartzCore Foundation SwiftUI Photos'),
]:
    if token not in text:
        raise SystemExit(f'missing {name} token: {token}')

# Both Friends and Messages mirror unread state through the same source reader.
for token in [
    '@objc(updateMessageBadgeValue:)',
    '@objc(updateFriendsBadgeValue:)',
    'friendsBadgeValue',
    'applyMirroredBadges()',
    'items[index].badgeValue = normalized',
    'items[index].badgeColor = .systemRed',
    'let scale: CGFloat = 0.84',
]:
    if token not in swift:
        raise SystemExit(f'missing Swift badge token: {token}')
if 'badgePositionAdjustment' in swift:
    raise SystemExit('custom badge position adjustment must remain absent')

for token in [
    'AWECurrentOriginalTabBadgeValueAtIndex',
    'AWECurrentOriginalFriendsBadgeValue',
    'AWEUpdateAlbumMorphBadges',
    'updateFriendsBadgeValue:friendsValue',
    'AWEHasVisibleCompactBadgeDot',
    'AWENormalModeTabBarBadgeContainerView',
    '显示消息/朋友未读角标',
]:
    if token not in objc:
        raise SystemExit(f'missing Objective-C badge token: {token}')
if 'if (AWEHasVisibleCompactBadgeDot(button, 0)) return @" ";' not in objc:
    raise SystemExit('concrete dot-badge mirroring path missing')

# Downloader is a long-lived independent floating source; no avatar/cell geometry.
for token in [
    'AwemeLiquidBar.DownloadButtonCenterXPercentV1',
    'AwemeLiquidBar.DownloadButtonCenterYPercentV1',
    'alb_handleDownloadPan:',
    'UIPanGestureRecognizer',
    'return overlay;',
    'Fixed, screen-based default',
    'AWEEnsureExternalBridgeMenuSlot(stack)',
    'slot.menuButton.menu = downloadMenu;',
    'slot.menuButton.showsMenuAsPrimaryAction = YES;',
    'DOWNLOAD_SLOT state=visible',
]:
    if token not in objc:
        raise SystemExit(f'missing floating download token: {token}')

# Right-column recovery is explicitly decoupled from downloader ownership and
# restores the 1.0.52e geometry/host selection contract.
for token in [
    'AWEFeedInteractionHostForStack',
    'Restore the proven 1.0.52e selection rule',
    'if (!AWEFrameLooksLikeCurrentRightActionStack(candidate)) continue;',
    'AWERefreshExternalBridgeMenu(target);',
]:
    if token not in objc:
        raise SystemExit(f'missing right recovery token: {token}')
right_start = objc.index('static UIView *AWEFindCurrentRightActionStackAcrossWindows(void) {')
right_end = objc.index('static BOOL AWEControllerTreeContainsPlayableFeed', right_start)
right_block = objc[right_start:right_end]
if 'AWEDownloadMenuProfileAnchorForStack' in right_block:
    raise SystemExit('right stack finder is still coupled to download/avatar anchor')

if objc.count('[[AWEExternalBridgeMenuSlotView alloc] initWithFrame:CGRectZero]') != 1:
    raise SystemExit('download menu slot is not singleton')
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

print('AwemeLiquidBar 1.0.52l delivery-stability preflight passed')
PY2
