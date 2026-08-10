#!/bin/sh
set -e

EXPECTED_PACKAGE='com.xyy.awemeliquidbar'
EXPECTED_VERSION='1.0.52a'

rm -rf .theos packages
grep -q "^Package: ${EXPECTED_PACKAGE}$" control
grep -q "^Version: ${EXPECTED_VERSION}$" control
grep -q 'LiquidBar 设置 · 1.0.52a' Tweak.x
grep -q 'AwemeLiquidBar_1.0.52a_interaction.log' Tweak.x
grep -q 'AWEAlbumMorphTabController' AwemeAlbumMorphBar.swift
grep -q 'static BOOL AWEAlbumMorphCollapseEnabled(void)' Tweak.x
grep -q 'return NO;' Tweak.x
grep -q 'slot.userInteractionEnabled = NO;' Tweak.x
grep -q 'glassButton.userInteractionEnabled = NO;' Tweak.x
grep -q 'CGRectMake(0.0, MAX(0.0, rootHeight - 4.0), 4.0, 4.0)' Tweak.x
grep -q 'AWEApplyChatPillNearGrowingTextView' Tweak.x
grep -q 'MIN(22.0, height \* 0.5)' Tweak.x
grep -q 'button.showsMenuAsPrimaryAction = YES;' Tweak.x
grep -q '#import <Photos/Photos.h>' Tweak.x
grep -q 'AWEChooseSmartDownloadVariant' Tweak.x
grep -q 'PLAYBACK_HIGHEST' Tweak.x
grep -q 'AwemeLiquidBar.NativeDownloadMenuSlot' Tweak.x
! grep -q 'AWEExternalBridgePluginImageLoaded' Tweak.x
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

echo 'AwemeLiquidBar 1.0.52a BUILD COMPLETE'
echo "Package: $ACTUAL_PACKAGE"
echo "Version: $ACTUAL_VERSION"
echo "DEB: $DEB"
