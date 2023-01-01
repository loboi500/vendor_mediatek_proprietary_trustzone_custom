include $(CLEAR_VARS)
LOCAL_MODULE := tee_$(my_secure_os)$(if $(my_secure_os_variant),_$(my_secure_os_variant)).img
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_OWNER := mtk
LOCAL_PROPRIETARY_MODULE := true
LOCAL_UNINSTALLABLE_MODULE := true
LOCAL_MULTILIB := 32
intermediates := $(call local-intermediates-dir)
BUILT_TRUSTZONE_TARGET_$(my_secure_os)$(if $(my_secure_os_variant),_$(my_secure_os_variant)) := $(intermediates)/combined.img
LOCAL_PREBUILT_MODULE_FILE := $(BUILT_TRUSTZONE_TARGET_$(my_secure_os)$(if $(my_secure_os_variant),_$(my_secure_os_variant)))
include $(BUILD_PREBUILT)

$(BUILT_TRUSTZONE_TARGET_$(my_secure_os)$(if $(my_secure_os_variant),_$(my_secure_os_variant))):
	@echo "Trustzone build: $@ <= $^"
	$(hide) mkdir -p $(dir $@)
	$(hide) cat $^ > $@
