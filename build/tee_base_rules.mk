ifeq ($(LOCAL_MAKEFILE),)
  $(error LOCAL_MAKEFILE is not defined)
endif
ifeq ($(OUTPUT_NAME),)
  $(error $(LOCAL_MAKEFILE): OUTPUT_NAME is not defined)
endif
ifeq ($(TEE_MODE),)
  $(error $(LOCAL_MAKEFILE): TEE_MODE is not defined)
endif
ifeq ($(PLATFORM),)
  PLATFORM := ARM_V7A_STD
endif
ifeq ($(TEE_MODULE_TARGET_ARCH),)
  TEE_MODULE_TARGET_ARCH := $(PLATFORM)
endif
ifeq ($(TOOLCHAIN),)
  TOOLCHAIN := $(TEE_TOOLCHAIN)
endif

ifneq ($(strip $(DRIVER_UUID)),)
  ifeq ($(strip $(BUILD_DRIVER_LIBRARY_ONLY)),YES)
    module_id := $(OUTPUT_NAME).lib
  else ifneq ($(strip $(SRC_LIB_C)),)
    module_id := $(OUTPUT_NAME).lib
  else ifneq ($(strip $(SRC_CPP))$(strip $(SRC_C))$(strip $(SRC_ASM)),)
    module_id := $(OUTPUT_NAME).drbin
  else ifneq ($(wildcard $(foreach n,$(TEE_MODE) $(call LowerCase,$(TEE_MODE)) release debug,$(dir $(LOCAL_MAKEFILE))$(n)/$(OUTPUT_NAME).lib)),)
    module_id := $(OUTPUT_NAME).lib
  else
    module_id := $(OUTPUT_NAME).drbin
  endif
else ifneq ($(strip $(TRUSTLET_UUID)),)
  ifeq ($(BUILD_TRUSTLET_LIBRARY_ONLY),yes)
    module_id := $(OUTPUT_NAME).lib
  else ifeq ($(GP_ENTRYPOINTS),Y)
    module_id := $(OUTPUT_NAME).tabin
  else
    module_id := $(OUTPUT_NAME).tlbin
  endif
else
  $(error $(LOCAL_MAKEFILE): DRIVER_UUID and TRUSTLET_UUID are not defined)
endif
my_module_id_suffix :=
ifeq ($(TEE_MODULE_TARGET_ARCH),ARM_V8A_AARCH64)
  my_module_id_suffix := _$(TEE_MODULE_TARGET_ARCH)
endif
module_id := $(module_id)$(my_module_id_suffix)

ifneq ($(filter $(module_id),$(TEE_ALL_MODULES)),)
  ifneq ($(LOCAL_MAKEFILE),$(TEE_ALL_MODULES.$(module_id).MAKEFILE))
    $(error $(LOCAL_MAKEFILE): $(module_id) already defined by $(TEE_ALL_MODULES.$(module_id).MAKEFILE))
  endif
endif

TEE_ALL_MODULES := $(TEE_ALL_MODULES) $(module_id)
TEE_ALL_MODULES.$(module_id).MAKEFILE := $(LOCAL_MAKEFILE)
TEE_ALL_MODULES.$(module_id).PATH := $(patsubst %/makefile.mk,%,$(patsubst %/Locals/Code/makefile.mk,%,$(LOCAL_MAKEFILE)))
TEE_ALL_MODULES.$(module_id).OUTPUT_NAME := $(OUTPUT_NAME)
TEE_ALL_MODULES.$(module_id).PLATFORM := $(strip $(PLATFORM))

TEE_ARCH_MAKE_OPTION :=
TEE_HAL_DEPENDENCIES :=
imported_includes :=
TEE_DRIVER_OUTPUT_PATH := $(TEE_DRIVER_OUTPUT_PATH_$(TEE_MODULE_TARGET_ARCH))
TEE_TRUSTLET_OUTPUT_PATH := $(TEE_TRUSTLET_OUTPUT_PATH_$(TEE_MODULE_TARGET_ARCH))

ifneq ($(strip $(DRIVER_UUID)),)
    TEE_ALL_MODULES.$(module_id).CLASS := DRIVER
    TEE_ALL_MODULES.$(module_id).OUTPUT_ROOT := $(TEE_DRIVER_OUTPUT_PATH)/$(OUTPUT_NAME)
