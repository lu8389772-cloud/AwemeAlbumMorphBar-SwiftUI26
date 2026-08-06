#!/bin/bash
set -euo pipefail

swiftc -frontend -parse AwemeAlbumMorphBar.swift

python3 - <<'PY'
from pathlib import Path
swift = Path('AwemeAlbumMorphBar.swift').read_text()
objc = Path('Tweak.x').read_text()
control = Path('control').read_text()

for token in [
    'Version: 1.0.41b',
]:
    if token not in control:
        raise SystemExit(f'missing control token: {token}')

for token in [
    'tabBarMinimizeBehavior = .never',
    'let search = UISearchTab',
    'setResolvedInterfaceStyleRaw',
    'setVerticalOffset(_ offset: CGFloat)',
    'let designScale: CGFloat = 3.0',
    'let maximumPixelEdge: CGFloat = 100.0',
]:
    if token not in swift:
        raise SystemExit(f'missing Swift stable token: {token}')

for token in [
    'AwemeLiquidBar 1.0.41b',
    'Native minimization is intentionally disabled in 1.0.41b',
    'AWEApplyAlbumMorphResolvedAppearance',
    'gAWEAlbumMorphLastAppliedStyle',
    'AWERefreshRegisteredAdaptiveGlassButtons',
    'AWECreateAdaptiveGlassIconConfiguration',
    'AWEConfigureAdaptiveSystemGlassIconButton',
    '@"glassButtonConfiguration"',
    '@"clearGlassButtonConfiguration"',
    'configuration.baseBackgroundColor = nil;',
    'configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;',
    'configuration.contentInsets = NSDirectionalEdgeInsetsZero;',
    'button.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;',
    'slot.systemGlassButton',
    'const CGFloat diameter = 46.0;',
    'PNG is a separate original-colour path.',
    'All SF Symbols remain templates.',
    'AWEBottomBarSearchIsVisible',
    'AWESuppressTopSearchForBottomSearch',
    '#pragma mark - Native top-left four-action Liquid Glass menu',
    'button.menu = menu;',
    'button.showsMenuAsPrimaryAction = YES;',
    '@{@"title": @"直播", @"symbol": @"play.rectangle"}',
    '@{@"title": @"商城", @"symbol": @"storefront"}',
    '@{@"title": @"关注", @"symbol": @"person.2"}',
    '@{@"title": @"推荐", @"symbol": @"sparkles"}',
    '@"顶部与右侧按钮色调模式（系统自适应）"',
    'gAWEAlbumMorphTintProbe.alpha = 0.02;',
    'covered left platter',
]:
    if token not in objc:
        raise SystemExit(f'missing Objective-C token: {token}')

if objc.count('const CGFloat diameter = 46.0;') != 2:
    raise SystemExit('top/right 46 pt diameter count is not 2')
if objc.count('%hook') != objc.count('%end'):
    raise SystemExit('Logos hook/end count mismatch')
if objc.count('{') != objc.count('}'):
    raise SystemExit('Objective-C brace count mismatch')

for forbidden in [
    'UIDeferredMenuElement',
    'completion(@[])',
    'slot.photosGlassHost.hidden = NO;',
    'AWEInstallOrUpdateAlbumMorphBar((UIView *)gAWELastTabBar, YES)',
]:
    if forbidden in objc:
        raise SystemExit(f'forbidden regression remains: {forbidden}')

print('AwemeLiquidBar 1.0.41b local-backdrop glass preflight passed')
PY
