ifeq ($(LOCAL_MAKEFILE),)
  $(error LOCAL_MAKEFILE is not defined)
endif
ifeq ($(TARGET),)
  $(error $(LOCAL_MAKEFILE): TARGET is not defined)
endif

LOCAL_MODULE_CLASS := $(notdir $(lastword $(filter-out $(TRUSTKERNEL_BASE_RULES),$(MAKEFILE_LIST))))
ifneq ($(filter $(LOCAL_MODULE_CLASS),prog.mk prog_spec.mk),)
  ifneq ($(filter %.drv,$(TARGET)),)
    module_id := $(patsubst %.drv,%,$(filter %.drv,$(TARGET)))
  else ifneq ($(filter %.ta,$(TARGET)),)
    module_id := $(patsubst %.ta,%,$(filter %.ta,$(TARGET)))
  else
    module_id := $(strip $(TARGET))
  endif
else ifeq ($(LOCAL_MODULE_CLASS),lib.mk)
  ifneq ($(filter %.a,$(TARGET)),)
    module_id := $(patsubst %.a,%,$(filter %.a,$(TARGET)))
  else ifneq ($(filter %.so,$(TARGET)),)
    module_id := $(patsubst %.so,%,$(filter %.so,$(TARGET)))
  else
    module_id := $(strip $(TARGET))
  endif
else
  $(error $(LOCAL_MAKEFILE): prog.mk or prog_spec.mk or lib.mk are not included)
endif

ifneq ($(filter $(module_id),$(TRUSTKERNEL_ALL_MODULES)),)
  ifneq ($(LOCAL_MAKEFILE),$(TRUSTKERNEL_ALL_MODULES.$(module_id).MAKEFILE))
    $(error $(LOCAL_MAKEFILE): $(module_id) already defined by $(TRUSTKERNEL_ALL_MODULES.$(module_id).MAKEFILE))
  endif
endif

TRUSTKERNEL_ALL_MODULES := $(TRUSTKERNEL_ALL_MODULES) $(module_id)
TRUSTKERNEL_ALL_MODULES.$(module_id).MAKEFILE := $(LOCAL_MAKEFILE)
TRUSTKERNEL_ALL_MODULES.$(module_id).PATH := $(patsubst %/,%,$(dir $(LOCAL_MAKEFILE)))
TRUSTKERNEL_ALL_MODULES.$(module_id).OUTPUT_ROOT := $(TRUSTKERNEL_OUTPUT_PATH)/$(module_id)

TRUSTKERNEL_ARCH_MAKE_OPTION :=
TRUSTKERNEL_HAL_DEPENDENCIES :=
imported_includes :=

ifneq ($(filter $(LOCAL_MODULE_CLASS),prog.mk prog_spec.mk),)
    TRUSTKERNEL_ALL_MODULES.$(module_id).BUILT := $(TRUSTKERNEL_ALL_MODULES.$(module_id).OUTPUT_ROOT)/$(if $(strip $(TARGET_FILE_NAME)),$(strip $(TARGET_FILE_NAME)),$(strip $(TARGET)))
    TRUSTKERNEL_ALL_MODULES.$(module_id).INSTALLED := $(TRUSTKERNEL_INSTALL_PATH)/$(if $(strip $(TARGET_FILE_NAME)),$(strip $(TARGET_FILE_NAME)),$(strip $(TARGET)))
  ifneq ($(EXTERNAL_LIB),)
    TRUSTKERNEL_ALL_MODULES.$(module_id).REQUIRED := $(strip $(TRUSTKERNEL_ALL_MODULES.$(module_id).REQUIRED) $(patsubst lib%.a,lib%,$(filter lib%.a,$(notdir $(EXTERNAL_LIB)))))
  endif
  ifneq ($(MY_LDFLAGS),)
    TRUSTKERNEL_ALL_MODULES.$(module_id).REQUIRED := $(strip $(TRUSTKERNEL_ALL_MODULES.$(module_id).REQUIRED) $(patsubst -l%,lib%,$(filter -l%,$(MY_LDFLAGS))))
  endif
else ifeq ($(LOCAL_MODULE_CLASS),lib.mk)
  ifneq ($(filter %.a,$(TARGET)),)
    TRUSTKERNEL_ALL_MODULES.$(module_id).LIB := $(TRUSTKERNEL_ALL_MODULES.$(module_id).OUTPUT_ROOT)/$(filter %.a,$(TARGET))
    TRUSTKERNEL_ALL_MODULES.$(module_id).BUILT := $(TRUSTKERNEL_ALL_MODULES.$(module_id).LIB)
  endif
  ifneq ($(filter %.so,$(TARGET)),)
    TRUSTKERNEL_ALL_MODULES.$(module_id).BUILT := $(TRUSTKERNEL_ALL_MODULES.$(module_id).OUTPUT_ROOT)/$(filter %.so,$(TARGET))
    TRUSTKERNEL_ALL_MODULES.$(module_id).INSTALLED := $(TRUSTKERNEL_INSTALL_PATH)/$(filter %.so,$(TARGET))
  endif
endif

my_2nd_arch_var_prefix :=
ifdef TARGET_2ND_ARCH
    my_2nd_arch_var_prefix := $(TARGET_2ND_ARCH_VAR_PREFIX)
endif
TRUSTKERNEL_ARCH_MAKE_OPTION += ANDROID_STATIC_LIBRARIES_OUT_DIR=$(abspath $($(my_2nd_arch_var_prefix)TARGET_OUT_INTERMEDIATES)/STATIC_LIBRARIES)

