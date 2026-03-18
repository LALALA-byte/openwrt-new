#!/bin/bash
set -e  # 遇到错误立即退出

# 克隆 luci-app-socat（第三方）
git clone https://github.com/chenmozhijin/luci-app-socat.git package/luci-app-socat

# 修改默认 IP 为 192.168.2.1
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# ========== 修改 Flash 大小为 8M（WR703N 专用）==========
echo "=== 修改 tiny-tp-link.mk ==="
# 确认文件存在
if [ -f target/linux/ar71xx/image/tiny-tp-link.mk ]; then
    sed -i 's/IMAGE_SIZE := [0-9]*k/IMAGE_SIZE := 8128k/g' target/linux/ar71xx/image/tiny-tp-link.mk
    grep "IMAGE_SIZE" target/linux/ar71xx/image/tiny-tp-link.mk | head -5
else
    echo "Error: target/linux/ar71xx/image/tiny-tp-link.mk not found!"
    exit 1
fi

echo "=== 修改 Makefile ==="
sed -i 's/4Mlzma/8Mlzma/g' target/linux/ar71xx/image/Makefile
grep "8Mlzma" target/linux/ar71xx/image/Makefile | head -3

echo "=== 修改 mktplinkfw.c ==="
sed -i 's/4Mlzma/8Mlzma/g' tools/firmware-utils/src/mktplinkfw.c
# 修正 8Mlzma 的 fw_max_len（从 0x3c0000 改为 0x7c0000）
sed -i '/\.id.*=.*"8Mlzma"/,/\.rootfs_ofs/{s/\.fw_max_len.*=.*0x3c0000/.fw_max_len\t= 0x7c0000/}' tools/firmware-utils/src/mktplinkfw.c
grep -A5 '"8Mlzma"' tools/firmware-utils/src/mktplinkfw.c | head -10

echo "=== 修改 common-tp-link.mk ==="
sed -i 's/TPLINK_FLASHLAYOUT := 4Mlzma/TPLINK_FLASHLAYOUT := 8Mlzma/g' target/linux/ar71xx/image/common-tp-link.mk
grep "TPLINK_FLASHLAYOUT" target/linux/ar71xx/image/common-tp-link.mk

echo "=== 验证 .config 软件包配置 ==="
grep "CONFIG_PACKAGE_socat" .config || echo "Warning: socat not enabled in .config"
grep "CONFIG_PACKAGE_luci-app-socat" .config || echo "Warning: luci-app-socat not enabled in .config"
grep "CONFIG_TARGET_ar71xx" .config || echo "Warning: ar71xx target not set"

# 输出 diffconfig 用于调试
echo "=== diffconfig 输出（前 50 行）==="
./scripts/diffconfig.sh 2>/dev/null | head -50
