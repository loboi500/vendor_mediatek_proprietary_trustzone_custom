LOCAL_PATH := $(call my-dir)

my_secure_os := mtee
#ifndef my_secure_os_variant
#$(error my_secure_os_variant is not defined)
#endif

ATF_COMP_IMAGE_NAME :=
my_secure_os_protect_cfg := $(MTK_PRELOADER_PATH_CUSTOM)/inc/TRUSTZONE_IMG_PROTECT_CFG.ini
ifeq ($(wildcard $(my_secure_os_protect_cfg)),)
  my_secure_os_protect_cfg := $(MTK_PATH_SOURCE)/trustzone/mtee/protect/common/cfg/$(ARCH_MTK_PLATFORM)/TRUSTZONE_IMG_PROTECT_CFG.ini
  ifeq ($(wildcard $(my_secure_os_protect_cfg)),)
    my_secure_os_protect_cfg := $(MTK_PATH_SOURCE)/trustzone/mtee/build/test/$(ARCH_MTK_PLATFORM)/TRUSTZONE_IMG_PROTECT_CFG.ini
  endif
endif
ifdef MTK_ATF_VERSION
my_alignment := $(TRUSTZONE_ALIGNMENT)
my_mkimage_hdr_size := $(TRUSTZONE_MKIMAGE_HDR_SIZE)
my_rsa_sign_hdr_size := $(TRUSTZONE_RSA_SIGN_HDR_SIZE)
my_dram_size := $(TEE_DRAM_SIZE)
else
my_alignment := 1
my_mkimage_hdr_size := 0
my_rsa_sign_hdr_size := 0
my_dram_size := $(TEE_DRAM_SIZE)
endif
ifdef MTK_ATF_VERSION
include $(TRUSTZONE_CUSTOM_BUILD_PATH)/build_atf_image.mk
endif

include $(CLEAR_VARS)
LOCAL_MODULE := in_house_$(my_secure_os)$(if $(my_secure_os_variant),_$(my_secure_os_variant)).img
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_OWNER := mtk
LOCAL_PROPRIETARY_MODULE := true
LOCAL_UNINSTALLABLE_MODULE := true
LOCAL_MULTILIB := 32
intermediates := $(call local-intermediates-dir)
my_in_house_intermediates := $(intermediates)/IN_HOUSE
MTEE_COMP_IMAGE_NAME := $(my_in_house_intermediates)/bin/$(ARCH_MTK_PLATFORM)_$(TRUSTZONE_IMPL).img
LOCAL_PREBUILT_MODULE_FILE := $(MTEE_COMP_IMAGE_NAME)
include $(BUILD_PREBUILT)


ifeq ($(MTK_IN_HOUSE_TEE_FORCE_32_SUPPORT),yes)
  MTEE_RAW_IMAGE_NAME := $(call intermediates-dir-for,EXECUTABLES,tz.img,,,$(TARGET_2ND_ARCH_VAR_PREFIX))/tz.img
else
  MTEE_RAW_IMAGE_NAME := $(call intermediates-dir-for,EXECUTABLES,tz.img)/tz.img
endif

MTEE_SIGNED_IMAGE_NAME := $(my_in_house_intermediates)/bin/$(ARCH_MTK_PLATFORM)_$(TRUSTZONE_IMPL)_signed.img
MTEE_TEMP_PADDING_FILE := $(my_in_house_intermediates)/bin/$(ARCH_MTK_PLATFORM)_$(TRUSTZONE_IMPL)_pad.txt
MTEE_PADDING_IMAGE_NAME := $(my_in_house_intermediates)/bin/$(ARCH_MTK_PLATFORM)_$(TRUSTZONE_IMPL)_pad.img
MTEE_TEMP_CFG_FILE := $(my_in_house_intermediates)/bin/img_hdr_mtee.cfg

ifeq ($(HOST_OS),darwin)
  ifdef MTK_ATF_VERSION
MTEE_PROT_TOOL := vendor/mediatek/proprietary/trustzone/custom/build/tools/TeeImgSignEncTool.$(HOST_OS)
  else
MTEE_PROT_TOOL := vendor/mediatek/proprietary/trustzone/mtee/build/tools/MteeImgSignEncTool.$(HOST_OS)
  endif
