ifeq (yes,$(strip $(MTK_TEE_RELEASE_BASIC)))
MTK_TEE_CA_RELEASE_MAKEFILE :=
my_ca_module := $(LOCAL_MODULE)
$(if $(filter $(my_ca_module),$(PRODUCT_PACKAGES)),\
    $(eval MTK_TEE_CA_RELEASE_MAKEFILE += $(LOCAL_MODULE_MAKEFILE))\
)
else
MTK_TEE_CA_RELEASE_MAKEFILE := $(LOCAL_MODULE_MAKEFILE)
endif

ifneq (,$(wildcard $(MTK_TEE_CA_RELEASE_MAKEFILE)))
$(info including STATIC CA $(MTK_TEE_CA_RELEASE_MAKEFILE))
my_ca_static_module := $(LOCAL_MODULE)
my_ca_shared_libraries := $(LOCAL_SHARED_LIBRARIES)
my_ca_header_libraries := $(LOCAL_HEADER_LIBRARIES)

ifdef TRUSTONIC_TEE_VERSION
ifneq ($(filter trustonic,$(LOCAL_TEE_SUBARCH)),)
  LOCAL_MODULE               := $(my_ca_static_module).trustonic
  LOCAL_SHARED_LIBRARIES     := $(filter-out libTEECommon,$(my_ca_shared_libraries))
  LOCAL_HEADER_LIBRARIES     := $(my_ca_header_libraries) $(addsuffix _headers.trustonic,$(filter libTEECommon,$(my_ca_shared_libraries)))
  OVERRIDE_BUILT_MODULE_PATH :=
  LOCAL_BUILT_MODULE         :=
  LOCAL_INSTALLED_MODULE     :=
  LOCAL_INTERMEDIATE_TARGETS :=
  $(info $(LOCAL_MODULE_MAKEFILE): $(my_ca_static_module) -> $(LOCAL_MODULE))
  include $(BUILD_STATIC_LIBRARY)
endif
endif

ifdef MICROTRUST_TEE_VERSION
ifneq ($(filter microtrust,$(LOCAL_TEE_SUBARCH)),)
  LOCAL_MODULE               := $(my_ca_static_module).microtrust
  LOCAL_SHARED_LIBRARIES     := $(filter-out libTEECommon,$(my_ca_shared_libraries))
  LOCAL_HEADER_LIBRARIES     := $(my_ca_header_libraries) $(addsuffix _headers.microtrust,$(filter libTEECommon,$(my_ca_shared_libraries)))
  OVERRIDE_BUILT_MODULE_PATH :=
  LOCAL_BUILT_MODULE         :=
  LOCAL_INSTALLED_MODULE     :=
  LOCAL_INTERMEDIATE_TARGETS :=
  $(info $(LOCAL_MODULE_MAKEFILE): $(my_ca_static_module) -> $(LOCAL_MODULE))
  include $(BUILD_STATIC_LIBRARY)
endif
endif

LOCAL_TEE_SUBARCH := trustonic microtrust
endif # MTK_TEE_RELEASE_MAKEFILES
