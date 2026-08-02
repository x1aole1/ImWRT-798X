#!/bin/bash
#
# 版权所有 (c) 2019-2020 P3TERX <https://p3terx.com>
#
# 这是一个自由软件，根据 MIT 许可证授权。
# 详细信息请参见 /LICENSE。
#
# https://github.com/P3TERX/Actions-OpenWrt

# 修改默认 IP
CONFIG_FILE="package/base-files/files/bin/config_generate"
if [ -f "$CONFIG_FILE" ]; then
  if ! grep -q "192.168.2.1" "$CONFIG_FILE"; then
    sed -i 's/192\.168\.6\.1/192.168.2.1/g; s/192\.168\.1\.1/192.168.2.1/g' "$CONFIG_FILE"
    echo "IP 地址已更新为 192.168.2.1"
  else
    echo "IP 地址已是 192.168.2.1，无需修改"
  fi
else
  echo "警告：$CONFIG_FILE 不存在，跳过 IP 修改"
fi

# 预装 OpenClash（已注释，保持不变）
# echo "CONFIG_PACKAGE_luci-app-openclash=y" >> .config

# 删除 package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/e2p
rm -f package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/e2p
if [ $? -eq 0 ]; then
  echo "已删除 package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/e2p"
else
  echo "错误：删除 package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/e2p 失败"
fi

# 创建 MT7981 固件符号链接
EEPROM_FILE="package/mtk/drivers/mt_wifi/files/mt7981-default-eeprom/MT7981_iPAiLNA_EEPROM.bin"
if [ -f "$EEPROM_FILE" ]; then
  mkdir -p files/lib/firmware
  ln -sf /lib/firmware/MT7981_iPAiLNA_EEPROM.bin files/lib/firmware/e2p
  echo "符号链接已创建"
  ls -l files/lib/firmware/e2p || { echo "错误：符号链接创建失败"; exit 1; }
else
  echo "错误：$EEPROM_FILE 不存在，无法创建符号链接"
  exit 1
fi

# 修复依赖变更导致的问题 (OpenWrt 24.10 移除了 luci-app-ttyd, lua-cjson, ebtables-legacy)
sed -i 's/+luci-app-ttyd //g' package/mtk/applications/luci-app-turboacc-mtk/Makefile || true
sed -i 's/+lua-cjson //g' package/mtk/applications/mtwifi-cfg/Makefile || true
sed -i 's/+lua-cjson//g' package/mtk/applications/mtwifi-cfg/Makefile || true
sed -i 's/+ebtables-legacy-utils//g' package/mtk/applications/luci-app-eqos-mtk/Makefile || true
sed -i 's/+ebtables-legacy//g' package/mtk/applications/luci-app-eqos-mtk/Makefile || true

# 添加 cmcc_rax3000m-emmc (U-Boot mod 布局，生成 sysupgrade.itb 固件)
# 使用 printf 逐行写入，避免 CRLF 换行符污染 Makefile
FILOGIC_MK="target/linux/mediatek/image/filogic.mk"
printf '\ndefine Device/cmcc_rax3000m-emmc\n' >> "$FILOGIC_MK"
printf '  DEVICE_VENDOR := CMCC\n' >> "$FILOGIC_MK"
printf '  DEVICE_MODEL := RAX3000M EMMC\n' >> "$FILOGIC_MK"
printf '  DEVICE_VARIANT := (U-Boot mod)\n' >> "$FILOGIC_MK"
printf '  DEVICE_DTS := mt7981b-cmcc-rax3000m-emmc-mtk\n' >> "$FILOGIC_MK"
printf '  DEVICE_DTS_DIR := ../dts\n' >> "$FILOGIC_MK"
printf '  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware kmod-usb3 \\\n' >> "$FILOGIC_MK"
printf '\tautomount f2fsck mkf2fs\n' >> "$FILOGIC_MK"
printf '  SUPPORTED_DEVICES += cmcc,rax3000m-emmc\n' >> "$FILOGIC_MK"
printf '  KERNEL_LOADADDR := 0x44000000\n' >> "$FILOGIC_MK"
printf '  KERNEL := kernel-bin | gzip\n' >> "$FILOGIC_MK"
printf '  KERNEL_INITRAMFS := kernel-bin | lzma | \\\n' >> "$FILOGIC_MK"
printf '\tfit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k\n' >> "$FILOGIC_MK"
printf '  KERNEL_INITRAMFS_SUFFIX := -recovery.itb\n' >> "$FILOGIC_MK"
printf '  IMAGES := sysupgrade.itb\n' >> "$FILOGIC_MK"
printf '  IMAGE/sysupgrade.itb := append-kernel | \\\n' >> "$FILOGIC_MK"
printf '\tfit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | \\\n' >> "$FILOGIC_MK"
printf '\tpad-rootfs | append-metadata\n' >> "$FILOGIC_MK"
printf 'endef\n' >> "$FILOGIC_MK"
printf 'TARGET_DEVICES += cmcc_rax3000m-emmc\n' >> "$FILOGIC_MK"
echo "已注入 cmcc_rax3000m-emmc 设备定义（U-Boot mod .itb）"
