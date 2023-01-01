ifneq (,$(filter vendor/mediatek/proprietary/trustzone/common/hal/source/trustlets/%,$(LOCAL_MODULE_MAKEFILE)))
MTK_TEE_CHECK_RELEASE_MAKEFILE := $(LOCAL_MODULE_MAKEFILE)
else
ifneq (yes,$(strip $(MTK_TEE_RELEASE_BASIC)))
MTK_TEE_CHECK_RELEASE_MAKEFILE := $(LOCAL_MODULE_MAKEFILE)
else # MTK_TEE_RELEASE_BASIC=yes
MTK_TEE_CHECK_RELEASE_MAKEFILE :=
MTK_TEE_RELEASE_MAKEFILES :=
MTK_TEE_RELEASE_BASIC_MODULE_CHECK :=
MTK_TEE_RELEASE_OTHER_MODULE_CHECK :=
define mtk_tee_release_include_module_makefile
$(firstword \
  $(wildcard \
    vendor/mediatek/proprietary/trustzone/common/hal/secure/trustlets/$(strip $(1))/Android.mk \
  )\
)
endef
$(foreach m,$(sort $(MTK_TEE_RELEASE_BASIC_MODULES)),\
        $(eval MTK_TEE_RELEASE_BASIC_MODULE_CHECK += $(word 1,$(subst :, ,$(m))))\
)
ifneq (,$(filter yes,$(MTK_TEE_RELEASE_SVP) $(MTK_SEC_VIDEO_PATH_SUPPORT)))
$(foreach m,$(MTK_TEE_RELEASE_SVP_MODULES),$(eval MTK_TEE_RELEASE_OTHER_MODULE_CHECK += $(word 1,$(subst :, ,$(m)))))
endif
ifneq (,$(filter yes,$(MTK_TEE_RELEASE_SCAM) $(MTK_CAM_SECURITY_SUPPORT)))
$(foreach m,$(MTK_TEE_RELEASE_SCAM_MODULES),$(eval MTK_TEE_RELEASE_OTHER_MODULE_CHECK += $(word 1,$(subst :, ,$(m)))))
endif
$(foreach m1,$(sort $(MTK_TEE_RELEASE_BASIC_MODULE_CHECK)),\
        $(eval MTK_TEE_RELEASE_MAKEFILES += $(addsuffix %,$(dir $(call mtk_tee_release_include_module_makefile,$(m1)))))\
)
$(foreach n1,$(sort $(MTK_TEE_RELEASE_OTHER_MODULE_CHECK)),\
        $(eval MTK_TEE_RELEASE_MAKEFILES += $(addsuffix %,$(dir $(call mtk_tee_release_include_module_makefile,$(n1)))))\
)
MTK_TEE_CHECK_RELEASE_MAKEFILE := $(filter $(MTK_TEE_RELEASE_MAKEFILES),$(LOCAL_MODULE_MAKEFILE))
endif
endif

ifneq (,$(wildcard $(MTK_TEE_CHECK_RELEASE_MAKEFILE)))
$(info including STATIC DR/TA $(MTK_TEE_CHECK_RELEASE_MAKEFILE))
my_tee_hal_static_module := $(LOCAL_MODULE)
my_tee_hal_cflags := $(LOCAL_CFLAGS)
my_tee_hal_cflags_32 := $(LOCAL_CFLAGS_32)
my_tee_hal_cflags_64 := $(LOCAL_CFLAGS_64)
my_tee_hal_c_includes := $(LOCAL_C_INCLUDES)
my_tee_hal_static_libraries := $(LOCAL_STATIC_LIBRARIES)
my_tee_hal_whole_static_libraries := $(LOCAL_WHOLE_STATIC_LIBRARIES)

LOCAL_NO_DEFAULT_COMPILER_FLAGS := true
LOCAL_SYSTEM_SHARED_LIBRARIES :=
LOCAL_CXX_STL := none

LOCAL_CONLYFLAGS += -std=c99
LOCAL_MODULE_SUFFIX := .lib

ifeq ($(TRUSTONIC_TEE_VERSION),$(filter $(TRUSTONIC_TEE_VERSION),500 510))
ifndef LOCAL_MULTILIB
LOCAL_MULTILIB := 32
endif
else
ifndef LOCAL_MULTILIB
LOCAL_MULTILIB := 32
endif
endif

LOCAL_NO_CRT := true
LOCAL_NO_LIBGCC := true
LOCAL_NO_STATIC_ANALYZER := true
LOCAL_PROPRIETARY_MODULE := true
LOCAL_SANITIZE := never

ifdef TRUSTONIC_TEE_VERSION
ifneq ($(filter trustonic,$(LOCAL_TEE_SUBARCH)),)
  LOCAL_MODULE               := $(my_tee_hal_static_module).trustonic
  OVERRIDE_BUILT_MODULE_PATH :=
  LOCAL_BUILT_MODULE         :=
  LOCAL_INSTALLED_MODULE     :=
  LOCAL_INTERMEDIATE_TARGETS :=
  LOCAL_CFLAGS               := $(my_tee_hal_cflags)
  LOCAL_CFLAGS_32            := $(my_tee_hal_cflags_32)
  LOCAL_CFLAGS_64            := $(my_tee_hal_cflags_64)
  LOCAL_C_INCLUDES           := $(my_tee_hal_c_includes)
  LOCAL_STATIC_LIBRARIES     := $(my_tee_hal_static_libraries)
  LOCAL_WHOLE_STATIC_LIBRARIES := $(my_tee_hal_whole_static_libraries)
  $(info $(LOCAL_MODULE_MAKEFILE): $(my_tee_hal_static_module) -> $(LOCAL_MODULE))
  include $(TRUSTZONE_CUSTOM_BUILD_PATH)/trustonic_hal_static_library.mk
endif
endif

ifdef MICROTRUST_TEE_VERSION
ifneq ($(filter microtrust,$(LOCAL_TEE_SUBARCH)),)
  LOCAL_MODULE               := $(my_tee_hal_static_module).microtrust
  OVERRIDE_BUILT_MODULE_PATH :=
  LOCAL_BUILT_MODULE         :=
  LOCAL_INSTALLED_MODULE     :=
  LOCAL_INTERMEDIATE_TARGETS :=
  LOCAL_CFLAGS               := $(my_tee_hal_cflags)
  LOCAL_CFLAGS_32            := $(my_tee_hal_cflags_32)
  LOCAL_CFLAGS_64            := $(my_tee_hal_cflags_64)
  LOCAL_C_INCLUDES           := $(my_tee_hal_c_includes)
  LOCAL_STATIC_LIBRARIES     := $(my_tee_hal_static_libraries)
  LOCAL_WHOLE_STATIC_LIBRARIES := $(my_tee_hal_whole_static_libraries)
  $(info $(LOCAL_MODULE_MAKEFILE): $(my_tee_hal_static_module) -> $(LOCAL_MODULE))
  ifeq ($(MICROTRUST_TEE_VERSION),450)
    LOCAL_MULTILIB := 64
  endif
  include $(TRUSTZONE_CUSTOM_BUILD_PATH)/microtrust_hal_static_library.mk
endif
endif

endif ## MTK_TEE_CHECK_RELEASE_MAKEFILE
LOCAL_TEE_SUBARCH := trustonic microtrust
