#!/bin/sh
set -e

EXPECTED_PACKAGE='com.xyy.awemeliquidbar'
EXPECTED_VERSION='1.0.40b'

rm -rf .theos packages
grep -q "^Package: ${EXPECTED_PACKAGE}$" control
grep -q "^Version: ${EXPECTED_VERSION}$" control
grep -q 'LiquidBar 设置 · 1.0.40b' Tweak.x
grep -q 'AwemeLiquidBar_1.0.40b_interaction.log' Tweak.x
grep -q 'AWEAlbumMorphTabController' AwemeAlbumMorphBar.swift
grep -q 'tabBarMinimizeBehavior = .never' AwemeAlbumMorphBar.swift
grep -q '.glassEffect(.clear.interactive(), in: Capsule())' AwemeAlbumMorphBar.swift
grep -q '.glassEffect(.regular.interactive(), in: Capsule())' AwemeAlbumMorphBar.swift
grep -q 'let tintedGlass: Bool' AwemeAlbumMorphBar.swift
grep -q 'private var resolvedIconSize: CGSize' AwemeAlbumMorphBar.swift
! grep -q 'presentHomeModeMorph' AwemeAlbumMorphBar.swift
grep -q '@"调整底栏按钮布局"' Tweak.x
grep -q 'PNG is a separate original-colour path.' Tweak.x
grep -q 'let scale = min(1.0, pixelDownscale)' AwemeAlbumMorphBar.swift
grep -q 'AWEBottomBarSearchIsVisible' Tweak.x
grep -q 'AWESuppressTopSearchForBottomSearch' Tweak.x
grep -q 'All SF Symbols remain templates.' Tweak.x
grep -q '顶部与右侧按钮色调模式' Tweak.x
grep -q 'tintedGlass:AWEHomeTintedGlassEnabled()' Tweak.x
grep -q '#pragma mark - Native top-left four-action Liquid Glass menu' Tweak.x
grep -q '@{@"title": @"直播"' Tweak.x
grep -q '@{@"title": @"商城"' Tweak.x
grep -q '@{@"title": @"关注"' Tweak.x
grep -q '@{@"title": @"推荐"' Tweak.x
grep -q 'button.showsMenuAsPrimaryAction = YES;' Tweak.x
! grep -q 'UIDeferredMenuElement' Tweak.x
grep -q 'kAWEAuthorizationDigests\[21\]' Tweak.x
grep -q 'entry < 21' Tweak.x

make clean
make package -j1

DEB="$(ls -t packages/*.deb 2>/dev/null | head -n 1)"
[ -n "$DEB" ]
ACTUAL_PACKAGE="$(dpkg-deb -f "$DEB" Package)"
ACTUAL_VERSION="$(dpkg-deb -f "$DEB" Version)"
[ "$ACTUAL_PACKAGE" = "$EXPECTED_PACKAGE" ]
[ "$ACTUAL_VERSION" = "$EXPECTED_VERSION" ]

echo 'AwemeLiquidBar 1.0.40b BUILD COMPLETE'
echo "Package: $ACTUAL_PACKAGE"
echo "Version: $ACTUAL_VERSION"
echo "DEB: $DEB"
