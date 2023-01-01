#=============================================
# Do not support SW ready go yet
# set $(MTK_PLATFORM).mk settings here instead
ATF_PLATFORM:=mt6893
MTK_ATF_SUPPORT=yes
MTK_TEE_SUPPORT=no
MTK_MACH_TYPE=mt6893
MTK_ATF_VERSION=v1.6
SECURE_DEINT_SUPPORT=no
#ATF_BYPASS_DRAM=yes
ifneq ($(TARGET_BUILD_VARIANT), user)
MTK_ATF_RAM_DUMP=yes
endif
KEYMASTER_RPMB=no
KEYMASTER_WRAPKEY=yes
MTK_DRCC=yes
MTK_CM_MGR=yes
MTK_ENABLE_GENIEZONE = yes
#PLATFORM_OPTION="MTK_FPGA_LDVT = yes"
MTK_ENABLE_MPU_HAL_SUPPORT=yes
HW_ASSISTED_COHERENCY=1
ifeq ($(TARGET_BUILD_VARIANT), user)
  MTK_DEBUGSYS_LOCK = yes
endif
MTK_WORKAROUND_GIC_NON_BYTE_ACCESS = no
MTK_DEVMPU_SUPPORT=no
MTK_TINYSYS_SCP_SECURE_DUMP=yes
MTK_TINYSYS_SCP_VERSION=1
# $(MTK_PLATFORM).mk settings end
#=============================================
TRUSTONIC_TEE_SUPPORT = no
MICROTRUST_TEE_SUPPORT = no
MTK_GOOGLE_TRUSTY_SUPPORT = no
TRUSTKERNEL_TEE_SUPPORT=no
MTK_ENABLE_GENIEZONE = yes
MTK_PSCI_CONFIG = disable_system_suspend,validate_pwr_control_apmcu,validate_pwr_control_mcu,system_idle_states_support
