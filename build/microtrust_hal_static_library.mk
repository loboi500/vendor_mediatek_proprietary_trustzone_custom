
# Native CA
LOCAL_C_INCLUDES += $(UT_SDK_DIR)/api/client_api/include
# TA and DRV
LOCAL_C_INCLUDES += $(UT_SDK_DIR)/api/c/include
LOCAL_C_INCLUDES += $(UT_SDK_DIR)/api/pf/gp_native/include
LOCAL_C_INCLUDES += $(UT_SDK_DIR)/api/pf/libuTbta/include
LOCAL_C_INCLUDES += $(UT_SDK_DIR)/api/pf/crypto/include
LOCAL_C_INCLUDES += $(UT_SDK_DIR)/api/pf/ts/include
LOCAL_C_INCLUDES += $(UT_SDK_DIR)/api/pf/rpmb/include
LOCAL_C_INCLUDES += $(UT_SDK_DIR)/api/pf/time/include
LOCAL_C_INCLUDES += $(UT_SDK_DIR)/api/pf/driver_call/include
LOCAL_C_INCLUDES += $(UT_SDK_DIR)/api/pf/driver_framework/include
LOCAL_C_INCLUDES += $(UT_SDK_DIR)/api/sys/base/include
ifeq ($(MICROTRUST_TEE_VERSION),450)
  LOCAL_C_INCLUDES += $(UT_SDK_DIR)/api/teei/system/include
endif

# For compatibility
LOCAL_C_INCLUDES += vendor/mediatek/proprietary/trustzone/common/hal/source/tee/common/include

LOCAL_C_INCLUDES += bionic/libc/kernel/uapi

$(info static lib MICROTRUST_TEE_VERSION = $(MICROTRUST_TEE_VERSION))

ifneq ($(TRUSTZONE_GCC_PREFIX),)
    LOCAL_CC := $(TRUSTZONE_GCC_PREFIX)gcc
    LOCAL_CXX := $(TRUSTZONE_GCC_PREFIX)g++
else
    ifeq ($(MICROTRUST_TEE_VERSION),450)
        LOCAL_CC_64  := prebuilts/gcc/linux-x86/aarch64/gcc-arm-8.3-2019.03-x86_64-aarch64-elf/bin/aarch64-elf-gcc
        LOCAL_CXX_64 := prebuilts/gcc/linux-x86/aarch64/gcc-arm-8.3-2019.03-x86_64-aarch64-elf/bin/aarch64-elf-g++
        LOCAL_CC_32  := prebuilts/gcc/linux-x86/arm/gcc-arm-8.3-2019.03-x86_64-arm-eabi/bin/arm-eabi-gcc
        LOCAL_CXX_32 := prebuilts/gcc/linux-x86/arm/gcc-arm-8.3-2019.03-x86_64-arm-eabi/bin/arm-eabi-g++
        LOCAL_CFLAGS_32 += -march=armv7-a
        LOCAL_CFLAGS_64 += -march=armv8-a
    else
        LOCAL_CC := prebuilts/gcc/linux-x86/arm/gcc-arm-none-eabi-4_8-2014q3/bin/arm-none-eabi-gcc
        LOCAL_CXX := prebuilts/gcc/linux-x86/arm/gcc-arm-none-eabi-4_8-2014q3/bin/arm-none-eabi-g++
        LOCAL_CFLAGS += -march=armv7-a
    endif
endif ### ifneq ($(TRUSTZONE_GCC_PREFIX),)
LOCAL_NO_PIC := true
LOCAL_CFLAGS += -D__MICROTRUST_TEE__=1

ifeq ($(MTK_TRUSTZONE_PLATFORM),)
# ARM_OPT_CC
LOCAL_CFLAGS_32 += -DPLAT=ARMV7_A_STD
LOCAL_CFLAGS_32 += -DARM_ARCH=ARMv7 -D__ARMv7__
LOCAL_CFLAGS_32 += -D__ARMV7_A__
LOCAL_CFLAGS_32 += -D__ARMV7_A_STD__
LOCAL_CFLAGS_32 += -DARMV7_A_SHAPE=STD

# CPU_OPT_CC_NO_NEON
LOCAL_CFLAGS_32 += -mfpu=vfp
LOCAL_CFLAGS_32 += -mfloat-abi=soft
endif

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

LOCAL_CFLAGS_32 += -fms-extensions

include $(TRUSTZONE_CUSTOM_BUILD_PATH)/hal_static_library.mk