ifneq ($(strip $(HAL_LIBS)),)
  TRUSTKERNEL_ALL_MODULES.$(module_id).HAL_LIBS := $(notdir $(filter $(TRUSTKERNEL_ANDROID_STATIC_LIBRARIES_OUT_DIR_PLACEHOLDER)/%,$(HAL_LIBS)))
  #my_static_libraries := $(basename $(TRUSTKERNEL_ALL_MODULES.$(module_id).HAL_LIBS))
  my_static_libraries := $(addsuffix .microtrust,$(basename $(TRUSTKERNEL_ALL_MODULES.$(module_id).HAL_LIBS)))
  TRUSTKERNEL_HAL_DEPENDENCIES := $(foreach l,$(my_static_libraries),$(call intermediates-dir-for,STATIC_LIBRARIES,$(l),,,$(my_2nd_arch_var_prefix))/$(l).lib)
endif

TRUSTKERNEL_MAKE_DEPENDENCIES := $(shell find $(TRUSTKERNEL_ALL_MODULES.$(module_id).PATH) -type f -and -not -name ".*" | sort)

.KATI_RESTAT: $(TRUSTKERNEL_ALL_MODULES.$(module_id).BUILT)
$(TRUSTKERNEL_ALL_MODULES.$(module_id).BUILT): PRIVATE_MAKEFILE := $(abspath $(TRUSTKERNEL_ALL_MODULES.$(module_id).MAKEFILE))
$(TRUSTKERNEL_ALL_MODULES.$(module_id).BUILT): PRIVATE_PATH := $(abspath $(TRUSTKERNEL_ALL_MODULES.$(module_id).PATH))
$(TRUSTKERNEL_ALL_MODULES.$(module_id).BUILT): PRIVATE_MAKE_OPTION := $(TRUSTKERNEL_GLOBAL_MAKE_OPTION)
$(TRUSTKERNEL_ALL_MODULES.$(module_id).BUILT): PRIVATE_MAKE_OPTION += $(TRUSTKERNEL_ARCH_MAKE_OPTION)
$(TRUSTKERNEL_ALL_MODULES.$(module_id).BUILT): PRIVATE_MAKE_OPTION += LOCAL_OBJS_DIR=$(abspath $(TRUSTKERNEL_ALL_MODULES.$(module_id).OUTPUT_ROOT))

$(TRUSTKERNEL_ALL_MODULES.$(module_id).BUILT): $(TRUSTKERNEL_MAKE_DEPENDENCIES)
$(TRUSTKERNEL_ALL_MODULES.$(module_id).BUILT): $(TRUSTKERNEL_HAL_DEPENDENCIES)
	@echo Trustkernel build: $@
	$(hide) mkdir -p $(dir $@)
	$(PREBUILT_MAKE_PREFIX)$(MAKE) -r -R -C $(PRIVATE_PATH) -f $(PRIVATE_MAKEFILE) $(PRIVATE_MAKE_OPTION) all

ifeq ($(TRUSTKERNEL_ALL_MODULES.$(module_id).INSTALLED),)
TRUSTKERNEL_modules_to_check := $(TRUSTKERNEL_modules_to_check) $(TRUSTKERNEL_ALL_MODULES.$(module_id).BUILT)
else ifneq ($(strip $(TRUSTKERNEL_TEE_SUPPORT)),yes)
TRUSTKERNEL_modules_to_check := $(TRUSTKERNEL_modules_to_check) $(TRUSTKERNEL_ALL_MODULES.$(module_id).BUILT)
else
TRUSTKERNEL_modules_to_install := $(TRUSTKERNEL_modules_to_install) $(TRUSTKERNEL_ALL_MODULES.$(module_id).INSTALLED)
endif

ifeq (dump,dump)
TRUSTKERNEL_dumpvar_log := $(TARGET_OUT_INTERMEDIATES)/TRUSTKERNEL_OBJ/dump/$(module_id).log
$(TRUSTKERNEL_dumpvar_log): DUMPVAR_VALUE := MAKEFILE=$(TRUSTKERNEL_ALL_MODULES.$(module_id).MAKEFILE)
$(TRUSTKERNEL_dumpvar_log): DUMPVAR_VALUE += PATH=$(TRUSTKERNEL_ALL_MODULES.$(module_id).PATH)
$(TRUSTKERNEL_dumpvar_log): DUMPVAR_VALUE += BUILT=$(TRUSTKERNEL_ALL_MODULES.$(module_id).BUILT)
$(TRUSTKERNEL_dumpvar_log): DUMPVAR_VALUE += INSTALLED=$(TRUSTKERNEL_ALL_MODULES.$(module_id).INSTALLED)
$(TRUSTKERNEL_dumpvar_log): PRIVATE_TARGET := $(strip $(TARGET))
$(TRUSTKERNEL_dumpvar_log): PRIVATE_REQUIRED := $(TRUSTKERNEL_ALL_MODULES.$(module_id).REQUIRED)
$(TRUSTKERNEL_dumpvar_log): PRIVATE_HAL_LIBS := $(TRUSTKERNEL_ALL_MODULES.$(module_id).HAL_LIBS)
TRUSTKERNEL_modules_to_check := $(TRUSTKERNEL_modules_to_check) $(TRUSTKERNEL_dumpvar_log)
$(TRUSTKERNEL_dumpvar_log): $(TRUSTKERNEL_ALL_MODULES.$(module_id).MAKEFILE) $(TRUSTKERNEL_BASE_RULES)
	@echo Trustkernel dump: $@
	@mkdir -p $(dir $@)
	@rm -f $@
	@$(foreach v,$(DUMPVAR_VALUE),echo $(v) >>$@;)
	@echo TARGET=$(PRIVATE_TARGET) >>$@
	@echo REQUIRED=$(PRIVATE_REQUIRED) >>$@
	@echo HAL_LIBS=$(PRIVATE_HAL_LIBS) >>$@

endif
