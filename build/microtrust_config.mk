LOCAL_PATH := $(call my-dir)
$(info including $(LOCAL_MODULE_MAKEFILE) ...)

my_secure_os := teeid
my_secure_os_variant :=

ATF_COMP_IMAGE_NAME :=
my_secure_os_protect_cfg := $(TRUSTZONE_IMG_PROTECT_CFG)
my_dram_size := $(TEE_TOTAL_DRAM_SIZE)
ifneq ($(filter full vnd vext,$(MTK_SPLIT_BUILD_LAYERS)),)
ifneq (,$(MTK_TFA_VERSION))
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/build_atf_image.mk
else
ifeq ($(strip $(MTK_ATF_SUPPORT)), yes)
ifdef MTK_ATF_VERSION
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/build_atf_image.mk
endif
endif
endif

include $(CLEAR_VARS)
LOCAL_MODULE := microtrust_$(my_secure_os).img
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_OWNER := mtk
LOCAL_PROPRIETARY_MODULE := true
LOCAL_UNINSTALLABLE_MODULE := true
ifeq ($(MICROTRUST_TEE_VERSION),450)
  LOCAL_MULTILIB := 64
else
  LOCAL_MULTILIB := 32
endif
intermediates := $(call local-intermediates-dir)
my_microtrust_intermediates := $(intermediates)/MICROTRUST
MICROTRUST_COMP_IMAGE_NAME := $(my_microtrust_intermediates)/bin/$(ARCH_MTK_PLATFORM)_microtrust.img
LOCAL_PREBUILT_MODULE_FILE := $(MICROTRUST_COMP_IMAGE_NAME)
include $(BUILD_PREBUILT)
endif # layers

ifeq ($(TARGET_BUILD_VARIANT),eng)
  MICROTRUST_INSTALL_MODE ?= Debug
else
  MICROTRUST_INSTALL_MODE ?= Release
endif
ifeq ($(MICROTRUST_INSTALL_MODE),Debug)
  MICROTRUST_INSTALL_MODE_LC := debug
else
  MICROTRUST_INSTALL_MODE_LC := release
endif

MICROTRUST_UT_SDK_HOME := vendor/mediatek/proprietary/trustzone/microtrust/ut_sdk/$(MICROTRUST_TEE_VERSION)

UT_SDK_HOME := $(abspath $(MICROTRUST_UT_SDK_HOME))
UT_SDK_DIR := $(MICROTRUST_UT_SDK_HOME)
MICROTRUST_GLOBAL_MAKE_OPTION :=

ifneq ($(wildcard $(UT_SDK_HOME)),)

ifeq ($(strip $(MICROTRUST_TEE_SUPPORT)), yes)

MICROTRUST_GLOBAL_MAKE_OPTION += UT_SDK_HOME=$(UT_SDK_HOME)
MICROTRUST_GLOBAL_MAKE_OPTION += ARCH_MTK_PLATFORM=$(ARCH_MTK_PLATFORM)
#MICROTRUST_PRIVATE_TRUSTLET_PATH := $(MTK_PATH_SOURCE)/trustzone/trustonic/private/trustlets
MICROTRUST_PROTECT_TRUSTLET_PATH := $(MTK_PATH_SOURCE)/trustzone/microtrust/secure/trustlets
MICROTRUST_SOURCE_TRUSTLET_PATH := $(MTK_PATH_SOURCE)/trustzone/microtrust/source/trustlets

