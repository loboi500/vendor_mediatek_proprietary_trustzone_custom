# input:
# my_secure_os or TRUSTZONE_IMPL
# my_secure_os_protect_cfg or TRUSTZONE_IMG_PROTECT_CFG
# TARGET_BUILD_VARIANT or ATF_DEBUG_ENABLE
# MTK_ATF_VERSION
# ARCH_MTK_PLATFORM
# output:
# ATF_COMP_IMAGE_NAME

include $(CLEAR_VARS)
ifneq (,$(MTK_TFA_VERSION))
LOCAL_MODULE := tfa_$(my_secure_os).img
else
LOCAL_MODULE := atf_$(my_secure_os).img
endif
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_OWNER := mtk
LOCAL_PROPRIETARY_MODULE := true
LOCAL_UNINSTALLABLE_MODULE := true
LOCAL_MULTILIB := 32
intermediates := $(call local-intermediates-dir)
ifneq (,$(MTK_TFA_VERSION))
my_atf_intermediates := $(intermediates)/TFA
else
ifeq ($(ATF_STANDALONE_BUILD),yes)
my_atf_intermediates := $(TRUSTZONE_OUTPUT_PATH)/ATF_OBJ
else
my_atf_intermediates := $(intermediates)/ATF
endif
endif
ifneq (,$(MTK_TFA_VERSION))
ATF_COMP_IMAGE_NAME := $(my_atf_intermediates)/$(TRUSTZONE_TARGET_PROJECT)/bin/$(ATF_PLATFORM)_tfa.img
else
ATF_COMP_IMAGE_NAME := $(my_atf_intermediates)/bin/$(ATF_PLATFORM)_atf.img
endif
LOCAL_PREBUILT_MODULE_FILE := $(ATF_COMP_IMAGE_NAME)
include $(BUILD_PREBUILT)


ifndef my_secure_os
  ifdef TRUSTZONE_IMPL
    my_secure_os := $(TRUSTZONE_IMPL)
  else
    $(error my_secure_os is not defined)
  endif
endif
ifndef my_secure_os_protect_cfg
  ifdef TRUSTZONE_IMG_PROTECT_CFG
    my_secure_os_protect_cfg := $(TRUSTZONE_IMG_PROTECT_CFG)
  else
    $(error my_secure_os_protect_cfg is not defined)
  endif
endif

ifneq ($(strip $(MTK_TFA_VERSION)),)
ifeq ($(TARGET_BUILD_VARIANT), user)
  ATF_DEBUG_ENABLE := 0
  ATF_INSTALL_MODE_LC := release
else ifneq ($(findstring $(TARGET_BUILD_VARIANT), userdebug eng),)
  ATF_DEBUG_ENABLE := 1
  ATF_INSTALL_MODE_LC := debug
endif
else
ifeq ($(TARGET_BUILD_VARIANT),eng)
  ATF_DEBUG_ENABLE := 1
  ATF_INSTALL_MODE_LC := debug
  TARGET_BUILD_VARIANT_ENG := 1
else
  ATF_DEBUG_ENABLE := 1
  ATF_INSTALL_MODE_LC := debug
  TARGET_BUILD_VARIANT_ENG := 0
endif
endif #MTK_TFA_VERSION

### CUSTOMIZTION FILES ###
PART_DEFAULT_MEMADDR := 0xFFFFFFFF

ifndef MTK_ATF_VERSION
  $(error MTK_ATF_VERSION is not defined)
endif

ifndef ATF_BUILD_PATH
ifneq (,$(MTK_TFA_VERSION))
ATF_BUILD_PATH := vendor/mediatek/proprietary/trustzone/$(MTK_TFA_VERSION)
else
ATF_BUILD_PATH := vendor/mediatek/proprietary/trustzone/atf/$(MTK_ATF_VERSION)
endif
endif
ATF_ADDITIONAL_DEPENDENCIES := $(abspath $(TRUSTZONE_PROJECT_MAKEFILE) $(TRUSTZONE_CUSTOM_BUILD_PATH)/common_config.mk $(TRUSTZONE_CUSTOM_BUILD_PATH)/atf_config.mk)

