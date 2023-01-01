# vendor/mediatek/proprietary/trustzone/Android.mk
LOCAL_PATH := $(call my-dir)
TRUSTZONE_CUSTOM_BUILD_PATH := $(LOCAL_PATH)

ifneq ($(strip $(MTK_TARGET_PROJECT)$(TRUSTZONE_TARGET_PROJECT)),)
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/build_trustzone.mk
endif
