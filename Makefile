INSTALL_TARGET_PROCESSES = SpringBoard
PACKAGE_VERSION=$(THEOS_PACKAGE_BASE_VERSION)
ARCHS = arm64 arm64e
TARGET = iphone:clang:11.2:11.0
SYSROOT = $(THEOS)/sdks/iPhoneOS11.2.sdk
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HomePlus


dtoim = $(foreach d,$(1),-I$(d))


_IMPORTS =  $(shell /bin/ls -d ./HomePlusEditor/*/)
_IMPORTS += $(shell /bin/ls -d ./)
IMPORTS = -I$./HomePlusEditor $(call dtoim, $(_IMPORTS))

SOURCES = $(shell find HomePlusEditor -name '*.m')
HomePlus_FILES = HomePlus.xm ${SOURCES}
HomePlus_CFLAGS += -fobjc-arc -w $(IMPORTS)

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += homeplusprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
