INSTALL_TARGET_PROCESSES = SpringBoard
PACKAGE_VERSION=$(THEOS_PACKAGE_BASE_VERSION)
ARCHS = arm64 arm64e
TARGET = iphone:clang:11.2:11.0
SYSROOT = $(THEOS)/sdks/iPhoneOS11.2.sdk
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HomePlus

HomePlus_FILES = HomePlus.xm HPEditorViewController.m HPEditorWindow.m HPSettingsTableViewController.m HPUtilities.m EditorManager.m OBSlider.m

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += homeplusprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
