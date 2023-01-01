
# DRSDK_DIR_INC

TEE_INTERNAL_BSP_PATH := $(MTK_PATH_SOURCE)/trustzone/trustonic/internal/bsp
ifneq ($(wildcard $(TEE_INTERNAL_BSP_PATH)/platform/$(MTK_PLATFORM_DIR)),)
LOCAL_C_INCLUDES += $(TEE_INTERNAL_BSP_PATH)/platform/$(MTK_PLATFORM_DIR)/t-sdk/DrSdk/Out/Public
LOCAL_C_INCLUDES += $(TEE_INTERNAL_BSP_PATH)/platform/$(MTK_PLATFORM_DIR)/t-sdk/DrSdk/Out/Public/MobiCore/inc
LOCAL_C_INCLUDES += $(TEE_INTERNAL_BSP_PATH)/platform/$(MTK_PLATFORM_DIR)/t-sdk/TlSdk/Out/Public
LOCAL_C_INCLUDES += $(TEE_INTERNAL_BSP_PATH)/platform/$(MTK_PLATFORM_DIR)/t-sdk/TlSdk/Out/Public/MobiCore/inc
LOCAL_C_INCLUDES += $(TEE_INTERNAL_BSP_PATH)/platform/$(MTK_PLATFORM_DIR)/t-sdk/TlSdk/Out/Public/GPD_TEE_Internal_API
else ifneq ($(wildcard $(TEE_INTERNAL_BSP_PATH)/common/$(TRUSTONIC_TEE_VERSION)/t-sdk),)
LOCAL_C_INCLUDES += $(TEE_INTERNAL_BSP_PATH)/common/$(TRUSTONIC_TEE_VERSION)/t-sdk/DrSdk/Out/Public
LOCAL_C_INCLUDES += $(TEE_INTERNAL_BSP_PATH)/common/$(TRUSTONIC_TEE_VERSION)/t-sdk/DrSdk/Out/Public/MobiCore/inc
LOCAL_C_INCLUDES += $(TEE_INTERNAL_BSP_PATH)/common/$(TRUSTONIC_TEE_VERSION)/t-sdk/TlSdk/Out/Public
LOCAL_C_INCLUDES += $(TEE_INTERNAL_BSP_PATH)/common/$(TRUSTONIC_TEE_VERSION)/t-sdk/TlSdk/Out/Public/MobiCore/inc
LOCAL_C_INCLUDES += $(TEE_INTERNAL_BSP_PATH)/common/$(TRUSTONIC_TEE_VERSION)/t-sdk/TlSdk/Out/Public/GPD_TEE_Internal_API
endif

# For compatibility
LOCAL_C_INCLUDES += vendor/mediatek/proprietary/trustzone/common/hal/source/tee/common/include

LOCAL_C_INCLUDES += bionic/libc/kernel/uapi

LOCAL_WHOLE_STATIC_LIBRARIES += msee_fwk_drv_header msee_fwk_ta_header

ifneq ($(TRUSTZONE_GCC_PREFIX),)
    LOCAL_CC := $(TRUSTZONE_GCC_PREFIX)gcc
    LOCAL_CXX := $(TRUSTZONE_GCC_PREFIX)g++
else
   ifeq ($(TRUSTONIC_TEE_VERSION),$(filter $(TRUSTONIC_TEE_VERSION),500 510))
      LOCAL_CC_64  := prebuilts/gcc/linux-x86/aarch64/gcc-arm-8.3-2019.03-x86_64-aarch64-elf/bin/aarch64-elf-gcc
      LOCAL_CXX_64 := prebuilts/gcc/linux-x86/aarch64/gcc-arm-8.3-2019.03-x86_64-aarch64-elf/bin/aarch64-elf-g++
      LOCAL_CC_32  := prebuilts/gcc/linux-x86/arm/gcc-arm-8.3-2019.03-x86_64-arm-eabi/bin/arm-eabi-gcc
      LOCAL_CXX_32 := prebuilts/gcc/linux-x86/arm/gcc-arm-8.3-2019.03-x86_64-arm-eabi/bin/arm-eabi-g++
      LOCAL_CFLAGS_32 += -march=armv7-a
      LOCAL_CFLAGS_64 += -march=armv8-a
   else
      LOCAL_CC  := prebuilts/gcc/linux-x86/arm/gcc-linaro-7.1.1-2017.08-x86_64_arm-eabi/bin/arm-eabi-gcc
      LOCAL_CXX := prebuilts/gcc/linux-x86/arm/gcc-linaro-7.1.1-2017.08-x86_64_arm-eabi/bin/arm-eabi-g++
      LOCAL_CFLAGS += -march=armv7-a
   endif
endif ### ifneq ($(TRUSTZONE_GCC_PREFIX),)
LOCAL_NO_PIC := false
LOCAL_CFLAGS += -D__TRUSTONIC_TEE__=1

# ARM_OPT_CC
LOCAL_CFLAGS_32 += -DPLAT=ARMV7_A_STD
LOCAL_CFLAGS_32 += -DARM_ARCH=ARMv7 -D__ARMv7__
LOCAL_CFLAGS_32 += -D__ARMV7_A__
LOCAL_CFLAGS_32 += -D__ARMV7_A_STD__
LOCAL_CFLAGS_32 += -DARMV7_A_SHAPE=STD
# CPU_OPT_CC_NO_NEON
ifeq ($(TARGET_BUILD_VARIANT),eng)
ifneq ($(wildcard vendor/mediatek/proprietary/trustzone/trustonic/secure/),)
LOCAL_CFLAGS += -DMEMORY_MONITOR=1
else
LOCAL_CFLAGS += -DMEMORY_MONITOR=0
endif
else
LOCAL_CFLAGS += -DMEMORY_MONITOR=0
endif
LOCAL_CFLAGS_32 += -mfpu=vfp
LOCAL_CFLAGS_32 += -mfloat-abi=soft
# CC_OPTS_BASE
LOCAL_CFLAGS += -O3
LOCAL_CFLAGS_32 += -mthumb
LOCAL_CFLAGS_32 += -mthumb-interwork
LOCAL_CFLAGS_32 += -D__THUMB__
ifeq ($(TARGET_BUILD_VARIANT),eng)
LOCAL_CFLAGS += -DDEBUG --debug
endif
#LOCAL_CFLAGS += -Werror
#LOCAL_CFLAGS += -Wall
#LOCAL_CFLAGS += -Wextra
LOCAL_CFLAGS += -D__$(shell echo $(TARGET_BOARD_PLATFORM) | tr '[a-z]' '[A-Z]')__=1

include $(TRUSTZONE_CUSTOM_BUILD_PATH)/hal_static_library.mk

LOCAL_CC_32 :=
LOCAL_CC_64 :=
LOCAL_CXX_32 :=
LOCAL_CXX_64 :=
