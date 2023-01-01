LOCAL_PATH := $(call my-dir)
$(info including $(LOCAL_MODULE_MAKEFILE) ...)

my_secure_os := no
my_secure_os_variant :=
my_secure_os_protect_cfg := $(firstword $(wildcard $(MTK_PRELOADER_PATH_CUSTOM)/inc/TRUSTZONE_IMG_PROTECT_CFG.ini $(TRUSTZONE_CUSTOM_BUILD_PATH)/cfg/TRUSTZONE_IMG_PROTECT_CFG.ini))
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/build_atf_image.mk


include $(TRUSTZONE_CUSTOM_BUILD_PATH)/build_tee_image.mk
$(BUILT_TRUSTZONE_TARGET_$(my_secure_os)): $(ATF_COMP_IMAGE_NAME)
