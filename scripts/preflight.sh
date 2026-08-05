#!/bin/bash
set -euo pipefail

swiftc -frontend -parse AwemeAlbumMorphBar.swift

python3 - <<'PY'
from pathlib import Path
s = Path('AwemeAlbumMorphBar.swift').read_text()
required = [
    'tabBarMinimizeBehavior = .never',
    'visibleItemIdentifiers = ItemKey.defaultVisible',
    '@objc(configureVisibleItemIdentifiers:)',
    'VISIBLE_ITEMS_APPLIED',
    'let search = UISearchTab',
    'hasUserDrivenSelection',
    'setResolvedInterfaceStyleRaw',
    'setVerticalOffset(_ offset: CGFloat)',
    'TAB_CONTROLLER_SOURCE_BIND_DISABLED',
    'albumMorphProbe(',
    'AWEPhotosExactGlassButtonHostView',
    '.glassEffect(.clear.interactive(), in: Capsule())',
    '.glassEffect(.regular.interactive(), in: Capsule())',
    'let tintedGlass: Bool',
    'lastTintedGlass',
    '.contentShape(Capsule())',
    'let designScale: CGFloat = 3.0',
    'let maximumPixelEdge: CGFloat = 100.0',
    'private var resolvedIconSize: CGSize',
    'Original-colour PNG: preserve pixel-authored size, ratio and alpha.',
]
for token in required:
    if token not in s:
        raise SystemExit(f'missing Swift stable-release token: {token}')
for forbidden in [
    'compactTabIdentifiers', 'UIGlassEffect', 'UIGlassContainerEffect',
    'presentHomeModeMorph', 'AWEHomeModeMorph', 'glassEffectUnion',
]:
    if forbidden in s:
        raise SystemExit(f'forbidden experimental implementation present: {forbidden}')
print('Swift stable clear-glass preflight passed')
PY

python3 - <<'PY'
from pathlib import Path
s = Path('Tweak.x').read_text()
required = [
    'AWEApplyAlbumMorphResolvedAppearance',
    'ALBUM_MORPH_APPEARANCE',
    'Native minimization is intentionally disabled in 1.0.40b',
    'AWEAlbumMorphProbeWrite',
    'AWEForceAlbumMorphRouteRecovery',
    'HEIGHT_SYNC_FIXED saved=',
    'HEIGHT_SLIDER_FIXED value=',
    'setVerticalOffset:',
    'AWEAlbumMorphButtonSettingsController',
    'configureVisibleItemIdentifiers:AWEAlbumMorphVisibleItemIdentifiers()',
    'kAWEAlbumMorphItemOrderDefaultsKey',
    'AWEPhotosExactGlassButtonHostView',
    'updateWithImage:image',
    'const CGFloat diameter = 46.0;',
    '- (void)setTintColor:(UIColor *)tintColor',
    'PNG is a separate original-colour path.',
    'All SF Symbols remain templates.',
    'if (!originalPNG) {',
    'AWEBottomBarSearchIsVisible',
    'AWESuppressTopSearchForBottomSearch',
    'owner.userInteractionEnabled = NO;',
    '@"调整底栏按钮布局"',
    'initWithArrangedSubviews:@[masterRow, albumButtonsButton]',
    'configuration.baseForegroundColor = buttonForeground;',
    'PNG 按源文件像素以 @3x 显示',
    'pngRow, pngHint, reloadPNG',
]
for token in required:
    if token not in s:
        raise SystemExit(f'missing Objective-C stable-release token: {token}')

for forbidden in [
    'AWECreateHomeNativeGlassConfiguration',
    'AWEConfigureNativeGlassIconButton',
    'clearGlassButtonConfiguration',
    'AWECreateHomeClearGlassEffect',
    'presentHomeModeMorph',
    'AWEHomeModeCurrentLayout',
    'AWEHomeModePerformAction',
    '性能提示：',
    '设置入口：',
    '只改变上下位置，不改变宽度',
    '开启后，分界线以上执行抖音原生点赞',
    '只调整聊天输入栏的圆角',
    '唯一底栏形式：',
    '隐藏五个底栏标题',
    '路径：Documents/AwemeLiquidBar/CustomIcons',
    '日志位于抖音自签沙盒 Documents 内',
]:
    if forbidden in s:
        raise SystemExit(f'forbidden experimental/hint content remains: {forbidden}')
if '[gAWEAlbumMorphController mirrorSourceScrollOffset:delta];' in s:
    raise SystemExit('failed proxy-offset mirroring is still present')
if s.count('%hook') != s.count('%end'):
    raise SystemExit('Logos hook/end count mismatch')
if s.count('{') != s.count('}'):
    raise SystemExit('Objective-C brace count mismatch')
for forbidden in [
    'AWENormalizedHomeCustomPNG',
    'rendered as white templates',
    'Top menu and fallback top search are always white templates.',
    'originalPNG = NO;\n    UIColor *foregroundColor = UIColor.whiteColor;',
]:
    if forbidden in s:
        raise SystemExit(f'forced-white/PNG-normalization regression present: {forbidden}')
