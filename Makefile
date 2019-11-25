INSTALL_TARGET_PROCESSES = SpringBoard
PACKAGE_VERSION=$(THEOS_PACKAGE_BASE_VERSION)
ARCHS = armv7 arm64 arm64e
TARGET = iphone:clang:11.2:10.0
SYSROOT = $(THEOS)/sdks/iPhoneOS11.2.sdk
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HomePlus

dtoim = $(foreach d,$(1),-I$(d))

_IMPORTS =  $(shell /bin/ls -d ./HomePlusEditor/*/)
_IMPORTS +=  $(shell /bin/ls -d ./HomePlusEditor/*/*/)
_IMPORTS += $(shell /bin/ls -d ./)
IMPORTS = -I$./HomePlusEditor $(call dtoim, $(_IMPORTS))

SOURCES = $(shell find HomePlusEditor -name '*.m')

HomePlus_FILES = HomePlus.xm ${SOURCES}
HomePlus_CFLAGS += -fobjc-arc -w $(IMPORTS)

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += homeplusprefs
include $(THEOS_MAKE_PATH)/aggregate.mk


ifneq (,$(filter x86_64 i386,$(ARCHS)))
setup:: clean all
	@rm -f /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(PWD)/$(TWEAK_NAME).plist /opt/simject
endif