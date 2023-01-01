ifndef TRUSTZONE_CUSTOM_BUILD_PATH
$(error TRUSTZONE_CUSTOM_BUILD_PATH is not defined)
endif

TRUSTZONE_ROOT_DIR := $(PWD)
TRUSTZONE_ALL_SECURE_OS :=
TRUSTZONE_modules_to_install :=
TRUSTZONE_modules_to_check :=

include $(TRUSTZONE_CUSTOM_BUILD_PATH)/project_config.mk
# FIXME
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/common_config.mk

# ATF only
ifneq (,$(MTK_TFA_VERSION))
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/atf_only_config.mk
TRUSTZONE_ALL_SECURE_OS += $(my_secure_os)
else
ifeq ($(strip $(MTK_ATF_SUPPORT)),yes)
ifdef MTK_ATF_VERSION
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/atf_only_config.mk
TRUSTZONE_ALL_SECURE_OS += $(my_secure_os)
endif
endif
endif
# Trustonic
ifdef TRUSTONIC_TEE_VERSION
ifneq ($(wildcard $(MTK_PATH_SOURCE)/trustzone/trustonic/source),)
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/tee_config.mk
TRUSTZONE_ALL_SECURE_OS += $(my_secure_os)
TRUSTZONE_modules_to_check += $(TEE_modules_to_check)
endif
endif

# Microtrust
ifdef MICROTRUST_TEE_VERSION
ifneq ($(wildcard $(MTK_PATH_SOURCE)/trustzone/microtrust/source),)
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/microtrust_config.mk
TRUSTZONE_ALL_SECURE_OS += $(my_secure_os)
TRUSTZONE_modules_to_check += $(MICROTRUST_modules_to_check)
endif
endif

# In-house
ifeq ($(MTK_IN_HOUSE_TEE_SUPPORT),yes)
ifneq ($(wildcard $(MTK_PATH_SOURCE)/trustzone/mtee/source),)
my_secure_os_variant :=
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/in_house_config.mk
TRUSTZONE_ALL_SECURE_OS += $(my_secure_os)
endif
endif

# trustkernel
ifeq ($(TRUSTKERNEL_TEE_SUPPORT),yes)
ifneq ($(wildcard $(MTK_PATH_SOURCE)/trustzone/trustkernel/source),)
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/trustkernel_config.mk
TRUSTZONE_ALL_SECURE_OS += $(my_secure_os)
TRUSTZONE_modules_to_check += $(TRUSTKERNEL_modules_to_check)
endif
endif

ifneq ($(filter full vnd vext,$(MTK_SPLIT_BUILD_LAYERS)),)
# current project
TRUSTZONE_IMPL :=
ifeq ($(MTK_IN_HOUSE_TEE_SUPPORT),yes)
  ifeq ($(MTK_IN_HOUSE_TEE_FORCE_32_SUPPORT),yes)
    TRUSTZONE_IMPL := mtee32
  else
    TRUSTZONE_IMPL := mtee
  endif
else ifeq ($(TRUSTONIC_TEE_SUPPORT),yes)
  ifdef TRUSTONIC_TEE_VERSION
    TRUSTZONE_IMPL := tbase
    TRUSTZONE_modules_to_install += $(TEE_modules_to_install)
  else
    TRUSTZONE_IMPL := no
  endif
else ifeq ($(MICROTRUST_TEE_SUPPORT),yes)
  ifdef MICROTRUST_TEE_VERSION
    TRUSTZONE_IMPL := teeid
    TRUSTZONE_modules_to_install += $(MICROTRUST_modules_to_install)
  else
    TRUSTZONE_IMPL := no
  endif
else ifeq ($(MICROTRUST_TEE_LITE_SUPPORT),yes)
  ifdef MICROTRUST_TEE_VERSION
    TRUSTZONE_IMPL := teeid
    TRUSTZONE_modules_to_install += $(MICROTRUST_modules_to_install)
  else
    TRUSTZONE_IMPL := no
  endif
else ifeq ($(MTK_GOOGLE_TRUSTY_SUPPORT),yes)
    TRUSTZONE_IMPL := trusty
else ifeq ($(TRUSTKERNEL_TEE_SUPPORT),yes)
    TRUSTZONE_IMPL := tkcored
else ifeq ($(WATCHDATA_TEE_SUPPORT),yes)
    TRUSTZONE_IMPL := watchdata
else
    TRUSTZONE_IMPL := no
