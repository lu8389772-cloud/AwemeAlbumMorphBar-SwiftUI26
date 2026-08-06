#!/bin/bash
set -euo pipefail

swiftc -frontend -parse AwemeAlbumMorphBar.swift

python3 - <<'PY2'
from pathlib import Path
swift = Path('AwemeAlbumMorphBar.swift').read_text()
objc = Path('Tweak.x').read_text()
control = Path('control').read_text()
workflow = Path('.github/workflows/build.yml').read_text()

required_control = ['Version: 1.0.45a']
required_workflow = ['AwemeLiquidBar-1.0.45a-Xcode27-rootless']
required_swift = [
    'tabBarMinimizeBehavior = .never',
    'let search = UISearchTab',
    'setResolvedInterfaceStyleRaw',
    'setVerticalOffset(_ offset: CGFloat)',
    'let designScale: CGFloat = 3.0',
    'let maximumPixelEdge: CGFloat = 100.0',
]
required_objc = [
    'AwemeLiquidBar 1.0.45a',
    'LiquidBar 设置 · 1.0.45a',
    'static BOOL AWEAlbumMorphCollapseEnabled(void)',
    'return NO;',
    'AWETopLiquidGroupView',
    'UISegmentedControl',
    'contentVisible',
    'AWEStartHomeChromeRecoverySampler',
    '顶部分类液态分组（默认）',
    '左上按钮展开分类菜单',
    'AWETopMenuMorphEnabled',
    'AWEUpdateTopLiquidGroup',
    'AWEScheduleHomeChromeRecovery',
    '- (void)setCenter:(CGPoint)center',
    'AWEPrepareAlbumMorphOverlayTransparency',
    'AWEApplyExactChatCapsuleMask(fill',
    'continuousPill',
    'kAWEAdaptiveGlassExplicitForegroundKey',
    'setContentSize:(CGSize)contentSize',
    'growingText.contentSize.async',
    'button.menu = menu;',
    'button.showsMenuAsPrimaryAction = YES;',
    '%hook AWEFeedMultiTabSelectedContainerView',
    'AWEForceExactTopIndicatorSuppression',
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
]:
    if forbidden in objc:
        raise SystemExit(f'forbidden regression remains: {forbidden}')

print('AwemeLiquidBar 1.0.45a segmented resident recovery preflight passed')
PY2