ifneq (,$(MTK_TFA_VERSION))
ATF_RAW_IMAGE_NAME := $(my_atf_intermediates)/$(TRUSTZONE_TARGET_PROJECT)/$(ATF_INSTALL_MODE_LC)/bl31.bin
else
ATF_RAW_IMAGE_NAME := $(my_atf_intermediates)/$(ATF_INSTALL_MODE_LC)/bl31.bin
endif
ATF_TEMP_PADDING_FILE := $(my_atf_intermediates)/bin/$(ATF_PLATFORM)_atf_$(ATF_INSTALL_MODE_LC)_pad.txt
ATF_DRAM_TEMP_PADDING_FILE := $(my_atf_intermediates)/bin/$(ATF_PLATFORM)_atf_dram_$(ATF_INSTALL_MODE_LC)_pad.txt
ATF_TEMP_CFG_FILE := $(my_atf_intermediates)/bin/img_hdr_atf.cfg
ATF_SIGNED_IMAGE_NAME := $(my_atf_intermediates)/bin/$(ATF_PLATFORM)_atf_$(ATF_INSTALL_MODE_LC)_signed.img
ATF_PADDING_IMAGE_NAME := $(my_atf_intermediates)/bin/$(ATF_PLATFORM)_atf_$(ATF_INSTALL_MODE_LC)_pad.img
ATF_DRAM_IMAGE_NAME := $(my_atf_intermediates)/bin/dram_atf.img
ATF_DRAM_PADDING_IMAGE_NAME := $(my_atf_intermediates)/bin/dram_atf_pad.img
ATF_DRAM_MKIMAGE_NAME := $(my_atf_intermediates)/bin/mkimg_dram_atf.img
ATF_SRAM_IMAGE_NAME := $(my_atf_intermediates)/bin/sram_atf.img
ATF_SRAM_MKIMAGE_NAME := $(my_atf_intermediates)/bin/mkimg_sram_atf.img
ATF_DRAM_TEMP_CFG_FILE := $(my_atf_intermediates)/bin/dram_img_hdr_atf.cfg
ifneq (,$(MTK_TFA_VERSION))
TFA_CFG_FILE := $(my_atf_intermediates)/bin/img_hdr_tfa.cfg
endif