endif
ifeq ($(strip $(MTK_SPLIT_BUILD_LAYERS)),hal)
    TRUSTZONE_IMPL :=
endif
ifdef TRUSTZONE_IMPL
my_secure_os := $(TRUSTZONE_IMPL)
ifeq ($(TARGET_ARCH),arm64)
my_secure_os_built := $(call module-built-files,tee_$(my_secure_os).img$(TARGET_2ND_ARCH_MODULE_SUFFIX))
else
my_secure_os_built := $(call module-built-files,tee_$(my_secure_os).img)
endif
ifneq ($(filter yes,$(MTK_ATF_SUPPORT) $(TRUSTONIC_TEE_SUPPORT) $(WATCHDATA_TEE_SUPPORT) $(MICROTRUST_TEE_SUPPORT) $(MICROTRUST_TEE_LITE_SUPPORT) $(TRUSTKERNEL_TEE_SUPPORT) $(MTK_GOOGLE_TRUSTY_SUPPORT)),)
 include $(CLEAR_VARS)
 LOCAL_MODULE := tee.img
 LOCAL_PREBUILT_MODULE_FILE := $(my_secure_os_built)
 LOCAL_MODULE_CLASS := ETC
 LOCAL_MODULE_OWNER := mtk
 LOCAL_PROPRIETARY_MODULE := true
 LOCAL_MODULE_PATH := $(PRODUCT_OUT)
 LOCAL_MULTILIB := 32
 include $(BUILD_PREBUILT)
 TRUSTZONE_modules_to_install += $(LOCAL_INSTALLED_MODULE)
 TRUSTZONE_IMAGE_NAME := $(notdir $(LOCAL_INSTALLED_MODULE))
endif
endif#TRUSTZONE_IMPL
endif # ifndef HAL_TARGET_PROJECT
# common HAL
ifneq ($(strip $(TRUSTONIC_TEE_VERSION))$(strip $(MICROTRUST_TEE_VERSION))$(strip $(MGVI_MTK_TEE_RELEASE)),)
#ifeq (yes,$(strip $(MGVI_MTK_TEE_RELEASE)))
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/hal_config.mk
endif

TEE_HAL_modules_to_check := $(call module-built-files,$(TEE_HAL_SRC_MODULES))
ifeq (vext,$(strip $(MTK_SPLIT_BUILD_LAYERS)))
TEE_HAL_modules_to_check := $(filter %.lib, $(TEE_HAL_modules_to_check))
else
ifeq (hal,$(strip $(MTK_SPLIT_BUILD_LAYERS)))
TEE_HAL_modules_to_check := $(filter-out %.lib, $(TEE_HAL_modules_to_check))
endif
endif
ALL_DEFAULT_INSTALLED_MODULES += $(TRUSTZONE_modules_to_install)
ifneq ($(filter yes,$(TRUSTONIC_TEE_SUPPORT) $(RELEASE_BRM)),)
droid vnd_images vext_images: $(TEE_modules_to_check)
endif
ifneq ($(filter yes,$(MICROTRUST_TEE_SUPPORT) $(RELEASE_BRM)),)
droid vnd_images vext_images: $(MICROTRUST_modules_to_check)
endif
ifneq ($(filter yes,$(MICROTRUST_TEE_LITE_SUPPORT) $(RELEASE_BRM)),)
droid vnd_images vext_images: $(MICROTRUST_modules_to_check)
endif
### build all HAL modules when RELEASE_BRM=yes
ifeq ($(RELEASE_BRM),yes)
droid vnd_images vext_images trustzone hal_images: $(TEE_HAL_modules_to_check)
endif

ifneq ($(filter full vnd vext hal,$(MTK_SPLIT_BUILD_LAYERS)),)
.PHONY: trustzone check-trustzone $(TRUSTZONE_IMAGE_NAME)
trustzone: $(TRUSTZONE_modules_to_install) $(TRUSTZONE_IMAGE_NAME)
$(TRUSTZONE_IMAGE_NAME):
trustzone: $(TRUSTZONE_modules_to_check)
check-trustzone: $(call module-built-files,$(foreach my_secure_os,$(TRUSTZONE_ALL_SECURE_OS),tee_$(my_secure_os).img))
check-trustzone: $(TRUSTZONE_modules_to_install) $(SIGN_TRUSTZONE_TARGET)
check-trustzone: $(TRUSTZONE_modules_to_check)
check-trustzone: $(TEE_HAL_modules_to_check)
endif
