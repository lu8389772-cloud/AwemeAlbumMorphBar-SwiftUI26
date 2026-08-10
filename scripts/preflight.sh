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
    ('control', control, 'Version: 1.0.52w'),
    ('workflow', workflow, 'AwemeLiquidBar-1.0.52w-Xcode27-rootless'),
    ('build', build_script, "EXPECTED_VERSION='1.0.52w'"),
    ('build', build_script, 'LiquidBar 设置 · 1.0.52w'),
    ('build', build_script, 'AwemeLiquidBar_1.0.52w_interaction.log'),
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
    'AwemeLiquidBar 1.0.52w', 'LiquidBar 设置 · 1.0.52w',
    '#import <Photos/Photos.h>',
    'AWEAvatarBaseMenuForStack', '@"进入主页"', '@"一键清屏"', '@"退出清屏"',
    'AWEEnterCleanScreenFromStack', 'AWEExitCleanScreen',
    'AWERefreshCleanScreenRecoveryButton',
    'AwemeLiquidBar.CleanScreen.AvatarRecovery',
    '[stack addSubview:menuButton];',
    'slot.menuButton.menu = AWEAvatarBaseMenuForStack(stack, pictureHost);',
    'slot.menuButton.showsMenuAsPrimaryAction = YES;',
    'AWEInstallGlassPressFeedback(slot.menuButton, slot.glassButton);',
    'if (gAWECleanScreenEnabled) fraction = 0.0;',
    'AWECleanScreenSuppressStatusBarViews',
    'if (![scanner scanInteger:&count] || count <= 0) return nil;',
    'AWECurrentOriginalSecondBadgeValue', 'BOTTOM_BADGES_NATIVE',
    'kAWEAuthorizationDigests[33]',
]
for token in required_objc:
    if token not in objc:
        raise SystemExit(f'missing Objective-C token: {token}')

for forbidden in [
    'UIContextMenuInteraction', 'AWEAvatarContextMenuDelegate',
    'AWEInstallAvatarContextMenu',
    'AWEPlayInteractionViewController.class',
    'Long-press avatar menu',
]:
    if forbidden in objc:
        raise SystemExit(f'forbidden avatar/context/private-link regression: {forbidden}')

# The normal avatar menu must remain the verified 1.0.52o primary-action structure.
ensure_start = objc.index('static AWEHomeProfileGlassView *AWEEnsureProfileGlassSlot')
ensure_end = objc.index('static NSMutableDictionary<NSNumber *, AWEHomeActionSlotView *> *', ensure_start)
avatar_block = objc[ensure_start:ensure_end]
for token in [
    '[stack addSubview:menuButton];',
    'if (slot.menuButton.superview != stack)',
    '[stack addSubview:slot.menuButton];',
    'slot.menuButton.center = center;',
    'slot.menuButton.menu = AWEAvatarBaseMenuForStack(stack, pictureHost);',
]:
    if token not in avatar_block:
        raise SystemExit(f'stable 1.0.52o avatar-menu token missing: {token}')

# Clean-screen recovery may own only its dedicated transparent UIWindow button.
# It must never reparent the real menu button.
recovery_start = objc.index('@interface AWECleanScreenRecoveryTarget')
recovery_end = objc.index('static void AWEApplyCleanScreenToInteractionController', recovery_start)
recovery = objc[recovery_start:recovery_end]
if '[window addSubview:gAWECleanScreenRecoveryButton]' not in recovery:
    raise SystemExit('window-level recovery target missing')
for forbidden in [
    '[window addSubview:slot.menuButton]',
    '[slot.profileHost addSubview:slot.menuButton]',
    '[slot.menuButton removeFromSuperview]',
]:
    if forbidden in recovery:
        raise SystemExit(f'real avatar menu is being reparented during clean screen: {forbidden}')

if objc.count('%hook') != objc.count('%end'):
    raise SystemExit('Logos hook/end count mismatch')
for left, right, name in [('{','}','brace'),('(',')','parenthesis'),('[',']','bracket')]:
    if objc.count(left) != objc.count(right):
        raise SystemExit(f'Objective-C {name} count mismatch')

start = objc.index('kAWEAuthorizationDigests[33]')
end = objc.index('};', start)
rows = [line for line in objc[start:end].splitlines()
        if line.strip().startswith('{') and 'kAWEAuthorizationDigests' not in line]
if len(rows) != 33:
    raise SystemExit(f'auth digest row count is {len(rows)}, expected 33')

print('AwemeLiquidBar 1.0.52w stable-click-menu isolated-clean-screen preflight passed')
PY2