MICROTRUST_ALL_MODULE_MAKEFILE :=
# $(1): path
# $(2): common or platform
# $(3): sub-path
define mtk_microtrust_find_module_makefile
$(firstword \
  $(wildcard \
    $(MICROTRUST_PRIVATE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/Makefile \
    $(MICROTRUST_PROTECT_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/Makefile \
    $(MICROTRUST_SOURCE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/Makefile \
  )\
)
endef
define mtk_microtrust_find_module_makefile_if
$(if $(filter yes,$(4) $(RELEASE_BRM)),$(call mtk_microtrust_find_module_makefile,$(1),$(2),$(3)))
endef

ifneq ($(filter full vnd vext,$(MTK_SPLIT_BUILD_LAYERS)),)
ifdef TARGET_BOARD_PLATFORM
include $(MTK_PATH_SOURCE)/trustzone/microtrust/source/build/platform/$(TARGET_BOARD_PLATFORM)/microtrust_config.mk
else
include $(MTK_PATH_SOURCE)/trustzone/microtrust/source/build/platform/$(ARCH_MTK_PLATFORM)/microtrust_config.mk
endif
endif

MICROTRUST_OUTPUT_PATH := $(my_microtrust_intermediates)
MICROTRUST_INSTALL_PATH := $(TARGET_OUT_VENDOR)/thh/ta
ifdef TARGET_2ND_ARCH
ifeq ($(MICROTRUST_TEE_VERSION),450)
  MICROTRUST_HAL_OUTPUT_PATH := $(TARGET_OUT_INTERMEDIATES)/STATIC_LIBRARIES
else
  MICROTRUST_HAL_OUTPUT_PATH := $($(TARGET_2ND_ARCH_VAR_PREFIX)TARGET_OUT_INTERMEDIATES)/STATIC_LIBRARIES
endif
else
MICROTRUST_HAL_OUTPUT_PATH := $(TARGET_OUT_INTERMEDIATES)/STATIC_LIBRARIES
endif

MICROTRUST_ANDROID_STATIC_LIBRARIES_OUT_DIR_PLACEHOLDER := ||ANDROID-STATIC-LIBRARIES-OUT-DIR-PH||
ANDROID_STATIC_LIBRARIES_OUT_DIR := $(MICROTRUST_ANDROID_STATIC_LIBRARIES_OUT_DIR_PLACEHOLDER)
MICROTRUST_ADDITIONAL_DEPENDENCIES := $(abspath $(TRUSTZONE_PROJECT_MAKEFILE) $(TRUSTZONE_CUSTOM_BUILD_PATH)/common_config.mk $(TRUSTZONE_CUSTOM_BUILD_PATH)/microtrust_config.mk)

MICROTRUST_CLEAR_VARS := $(TRUSTZONE_CUSTOM_BUILD_PATH)/microtrust_clear_vars.mk
MICROTRUST_BASE_RULES := $(TRUSTZONE_CUSTOM_BUILD_PATH)/microtrust_base_rules.mk
MICROTRUST_LIB_MODULES := $(MICROTRUST_ALL_MODULES)
MICROTRUST_ALL_MODULES :=
MICROTRUST_modules_to_install :=
MICROTRUST_modules_to_check :=
MICROTRUST_GLOBAL_MAKE_OPTION += --no-print-directory
ifneq ($(TRUSTZONE_ROOT_DIR),)
  MICROTRUST_GLOBAL_MAKE_OPTION += ROOTDIR=$(TRUSTZONE_ROOT_DIR)
endif
MICROTRUST_GLOBAL_MAKE_OPTION += MTK_PROJECT=$(MTK_PROJECT)


TEE_DUMP_MAKEFILE_ONLY := true
$(foreach p,$(sort $(MICROTRUST_ALL_MODULE_MAKEFILE)),\
	$(eval include $(MICROTRUST_CLEAR_VARS))\
	$(eval LOCAL_MAKEFILE := $(p))\
	$(info including $(LOCAL_MAKEFILE) ...)\
	$(eval include $(LOCAL_MAKEFILE))\
	$(eval include $(MICROTRUST_BASE_RULES))\
)
TEE_DUMP_MAKEFILE_ONLY :=


$(foreach m,$(sort $(MICROTRUST_ALL_MODULES)),\
	$(foreach r,$(filter-out $(MICROTRUST_ALL_MODULES),$(MICROTRUST_ALL_MODULES.$(m).REQUIRED)),\
		$(info Ignore $(m).REQUIRED = $(r))\
	)\
	$(eval l := $(foreach r,$(filter $(MICROTRUST_ALL_MODULES),$(MICROTRUST_ALL_MODULES.$(m).REQUIRED)),$(abspath $(MICROTRUST_ALL_MODULES.$(r).OUTPUT_ROOT))))\
	$(if $(strip $(l)),\
		$(eval $(MICROTRUST_ALL_MODULES.$(m).BUILT): PRIVATE_MAKE_OPTION += EXTERNAL_LIB_DIR="$(l)")\
	)\
	$(foreach r,$(filter $(MICROTRUST_ALL_MODULES),$(MICROTRUST_ALL_MODULES.$(m).REQUIRED)),\
		$(eval $(MICROTRUST_ALL_MODULES.$(m).BUILT): $(MICROTRUST_ALL_MODULES.$(r).BUILT))\
	)\
)

MICROTRUST_TUI_SUPPORT ?= no
$(info MICROTRUST_TUI_SUPPORT=$(MICROTRUST_TUI_SUPPORT))
ATF_GLOBAL_MAKE_OPTION += \
	MICROTRUST_TUI_SUPPORT=$(MICROTRUST_TUI_SUPPORT)

endif # ifeq ($(strip $(MICROTRUST_TEE_SUPPORT)), yes)

else

$(info MICROTRUST SDK is removed for DrvFwk)

endif # ifneq ($(wildcard $(UT_SDK_HOME)),)

#TEE_modules_to_install := $(TEE_modules_to_install) $(MICROTRUST_modules_to_install)
#TEE_modules_to_check := $(TEE_modules_to_check) $(MICROTRUST_modules_to_check)

MICROTRUST_ORI_IMAGE_NAME := $(MTK_PATH_SOURCE)/trustzone/microtrust/source/common/$(MICROTRUST_TEE_VERSION)/teei/teei.raw

ifeq ($(strip $(MICROTRUST_TEE_LITE_SUPPORT)), yes)
MICROTRUST_ORI_IMAGE_NAME := $(MTK_PATH_SOURCE)/trustzone/microtrust/source/common/lite/teei/teei.raw
else
MICROTRUST_ORI_IMAGE_NAME := $(MTK_PATH_SOURCE)/trustzone/microtrust/source/common/$(MICROTRUST_TEE_VERSION)/teei/teei.raw
endif #MICROTRUST_TEE_LITE_SUPPORT
MICROTRUST_RAW_IMAGE_NAME := $(my_microtrust_intermediates)/bin/$(ARCH_MTK_PLATFORM)_microtrust_$(MICROTRUST_INSTALL_MODE_LC)_raw.img
MICROTRUST_TEMP_PADDING_FILE := $(my_microtrust_intermediates)/bin/$(ARCH_MTK_PLATFORM)_microtrust_$(MICROTRUST_INSTALL_MODE_LC)_pad.txt
MICROTRUST_TEMP_CFG_FILE := $(my_microtrust_intermediates)/bin/img_hdr_microtrust.cfg
MICROTRUST_SIGNED_IMAGE_NAME := $(my_microtrust_intermediates)/bin/$(ARCH_MTK_PLATFORM)_microtrust_$(MICROTRUST_INSTALL_MODE_LC)_signed.img
MICROTRUST_PADDING_IMAGE_NAME := $(my_microtrust_intermediates)/bin/$(ARCH_MTK_PLATFORM)_microtrust_$(MICROTRUST_INSTALL_MODE_LC)_pad.img

ifneq ($(filter full vnd vext,$(MTK_SPLIT_BUILD_LAYERS)),)
$(MICROTRUST_RAW_IMAGE_NAME): $(MICROTRUST_ORI_IMAGE_NAME)
	@echo Microtrust build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) cp -f $< $@

$(MICROTRUST_TEMP_PADDING_FILE): ALIGNMENT := $(TRUSTZONE_ALIGNMENT)
$(MICROTRUST_TEMP_PADDING_FILE): MKIMAGE_HDR_SIZE := $(TRUSTZONE_MKIMAGE_HDR_SIZE)
$(MICROTRUST_TEMP_PADDING_FILE): RSA_SIGN_HDR_SIZE := $(TRUSTZONE_RSA_SIGN_HDR_SIZE)
$(MICROTRUST_TEMP_PADDING_FILE): $(MICROTRUST_RAW_IMAGE_NAME)
	@echo Microtrust build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) rm -f $@
	$(hide) FILE_SIZE=$$(($$(wc -c < "$<")+$(MKIMAGE_HDR_SIZE)+$(RSA_SIGN_HDR_SIZE)));\
	REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then dd if=/dev/zero of=$@ bs=$$(($(ALIGNMENT)-$${REMAINDER})) count=1; else touch $@; fi

$(MICROTRUST_TEMP_CFG_FILE): PRIVATE_MODE := 0
$(MICROTRUST_TEMP_CFG_FILE): PRIVATE_ADDR := $(my_dram_size)
$(MICROTRUST_TEMP_CFG_FILE):
	@echo Microtrust build: $@
	$(hide) mkdir -p $(dir $@)
	@echo "LOAD_MODE = $(PRIVATE_MODE)" > $@
	@echo "NAME = tee" >> $@
	@echo "LOAD_ADDR = $(PRIVATE_ADDR)" >> $@

$(MICROTRUST_PADDING_IMAGE_NAME): $(MICROTRUST_RAW_IMAGE_NAME) $(MICROTRUST_TEMP_PADDING_FILE)
	@echo Microtrust build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) cat $^ > $@