if s.count('if (!originalPNG) {') < 2:
    raise SystemExit('independent SF/PNG colour branches are missing')
print('Objective-C stable-release preflight passed')
PY

python3 - <<'PY'
from pathlib import Path
s = Path('Tweak.x').read_text()
name = 'AWEApplyAlbumMorphOriginalSuppression'
prototype = s.find('static void AWEApplyAlbumMorphOriginalSuppression(UIView *originalBar,')
first_call = s.find('AWEApplyAlbumMorphOriginalSuppression(tabBar, NO);')
definition = s.find('static void AWEApplyAlbumMorphOriginalSuppression(UIView *originalBar,', prototype + 1)
if min(prototype, first_call, definition) < 0 or not prototype < first_call < definition:
    raise SystemExit(f'{name} declaration order is invalid')
print('Objective-C helper declaration order passed')
PY

python3 - <<'PY'
from pathlib import Path
swift = Path('AwemeAlbumMorphBar.swift').read_text()
objc = Path('Tweak.x').read_text()
if 'foregroundColor.map { Color(uiColor: $0) } ?? Color.primary' in swift:
    raise SystemExit('automatic glass icon color is still overridden by Color.primary')
for token in [
    'let designScale: CGFloat = 3.0',
    'let maximumPixelEdge: CGFloat = 100.0',
    'private var resolvedIconSize: CGSize',
    'Original-colour PNG: preserve pixel-authored size, ratio and alpha.',
    'else if let foregroundColor',
    'base.foregroundStyle(Color(uiColor: foregroundColor))',
]:
    if token not in swift:
        raise SystemExit(f'missing Swift icon-pipeline token: {token}')
if objc.count('const CGFloat diameter = 46.0;') != 2:
    raise SystemExit('top/right 46 pt diameter tokens are missing or duplicated')
for token in [
    'PNG is a separate original-colour path.',
    'All SF Symbols remain templates.',
    'AWEConfiguredIconColorMode colorMode = AWEStoredSymbolColorMode(symbolKey);',
    'foregroundColor = UIColor.systemPinkColor;',
    'foregroundColor = UIColor.systemYellowColor;',
]:
    if token not in objc:
        raise SystemExit(f'missing restored icon-pipeline token: {token}')
for forbidden in [
    'AWENormalizedHomeCustomPNG',
    'Top menu and fallback top search are always white templates.',
    'rendered as white templates',
]:
    if forbidden in objc:
        raise SystemExit(f'forced-white/PNG-normalization regression remains: {forbidden}')
bottom_flag = objc.find('BOOL bottomSearchVisible = AWEBottomBarSearchIsVisible();')
suppress_call = objc.find('AWESuppressTopSearchForBottomSearch(', bottom_flag)
restore_top = objc.find('AWEConfigureTopSlot(container, AWEHomeTopActionKindSearch,', suppress_call)
if min(bottom_flag, suppress_call, restore_top) < 0 or not bottom_flag < suppress_call < restore_top:
    raise SystemExit('top/bottom search mutual-exclusion ordering is invalid')
print('Restored icon pipeline and mutually exclusive search preflight passed')
PY

python3 - <<'EOF_PY'
from pathlib import Path
s = Path('Tweak.x').read_text()
checks = [
    ('AWEActiveMainWindow',
     'static UIWindow *AWEActiveMainWindow(void);',
     'UIWindow *window = AWEActiveMainWindow();',
     'static UIWindow *AWEActiveMainWindow(void) {'),
    ('AWEFindViewByExactRuntimeClass',
     'static UIView *AWEFindViewByExactRuntimeClass(UIView *root,',
     'UIView *top = window ? AWEFindViewByExactRuntimeClass(',
     'static UIView *AWEFindViewByExactRuntimeClass(UIView *root,\n                                              NSString *className,\n                                              NSUInteger depth) {'),
    ('AWEScheduleTopActionContainerRefresh',
     'static void AWEScheduleTopActionContainerRefresh(UIView *container);',
     'if (top) AWEScheduleTopActionContainerRefresh(top);',
     'static void AWEScheduleTopActionContainerRefresh(UIView *container) {'),
]
for name, declaration_token, call_token, definition_token in checks:
    declaration = s.find(declaration_token)
    call = s.find(call_token)
    definition = s.find(definition_token)
    if min(declaration, call, definition) < 0 or not declaration < call < definition:
        raise SystemExit(f'{name} declaration order is invalid: declaration={declaration}, call={call}, definition={definition}')
print('Search-refresh helper declaration order passed')
EOF_PY

# iOS 27 bottom-bar force-dark compatibility must remain isolated to the
# album-morph overlay hierarchy and must be declared in Settings.
grep -q 'iOS 27 底栏强制深色' Tweak.x
grep -q 'return AWEIsIOS27OrLater();' Tweak.x
grep -q 'AWEIsIOS27OrLater() && AWEHomeForceDarkGlassEnabled()' Tweak.x
grep -q 'forced' AwemeAlbumMorphBar.swift
grep -q 'UIUserInterfaceStyle.dark.rawValue' AwemeAlbumMorphBar.swift
echo 'iOS 27 bottom-bar force-dark preflight passed'


