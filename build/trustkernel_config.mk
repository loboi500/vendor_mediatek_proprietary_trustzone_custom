#include $(TRUSTZONE_CUSTOM_BUILD_PATH)/common_config.mk
LOCAL_PATH := $(call my-dir)
my_secure_os := tkcored
my_secure_os_variant :=

ATF_COMP_IMAGE_NAME :=
my_secure_os_protect_cfg := $(TRUSTZONE_IMG_PROTECT_CFG)
my_dram_size := $(TEE_TOTAL_DRAM_SIZE)
ifneq ($(filter full vnd vext,$(MTK_SPLIT_BUILD_LAYERS)),)
ifdef MTK_ATF_VERSION
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/build_atf_image.mk
endif

include $(CLEAR_VARS)
LOCAL_MODULE := trustkernel_$(my_secure_os).img
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_OWNER := mtk
LOCAL_PROPRIETARY_MODULE := true
LOCAL_UNINSTALLABLE_MODULE := true
LOCAL_MULTILIB := 32
intermediates := $(call local-intermediates-dir)
my_trustkernel_intermediates := $(intermediates)/TRUSTKERNEL
TRUSTKERNEL_COMP_IMAGE_NAME := $(my_trustkernel_intermediates)/bin/$(ARCH_MTK_PLATFORM)_trustkernel.img
LOCAL_PREBUILT_MODULE_FILE := $(TRUSTKERNEL_COMP_IMAGE_NAME)
include $(BUILD_PREBUILT)
endif # layers

##
# global setting
##
#TEE_BUILD_MODE ?= Debug Release
ifeq ($(TARGET_BUILD_VARIANT),eng)
  TRUSTKERNEL_INSTALL_MODE ?= Debug
else
  TRUSTKERNEL_INSTALL_MODE ?= Release
endif

ifeq ($(TRUSTKERNEL_INSTALL_MODE),Debug)
  TRUSTKERNEL_INSTALL_MODE_LC := debug
else
  TRUSTKERNEL_INSTALL_MODE_LC := release
endif

### module makefile
TRUSTKERNEL_PACKAGE_PATH := vendor/mediatek/proprietary/trustzone/trustkernel/source
TRUSTKERNEL_CLEAR_VARS := $(TRUSTZONE_CUSTOM_BUILD_PATH)/trustkernel_clear_vars.mk
TRUSTKERNEL_BASE_RULES := $(TRUSTZONE_CUSTOM_BUILD_PATH)/trustkernel_base_rules.mk

TRUSTKERNEL_ALL_MODULE_MAKEFILE :=
TRUSTKERNEL_ALL_MODULES :=
TRUSTKERNEL_modules_to_install :=
TRUSTKERNEL_modules_to_check :=

TRUSTKERNEL_ALL_MODULE_MAKEFILE := $(call first-makefiles-under, $(TRUSTKERNEL_PACKAGE_PATH))

#$(foreach mk,$(TRUSTKERNEL_MAKEFILE_DIR),$(info AA including $(mk) ...)$(eval include $(mk)))


$(info HHHHHHHHHHHHHH $(TRUSTKERNEL_ALL_MODULE_MAKEFILE))

TEE_DUMP_MAKEFILE_ONLY := true
$(foreach p,$(sort $(TRUSTKERNEL_ALL_MODULE_MAKEFILE)),\
        $(eval include $(TRUSTKERNEL_CLEAR_VARS))\
        $(eval LOCAL_MAKEFILE := $(p))\
        $(info including $(LOCAL_MAKEFILE) ...)\
)
TEE_DUMP_MAKEFILE_ONLY :=