else ifneq ($(strip $(TRUSTLET_UUID)),)
    TEE_ALL_MODULES.$(module_id).CLASS := TRUSTLET
    TEE_ALL_MODULES.$(module_id).OUTPUT_ROOT := $(TEE_TRUSTLET_OUTPUT_PATH)/$(OUTPUT_NAME)
endif
ifeq ($(TRUSTONIC_TEE_VERSION),$(filter $(TRUSTONIC_TEE_VERSION),500 510))
    TEE_ALL_MODULES.$(module_id).EXPORT_OUTDIR := $(TEE_ALL_MODULES.$(module_id).OUTPUT_ROOT)/$(TEE_ALL_MODULES.$(module_id).PLATFORM)/$(TOOLCHAIN)
else
    TEE_ALL_MODULES.$(module_id).EXPORT_OUTDIR := $(TEE_ALL_MODULES.$(module_id).OUTPUT_ROOT)
endif
    TEE_ALL_MODULES.$(module_id).$(TEE_MODE).OUTPUT_PATH := $(TEE_ALL_MODULES.$(module_id).EXPORT_OUTDIR)/$(TEE_MODE)
ifneq ($(strip $(DRIVER_UUID)),)
  ifeq ($(strip $(BUILD_DRIVER_LIBRARY_ONLY)),YES)
    TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT := $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).OUTPUT_PATH)/$(OUTPUT_NAME).lib
  else
    TEE_ALL_MODULES.$(module_id).$(TEE_MODE).AXF := $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).OUTPUT_PATH)/$(OUTPUT_NAME).axf
    TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT := $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).OUTPUT_PATH)/$(strip $(DRIVER_UUID)).drbin
    TEE_ALL_MODULES.$(module_id).INSTALLED := $(TEE_APP_INSTALL_PATH)/$(strip $(DRIVER_UUID)).drbin $(TEE_APP_INSTALL_PATH)/$(strip $(DRIVER_UUID)).tlbin
  endif
  ifeq ($(BUILD_DRIVER_LIBRARY_ONLY),YES)
    TEE_ALL_MODULES.$(module_id).$(TEE_MODE).LIB := $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).OUTPUT_PATH)/$(OUTPUT_NAME).lib
  else ifneq ($(strip $(SRC_LIB_C)),)
    TEE_ALL_MODULES.$(module_id).$(TEE_MODE).LIB := $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).OUTPUT_PATH)/$(OUTPUT_NAME).lib
  endif
  ifneq ($(strip $(EXTRA_LIBS)),)
    TEE_ALL_MODULES.$(module_id).$(TEE_MODE).REQUIRED := $(foreach m,$(notdir $(EXTRA_LIBS)),$(basename $(m))$(suffix $(m))$(my_module_id_suffix))
  endif
else ifneq ($(strip $(TRUSTLET_UUID)),)
  ifeq ($(BUILD_TRUSTLET_LIBRARY_ONLY),yes)
    TEE_ALL_MODULES.$(module_id).$(TEE_MODE).LIB := $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).OUTPUT_PATH)/$(OUTPUT_NAME).lib
    TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT := $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).OUTPUT_PATH)/$(OUTPUT_NAME).lib
  else ifeq ($(GP_ENTRYPOINTS),Y)
    TEE_ALL_MODULES.$(module_id).$(TEE_MODE).AXF := $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).OUTPUT_PATH)/$(OUTPUT_NAME).axf
    TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT := $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).OUTPUT_PATH)/$(strip $(TRUSTLET_UUID)).tabin
    TEE_ALL_MODULES.$(module_id).INSTALLED := $(TEE_APP_INSTALL_PATH)/$(strip $(TRUSTLET_UUID)).tabin
  else
    TEE_ALL_MODULES.$(module_id).$(TEE_MODE).AXF := $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).OUTPUT_PATH)/$(OUTPUT_NAME).axf
    TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT := $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).OUTPUT_PATH)/$(strip $(TRUSTLET_UUID)).tlbin
    TEE_ALL_MODULES.$(module_id).INSTALLED := $(TEE_APP_INSTALL_PATH)/$(strip $(TRUSTLET_UUID)).tlbin
  endif
  ifneq ($(strip $(CUSTOMER_DRIVER_LIBS)),)
    TEE_ALL_MODULES.$(module_id).$(TEE_MODE).REQUIRED := $(foreach m,$(notdir $(CUSTOMER_DRIVER_LIBS)),$(basename $(m))$(suffix $(m))$(my_module_id_suffix))
  endif
