LOCAL_PATH := $(call my-dir)
$(info including $(LOCAL_MODULE_MAKEFILE) ...)

BUILD_TEE_HAL_STATIC_LIBRARY := $(TRUSTZONE_CUSTOM_BUILD_PATH)/tee_static_library.mk

TEE_HAL_PROTECT_PATH := $(MTK_PATH_SOURCE)/trustzone/common/hal/secure
TEE_HAL_PROTECT_MAKEFILES := $(wildcard $(TEE_HAL_PROTECT_PATH)/trustlets/Android.mk)

TEE_HAL_SOURCE_PATH := $(MTK_PATH_SOURCE)/trustzone/common/hal/source
TEE_HAL_SOURCE_MAKEFILES := $(wildcard $(TEE_HAL_SOURCE_PATH)/trustlets/Android.mk)

TEE_HAL_EXCLUDE_MODULES := $(ALL_MODULES)
LOCAL_TEE_SUBARCH := trustonic microtrust
$(foreach mk,$(TEE_HAL_PROTECT_MAKEFILES) $(TEE_HAL_SOURCE_MAKEFILES),\
	$(info including $(mk) ...)\
	$(eval include $(mk))\
)

TEE_HAL_SRC_MODULES := $(filter-out $(TEE_HAL_EXCLUDE_MODULES),$(ALL_MODULES))
#TEE_HAL_modules_to_check := $(call module-built-files,$(TEE_HAL_SRC_MODULES))