else
MTEE_PROT_TOOL := vendor/mediatek/proprietary/trustzone/custom/build/tools/TeeImgSignEncTool
endif


ifdef MTK_ATF_VERSION
$(MTEE_TEMP_PADDING_FILE): ALIGNMENT := $(my_alignment)
$(MTEE_TEMP_PADDING_FILE): MKIMAGE_HDR_SIZE := $(my_mkimage_hdr_size)
$(MTEE_TEMP_PADDING_FILE): RSA_SIGN_HDR_SIZE := $(my_rsa_sign_hdr_size)
$(MTEE_TEMP_PADDING_FILE): $(MTEE_RAW_IMAGE_NAME)
	@echo MTEE build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) rm -f $@
	$(hide) FILE_SIZE=$$(($$(wc -c < "$<")+$(MKIMAGE_HDR_SIZE)+$(RSA_SIGN_HDR_SIZE)));\
	REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then dd if=/dev/zero of=$@ bs=$$(($(ALIGNMENT)-$${REMAINDER})) count=1; else touch $@; fi

else
$(MTEE_TEMP_PADDING_FILE):
	@echo MTEE build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) rm -f $@
	$(hide) touch $@

endif

ifdef MTK_ATF_VERSION
$(MTEE_TEMP_CFG_FILE): PRIVATE_MODE := 0
$(MTEE_TEMP_CFG_FILE): PRIVATE_ADDR := $(my_dram_size)
else
$(MTEE_TEMP_CFG_FILE): PRIVATE_MODE := -1
$(MTEE_TEMP_CFG_FILE): PRIVATE_ADDR := 0xffffffff
endif
$(MTEE_TEMP_CFG_FILE):
	@echo MTEE build: $@
	$(hide) mkdir -p $(dir $@)
	@echo "LOAD_MODE = $(PRIVATE_MODE)" > $@
	@echo "NAME = tee" >> $@
	@echo "LOAD_ADDR = $(PRIVATE_ADDR)" >> $@

$(MTEE_PADDING_IMAGE_NAME): $(MTEE_RAW_IMAGE_NAME) $(MTEE_TEMP_PADDING_FILE)
	@echo MTEE build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) cat $^ > $@

$(MTEE_SIGNED_IMAGE_NAME): ALIGNMENT := $(my_alignment)
$(MTEE_SIGNED_IMAGE_NAME): PRIVATE_CFG := $(my_secure_os_protect_cfg)
$(MTEE_SIGNED_IMAGE_NAME): PRIVATE_SIZE := $(TEE_DRAM_SIZE)
$(MTEE_SIGNED_IMAGE_NAME): $(MTEE_PADDING_IMAGE_NAME) $(my_secure_os_protect_cfg)
	@echo MTEE build: $@
	$(hide) $(MTEE_PROT_TOOL) $(PRIVATE_CFG) $< $@ $(PRIVATE_SIZE)
	$(hide) FILE_SIZE=$$(wc -c < "$@");REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then echo "[ERROR] File $@ size $${FILE_SIZE} is not $(ALIGNMENT) bytes aligned";exit 1; fi

$(MTEE_COMP_IMAGE_NAME): ALIGNMENT := $(my_alignment)
$(MTEE_COMP_IMAGE_NAME): PRIVATE_CFG := $(MTEE_TEMP_CFG_FILE)
$(MTEE_COMP_IMAGE_NAME): $(MTEE_SIGNED_IMAGE_NAME) $(MTK_MKIMAGE_TOOL) $(MTEE_TEMP_CFG_FILE)
	@echo MTEE build: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) $(MTK_MKIMAGE_TOOL) $< $(PRIVATE_CFG) > $@
	$(hide) FILE_SIZE=$$(wc -c < "$@");REMAINDER=$$(($${FILE_SIZE} % $(ALIGNMENT)));\
	if [ $${REMAINDER} -ne 0 ]; then echo "[ERROR] File $@ size $${FILE_SIZE} is not $(ALIGNMENT) bytes aligned";exit 1; fi


include $(TRUSTZONE_CUSTOM_BUILD_PATH)/build_tee_image.mk
$(BUILT_TRUSTZONE_TARGET_$(my_secure_os)): $(ATF_COMP_IMAGE_NAME) $(MTEE_COMP_IMAGE_NAME)

