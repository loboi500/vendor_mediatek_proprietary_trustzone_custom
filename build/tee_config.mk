LOCAL_PATH := $(call my-dir)
$(info including $(LOCAL_MODULE_MAKEFILE) ...)

my_secure_os := tbase
my_secure_os_variant :=


ATF_COMP_IMAGE_NAME :=
my_secure_os_protect_cfg := $(TRUSTZONE_IMG_PROTECT_CFG)
my_dram_size := $(TEE_TOTAL_DRAM_SIZE)
ifneq ($(filter full vnd vext,$(MTK_SPLIT_BUILD_LAYERS)),)
ifdef MTK_ATF_VERSION
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/build_atf_image.mk
else
ifneq (,$(MTK_TFA_VERSION))
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/build_atf_image.mk
endif
endif

include $(CLEAR_VARS)
LOCAL_MODULE := trustonic_$(my_secure_os).img
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_OWNER := mtk
LOCAL_PROPRIETARY_MODULE := true
LOCAL_UNINSTALLABLE_MODULE := true
LOCAL_MULTILIB := 32
intermediates := $(call local-intermediates-dir)
my_trustonic_intermediates := $(intermediates)/TRUSTONIC
TEE_COMP_IMAGE_NAME := $(my_trustonic_intermediates)/bin/$(ARCH_MTK_PLATFORM)_tee.img
LOCAL_PREBUILT_MODULE_FILE := $(TEE_COMP_IMAGE_NAME)
include $(BUILD_PREBUILT)
endif #MTK_SPLIT_BUILD_LAYERS

##
# global setting
##
TEE_BUILD_MODE ?= Debug Release
ifeq ($(TARGET_BUILD_VARIANT),eng)
  TEE_INSTALL_MODE ?= Debug
else
  TEE_INSTALL_MODE ?= Release
endif
TEE_TOOLCHAIN ?= GNU


##
# vendor/mediatek/proprietary/trustzone/build.sh
# source file path
##
TEE_CRYPTO_TRUSTLET_PATH := $(MTK_PATH_SOURCE)/trustzone/trustonic/crypto/trustlets
TEE_PRIVATE_TRUSTLET_PATH := $(MTK_PATH_SOURCE)/trustzone/trustonic/private/trustlets
TEE_INTERNAL_TRUSTLET_PATH := $(MTK_PATH_SOURCE)/trustzone/trustonic/internal/trustlets
TEE_PROTECT_TRUSTLET_PATH := $(MTK_PATH_SOURCE)/trustzone/trustonic/secure/trustlets
TEE_SOURCE_TRUSTLET_PATH := $(MTK_PATH_SOURCE)/trustzone/trustonic/source/trustlets

TEE_SOURCE_BSP_PATH := $(MTK_PATH_SOURCE)/trustzone/trustonic/source/bsp
TEE_INTERNAL_BSP_PATH := $(MTK_PATH_SOURCE)/trustzone/trustonic/internal/bsp
TEE_SOURCE_SDK_PATH := $(TEE_SOURCE_BSP_PATH)/common/$(TRUSTONIC_TEE_VERSION)/t-sdk
TEE_INTERNAL_SDK_PATH := $(TEE_INTERNAL_BSP_PATH)/common/$(TRUSTONIC_TEE_VERSION)/t-sdk
TEE_MOBICORE_TOOL_ROOT := $(TEE_SOURCE_BSP_PATH)/common/$(TRUSTONIC_TEE_VERSION)/tools
TEE_HAL_SOURCE_TRUSTLETS_PATH := $(MTK_PATH_SOURCE)/trustzone/common/hal/source/trustlets
TEE_HAL_SECURE_TRUSTLETS_PATH := $(MTK_PATH_SOURCE)/trustzone/common/hal/secure/trustlets
TEE_HAL_SECURE_LIB_PATH := $(MTK_PATH_SOURCE)/trustzone/common/hal/secure_lib