$(foreach m,$(sort $(TRUSTKERNEL_ALL_MODULES)),\
        $(foreach r,$(filter-out $(TRUSTKERNEL_ALL_MODULES),$(TRUSTKERNEL_ALL_MODULES.$(m).REQUIRED)),\
                $(info Ignore $(m).REQUIRED = $(r))\
        )\
        $(eval l := $(foreach r,$(filter $(TRUSTKERNEL_ALL_MODULES),$(TRUSTKERNEL_ALL_MODULES.$(m).REQUIRED)),$(abspath $(TRUSTKERNEL_ALL_MODULES.$(r).OUTPUT_ROOT))))\
        $(if $(strip $(l)),\
                $(eval $(TRUSTKERNEL_ALL_MODULES.$(m).BUILT): PRIVATE_MAKE_OPTION += EXTERNAL_LIB_DIR="$(l)")\
        )\
        $(foreach r,$(filter $(TRUSTKERNEL_ALL_MODULES),$(TRUSTKERNEL_ALL_MODULES.$(m).REQUIRED)),\
                $(eval $(TRUSTKERNEL_ALL_MODULES.$(m).BUILT): $(TRUSTKERNEL_ALL_MODULES.$(r).BUILT))\
        )\
)


### TRUSTKERNEL SETTING ###

TRUSTKERNEL_ADDITIONAL_DEPENDENCIES := $(abspath $(TRUSTZONE_PROJECT_MAKEFILE) $(TRUSTZONE_CUSTOM_BUILD_PATH)/common_config.mk $(TRUSTZONE_CUSTOM_BUILD_PATH)/trustkernel_config.mk)

TRUSTKERNEL_ORI_IMAGE_NAME := $(TRUSTKERNEL_PACKAGE_PATH)/bsp/platform/$(ARCH_MTK_PLATFORM)/tee/tee.bin
TRUSTKERNEL_RAW_IMAGE_NAME := $(my_trustkernel_intermediates)/bin/$(ARCH_MTK_PLATFORM)_trustkernel_$(TRUSTKERNEL_INSTALL_MODE_LC)_raw.img
TRUSTKERNEL_TEMP_IMM_IMAGE_NAME := $(my_trustkernel_intermediates)/bin/$(ARCH_MTK_PLATFORM)_$(MTK_TARGET_PROJECT)_trustkernel_$(TRUSTKERNEL_INSTALL_MODE_LC).injected.bin
TRUSTKERNEL_TEMP_PADDING_FILE := $(my_trustkernel_intermediates)/bin/$(ARCH_MTK_PLATFORM)_trustkernel_$(TRUSTKERNEL_INSTALL_MODE_LC)_pad.txt
TRUSTKERNEL_TEMP_CFG_FILE := $(my_trustkernel_intermediates)/bin/img_hdr_trustkernel.cfg
TRUSTKERNEL_SIGNED_IMAGE_NAME := $(my_trustkernel_intermediates)/bin/$(ARCH_MTK_PLATFORM)_trustkernel_$(TRUSTKERNEL_INSTALL_MODE_LC)_signed.img
TRUSTKERNEL_PADDING_IMAGE_NAME := $(my_trustkernel_intermediates)/bin/$(ARCH_MTK_PLATFORM)_trustkernel_$(TRUSTKERNEL_INSTALL_MODE_LC)_pad.img
TRUSTKERNEL_COMP_IMAGE_NAME := $(my_trustkernel_intermediates)/bin/$(ARCH_MTK_PLATFORM)_trustkernel.img

ifneq ($(filter full vnd vext,$(MTK_SPLIT_BUILD_LAYERS)),)
$(TRUSTKERNEL_RAW_IMAGE_NAME): $(TRUSTKERNEL_ORI_IMAGE_NAME)
	@echo Trustkernel build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) cp -f $< $@

$(TRUSTKERNEL_TEMP_PADDING_FILE): ALIGNMENT=512
$(TRUSTKERNEL_TEMP_PADDING_FILE): MKIMAGE_HDR_SIZE=512
$(TRUSTKERNEL_TEMP_PADDING_FILE): RSA_SIGN_HDR_SIZE=576
$(TRUSTKERNEL_TEMP_PADDING_FILE): $(TRUSTKERNEL_RAW_IMAGE_NAME) $(TRUSTKERNEL_ADDITIONAL_DEPENDENCIES)
	@echo TRUSTKERNEL build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) rm -f $@
	$(hide) FILE_SIZE=$$(($$(wc -c < "$(TRUSTKERNEL_RAW_IMAGE_NAME)")+$(MKIMAGE_HDR_SIZE)+$(RSA_SIGN_HDR_SIZE)));\
	REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then dd if=/dev/zero of=$@ bs=$$(($(ALIGNMENT)-$${REMAINDER})) count=1; else touch $@; fi