ifeq ($(ATF_CROSS_COMPILE),)
#ATF_CROSS_COMPILE := $(abspath $(TARGET_TOOLS_PREFIX))
endif
ATF_GLOBAL_MAKE_OPTION := $(if $(ATF_CROSS_COMPILE),CROSS_COMPILE=$(ATF_CROSS_COMPILE)) BUILD_BASE=$(abspath $(my_atf_intermediates))
ATF_GLOBAL_MAKE_OPTION += DEBUG=$(ATF_DEBUG_ENABLE) PLAT=$(ATF_PLATFORM) SECURE_OS=$(my_secure_os)
ATF_GLOBAL_MAKE_OPTION += MACH_TYPE=$(MTK_MACH_TYPE)
ATF_GLOBAL_MAKE_OPTION += ARCH_MTK_PLATFORM=$(ATF_PLATFORM)
ATF_GLOBAL_MAKE_OPTION += ATF_ADDITIONAL_DEPENDENCIES="$(ATF_ADDITIONAL_DEPENDENCIES)"
ATF_GLOBAL_MAKE_OPTION += \
  SECURE_DEINT_SUPPORT=$(SECURE_DEINT_SUPPORT) \
  MTK_STACK_PROTECTOR=$(MTK_STACK_PROTECTOR) \
  MTK_ATF_RAM_DUMP=$(MTK_ATF_RAM_DUMP) \
  MTK_ATF_LOG_BUF_SLIM=$(MTK_ATF_LOG_BUF_SLIM) \
  DEBUG_SMC_ID_LOG=$(DEBUG_SMC_ID_LOG) \
  DRAM_EXTENSION_SUPPORT=$(DRAM_EXTENSION_SUPPORT) \
  ATF_BYPASS_DRAM=$(ATF_BYPASS_DRAM) \
  MTK_UFS_SUPPORT=$(MTK_UFS_SUPPORT) \
  MTK_EMMC_SUPPORT=$(MTK_EMMC_SUPPORT) \
  MTK_FIQ_CACHE_SUPPORT=$(MTK_FIQ_CACHE_SUPPORT) \
  MTK_INDIRECT_ACCESS_SUPPORT=$(MTK_INDIRECT_ACCESS_SUPPORT) \
  MTK_ICCS_SUPPORT=$(MTK_ICCS_SUPPORT) \
  MTK_ACAO_SUPPORT=$(MTK_ACAO_SUPPORT) \
  MTK_FPGA_EARLY_PORTING=$(MTK_FPGA_EARLY_PORTING) \
  TARGET_BUILD_VARIANT_ENG=$(TARGET_BUILD_VARIANT_ENG) \
  MTK_ATF_ON_DRAM=$(MTK_ATF_ON_DRAM) \
  MCUPM_FW_USE_PARTITION=$(MCUPM_FW_USE_PARTITION) \
  MTK_ASSERTION=$(MTK_ASSERTION) \
  MTK_DRCC=$(MTK_DRCC) \
  MTK_CM_MGR=$(MTK_CM_MGR) \
  MTK_ENABLE_GENIEZONE=$(MTK_ENABLE_GENIEZONE) \
  MTK_ATF_GS_ENABLE=$(MTK_ATF_GS_ENABLE) \
  MTK_GIC_SAVE_REG_CACHE=$(MTK_GIC_SAVE_REG_CACHE) \
  MTK_SMC_ID_MGMT=$(MTK_SMC_ID_MGMT) \
  MTK_DEBUGSYS_LOCK=$(MTK_DEBUGSYS_LOCK) \
  MTK_ENABLE_MPU_HAL_SUPPORT=$(MTK_ENABLE_MPU_HAL_SUPPORT) \
  MTK_DEVMPU_SUPPORT=$(MTK_DEVMPU_SUPPORT) \
  MTK_TINYSYS_SCP_SECURE_DUMP=$(MTK_TINYSYS_SCP_SECURE_DUMP) \
  MTK_TINYSYS_SCP_VERSION=$(MTK_TINYSYS_SCP_VERSION) \
  MTK_SPM_EXTENSION_CONFIG=$(MTK_SPM_EXTENSION_CONFIG)\
  MTK_VOLTAGE_BIN_VCORE=$(MTK_VOLTAGE_BIN_VCORE) \
  MTK_PSCI_CONFIG=$(MTK_PSCI_CONFIG) \
  UBSAN_SUPPORT=$(UBSAN_SUPPORT) \
  KASAN_SUPPORT=$(KASAN_SUPPORT) \
  MTK_CAM_GENIEZONE_SUPPORT=$(MTK_CAM_GENIEZONE_SUPPORT) \
  SPI_LOCK_IN_SECURE=$(SPI_LOCK_IN_SECURE)

ifeq ($(HW_ASSISTED_COHERENCY),1)
  ATF_GLOBAL_MAKE_OPTION += HW_ASSISTED_COHERENCY=1
  ATF_GLOBAL_MAKE_OPTION += USE_COHERENT_MEM=0
endif

ifneq ($(TRUSTZONE_ROOT_DIR),)
  ATF_GLOBAL_MAKE_OPTION += ROOTDIR=$(TRUSTZONE_ROOT_DIR)
endif

ifneq ($(ATF_MEMBASE),)
  ATF_GLOBAL_MAKE_OPTION += ATF_MEMBASE=$(ATF_MEMBASE)
endif