endif

my_2nd_arch_var_prefix :=
ifeq ($(TEE_MODULE_TARGET_ARCH),ARM_V8A_AARCH64)
  ifdef TARGET_2ND_ARCH
    # Android 64bit, Trustonic 64bit
  else
    # Android 32bit, Trustonic 64bit
    $(error Not support)
  endif
else
  ifdef TARGET_2ND_ARCH
    # Android 64bit, Trustonic 32bit
    my_2nd_arch_var_prefix := $(TARGET_2ND_ARCH_VAR_PREFIX)
  else
    # Android 32bit, Trustonic 32bit
  endif
endif

ifeq ($(TEE_MODULE_TARGET_ARCH),ARM_V8A_AARCH64)
  ifdef TEE_CROSS_GCC64_PATH
      TEE_ARCH_MAKE_OPTION += CROSS_GCC64_PATH=$(abspath $(TEE_CROSS_GCC64_PATH))
      TEE_ARCH_MAKE_OPTION += CROSS_GCC64_PATH_BIN=$(abspath $(TEE_CROSS_GCC64_PATH))/bin
  else
      $(error TEE_CROSS_GCC64_PATH is not defined)
  endif
else
  ifdef TEE_CROSS_GCC32_PATH
      TEE_ARCH_MAKE_OPTION += CROSS_GCC_PATH=$(abspath $(TEE_CROSS_GCC32_PATH))
      TEE_ARCH_MAKE_OPTION += CROSS_GCC_PATH_BIN=$(abspath $(TEE_CROSS_GCC32_PATH))/bin
  else ifdef TEE_CROSS_GCC_PATH
      TEE_ARCH_MAKE_OPTION += CROSS_GCC_PATH_INC=$(abspath $(TEE_CROSS_GCC_PATH))/arm-none-eabi/include
      TEE_ARCH_MAKE_OPTION += CROSS_GCC_PATH_LIB=$(abspath $(TEE_CROSS_GCC_PATH))/arm-none-eabi/lib
      TEE_ARCH_MAKE_OPTION += CROSS_GCC_PATH_LGCC=$(abspath $(TEE_CROSS_GCC_PATH))/lib/gcc/arm-none-eabi/4.8.4
      TEE_ARCH_MAKE_OPTION += CROSS_GCC_PATH_BIN=$(abspath $(TEE_CROSS_GCC_PATH))/bin
  else
      $(error TEE_CROSS_GCC32_PATH or TEE_CROSS_GCC_PATH is not defined)
  endif
endif
TEE_ARCH_MAKE_OPTION += ANDROID_STATIC_LIBRARIES_OUT_DIR=$(abspath $($(my_2nd_arch_var_prefix)TARGET_OUT_INTERMEDIATES)/STATIC_LIBRARIES)

TEE_HAL_DEPENDENCIES :=
ifneq ($(strip $(HAL_LIBS)),)
  TEE_ALL_MODULES.$(module_id).$(TEE_MODE).HAL_LIBS := $(notdir $(filter $(TEE_ANDROID_STATIC_LIBRARIES_OUT_DIR_PLACEHOLDER)/%,$(HAL_LIBS)))
  my_static_libraries := $(addsuffix .trustonic,$(basename $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).HAL_LIBS)))
  TEE_HAL_DEPENDENCIES += $(foreach l,$(my_static_libraries),$(call intermediates-dir-for,STATIC_LIBRARIES,$(l),,,$(my_2nd_arch_var_prefix))/$(l).lib)
  imported_includes += $(foreach l,$(my_static_libraries),$(call intermediates-dir-for,STATIC_LIBRARIES,$(l),,,$(my_2nd_arch_var_prefix)))
