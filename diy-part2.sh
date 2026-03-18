#!/bin/bash
set -e  # 遇到错误立即退出

git clone https://github.com/chenmozhijin/luci-app-socat.git package/luci-app-socat

# 修改默认 IP
sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# ==========================================
# 修改 ath79 平台相关文件（WR703N 已移至 ath79）
# ==========================================

# 1. 修改 tiny-tp-link.mk
echo "=== 修改 tiny-tp-link.mk ==="
grep "DEVICE_TL-WR703N" target/linux/ath79/image/tiny-tp-link.mk -A 10 || true
sed -i 's/IMAGE_SIZE := [0-9]*k/IMAGE_SIZE := 8128k/g' target/linux/ath79/image/tiny-tp-link.mk

# 2. 修改 Makefile（4Mlzma → 8Mlzma）
echo "=== 修改 Makefile ==="
sed -i 's/4Mlzma/8Mlzma/g' target/linux/ath79/image/Makefile

# 3. 修改 mktplinkfw.c（如果存在）
echo "=== 修改 mktplinkfw.c ==="
if [ -f tools/firmware-utils/src/mktplinkfw.c ]; then
    sed -i 's/4Mlzma/8Mlzma/g' tools/firmware-utils/src/mktplinkfw.c
    sed -i '/\.id.*=.*"8Mlzma"/,/\.rootfs_ofs/{s/\.fw_max_len.*=.*0x3c0000/.fw_max_len\t= 0x7c0000/}' tools/firmware-utils/src/mktplinkfw.c
fi

# 4. 修改 common-tp-link.mk
echo "=== 修改 common-tp-link.mk ==="
sed -i 's/TPLINK_FLASHLAYOUT := 4Mlzma/TPLINK_FLASHLAYOUT := 8Mlzma/g' target/linux/ath79/image/common-tp-link.mk

# ==========================================
# 验证 .config 配置（可选）
# ==========================================
echo "=== 验证 .config 软件包配置 ==="
grep "CONFIG_PACKAGE_socat" .config || true
grep "CONFIG_PACKAGE_luci-i18n-base-zh-cn" .config || true
grep "CONFIG_TARGET_ath79" .config || echo "警告：未找到 ath79 目标配置，请检查 .config"

echo "diy-part2.sh 执行完成"