python3 - <<'PY_VISIBILITY'
from pathlib import Path
import re
s = Path('Tweak.x').read_text()
for token in [
    'static BOOL AWEAlbumMorphOriginalBarWantsVisible(UIView *originalBar)',
    'forceVisible is retained only for call-site compatibility.',
    'BOOL visible = !routeSuppresses && !gAWESettingsVisible &&\n        settledOriginalVisible;',
    'result = AWEInstallOrUpdateAlbumMorphBar(\n                        (UIView *)tabBar, NO);',
]:
    if token not in s:
        raise SystemExit(f'missing original-bar visibility mirror token: {token}')
for forbidden in [
    '(forceVisible || settledOriginalVisible)',
    'AWEInstallOrUpdateAlbumMorphBar(tabBar, forceVisible)',
    'AWEInstallOrUpdateAlbumMorphBar((UIView *)gAWELastTabBar, YES)',
]:
    if forbidden in s:
        raise SystemExit(f'force-visible regression remains: {forbidden}')
# No call may pass YES, including calls split over several lines.
for match in re.finditer(r'AWEInstallOrUpdateAlbumMorphBar\s*\((.*?)\)\s*;', s, re.S):
    if re.search(r',\s*YES\s*$', match.group(1)):
        raise SystemExit('Album Morph install call still passes YES')
print('Original-bar visibility mirroring preflight passed')
PY_VISIBILITY

python3 - <<'PY_NATIVE_MENU'
from pathlib import Path
s = Path('Tweak.x').read_text()
required = [
    '#pragma mark - Native top-left four-action Liquid Glass menu',
    '[UIAction actionWithTitle:title',
    '[UIMenu menuWithTitle:@"" children:children]',
    'button.menu = menu;',
    'button.showsMenuAsPrimaryAction = YES;',
    'menu.preferredElementSize = UIMenuElementSizeLarge;',
    '@{@"title": @"直播", @"symbol": @"play.rectangle"}',
    '@{@"title": @"商城", @"symbol": @"storefront"}',
    '@{@"title": @"关注", @"symbol": @"person.2"}',
    '@{@"title": @"推荐", @"symbol": @"sparkles"}',
]
for token in required:
    if token not in s:
        raise SystemExit(f'missing native four-action menu token: {token}')
for forbidden in [
    'UIDeferredMenuElement',
    'uncachedElementWithProvider:',
    'completion(@[])',
]:
    if forbidden in s:
        raise SystemExit(f'empty deferred-menu experiment remains: {forbidden}')
if s.count('@{@"title": @"直播"') != 1 or s.count('@{@"title": @"商城"') < 1 or s.count('@{@"title": @"关注"') != 1 or s.count('@{@"title": @"推荐"') != 1:
    raise SystemExit('native quick-menu definitions are missing or duplicated')
print('Native four-action Liquid Glass menu preflight passed')
PY_NATIVE_MENU

python3 - <<'PY_PNG_RANGE'
from pathlib import Path
swift = Path('AwemeAlbumMorphBar.swift').read_text()
objc = Path('Tweak.x').read_text()
for token in [
    'let designScale: CGFloat = 3.0',
    'let maximumPixelEdge: CGFloat = 100.0',
    'let pixelDownscale = min(',
    'let scale = min(1.0, pixelDownscale)',
    '.glassEffect(.clear.interactive(), in: Capsule())',
    '.glassEffect(.regular.interactive(), in: Capsule())',
    '.contentShape(Capsule())',
    'A 46x46 square Capsule is a true circle.',
]:
    if token not in swift:
        raise SystemExit(f'missing 46 pt capsule/PNG token: {token}')
if swift.count('.frame(width: controlSize, height: controlSize)') < 3:
    raise SystemExit('fixed square glass/icon frames are missing')
if objc.count('const CGFloat diameter = 46.0;') != 2:
    raise SystemExit('top and right glass bodies must both be 46 pt')
for token in [
    '玻璃按钮本体固定为 46×46 pt',
    'PNG 按源文件像素以 @3x 显示',
    '任一边超过 100 px 时才等比例缩小',
    '透明留白也会计入尺寸',
]:
    if token not in objc:
        raise SystemExit(f'missing 46 pt/PNG settings hint: {token}')
for forbidden in [
    '.buttonStyle(.glass)',
    '.buttonStyle(.glass(.clear))',
    '.glassEffect(.clear, in: Circle())',
    '.glassEffect(.regular, in: Circle())',
    'preserveOriginalImage ? pointSize * 2.0 : pointSize',
]:
    if forbidden in swift:
        raise SystemExit(f'old padded/non-stretchable implementation remains: {forbidden}')
print('True 46 pt square-Capsule and @3x bounded PNG preflight passed')
PY_PNG_RANGE
