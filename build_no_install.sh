#!/bin/sh
set -e

EXPECTED_PACKAGE='com.xyy.awemeliquidbar'
EXPECTED_VERSION='1.0.39'

rm -rf .theos packages
grep -q "^Package: ${EXPECTED_PACKAGE}$" control
grep -q "^Version: ${EXPECTED_VERSION}$" control
grep -q 'LiquidBar 设置 · 1.0.39' Tweak.x
grep -q 'AwemeLiquidBar_1.0.39_interaction.log' Tweak.x
grep -q 'AWEAlbumMorphTabController' AwemeAlbumMorphBar.swift
grep -q 'tabBarMinimizeBehavior = .never' AwemeAlbumMorphBar.swift
grep -q 'buttonStyle(.glass(.clear))' AwemeAlbumMorphBar.swift
grep -q 'buttonStyle(.glass)' AwemeAlbumMorphBar.swift
grep -q 'let tintedGlass: Bool' AwemeAlbumMorphBar.swift
grep -q 'private var resolvedIconSize: CGSize' AwemeAlbumMorphBar.swift
! grep -q 'presentHomeModeMorph' AwemeAlbumMorphBar.swift
grep -q '@"调整底栏按钮布局"' Tweak.x
grep -q 'PNG is a separate original-colour path.' Tweak.x
grep -q 'let scale = min(1.0, downscale)' AwemeAlbumMorphBar.swift
grep -q 'AWEBottomBarSearchIsVisible' Tweak.x
grep -q 'AWESuppressTopSearchForBottomSearch' Tweak.x
grep -q 'All SF Symbols remain templates.' Tweak.x
grep -q '顶部与右侧按钮色调模式' Tweak.x
grep -q 'tintedGlass:AWEHomeTintedGlassEnabled()' Tweak.x
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

echo 'AwemeLiquidBar 1.0.39 BUILD COMPLETE'
echo "Package: $ACTUAL_PACKAGE"
echo "Version: $ACTUAL_VERSION"
echo "DEB: $DEB"
