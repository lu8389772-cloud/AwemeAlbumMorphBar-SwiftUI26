#!/bin/bash
set -euo pipefail

swiftc -frontend -parse AwemeAlbumMorphBar.swift

python3 - <<'PY2'
from pathlib import Path
swift = Path('AwemeAlbumMorphBar.swift').read_text()
objc = Path('Tweak.x').read_text()
control = Path('control').read_text()
workflow = Path('.github/workflows/build.yml').read_text()

required_control = ['Version: 1.0.47c']
required_workflow = ['AwemeLiquidBar-1.0.47c-Xcode27-rootless']
required_swift = [
    'tabBarMinimizeBehavior = .never',
    'let search = UISearchTab',
    'setResolvedInterfaceStyleRaw',
    'setVerticalOffset(_ offset: CGFloat)',
    '@objc(setVisibleFraction:animated:)',
    'visibilityMaskView',
    'self.view.mask = self.visibilityMaskView',
]
required_objc = [
    'AwemeLiquidBar 1.0.47c',
    'LiquidBar 设置 · 1.0.47c',
    'Telegram-style top liquid category group',
    'AWETopLiquidGroupView',
    'alb_swipedLeft:',
    'alb_swipedRight:',
    'AWETopTelegramVisibleCount()',
    'AWEConfigureTopSelectionPill',
    'topCategoryVisibleCountChanged:',
    'AWEApplyAlbumMorphVisibleFraction',
    'AWEUpdateAlbumMorphVisibility',
    'return.prewarm.resident',
    'RECOVERY_ONCE',
    'button.menu = menu;',
    'button.showsMenuAsPrimaryAction = YES;',
    'AwemeLiquidBarChatCapsuleEnabled1.0.46',
]
for token in required_control:
    if token not in control: raise SystemExit(f'missing control token: {token}')
for token in required_workflow:
    if token not in workflow: raise SystemExit(f'missing workflow token: {token}')
for token in required_swift:
    if token not in swift: raise SystemExit(f'missing Swift token: {token}')
for token in required_objc:
    if token not in objc: raise SystemExit(f'missing Objective-C token: {token}')

if objc.count('const CGFloat diameter = 46.0;') != 2:
    raise SystemExit('top/right 46 pt diameter count is not 2')
if objc.count('%hook') != objc.count('%end'):
    raise SystemExit('Logos hook/end count mismatch')
for left, right, name in [('{','}','brace'),('(',')','parenthesis'),('[',']','bracket')]:
    if objc.count(left) != objc.count(right):
        raise SystemExit(f'Objective-C {name} count mismatch')
for forbidden in [
    'UIDeferredMenuElement',
    'completion(@[])',
    'preferredElementSize = UIMenuElementSizeLarge',
    'collapseLabel',
    '上滑收缩底栏（动态高度）',
    'NSArray<NSNumber *> *delays = preDismiss',
]:
    if forbidden in objc:
        raise SystemExit(f'forbidden regression remains: {forbidden}')

# The top category implementation must not create a UISegmentedControl. A
# UISegmentedControl in the settings UI is allowed.
top_start = objc.index('#pragma mark - Telegram-style top liquid category group')
top_end = objc.index('#pragma mark - Top action refresh', top_start)
if '[[UISegmentedControl alloc]' in objc[top_start:top_end]:
    raise SystemExit('top group regressed to UISegmentedControl')
if 'AWEConfigureAdaptiveSystemGlassPlateButton(\n        group.backgroundGlass' not in objc:
    raise SystemExit('single top glass platter configuration missing')

print('AwemeLiquidBar 1.0.47c configurable Telegram switcher and controller-mask preflight passed')
PY2
