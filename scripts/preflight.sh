#!/bin/bash
set -euo pipefail

swiftc -frontend -parse AwemeAlbumMorphBar.swift

python3 - <<'PY2'
from pathlib import Path
swift = Path('AwemeAlbumMorphBar.swift').read_text()
objc = Path('Tweak.x').read_text()
control = Path('control').read_text()
workflow = Path('.github/workflows/build.yml').read_text()
build_script = Path('build_no_install.sh').read_text()

for token in ['Version: 1.0.50c']:
    if token not in control: raise SystemExit(f'missing control token: {token}')
for token in ['AwemeLiquidBar-1.0.50c-Xcode27-rootless']:
    if token not in workflow: raise SystemExit(f'missing workflow token: {token}')
for token in ["EXPECTED_VERSION='1.0.50c'", 'LiquidBar 设置 · 1.0.50c', 'AwemeLiquidBar_1.0.50c_interaction.log']:
    if token not in build_script: raise SystemExit(f'missing build script token: {token}')
for token in [
    'tabBarMinimizeBehavior = .never', 'let search = UISearchTab',
    '@objc(updateMessageBadgeValue:)', 'applyMessageBadge()',
    'setResolvedInterfaceStyleRaw', 'setVerticalOffset(_ offset: CGFloat)',
    '@objc(setVisibleFraction:animated:)', 'visibilityMaskView',
]:
    if token not in swift: raise SystemExit(f'missing Swift token: {token}')
for token in [
    'AwemeLiquidBar 1.0.50c', 'LiquidBar 设置 · 1.0.50c',
    'AWEInvokeCompatibleTabTapGesture', 'TAB_COMPAT_GESTURE',
    'AWEInvokeControllerTabRoute', 'TAB_CONTROLLER_ROUTE',
    'AWEExternalBridgePluginImageLoaded', 'saveCurrentVideo',
    'copyCompleteText', 'BRIDGE_ACTION',
    'AwemeLiquidBarSettingsGestureMineOnlyV1',
    '双指长按仅在‘我’页面触发', 'AWECurrentPageAllowsSettingsGesture',
    '显示消息未读角标', 'AWEUpdateAlbumMorphMessageBadge',
    '%hook AWENormalModeTabBarBadgeContainerView',
    'AWEInstallGlassPressFeedback', 'AWEGlassPressFeedbackTarget',
    'AWEAlbumMorphSteadyWantsVisible',
    'button.showsMenuAsPrimaryAction = YES;',
    'RIGHT_REBIND_PASS',
    'AWEFrameForTopLiquidGroup', 'sideReserve = (menuVisible || searchVisible) ? 82.0 : 14.0',
]:
    if token not in objc: raise SystemExit(f'missing Objective-C token: {token}')

if objc.count('%hook') != objc.count('%end'):
    raise SystemExit('Logos hook/end count mismatch')
for left, right, name in [('{','}','brace'),('(',')','parenthesis'),('[',']','bracket')]:
    if objc.count(left) != objc.count(right):
        raise SystemExit(f'Objective-C {name} count mismatch')
for forbidden in [
    'newbar.home.selected', 'newbar.messages.selected', 'newbar.profile.selected',
    'bottom.home.selected', 'bottom.messages.selected', 'bottom.profile.selected',
    '上滑收缩底栏（动态高度）',
]:
    if forbidden in objc or forbidden in swift:
        raise SystemExit(f'forbidden regression remains: {forbidden}')

# auth table must remain 29.
if 'kAWEAuthorizationDigests[29]' not in objc:
    raise SystemExit('auth29 digest table declaration missing')
# Count encrypted digest initializer rows only inside the table.
start = objc.index('kAWEAuthorizationDigests[29]')
end = objc.index('};', start)
rows = [line for line in objc[start:end].splitlines() if line.strip().startswith('{') and 'kAWEAuthorizationDigests' not in line]
if len(rows) != 29:
    raise SystemExit(f'auth digest row count is {len(rows)}, expected 29')


# Reject the invalid UIKit convenience selector that caused the 1.0.50b Xcode compile failure.
tweak = objc
if 'menuWithTitle:@"" options:UIMenuOptionsDisplayInline' in tweak:
    raise SystemExit('invalid UIMenu selector menuWithTitle:options:children: is still present')
if 'menuWithTitle:@""\n                                         image:nil\n                                    identifier:nil\n                                       options:UIMenuOptionsDisplayInline' not in tweak:
    raise SystemExit('expected full UIMenu menuWithTitle:image:identifier:options:children: call missing')

print('AwemeLiquidBar 1.0.50c bridge/routes/gesture/badge/center preflight passed')
PY2