endif
ifneq ($(strip $(HAL_PREBUILT_LIBS)),)
  TEE_ALL_MODULES.$(module_id).$(TEE_MODE).HAL_PREBUILT_LIBS := $(notdir $(filter $(TEE_ANDROID_STATIC_LIBRARIES_OUT_DIR_PLACEHOLDER)/%,$(HAL_PREBUILT_LIBS)))
  my_static_libraries := $(basename $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).HAL_PREBUILT_LIBS))
  TEE_HAL_DEPENDENCIES += $(foreach l,$(my_static_libraries),$(call intermediates-dir-for,STATIC_LIBRARIES,$(l),,,$(my_2nd_arch_var_prefix))/$(l).lib)
  imported_includes += $(foreach l,$(my_static_libraries),$(call intermediates-dir-for,STATIC_LIBRARIES,$(l),,,$(my_2nd_arch_var_prefix)))
endif

TEE_MAKE_DEPENDENCIES := $(shell find $(TEE_ALL_MODULES.$(module_id).PATH) -type f -and -not -name ".*" | sort)

.KATI_RESTAT: $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT)
$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT): PRIVATE_PATH := $(TRUSTZONE_ROOT_DIR)/$(TEE_ALL_MODULES.$(module_id).PATH)
$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT): PRIVATE_MAKEFILE := $(TRUSTZONE_ROOT_DIR)/$(TEE_ALL_MODULES.$(module_id).MAKEFILE)
$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT): PRIVATE_MAKE_OPTION := $(TEE_GLOBAL_MAKE_OPTION)
$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT): PRIVATE_MAKE_OPTION += TOOLCHAIN=$(TOOLCHAIN)
$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT): PRIVATE_MAKE_OPTION += MODE=$(TEE_MODE)
$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT): PRIVATE_MAKE_OPTION += TEE_MODE=$(TEE_MODE)
$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT): PRIVATE_MAKE_OPTION += OUTPUT_ROOT=$(if $(filter ~% /%,$(TRUSTZONE_OUTPUT_PATH)),,$(TRUSTZONE_ROOT_DIR)/)$(TEE_ALL_MODULES.$(module_id).OUTPUT_ROOT)
$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT): PRIVATE_MAKE_OPTION += TEE_DRIVER_OUTPUT_PATH=$(if $(filter ~% /%,$(TRUSTZONE_OUTPUT_PATH)),,$(TRUSTZONE_ROOT_DIR)/)$(TEE_DRIVER_OUTPUT_PATH)
$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT): PRIVATE_MAKE_OPTION += $(TEE_GLOBAL_PLATFORM_OPTION)
$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT): PRIVATE_MAKE_OPTION += $(TEE_ARCH_MAKE_OPTION)
$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT): imported_includes := $(imported_includes)

$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT): $(TEE_MAKE_DEPENDENCIES)
$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT): $(TEE_HAL_DEPENDENCIES)
	@echo TEE build: $@
	$(hide) mkdir -p $(dir $@)
	$(eval TEE_HAL_INC := $(addprefix $(TRUSTZONE_ROOT_DIR)/,$(filter-out -I,$(foreach h,$(imported_includes),$(EXPORTS.$(h).FLAGS)))))
	$(eval PRIVATE_MAKE_OPTION += TEE_HAL_INC="$(TEE_HAL_INC)")
	$(PREBUILT_MAKE_PREFIX)$(MAKE) -C $(PRIVATE_PATH) -f $(PRIVATE_MAKEFILE) $(PRIVATE_MAKE_OPTION) all

ifeq ($(TEE_ALL_MODULES.$(module_id).INSTALLED),)
TEE_modules_to_check := $(TEE_modules_to_check) $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT)
else ifneq ($(TEE_MODE),$(strip $(TEE_INSTALL_MODE)))
TEE_modules_to_check := $(TEE_modules_to_check) $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT)
else ifneq ($(strip $(TRUSTONIC_TEE_SUPPORT)),yes)
TEE_modules_to_check := $(TEE_modules_to_check) $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT)
else ifeq ($(TEE_skip_non_preferred_arch),true)
TEE_modules_to_check := $(TEE_modules_to_check) $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT)
else
TEE_modules_to_install := $(TEE_modules_to_install) $(TEE_ALL_MODULES.$(module_id).INSTALLED)
$(TEE_ALL_MODULES.$(module_id).INSTALLED): $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT)
	@echo Copying: $@
	$(hide) mkdir -p $(dir $@)
	$(hide) cp -f $(dir $<)$(notdir $@) $@

endif