# driver/trustlet module path list
TEE_ALL_MODULE_MAKEFILE :=
ifneq ($(wildcard $(TEE_INTERNAL_BSP_PATH)),)
# $(1): path
# $(2): common or platform
# $(3): sub-path
define mtk_tee_find_module_makefile
$(firstword \
  $(wildcard \
    $(TEE_CRYPTO_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/Locals/Code/makefile.mk \
    $(TEE_PRIVATE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/Locals/Code/makefile.mk \
    $(TEE_INTERNAL_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/Locals/Code/makefile.mk \
    $(TEE_INTERNAL_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/makefile.mk \
    $(TEE_PROTECT_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/Locals/Code/makefile.mk \
    $(TEE_SOURCE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/Locals/Code/makefile.mk \
    $(TEE_SOURCE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/makefile.mk \
  )\
)
endef
define mtk_tee_find_module_makefile_source
$(firstword \
  $(wildcard \
    $(TEE_SOURCE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/Locals/Code/makefile.mk \
    $(TEE_SOURCE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/makefile.mk \
  )\
)
endef
else
define mtk_tee_find_module_makefile
endef
define mtk_tee_find_module_makefile_source
endef
endif

define mtk_tee_find_module_makefile_prebuilt
$(firstword \
  $(wildcard \
    $(TEE_INTERNAL_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/Locals/Code/makefile.mk \
    $(TEE_INTERNAL_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/makefile.mk \
    $(TEE_SOURCE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/Locals/Code/makefile.mk \
    $(TEE_SOURCE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/makefile.mk \
  )\
)
endef

define mtk_tee_find_module_makefile_if
$(if $(filter yes,$(4) $(RELEASE_BRM)),$(call mtk_tee_find_module_makefile,$(1),$(2),$(3)))
endef
TEE_GLOBAL_MAKE_OPTION :=
ifneq ($(filter mt6735 mt6753,$(ARCH_MTK_PLATFORM)), )
MTK_TEE_GP_SUPPORT := no
else
MTK_TEE_GP_SUPPORT := yes
endif
TEE_CROSS_GCC_PATH :=
TEE_CROSS_GCC32_PATH :=
TEE_CROSS_GCC64_PATH :=
ifneq ($(filter full vnd vext,$(MTK_SPLIT_BUILD_LAYERS)),)
ifdef TARGET_BOARD_PLATFORM
include $(MTK_PATH_SOURCE)/trustzone/trustonic/source/build/platform/$(TARGET_BOARD_PLATFORM)/tee_config.mk
else
include $(MTK_PATH_SOURCE)/trustzone/trustonic/source/build/platform/$(ARCH_MTK_PLATFORM)/tee_config.mk
endif
endif
##
# vendor/trustonic/platform/mtXXXX/t-base/build.sh
# TEE_MACH_TYPE for denali
##
TEE_MACH_TYPE := $(MTK_MACH_TYPE)
TEE_GLOBAL_MAKE_OPTION += MTK_INDIRECT_ACCESS_SUPPORT=$(MTK_INDIRECT_ACCESS_SUPPORT)
TEE_GLOBAL_MAKE_OPTION += MTK_GIC_VERSION=$(MTK_GIC_VERSION)
TEE_GLOBAL_MAKE_OPTION += MTK_TEE_GP_SUPPORT=$(MTK_TEE_GP_SUPPORT)
TEE_GLOBAL_MAKE_OPTION += TRUSTONIC_TEE_VERSION=$(TRUSTONIC_TEE_VERSION)
TEE_GLOBAL_MAKE_OPTION += KEYMASTER_VERSION=$(KEYMASTER_VERSION)
TEE_GLOBAL_MAKE_OPTION += KEYMASTER_RPMB=$(KEYMASTER_RPMB)
TEE_GLOBAL_MAKE_OPTION += KEYMASTER_WRAPKEY=$(KEYMASTER_WRAPKEY)
TEE_GLOBAL_MAKE_OPTION += CRYPTO_KEY_REPLACEMENT=$(CRYPTO_KEY_REPLACEMENT)
TEE_GLOBAL_MAKE_OPTION += GATEKEEPER_VERSION=$(GATEKEEPER_VERSION)
TEE_GLOBAL_MAKE_OPTION += FINGERPRINT_TEE_SPI=$(FINGERPRINT_TEE_SPI)
TEE_GLOBAL_MAKE_OPTION += TEE_MACH_TYPE=$(TEE_MACH_TYPE)
TEE_GLOBAL_MAKE_OPTION += ARCH_MTK_PLATFORM=$(ARCH_MTK_PLATFORM)

##
# Locals/Build/Build.sh
# SDK path
##
INTERNAL_TLSDK_DIR := $(TEE_INTERNAL_SDK_PATH)/TlSdk/Out
INTERNAL_DRSDK_DIR := $(TEE_INTERNAL_SDK_PATH)/DrSdk/Out
TLSDK_DIR := $(TEE_SOURCE_SDK_PATH)/TlSdk/Out
DRSDK_DIR := $(TEE_SOURCE_SDK_PATH)/DrSdk/Out
ifeq ($(TRUSTONIC_TEE_VERSION),$(filter $(TRUSTONIC_TEE_VERSION),500 510))
ifneq ($(wildcard $(TEE_INTERNAL_BSP_PATH)),)
  TLSDK_DIR := $(TEE_INTERNAL_SDK_PATH)/TlSdk/Out
  DRSDK_DIR := $(TEE_INTERNAL_SDK_PATH)/DrSdk/Out
endif
endif

TEE_GLOBAL_MAKE_OPTION += TLSDK_DIR=$(TRUSTZONE_ROOT_DIR)/$(TLSDK_DIR)
ifeq ($(TRUSTONIC_TEE_VERSION),$(filter $(TRUSTONIC_TEE_VERSION),500 510))
TEE_GLOBAL_MAKE_OPTION += INTERNAL_TLSDK_DIR=$(TRUSTZONE_ROOT_DIR)/$(TLSDK_DIR)
else
TEE_GLOBAL_MAKE_OPTION += INTERNAL_TLSDK_DIR=$(TRUSTZONE_ROOT_DIR)/$(INTERNAL_TLSDK_DIR)
endif
TEE_GLOBAL_MAKE_OPTION += DRSDK_DIR=$(TRUSTZONE_ROOT_DIR)/$(DRSDK_DIR)
ifeq ($(TRUSTONIC_TEE_VERSION),$(filter $(TRUSTONIC_TEE_VERSION),500 510))
TEE_GLOBAL_MAKE_OPTION += INTERNAL_DRSDK_DIR=$(TRUSTZONE_ROOT_DIR)/$(DRSDK_DIR)
else
TEE_GLOBAL_MAKE_OPTION += INTERNAL_DRSDK_DIR=$(TRUSTZONE_ROOT_DIR)/$(INTERNAL_DRSDK_DIR)
endif

#COMP_PATH_MobiConfig := $(MTK_PATH_SOURCE)/trustzone/trustonic/source/external/mobicore/common/$(TRUSTONIC_TEE_VERSION)/MobiConfig
COMP_PATH_MobiConfig := $(MTK_PATH_SOURCE)/trustzone/trustonic/source/bsp/common/$(TRUSTONIC_TEE_VERSION)/tools/MobiConfig
MOBICONFIG_JAR := $(MTK_PATH_SOURCE)/trustzone/trustonic/source/bsp/common/$(TRUSTONIC_TEE_VERSION)/tools/MobiConfig/Bin/MobiConfig.jar
IMAGE_BUILDER := $(MTK_PATH_SOURCE)/trustzone/trustonic/internal/bsp/common/$(TRUSTONIC_TEE_VERSION)/kernel-kit/Locals/Build/imageBuilder.py
TEE_GLOBAL_MAKE_OPTION += COMP_PATH_MobiConfig=$(TRUSTZONE_ROOT_DIR)/$(COMP_PATH_MobiConfig)


TRUSTZONE_OUTPUT_PATH := $(my_trustonic_intermediates)
TEE_DRIVER_OUTPUT_PATH_ARM_V7A_STD := $(my_trustonic_intermediates)/driver
TEE_TRUSTLET_OUTPUT_PATH_ARM_V7A_STD := $(my_trustonic_intermediates)/trustlet
TEE_DRIVER_OUTPUT_PATH_ARM_V8A_AARCH64 := $(my_trustonic_intermediates)/driver_ARM_V8A_AARCH64
TEE_TRUSTLET_OUTPUT_PATH_ARM_V8A_AARCH64 := $(my_trustonic_intermediates)/trustlet_ARM_V8A_AARCH64
TEE_TLC_OUTPUT_PATH := $(my_trustonic_intermediates)/tlc
TEE_APP_INSTALL_PATH := $(TARGET_OUT_VENDOR_APPS)/mcRegistry
TEE_ANDROID_STATIC_LIBRARIES_OUT_DIR_PLACEHOLDER := ||ANDROID-STATIC-LIBRARIES-OUT-DIR-PH||
ANDROID_STATIC_LIBRARIES_OUT_DIR := $(TEE_ANDROID_STATIC_LIBRARIES_OUT_DIR_PLACEHOLDER)
TEE_ADDITIONAL_DEPENDENCIES := $(abspath $(TRUSTZONE_PROJECT_MAKEFILE) $(TRUSTZONE_CUSTOM_BUILD_PATH)/common_config.mk $(TRUSTZONE_CUSTOM_BUILD_PATH)/tee_config.mk $(MTK_PATH_SOURCE)/trustzone/trustonic/source/build/platform/$(ARCH_MTK_PLATFORM)/tee_config.mk)


TEE_CLEAR_VARS := $(TRUSTZONE_CUSTOM_BUILD_PATH)/tee_clear_vars.mk
TEE_BASE_RULES := $(TRUSTZONE_CUSTOM_BUILD_PATH)/tee_base_rules.mk
TEE_LIB_MODULES := $(TEE_ALL_MODULES)
TEE_ALL_MODULES :=
TEE_modules_to_install :=
TEE_modules_to_check :=
ifneq ($(TRUSTZONE_ROOT_DIR),)
  TEE_GLOBAL_MAKE_OPTION += ROOTDIR=$(TRUSTZONE_ROOT_DIR)
endif
TEE_GLOBAL_MAKE_OPTION += MTK_PROJECT=$(MTK_PROJECT)
TEE_GLOBAL_MAKE_OPTION += MTK_SOTER_SUPPORT=$(MTK_SOTER_SUPPORT)


TEE_DUMP_MAKEFILE_ONLY := true
$(foreach p,$(sort $(TEE_ALL_MODULE_MAKEFILE)),\
	$(eval include $(TEE_CLEAR_VARS))\
	$(eval LOCAL_MAKEFILE := $(p))\
	$(info including $(LOCAL_MAKEFILE) ...)\
	$(eval include $(LOCAL_MAKEFILE))\
	$(foreach n,$(TEE_BUILD_MODE),\
		$(eval TEE_MODE := $(n))\
		$(eval include $(TEE_BASE_RULES))\
	)\
)
TEE_DUMP_MAKEFILE_ONLY :=


# library and include path dependency between modules
ifeq ($(strip $(MTK_TEE_GP_SUPPORT)), yes)
  TEE_HEADER_REQUIRED_MODULES := drutils.drbin
else
  TEE_HEADER_REQUIRED_MODULES := drutils.lib
endif
$(foreach m,$(sort $(TEE_ALL_MODULES)),\
	$(foreach n,$(TEE_BUILD_MODE),\
		$(foreach r,$(TEE_ALL_MODULES.$(m).$(n).REQUIRED),\
			$(eval $(TEE_ALL_MODULES.$(m).$(n).BUILT): $(TEE_ALL_MODULES.$(r).$(n).BUILT))\
		)\
		$(foreach r,$(TEE_HEADER_REQUIRED_MODULES) $(TEE_ALL_MODULES.$(m).$(n).REQUIRED),\
			$(if $(TEE_ALL_MODULES.$(r).PATH),\
				$(eval s := $(call UpperCase,$(basename $(r))))\
				$(eval $(TEE_ALL_MODULES.$(m).$(n).BUILT): PRIVATE_MAKE_OPTION += COMP_PATH_$(TEE_ALL_MODULES.$(r).OUTPUT_NAME)=$(TRUSTZONE_ROOT_DIR)/$(TEE_ALL_MODULES.$(r).PATH))\
				$(eval $(TEE_ALL_MODULES.$(m).$(n).BUILT): PRIVATE_MAKE_OPTION += $(s)_DIR=$(TRUSTZONE_ROOT_DIR)/$(TEE_ALL_MODULES.$(r).PATH))\
				$(eval $(TEE_ALL_MODULES.$(m).$(n).BUILT): PRIVATE_MAKE_OPTION += $(s)_OUT_DIR=$(if $(filter ~% /%,$(my_trustonic_intermediates)),,$(TRUSTZONE_ROOT_DIR)/)$(TEE_ALL_MODULES.$(r).EXPORT_OUTDIR))\
			)\
		)\
	)\
)
ifeq ($(TEE_INSTALL_MODE),Debug)
  TEE_INSTALL_MODE_LC := debug
  TEE_ENDORSEMENT_PUB_KEY := $(TEE_SOURCE_BSP_PATH)/platform/$(ARCH_MTK_PLATFORM)/kernel/debugEndorsementPubKey.pem
  ifeq ($(wildcard $(TEE_ENDORSEMENT_PUB_KEY)),)
    TEE_ENDORSEMENT_PUB_KEY := $(TEE_SOURCE_BSP_PATH)/common/$(TRUSTONIC_TEE_VERSION)/kernel/debugEndorsementPubKey.pem
  endif
else
  TEE_INSTALL_MODE_LC := release
  TEE_ENDORSEMENT_PUB_KEY := $(TEE_SOURCE_BSP_PATH)/platform/$(ARCH_MTK_PLATFORM)/kernel/endorsementPubKey.pem
  ifeq ($(wildcard $(TEE_ENDORSEMENT_PUB_KEY)),)
    TEE_ENDORSEMENT_PUB_KEY := $(TEE_SOURCE_BSP_PATH)/common/$(TRUSTONIC_TEE_VERSION)/kernel/endorsementPubKey.pem
  endif
endif
TEE_TRUSTLET_KEY := $(TEE_SOURCE_BSP_PATH)/platform/$(ARCH_MTK_PLATFORM)/kernel/pairVendorTltSig.pem
ifeq ($(wildcard $(TEE_TRUSTLET_KEY)),)
  TEE_TRUSTLET_KEY := $(TEE_SOURCE_BSP_PATH)/common/$(TRUSTONIC_TEE_VERSION)/kernel/pairVendorTltSig.pem
endif
TEE_ORI_IMAGE_NAME := $(TEE_SOURCE_BSP_PATH)/platform/$(ARCH_MTK_PLATFORM)/kernel/$(TEE_INSTALL_MODE)/$(ARCH_MTK_PLATFORM)_mobicore_$(TEE_INSTALL_MODE_LC).raw
ifeq ($(wildcard $(TEE_ORI_IMAGE_NAME)),)
  TEE_ORI_IMAGE_NAME := $(TEE_SOURCE_BSP_PATH)/common/$(TRUSTONIC_TEE_VERSION)/kernel/$(TEE_INSTALL_MODE)/mobicore_$(TEE_INSTALL_MODE_LC).raw
endif


TEE_RAW_IMAGE_NAME := $(my_trustonic_intermediates)/bin/$(ARCH_MTK_PLATFORM)_tee_$(TEE_INSTALL_MODE_LC)_raw.img
TEE_TEMP_PADDING_FILE := $(my_trustonic_intermediates)/bin/$(ARCH_MTK_PLATFORM)_tee_$(TEE_INSTALL_MODE_LC)_pad.txt
TEE_TEMP_CFG_FILE := $(my_trustonic_intermediates)/bin/img_hdr_tee.cfg
TEE_SIGNED_IMAGE_NAME := $(my_trustonic_intermediates)/bin/$(ARCH_MTK_PLATFORM)_tee_$(TEE_INSTALL_MODE_LC)_signed.img
TEE_PADDING_IMAGE_NAME := $(my_trustonic_intermediates)/bin/$(ARCH_MTK_PLATFORM)_tee_$(TEE_INSTALL_MODE_LC)_pad.img

ifneq ($(filter full vnd vext,$(MTK_SPLIT_BUILD_LAYERS)),)
$(TEE_RAW_IMAGE_NAME): PRIVATE_JAR := $(MOBICONFIG_JAR)
$(TEE_RAW_IMAGE_NAME): PRIVATE_KEY1 := $(TEE_TRUSTLET_KEY)
$(TEE_RAW_IMAGE_NAME): PRIVATE_KEY2 := $(TEE_ENDORSEMENT_PUB_KEY)
$(TEE_RAW_IMAGE_NAME): $(TEE_ORI_IMAGE_NAME) $(MOBICONFIG_JAR) $(TEE_TRUSTLET_KEY) $(TEE_ENDORSEMENT_PUB_KEY)
	@echo TEE build: $@
	$(hide) mkdir -p $(dir $@)
ifeq ($(TRUSTONIC_TEE_VERSION),$(filter $(TRUSTONIC_TEE_VERSION),510))
	# $(hide) $(IMAGE_BUILDER) --input $< --output $@ --cfg $(IMAGE_BUILDER)/manifest.xml
	$(hide) cp $< $@
else
	$(hide) java -jar $(PRIVATE_JAR) -c -i $< -o $@ -k $(PRIVATE_KEY1)
endif

$(TEE_TEMP_PADDING_FILE): ALIGNMENT := $(TRUSTZONE_ALIGNMENT)
$(TEE_TEMP_PADDING_FILE): MKIMAGE_HDR_SIZE := $(TRUSTZONE_MKIMAGE_HDR_SIZE)
$(TEE_TEMP_PADDING_FILE): RSA_SIGN_HDR_SIZE := $(TRUSTZONE_RSA_SIGN_HDR_SIZE)
$(TEE_TEMP_PADDING_FILE): $(TEE_RAW_IMAGE_NAME)
	@echo TEE build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) rm -f $@
	$(hide) FILE_SIZE=$$(($$(wc -c < "$<")+$(MKIMAGE_HDR_SIZE)+$(RSA_SIGN_HDR_SIZE)));\
	REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then dd if=/dev/zero of=$@ bs=$$(($(ALIGNMENT)-$${REMAINDER})) count=1; else touch $@; fi

$(TEE_TEMP_CFG_FILE): PRIVATE_MODE := 0
$(TEE_TEMP_CFG_FILE): PRIVATE_ADDR := $(my_dram_size)
$(TEE_TEMP_CFG_FILE): $(TEE_DRAM_SIZE_CFG)
	@echo TEE build: $@
	$(hide) mkdir -p $(dir $@)
	@echo "LOAD_MODE = $(PRIVATE_MODE)" > $@
	@echo "NAME = tee" >> $@
	@echo "LOAD_ADDR = $(PRIVATE_ADDR)" >> $@

$(TEE_PADDING_IMAGE_NAME): $(TEE_RAW_IMAGE_NAME) $(TEE_TEMP_PADDING_FILE)
	@echo TEE build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) cat $^ > $@

$(TEE_SIGNED_IMAGE_NAME): ALIGNMENT := $(TRUSTZONE_ALIGNMENT)
$(TEE_SIGNED_IMAGE_NAME): PRIVATE_CFG := $(my_secure_os_protect_cfg)
$(TEE_SIGNED_IMAGE_NAME): PRIVATE_SIZE := $(TEE_DRAM_SIZE)
$(TEE_SIGNED_IMAGE_NAME): $(TEE_PADDING_IMAGE_NAME) $(TRUSTZONE_SIGN_TOOL) $(my_secure_os_protect_cfg) $(TEE_DRAM_SIZE_CFG)
	@echo TEE build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) $(TRUSTZONE_SIGN_TOOL) $(PRIVATE_CFG) $< $@ $(PRIVATE_SIZE)
	$(hide) FILE_SIZE=$$(wc -c < "$@");REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then echo "[ERROR] File $@ size $${FILE_SIZE} is not $(ALIGNMENT) bytes aligned";exit 1; fi

$(TEE_COMP_IMAGE_NAME): ALIGNMENT := $(TRUSTZONE_ALIGNMENT)
$(TEE_COMP_IMAGE_NAME): PRIVATE_CFG := $(TEE_TEMP_CFG_FILE)
$(TEE_COMP_IMAGE_NAME): $(TEE_SIGNED_IMAGE_NAME) $(MTK_MKIMAGE_TOOL) $(TEE_TEMP_CFG_FILE)
	@echo TEE build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) $(MTK_MKIMAGE_TOOL) $< $(PRIVATE_CFG) > $@
	$(hide) FILE_SIZE=$$(stat -c%s "$@");REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then echo "[ERROR] File $@ size $${FILE_SIZE} is not $(ALIGNMENT) bytes aligned";exit 1; fi


include $(TRUSTZONE_CUSTOM_BUILD_PATH)/build_tee_image.mk
$(BUILT_TRUSTZONE_TARGET_$(my_secure_os)): $(ATF_COMP_IMAGE_NAME) $(TEE_COMP_IMAGE_NAME)
endif #MTK_SPLIT_BUILD_LAYERS
