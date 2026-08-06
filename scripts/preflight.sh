#!/bin/bash
set -euo pipefail

swiftc -frontend -parse AwemeAlbumMorphBar.swift

python3 - <<'PY2'
from pathlib import Path
swift = Path('AwemeAlbumMorphBar.swift').read_text()
objc = Path('Tweak.x').read_text()
control = Path('control').read_text()
workflow = Path('.github/workflows/build.yml').read_text()

required_control = ['Version: 1.0.43c']
required_workflow = ['AwemeLiquidBar-1.0.43c-Xcode27-rootless']
required_swift = [
    'tabBarMinimizeBehavior = .never',
    'let search = UISearchTab',
    'setResolvedInterfaceStyleRaw',
    'setVerticalOffset(_ offset: CGFloat)',
    'currentFallbackCompactScale()',
    'applyFallbackCompactTransform(animated:',
    'setCompactMode(_ compact: Bool, animated: Bool)',
    'let designScale: CGFloat = 3.0',
    'let maximumPixelEdge: CGFloat = 100.0',
]
required_objc = [
    'AwemeLiquidBar 1.0.43c',
    'AWEApplyAlbumMorphResolvedAppearance',
    'AWERefreshRegisteredAdaptiveGlassButtons',
    'AWEAdaptiveButtonResolvedLocalStyle',
    'AWERefreshOneAdaptiveButtonContrast',
    'kAWEAdaptiveGlassAutomaticContrastKey',
    'AWESoftClearEdgeColor',
    'view.layer.borderWidth = 0.0;',
    'AWEConfigureAdaptiveSystemGlassIconButton',
    '@"glassButtonConfiguration"',
    '@"clearGlassButtonConfiguration"',
    'AWEHomeTransparentGlassEnabled',
    'AWEDynamicTopQuickMenuDefinitions',
    'AWEViewEffectivelyVisibleInsideTopContainer',
    'button.menu = menu;',
    'button.showsMenuAsPrimaryAction = YES;',
    '%hook AWEFeedMultiTabSelectedContainerView',
    'AWEForceExactTopIndicatorSuppression',
    'AWERefreshProfileAvatarGlass',
    'const CGFloat diameter = 54.0;',
    'AWEAlbumMorphCollapseGestureDelegate',
    'CGAffineTransformMakeScale(0.01, 0.01)',
    'AWEHideAlbumMorphTintProbe',
    'MIN(22.0, height * 0.5)',
    '纯透明材质（无额外描边，局部黑白自适应）',
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
    '纯透明材质（灰色柔边',
    'AwemeLiquidBar_1.0.42a_interaction.log',
]:
    if forbidden in objc:
        raise SystemExit(f'forbidden regression remains: {forbidden}')

print('AwemeLiquidBar 1.0.43c consolidated preflight passed')
PY2