ifeq (dump,dump)
TEE_dumpvar_log := $(PRODUCT_OUT)/trustzone/dump/$(module_id).log
$(TEE_dumpvar_log): DUMPVAR_VALUE := $(DUMPVAR_VALUE)
$(TEE_dumpvar_log): DUMPVAR_VALUE += $(TEE_MODE).BUILT=$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).BUILT)
$(TEE_dumpvar_log): DUMPVAR_VALUE += $(TEE_MODE).LIB=$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).LIB)
$(TEE_dumpvar_log): DUMPVAR_VALUE += $(TEE_MODE).AXF=$(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).AXF)
$(TEE_dumpvar_log): PRIVATE_$(TEE_MODE).REQUIRED := $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).REQUIRED)
$(TEE_dumpvar_log): PRIVATE_$(TEE_MODE).HAL_LIBS := $(TEE_ALL_MODULES.$(module_id).$(TEE_MODE).HAL_LIBS)
  ifeq ($(TEE_MODE),$(strip $(TEE_INSTALL_MODE)))
$(TEE_dumpvar_log): DUMPVAR_VALUE += OUTPUT_NAME=$(strip $(OUTPUT_NAME))
    ifneq ($(strip $(DRIVER_UUID)),)
$(TEE_dumpvar_log): DUMPVAR_VALUE += DRIVER_UUID=$(strip $(DRIVER_UUID))
$(TEE_dumpvar_log): DUMPVAR_VALUE += DRIVER_MEMTYPE=$(strip $(DRIVER_MEMTYPE))
$(TEE_dumpvar_log): DUMPVAR_VALUE += DRIVER_NO_OF_THREADS=$(strip $(DRIVER_NO_OF_THREADS))
$(TEE_dumpvar_log): DUMPVAR_VALUE += DRIVER_SERVICE_TYPE=$(strip $(DRIVER_SERVICE_TYPE))
$(TEE_dumpvar_log): DUMPVAR_VALUE += DRIVER_KEYFILE=$(strip $(DRIVER_KEYFILE))
$(TEE_dumpvar_log): DUMPVAR_VALUE += DRIVER_FLAGS=$(strip $(DRIVER_FLAGS))
$(TEE_dumpvar_log): DUMPVAR_VALUE += DRIVER_VENDOR_ID=$(strip $(DRIVER_VENDOR_ID))
$(TEE_dumpvar_log): DUMPVAR_VALUE += DRIVER_NUMBER=$(strip $(DRIVER_NUMBER))
$(TEE_dumpvar_log): DUMPVAR_VALUE += DR_ROLLBACK_PROTECTED=$(strip $(DR_ROLLBACK_PROTECTED))
      ifneq ($(strip $(DRIVER_ID)),)
        ifeq ($(findstring <<16|,$(strip $(DRIVER_ID))),)
$(TEE_dumpvar_log): DUMPVAR_VALUE += DRIVER_ID=$(strip $(DRIVER_ID))
        endif
      endif
$(TEE_dumpvar_log): DUMPVAR_VALUE += DRIVER_INTERFACE_VERSION_MAJOR=$(strip $(DRIVER_INTERFACE_VERSION_MAJOR))
$(TEE_dumpvar_log): DUMPVAR_VALUE += DRIVER_INTERFACE_VERSION_MINOR=$(strip $(DRIVER_INTERFACE_VERSION_MINOR))
$(TEE_dumpvar_log): DUMPVAR_VALUE += DRIVER_INTERFACE_VERSION=$(strip $(DRIVER_INTERFACE_VERSION))
$(TEE_dumpvar_log): DUMPVAR_VALUE += BUILD_DRIVER_LIBRARY_ONLY=$(strip $(BUILD_DRIVER_LIBRARY_ONLY))
    else ifneq ($(strip $(TRUSTLET_UUID)),)
