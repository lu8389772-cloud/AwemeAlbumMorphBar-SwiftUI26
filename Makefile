ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = rootless
FINALPACKAGE = 1
DEBUG = 0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AwemeLiquidBar
AwemeLiquidBar_FILES = Tweak.x AwemeAlbumMorphBar.swift
AwemeLiquidBar_CFLAGS = -O2 -fvisibility=hidden -fobjc-arc -Wno-deprecated-declarations -Wno-unused-function -Wno-unused-variable -Wno-nullability-completeness
AwemeLiquidBar_SWIFTFLAGS = -O -swift-version 5 -parse-as-library
AwemeLiquidBar_FRAMEWORKS = UIKit QuartzCore Foundation SwiftUI
AwemeLiquidBar_LDFLAGS = -Wl,-x

include $(THEOS_MAKE_PATH)/tweak.mk
