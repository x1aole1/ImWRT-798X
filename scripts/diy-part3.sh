#!/bin/bash
#
# 版权所有 (c) 2019-2020 P3TERX <https://p3terx.com>
#
# 这是一个自由软件，根据 MIT 许可证授权。
# 详细信息请参见 /LICENSE。
#
# https://github.com/P3TERX/Actions-OpenWrt

# 修复依赖变更导致的问题 (OpenWrt 25 移除了 luci-app-ttyd, lua-cjson, ebtables-legacy)
sed -i 's/+luci-app-ttyd //g' package/mtk/applications/luci-app-turboacc-mtk/Makefile 2>/dev/null || true
sed -i 's/+lua-cjson //g' package/mtk/applications/mtwifi-cfg/Makefile 2>/dev/null || true
sed -i 's/+lua-cjson//g' package/mtk/applications/mtwifi-cfg/Makefile 2>/dev/null || true
sed -i 's/+ebtables-legacy-utils//g' package/mtk/applications/luci-app-eqos-mtk/Makefile 2>/dev/null || true
sed -i 's/+ebtables-legacy//g' package/mtk/applications/luci-app-eqos-mtk/Makefile 2>/dev/null || true

# 添加 cmcc_rax3000m-emmc (U-Boot mod 布局，生成 sysupgrade.itb 固件)
cat << 'EOF' >> target/linux/mediatek/image/filogic.mk

define Device/cmcc_rax3000m-emmc
  DEVICE_VENDOR := CMCC
  DEVICE_MODEL := RAX3000M EMMC
  DEVICE_VARIANT := (U-Boot mod)
  DEVICE_DTS := mt7981b-cmcc-rax3000m-emmc-mtk
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware kmod-usb3 \
	automount f2fsck mkf2fs
  SUPPORTED_DEVICES += cmcc,rax3000m-emmc
  KERNEL_LOADADDR := 0x44000000
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  IMAGES := sysupgrade.itb
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | \
	pad-rootfs | append-metadata
endef
TARGET_DEVICES += cmcc_rax3000m-emmc

define Device/cmcc_xr30-emmc
  DEVICE_VENDOR := CMCC
  DEVICE_MODEL := XR30 EMMC
  DEVICE_VARIANT := (U-Boot mod)
  DEVICE_DTS := mt7981b-cmcc-rax3000m-emmc-mtk
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware kmod-usb3 \
	automount f2fsck mkf2fs
  SUPPORTED_DEVICES += cmcc,xr30-emmc
  KERNEL_LOADADDR := 0x44000000
  KERNEL := kernel-bin | gzip
  KERNEL_INITRAMFS := kernel-bin | lzma | \
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k
  KERNEL_INITRAMFS_SUFFIX := -recovery.itb
  IMAGES := sysupgrade.itb
  IMAGE/sysupgrade.itb := append-kernel | \
	fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | \
	pad-rootfs | append-metadata
endef
TARGET_DEVICES += cmcc_xr30-emmc
EOF