$(TEE_dumpvar_log): DUMPVAR_VALUE += TRUSTLET_UUID=$(strip $(TRUSTLET_UUID))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TRUSTLET_MEMTYPE=$(strip $(TRUSTLET_MEMTYPE))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TRUSTLET_NO_OF_THREADS=$(strip $(TRUSTLET_NO_OF_THREADS))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TRUSTLET_SERVICE_TYPE=$(strip $(TRUSTLET_SERVICE_TYPE))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TRUSTLET_KEYFILE=$(strip $(TRUSTLET_KEYFILE))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TRUSTLET_FLAGS=$(strip $(TRUSTLET_FLAGS))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TRUSTLET_INSTANCES=$(strip $(TRUSTLET_INSTANCES))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TRUSTLET_MOBICONFIG_KEY=$(strip $(TRUSTLET_MOBICONFIG_KEY))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TRUSTLET_MOBICONFIG_KID=$(strip $(TRUSTLET_MOBICONFIG_KID))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TRUSTLET_MOBICONFIG_USE=$(strip $(TRUSTLET_MOBICONFIG_USE))
$(TEE_dumpvar_log): DUMPVAR_VALUE += BUILD_TRUSTLET_LIBRARY_ONLY=$(strip $(BUILD_TRUSTLET_LIBRARY_ONLY))
$(TEE_dumpvar_log): DUMPVAR_VALUE += GP_ENTRYPOINTS=$(strip $(GP_ENTRYPOINTS))
$(TEE_dumpvar_log): DUMPVAR_VALUE += GP_LIBRARY=$(strip $(GP_LIBRARY))
$(TEE_dumpvar_log): DUMPVAR_VALUE += GP_TA_CONFIG_FILE=$(strip $(GP_TA_CONFIG_FILE))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TA_INTERFACE_VERSION=$(strip $(TA_INTERFACE_VERSION))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TA_KEYFILE=$(strip $(TA_KEYFILE))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TA_ROLLBACK_PROTECTED=$(strip $(TA_ROLLBACK_PROTECTED))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TA_SERVICE_TYPE=$(strip $(TA_SERVICE_TYPE))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TA_PIE=$(strip $(TA_PIE))
    endif
$(TEE_dumpvar_log): DUMPVAR_VALUE += HW_FLOATING_POINT=$(strip $(HW_FLOATING_POINT))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TBASE_API_LEVEL=$(strip $(TBASE_API_LEVEL))
$(TEE_dumpvar_log): DUMPVAR_VALUE += HEAP_SIZE_INIT=$(strip $(HEAP_SIZE_INIT))
$(TEE_dumpvar_log): DUMPVAR_VALUE += HEAP_SIZE_MAX=$(strip $(HEAP_SIZE_MAX))
$(TEE_dumpvar_log): DUMPVAR_VALUE += MAKEFILE=$(TEE_ALL_MODULES.$(module_id).MAKEFILE)
$(TEE_dumpvar_log): DUMPVAR_VALUE += PATH=$(TEE_ALL_MODULES.$(module_id).PATH)
$(TEE_dumpvar_log): DUMPVAR_VALUE += CLASS=$(TEE_ALL_MODULES.$(module_id).CLASS)
$(TEE_dumpvar_log): DUMPVAR_VALUE += PLATFORM=$(TEE_ALL_MODULES.$(module_id).PLATFORM)
$(TEE_dumpvar_log): DUMPVAR_VALUE += TOOLCHAIN=$(strip $(TOOLCHAIN))
$(TEE_dumpvar_log): DUMPVAR_VALUE += TEE_MODULE_TARGET_ARCH=$(TEE_ALL_MODULES.$(module_id).TEE_MODULE_TARGET_ARCH)
$(TEE_dumpvar_log): PRIVATE_INSTALLED := $(TEE_ALL_MODULES.$(module_id).INSTALLED)
TEE_modules_to_check := $(TEE_modules_to_check) $(TEE_dumpvar_log)
$(TEE_dumpvar_log): $(TEE_ALL_MODULES.$(module_id).MAKEFILE) $(TEE_BASE_RULES)
	@echo TEE Dump: $@
	@mkdir -p $(dir $@)
	@rm -f $@
	@$(foreach v,$(DUMPVAR_VALUE),echo $(v) >>$@;)
	@$(foreach v,$(TEE_BUILD_MODE),echo $(v).REQUIRED=$(PRIVATE_$(v).REQUIRED) >>$@;)
	@$(foreach v,$(TEE_BUILD_MODE),echo $(v).HAL_LIBS=$(PRIVATE_$(v).HAL_LIBS) >>$@;)
	@echo INSTALLED=$(PRIVATE_INSTALLED) >>$@

  endif
endif