$(TRUSTKERNEL_TEMP_CFG_FILE): $(TEE_DRAM_SIZE_CFG) $(TRUSTKERNEL_ADDITIONAL_DEPENDENCIES)
	@echo TRUSTKERNEL build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) rm -f $@
	@echo "LOAD_MODE = 0" > $@
	@echo "NAME = tee" >> $@
	@echo "LOAD_ADDR =" $(TEE_TOTAL_DRAM_SIZE) >> $@

$(TRUSTKERNEL_PADDING_IMAGE_NAME): $(TRUSTKERNEL_RAW_IMAGE_NAME) $(TRUSTKERNEL_TEMP_PADDING_FILE) $(TRUSTKERNEL_ADDITIONAL_DEPENDENCIES) $(TRUSTKERNEL_PACKAGE_PATH)/build/volume.dat
	@echo TRUSTKERNEL build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) $(TRUSTKERNEL_PACKAGE_PATH)/tools/inject_project_cert.py --cert $(TRUSTKERNEL_PACKAGE_PATH)/build/volume.dat --in $(TRUSTKERNEL_RAW_IMAGE_NAME) --out $(TRUSTKERNEL_TEMP_IMM_IMAGE_NAME)
	$(hide) cat $(TRUSTKERNEL_TEMP_IMM_IMAGE_NAME) $(TRUSTKERNEL_TEMP_PADDING_FILE) > $@

$(TRUSTKERNEL_SIGNED_IMAGE_NAME): ALIGNMENT=512
$(TRUSTKERNEL_SIGNED_IMAGE_NAME): $(TRUSTKERNEL_PADDING_IMAGE_NAME) $(TRUSTZONE_SIGN_TOOL) $(TRUSTZONE_IMG_PROTECT_CFG) $(TEE_DRAM_SIZE_CFG) $(TEE_ADDITIONAL_DEPENDENCIES)
	@echo TRUSTKERNEL build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) $(TRUSTZONE_SIGN_TOOL) $(TRUSTZONE_IMG_PROTECT_CFG) $(TRUSTKERNEL_PADDING_IMAGE_NAME) $@ $(TEE_DRAM_SIZE)
	$(hide) FILE_SIZE=$$(wc -c < "$(TRUSTKERNEL_SIGNED_IMAGE_NAME)");REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then echo "[ERROR] File $@ size $${FILE_SIZE} is not $(ALIGNMENT) bytes aligned";exit 1; fi

$(TRUSTKERNEL_COMP_IMAGE_NAME): ALIGNMENT=512
$(TRUSTKERNEL_COMP_IMAGE_NAME): $(TRUSTKERNEL_SIGNED_IMAGE_NAME) $(MTK_MKIMAGE_TOOL) $(TRUSTKERNEL_TEMP_CFG_FILE) $(TRUSTKERNEL_ADDITIONAL_DEPENDENCIES)
	@echo TRUSTKERNEL build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) $(MTK_MKIMAGE_TOOL) $(TRUSTKERNEL_SIGNED_IMAGE_NAME) $(TRUSTKERNEL_TEMP_CFG_FILE) > $@
	$(hide) FILE_SIZE=$$(stat -c%s "$(TRUSTKERNEL_COMP_IMAGE_NAME)");REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then echo "[ERROR] File $@ size $${FILE_SIZE} is not $(ALIGNMENT) bytes aligned";exit 1; fi

include $(TRUSTZONE_CUSTOM_BUILD_PATH)/build_tee_image.mk
$(BUILT_TRUSTZONE_TARGET_$(my_secure_os)): $(ATF_COMP_IMAGE_NAME) $(TRUSTKERNEL_COMP_IMAGE_NAME)
endif # layers