ifeq ($(my_secure_os),teeid)
  ATF_GLOBAL_MAKE_OPTION += MICROTRUST_TEE_VERSION=$(MICROTRUST_TEE_VERSION)
endif
ifeq ($(my_secure_os),tbase)
  ATF_GLOBAL_MAKE_OPTION += TRUSTONIC_TEE_VERSION=$(TRUSTONIC_TEE_VERSION)
endif

ifneq (,$(MTK_TFA_VERSION))
ifneq ($(wildcard $(TRUSTZONE_ROOT_DIR)/prebuilts/clang/host/linux-x86/clang-r383902),)
  ATF_GLOBAL_MAKE_OPTION := CC=$(TRUSTZONE_ROOT_DIR)/prebuilts/clang/host/linux-x86/clang-r383902/bin/clang
else
  ATF_GLOBAL_MAKE_OPTION := CC=$(TRUSTZONE_ROOT_DIR)/prebuilts/clang/host/linux-x86/clang-r433403b/bin/clang
endif
ATF_GLOBAL_MAKE_OPTION += CROSS_COMPILE=$(TRUSTZONE_ROOT_DIR)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9.1/bin/aarch64-linux-android-
ATF_GLOBAL_MAKE_OPTION += LD=$(TRUSTZONE_ROOT_DIR)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9.1/bin/aarch64-linux-android-ld
ATF_GLOBAL_MAKE_OPTION += BUILD_BASE=$(abspath $(my_atf_intermediates))
ATF_GLOBAL_MAKE_OPTION += PLAT=$(TRUSTZONE_TARGET_PROJECT) DEBUG=$(ATF_DEBUG_ENABLE)
endif

ATF_MAKE_DEPENDENCIES := $(filter-out %/.git %/.gitignore %/.gitattributes,$(shell find $(ATF_BUILD_PATH) -name .git -prune -o -type f | sort))

.KATI_RESTAT: $(ATF_RAW_IMAGE_NAME)
$(ATF_RAW_IMAGE_NAME): PRIVATE_MAKE_PATH := $(ATF_BUILD_PATH)
$(ATF_RAW_IMAGE_NAME): PRIVATE_MAKE_OPTION := $(ATF_GLOBAL_MAKE_OPTION)
ifneq ($(strip $(MTK_TFA_VERSION)),)
$(ATF_RAW_IMAGE_NAME): $(ATF_MAKE_DEPENDENCIES) $(ATF_MAKE_OPTION_FILE) $(ATF_ADDITIONAL_DEPENDENCIES)
	@echo TFA build: $@
	$(hide) mkdir -p $(dir $@)
	$(PREBUILT_MAKE_PREFIX)$(MAKE) -C $(PRIVATE_MAKE_PATH) $(PRIVATE_MAKE_OPTION) V=1 bl31 NEED_BL31=yes
else
$(ATF_RAW_IMAGE_NAME): $(ATF_MAKE_DEPENDENCIES) $(ATF_MAKE_OPTION_FILE) $(ATF_ADDITIONAL_DEPENDENCIES)
	@echo ATF build: $@
	$(hide) mkdir -p $(dir $@)
	$(PREBUILT_MAKE_PREFIX)$(MAKE) -r -R -C $(PRIVATE_MAKE_PATH) $(PRIVATE_MAKE_OPTION) TRUSTZONE_PROJECT_MAKEFILE="$(TRUSTZONE_PROJECT_MAKEFILE_FULL_PATH)" all
endif

ifneq ($(strip $(MTK_TFA_VERSION)),)
$(TFA_CFG_FILE):
	@echo TFA build: $@
	mkdir -p $(dir $@)
	echo "NAME = atf" > $@