$(MICROTRUST_SIGNED_IMAGE_NAME): ALIGNMENT := $(TRUSTZONE_ALIGNMENT)
$(MICROTRUST_SIGNED_IMAGE_NAME): PRIVATE_CFG := $(my_secure_os_protect_cfg)
$(MICROTRUST_SIGNED_IMAGE_NAME): PRIVATE_SIZE := $(TEE_DRAM_SIZE)
$(MICROTRUST_SIGNED_IMAGE_NAME): $(MICROTRUST_PADDING_IMAGE_NAME) $(TRUSTZONE_SIGN_TOOL) $(my_secure_os_protect_cfg)
	@echo Microtrust build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) $(TRUSTZONE_SIGN_TOOL) $(PRIVATE_CFG) $< $@ $(PRIVATE_SIZE)
	$(hide) FILE_SIZE=$$(wc -c < "$@");REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then echo "[ERROR] File $@ size $${FILE_SIZE} is not $(ALIGNMENT) bytes aligned";exit 1; fi

$(MICROTRUST_COMP_IMAGE_NAME): ALIGNMENT := $(TRUSTZONE_ALIGNMENT)
$(MICROTRUST_COMP_IMAGE_NAME): PRIVATE_CFG := $(MICROTRUST_TEMP_CFG_FILE)
$(MICROTRUST_COMP_IMAGE_NAME): $(MICROTRUST_SIGNED_IMAGE_NAME) $(MTK_MKIMAGE_TOOL) $(MICROTRUST_TEMP_CFG_FILE)
	@echo Microtrust build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) $(MTK_MKIMAGE_TOOL) $< $(PRIVATE_CFG) > $@
	$(hide) FILE_SIZE=$$(wc -c < "$@");REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then echo "[ERROR] File $@ size $${FILE_SIZE} is not $(ALIGNMENT) bytes aligned";exit 1; fi


include $(TRUSTZONE_CUSTOM_BUILD_PATH)/build_tee_image.mk
$(BUILT_TRUSTZONE_TARGET_$(my_secure_os)): $(ATF_COMP_IMAGE_NAME) $(MICROTRUST_COMP_IMAGE_NAME)
endif # layers
