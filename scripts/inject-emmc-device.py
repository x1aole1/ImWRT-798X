#!/usr/bin/env python3
"""
注入 cmcc_rax3000m-emmc 设备定义到 filogic.mk
用于 padavanonly/immortalwrt-mt798x-24.10 源码
产出格式: sysupgrade.itb (U-Boot mod 布局)
"""
import sys
import os

FILOGIC = "target/linux/mediatek/image/filogic.mk"
# 精确匹配行首，避免匹配到 cmcc_rax3000m-emmc-mtk 子串
MARKER = "define Device/cmcc_rax3000m-emmc\n"

if not os.path.exists(FILOGIC):
    print(f"ERROR: {FILOGIC} not found!", file=sys.stderr)
    sys.exit(1)

with open(FILOGIC, "r") as f:
    content = f.read()

if MARKER in content:
    print(f"cmcc_rax3000m-emmc already defined, skipping injection")
    sys.exit(0)

TAB = "\t"
BACKSLASH = "\\"

lines = [
    "",
    "define Device/cmcc_rax3000m-emmc",
    "  DEVICE_VENDOR := CMCC",
    "  DEVICE_MODEL := RAX3000M EMMC",
    "  DEVICE_VARIANT := (U-Boot mod)",
    "  DEVICE_DTS := mt7981b-cmcc-rax3000m-emmc-mtk",
    "  DEVICE_DTS_DIR := ../dts",
    "  DEVICE_PACKAGES := kmod-mt7915e kmod-mt7981-firmware mt7981-wo-firmware kmod-usb3 " + BACKSLASH,
    TAB + "automount f2fsck mkf2fs",
    "  SUPPORTED_DEVICES += cmcc,rax3000m-emmc",
    "  KERNEL_LOADADDR := 0x44000000",
    "  KERNEL := kernel-bin | gzip",
    "  KERNEL_INITRAMFS := kernel-bin | lzma | " + BACKSLASH,
    TAB + "fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd | pad-to 64k",
    "  KERNEL_INITRAMFS_SUFFIX := -recovery.itb",
    "  IMAGES := sysupgrade.itb",
    "  IMAGE/sysupgrade.itb := append-kernel | " + BACKSLASH,
    TAB + "fit gzip $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb external-static-with-rootfs | " + BACKSLASH,
    TAB + "pad-rootfs | append-metadata",
    "endef",
    "TARGET_DEVICES += cmcc_rax3000m-emmc",
    "",
]

device_def = "\n".join(lines)

with open(FILOGIC, "a") as f:
    f.write(device_def)

# 验证
with open(FILOGIC, "r") as f:
    verify = f.read()

if MARKER in verify:
    print("SUCCESS: cmcc_rax3000m-emmc injected and verified in filogic.mk")
    # 清理 target metadata 缓存，强制 make defconfig 重新解析 filogic.mk 包含新设备
    if os.path.exists("tmp"):
        shutil.rmtree("tmp")
        print("Cleared openwrt/tmp metadata cache for re-parsing")
else:
    print("ERROR: injection failed!", file=sys.stderr)
    sys.exit(1)