$(ATF_COMP_IMAGE_NAME): PRIVATE_MKIMG_TOOL := $(TRUSTZONE_ROOT_DIR)/vendor/mediatek/proprietary/scripts/sign-image_v2/mkimage20/mkimage
$(ATF_COMP_IMAGE_NAME): PRIVATE_TFA_CFG_FILE := $(TFA_CFG_FILE)
$(ATF_COMP_IMAGE_NAME): $(ATF_RAW_IMAGE_NAME) $(TFA_CFG_FILE)
	@echo TFA build: $@
	mkdir -p $(dir $@)
	$(PRIVATE_MKIMG_TOOL) $< $(PRIVATE_TFA_CFG_FILE) > $@

else

ifeq ($(DRAM_EXTENSION_SUPPORT), yes)
$(ATF_SRAM_IMAGE_NAME): PRIVATE_SIZE := $(ATF_SRAM_IMG_SIZE)
$(ATF_SRAM_IMAGE_NAME): $(ATF_RAW_IMAGE_NAME)
	@echo ATF split $< to $@
	$(hide) mkdir -p $(dir $@)
	dd if=$< of=$@ bs=$(PRIVATE_SIZE) count=1

else
$(ATF_SRAM_IMAGE_NAME): $(ATF_RAW_IMAGE_NAME)
	@echo ATF build: $@
	$(hide) mkdir -p $(dir $@)
	cp -f $< $@

endif

$(ATF_TEMP_PADDING_FILE): ALIGNMENT := $(TRUSTZONE_ALIGNMENT)
$(ATF_TEMP_PADDING_FILE): MKIMAGE_HDR_SIZE := $(TRUSTZONE_MKIMAGE_HDR_SIZE)
$(ATF_TEMP_PADDING_FILE): RSA_SIGN_HDR_SIZE := $(TRUSTZONE_RSA_SIGN_HDR_SIZE)
$(ATF_TEMP_PADDING_FILE): $(ATF_SRAM_IMAGE_NAME)
	@echo ATF build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) rm -f $@
	FILE_SIZE=$$(($$(wc -c < "$<")+$(MKIMAGE_HDR_SIZE)+$(RSA_SIGN_HDR_SIZE)));\
	REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then dd if=/dev/zero of=$@ bs=$$(($(ALIGNMENT)-$${REMAINDER})) count=1; else touch $@; fi

$(ATF_TEMP_CFG_FILE): PRIVATE_MODE := 0
$(ATF_TEMP_CFG_FILE): PRIVATE_ADDR := $(PART_DEFAULT_MEMADDR)
$(ATF_TEMP_CFG_FILE):
	@echo ATF build: $@
	$(hide) mkdir -p $(dir $@)
	@echo "LOAD_MODE = $(PRIVATE_MODE)" > $@
	@echo "NAME = atf" >> $@
	@echo "LOAD_ADDR = $(PRIVATE_ADDR)" >> $@

$(ATF_DRAM_TEMP_CFG_FILE): PRIVATE_MODE := -1
$(ATF_DRAM_TEMP_CFG_FILE): PRIVATE_ADDR := $(ATF_DRAM_START_ADDR)
$(ATF_DRAM_TEMP_CFG_FILE):
	@echo ATF build: $@
	$(hide) mkdir -p $(dir $@)
	@echo "LOAD_MODE = $(PRIVATE_MODE)" > $@
	@echo "NAME = atf_dram" >> $@
	@echo "LOAD_ADDR = $(PRIVATE_ADDR)" >> $@

$(ATF_PADDING_IMAGE_NAME): $(ATF_SRAM_IMAGE_NAME) $(ATF_TEMP_PADDING_FILE)
	@echo ATF build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) cat $^ > $@

$(ATF_SIGNED_IMAGE_NAME): ALIGNMENT := $(TRUSTZONE_ALIGNMENT)
$(ATF_SIGNED_IMAGE_NAME): PRIVATE_CFG := $(my_secure_os_protect_cfg)
$(ATF_SIGNED_IMAGE_NAME): PRIVATE_SIZE := $(PART_DEFAULT_MEMADDR)
$(ATF_SIGNED_IMAGE_NAME): $(ATF_PADDING_IMAGE_NAME) $(TRUSTZONE_SIGN_TOOL) $(my_secure_os_protect_cfg)
	@echo ATF build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) $(TRUSTZONE_SIGN_TOOL) $(PRIVATE_CFG) $< $@ $(PRIVATE_SIZE)
	$(hide) FILE_SIZE=$$(wc -c < "$@");REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then echo "[ERROR] File $@ size $${FILE_SIZE} is not $(ALIGNMENT) bytes aligned";exit 1; fi

