#!/bin/sh
set -e

EXPECTED_PACKAGE='com.xyy.awemeliquidbar'
EXPECTED_VERSION='1.0.43c'

rm -rf .theos packages
grep -q "^Package: ${EXPECTED_PACKAGE}$" control
grep -q "^Version: ${EXPECTED_VERSION}$" control
grep -q 'LiquidBar 设置 · 1.0.43c' Tweak.x
grep -q 'AwemeLiquidBar_1.0.43c_interaction.log' Tweak.x
grep -q 'AWEAlbumMorphTabController' AwemeAlbumMorphBar.swift
grep -q 'currentFallbackCompactTravel' AwemeAlbumMorphBar.swift
grep -q 'setCompactMode(_ compact: Bool, animated: Bool)' AwemeAlbumMorphBar.swift
grep -q 'AWEReadLocalBackdropLuminance' Tweak.x
grep -q 'AWERefreshOneAdaptiveButtonContrast' Tweak.x
grep -q 'AWEDynamicTopQuickMenuDefinitions' Tweak.x
grep -q '%hook AWEFeedMultiTabSelectedContainerView' Tweak.x
grep -q 'AWERefreshProfileAvatarGlass' Tweak.x
grep -q 'AWEAlbumMorphCollapseGestureDelegate' Tweak.x
grep -q 'MIN(22.0, height \* 0.5)' Tweak.x
grep -q 'button.showsMenuAsPrimaryAction = YES;' Tweak.x
! grep -q 'UIDeferredMenuElement' Tweak.x
! grep -q 'preferredElementSize = UIMenuElementSizeLarge' Tweak.x

make clean
make package -j1

DEB="$(ls -t packages/*.deb 2>/dev/null | head -n 1)"
[ -n "$DEB" ]
ACTUAL_PACKAGE="$(dpkg-deb -f "$DEB" Package)"
ACTUAL_VERSION="$(dpkg-deb -f "$DEB" Version)"
[ "$ACTUAL_PACKAGE" = "$EXPECTED_PACKAGE" ]
[ "$ACTUAL_VERSION" = "$EXPECTED_VERSION" ]

echo 'AwemeLiquidBar 1.0.43c BUILD COMPLETE'
echo "Package: $ACTUAL_PACKAGE"
echo "Version: $ACTUAL_VERSION"
echo "DEB: $DEB"
