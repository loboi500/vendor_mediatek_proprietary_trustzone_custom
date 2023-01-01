MTK_ATF_SUPPORT=yes
MTK_TEE_SUPPORT=no
MTK_MACH_TYPE=mt6885
MTK_ATF_VERSION=v1.6
MTK_TEE_DRAM_SIZE=0x1300000
SECURE_DEINT_SUPPORT=no
#ATF_BYPASS_DRAM=yes
ifneq ($(TARGET_BUILD_VARIANT), user)
MTK_ATF_RAM_DUMP=yes
endif
KEYMASTER_RPMB=no
KEYMASTER_WRAPKEY=yes
MTK_DRCC=yes
MTK_CM_MGR=yes
MTK_ENABLE_GENIEZONE=no
#PLATFORM_OPTION="MTK_FPGA_LDVT = yes"
MTK_ENABLE_MPU_HAL_SUPPORT=yes
HW_ASSISTED_COHERENCY=1
ifeq ($(TARGET_BUILD_VARIANT), user)
  MTK_DEBUGSYS_LOCK = yes
endif
MTK_WORKAROUND_GIC_NON_BYTE_ACCESS = no
MTK_DEVMPU_SUPPORT=yes
ifeq ($(MTK_FINGERPRINT_SUPPORT), yes)
  FINGERPRINT_TEE_SPI = spi1
  MTK_TEE_SPI1 = yes
endif

# New BRM for TEE/SVP/SecCAM
MTK_TEE_RELEASE_BASIC=yes
ifeq ($(MTK_SEC_VIDEO_PATH_SUPPORT), yes)
  MTK_TEE_RELEASE_SVP=yes
endif
MTK_TEE_RELEASE_SCAM=no
MTK_TEE_RELEASE_BASIC_MODULES=\
  m4u:common:drv \
  m4u:common:m4u_tl \
  secmem:common:secmem_drbin \
  secmem:common:secmem_tabin \
  secmem:common:drv \
  secmem:common:ta

ifeq ($(TRUSTONIC_TEE_VERSION),500)
MTK_TEE_RELEASE_BASIC_MODULES+=\
  sec:common:drv \
  msee_fwk:common:drv \
  msee_fwk:common:ta
endif

ifneq ($(strip $(TARGET_2ND_ARCH)),)
MTK_TEE_RELEASE_BASIC_MODULES+=\
  sec:common:drv64 \
  msee_fwk:common:drv64 \
  msee_fwk:common:ta64
endif
MTK_TEE_RELEASE_SVP_MODULES=\
  keyinstall:common:DrKeyInstall \
  keyinstall:common:TlKeyInstall \
  widevine:common:TlWidevineModularDrm \
  widevine:common:DrWidevineModularDrm \
  widevine:common:drv \
  widevine:common:ta \
  keyinstall:common:drv \
  keyinstall:common:ta \
  modular_drm:common:drv \
  modular_drm:common:ta \
  dp_hdcp:common:TlHdcp \
  dp_hdcp:common:ta \
  drm_hdcp_common:common:DrDRMHDCPCommon \
  drm_hdcp_common:common:drv