$(ATF_SRAM_MKIMAGE_NAME): PRIVATE_CFG := $(ATF_TEMP_CFG_FILE)
$(ATF_SRAM_MKIMAGE_NAME): PRIVATE_MTK_MKIMAGE_TOOL := $(MTK_MKIMAGE_TOOL)
$(ATF_SRAM_MKIMAGE_NAME): $(ATF_SIGNED_IMAGE_NAME) $(MTK_MKIMAGE_TOOL) $(ATF_TEMP_CFG_FILE)
	@echo ATF build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) $(PRIVATE_MTK_MKIMAGE_TOOL) $< $(PRIVATE_CFG) > $@

ifeq ($(DRAM_EXTENSION_SUPPORT), yes)
$(ATF_DRAM_IMAGE_NAME): PRIVATE_SIZE := $(ATF_SRAM_IMG_SIZE)
$(ATF_DRAM_IMAGE_NAME): $(ATF_RAW_IMAGE_NAME)
	@echo ATF split $< to $@
	$(hide) mkdir -p $(dir $@)
	dd if=$< of=$@ skip=$(PRIVATE_SIZE) bs=1

$(ATF_DRAM_TEMP_PADDING_FILE): ALIGNMENT := $(TRUSTZONE_ALIGNMENT)
$(ATF_DRAM_TEMP_PADDING_FILE): $(ATF_DRAM_IMAGE_NAME)
	@echo ATF build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) rm -f $@
	FILE_SIZE=$$(($$(wc -c < "$<")));\
	REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then dd if=/dev/zero of=$@ bs=$$(($(ALIGNMENT)-$${REMAINDER})) count=1; else touch $@; fi

$(ATF_DRAM_PADDING_IMAGE_NAME): $(ATF_DRAM_IMAGE_NAME) $(ATF_DRAM_TEMP_PADDING_FILE)
	@echo ATF build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) cat $^ > $@

$(ATF_DRAM_MKIMAGE_NAME): PRIVATE_CFG := $(ATF_DRAM_TEMP_CFG_FILE)
$(ATF_DRAM_MKIMAGE_NAME): PRIVATE_MTK_MKIMAGE_TOOL := $(MTK_MKIMAGE_TOOL)
$(ATF_DRAM_MKIMAGE_NAME): $(ATF_DRAM_PADDING_IMAGE_NAME) $(MTK_MKIMAGE_TOOL) $(ATF_DRAM_TEMP_CFG_FILE)
	@echo ATF build: $@
	$(hide) mkdir -p $(dir $@)
	$(PRIVATE_MTK_MKIMAGE_TOOL) $< $(PRIVATE_CFG) > $@

endif

$(ATF_COMP_IMAGE_NAME): ALIGNMENT := $(TRUSTZONE_ALIGNMENT)
ifeq ($(DRAM_EXTENSION_SUPPORT), yes)
$(ATF_COMP_IMAGE_NAME): $(ATF_SRAM_MKIMAGE_NAME) $(ATF_DRAM_MKIMAGE_NAME)
else
$(ATF_COMP_IMAGE_NAME): $(ATF_SRAM_MKIMAGE_NAME)
endif
$(ATF_COMP_IMAGE_NAME):
	@echo ATF build: $@
	$(hide) mkdir -p $(dir $@)
	cat $^ > $@
	$(hide) FILE_SIZE=$$(wc -c < "$@");REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then echo "[ERROR] File $@ size $${FILE_SIZE} is not $(ALIGNMENT) bytes aligned";exit 1; fi

endif # TFA
