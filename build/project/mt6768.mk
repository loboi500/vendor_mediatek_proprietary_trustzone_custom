MTK_ATF_SUPPORT=yes
MTK_TEE_SUPPORT=no
MTK_MACH_TYPE=mt6768
MTK_ATF_VERSION=v1.6
MTK_TEE_DRAM_SIZE=0x1300000
SECURE_DEINT_SUPPORT=no
#ATF_BYPASS_DRAM=yes
ifneq ($(TARGET_BUILD_VARIANT), user)
MTK_ATF_RAM_DUMP=yes
endif
MTK_FIQ_CACHE_SUPPORT=no
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
MTK_INDIRECT_ACCESS_SUPPORT=no

# New BRM for TEE/SVP/SecCAM
MTK_TEE_RELEASE_BASIC=yes
MTK_TEE_RELEASE_SVP=yes
MTK_TEE_RELEASE_SCAM=no
MTK_TEE_RELEASE_BASIC_MODULES=\
  sec:common:drv \
  secmem:common:secmem_drbin \
  secmem:common:secmem_tabin \
  msee_fwk:common:drv \
  msee_fwk:common:ta \
  secmem:common:drv \
  secmem:common:ta
ifneq ($(strip $(TARGET_2ND_ARCH)),)
MTK_TEE_RELEASE_BASIC_MODULES+=\
  sec:common:drv64 \
  msee_fwk:common:drv64 \
  msee_fwk:common:ta64
endif
MTK_TEE_RELEASE_SVP_MODULES=\
  cmdq:common:drv \
  cmdq:common:ta \
  drm_hdcp_common:common:DrDRMHDCPCommon \
  drm_hdcp_common:common:drv \
  keyinstall:common:DrKeyInstall \
  keyinstall:common:TlKeyInstall \
  m4u:common:drv \
  m4u:common:m4u_tl \
  video:common:MtkH264Vdec/MtkH264SecVdecDrv \
  video:common:MtkH264Vdec/MtkH264SecVdecTL \
  video:common:MtkVP9Vdec/MtkVP9SecVdecDrv \
  video:common:MtkVP9Vdec/MtkVP9SecVdecTL \
  video:common:MtkH264Venc/MtkH264SecVencDrv \
  video:common:MtkH264Venc/MtkH264SecVencTL \
  widevine:common:TlWidevineModularDrm \
  widevine:common:DrWidevineModularDrm \
  widevine:common:drv \
  widevine:common:ta \
  keyinstall:common:drv \
  keyinstall:common:ta \
  m4u:common:ta \
  video:common:MtkH264Vdec/drv \
  video:common:MtkH264Vdec/ta \
  video:common:MtkVP9Vdec/drv \
  video:common:MtkVP9Vdec/ta \
  modular_drm:common:drv \
  modular_drm:common:ta
MTK_TEE_RELEASE_SCAM_MODULES=\
  cmdq:common:drv \
  cmdq:common:ta \
  m4u:common:drv \
  m4u:common:m4u_tl
