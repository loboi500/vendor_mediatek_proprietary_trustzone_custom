# TEE_RELEASE_TRUSTLET_PATH was defined vendor/mediatek/proprietary/trustzone/custom/build/tee_config.mk in the past
TRUSTZONE_CUSTOM_BUILD_PATH := $(MTK_PATH_SOURCE)/trustzone/custom/build
ifeq ($(strip $(TRUSTONIC_TEE_SUPPORT)),yes)
ifneq ($(wildcard $(TRUSTZONE_CUSTOM_BUILD_PATH)/tee_config.mk),)
ifeq ($(strip $(shell grep TEE_RELEASE_TRUSTLET_PATH $(TRUSTZONE_CUSTOM_BUILD_PATH)/tee_config.mk)),)

LOCAL_PATH := $(call my-dir)
TRUSTZONE_ROOT_DIR := $(PWD)
TRUSTZONE_OUTPUT_PATH := $(PRODUCT_OUT)/trustzone

include $(TRUSTZONE_CUSTOM_BUILD_PATH)/common_config.mk

TEE_BUILD_MODE ?= Debug Release
ifeq ($(TARGET_BUILD_VARIANT),eng)
  TEE_INSTALL_MODE ?= Debug
else
  TEE_INSTALL_MODE ?= Release
endif
TEE_TOOLCHAIN ?= GNU


TEE_RELEASE_TRUSTLET_PATH := $(LOCAL_PATH)
TEE_CRYPTO_TRUSTLET_PATH := $(MTK_PATH_SOURCE)/trustzone/trustonic/crypto/trustlets
TEE_PRIVATE_TRUSTLET_PATH := $(MTK_PATH_SOURCE)/trustzone/trustonic/private/trustlets
TEE_INTERNAL_TRUSTLET_PATH := $(MTK_PATH_SOURCE)/trustzone/trustonic/internal/trustlets
TEE_PROTECT_TRUSTLET_PATH := $(MTK_PATH_SOURCE)/trustzone/trustonic/secure/trustlets
TEE_SOURCE_TRUSTLET_PATH := $(MTK_PATH_SOURCE)/trustzone/trustonic/source/trustlets

TEE_INTERNAL_BSP_PATH := $(MTK_PATH_SOURCE)/trustzone/trustonic/internal/bsp


TEE_ALL_MODULE_MAKEFILE :=
ifneq ($(wildcard $(TEE_INTERNAL_BSP_PATH)),)
define mtk_tee_find_module_makefile
$(firstword \
  $(wildcard \
    $(TEE_INTERNAL_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/Locals/Code/makefile.mk \
    $(TEE_INTERNAL_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/makefile.mk \
    $(TEE_PROTECT_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/Locals/Code/makefile.mk \
    $(TEE_SOURCE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/Locals/Code/makefile.mk \
    $(TEE_SOURCE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/makefile.mk \
    $(TEE_RELEASE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/makefile.mk \
  )\
)
endef
define mtk_tee_find_module_makefile_source
$(firstword \
  $(wildcard \
    $(TEE_SOURCE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/Locals/Code/makefile.mk \
    $(TEE_SOURCE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/makefile.mk \
    $(TEE_RELEASE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/makefile.mk \
  )\
)
endef
else
define mtk_tee_find_module_makefile
$(firstword \
  $(wildcard \
    $(TEE_RELEASE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/makefile.mk \
  )\
)
endef
define mtk_tee_find_module_makefile_source
$(firstword \
  $(wildcard \
    $(TEE_RELEASE_TRUSTLET_PATH)/$(strip $(1))/$(if $(filter platform,$(2)),platform/$(ARCH_MTK_PLATFORM),$(strip $(2)))/$(strip $(3))/makefile.mk \
  )\
)
endef
endif
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
ifdef TARGET_BOARD_PLATFORM
include $(MTK_PATH_SOURCE)/trustzone/trustonic/source/build/platform/$(TARGET_BOARD_PLATFORM)/tee_config.mk
else
include $(MTK_PATH_SOURCE)/trustzone/trustonic/source/build/platform/$(ARCH_MTK_PLATFORM)/tee_config.mk
endif
TEE_ALL_MODULE_MAKEFILE := $(filter $(TEE_RELEASE_TRUSTLET_PATH)/%,$(TEE_ALL_MODULE_MAKEFILE))


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

# SDK path
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
TEE_SRC_MODULES := $(TEE_ALL_MODULES)
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
$(foreach m,$(sort $(TEE_ALL_MODULES) $(TEE_SRC_MODULES)),\
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


$(PRODUCT_OUT)/recovery.img: $(TEE_modules_to_install)
trustzone: $(TEE_modules_to_install) $(TEE_modules_to_check)
ALL_DEFAULT_INSTALLED_MODULES += $(TEE_modules_to_install) $(TEE_modules_to_check)

endif
endif
endif
