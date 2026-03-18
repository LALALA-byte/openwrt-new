

set -e

git clone https://github.com/chenmozhijin/luci-app-socat.git package/luci-app-socat

sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate

# ==========================================
# diy-part2.sh - TL-WR703N 8MB 固件定制
# ==========================================

# 注意：不要执行 make defconfig，会覆盖 .config 配置！

# ==========================================
# 1. 修改 tiny-tp-link.mk（IMAGE_SIZE）
# ==========================================
echo "=== 修改 tiny-tp-link.mk ==="

# 先查看原始内容
grep "DEVICE TL-WR703N" target/linux/ar71xx/image/tiny-tp-link.mk -A 10

# 修改 IMAGE_SIZE 为 8128k
sed -i 's/IMAGE_SIZE := [0-9]*k/IMAGE_SIZE := 8128k/g' target/linux/ar71xx/image/tiny-tp-link.mk

# 验证修改
grep "IMAGE_SIZE" target/linux/ar71xx/image/tiny-tp-link.mk | head -5

# ==========================================
# 2. 修改 Makefile（4Mlzma → 8Mlzma）
# ==========================================
echo "=== 修改 Makefile ==="
sed -i 's/4Mlzma/8Mlzma/g' target/linux/ar71xx/image/Makefile
grep "8Mlzma" target/linux/ar71xx/image/Makefile | head -3

# ==========================================
# 3. 修改 mktplinkfw.c（添加 8M layout）
# ==========================================
echo "=== 修改 mktplinkfw.c ==="

# 修改 4Mlzma 为 8Mlzma
sed -i 's/4Mlzma/8Mlzma/g' tools/firmware-utils/src/mktplinkfw.c

# 修正 8Mlzma 的 fw_max_len（从 0x3c0000 改为 0x7c0000）
sed -i '/\.id.*=.*"8Mlzma"/,/\.rootfs_ofs/{s/\.fw_max_len.*=.*0x3c0000/.fw_max_len\t= 0x7c0000/}' tools/firmware-utils/src/mktplinkfw.c

# 验证修改
grep -A5 '"8Mlzma"' tools/firmware-utils/src/mktplinkfw.c | head -10

# ==========================================
# 4. 修改 common-tp-link.mk
# ==========================================
echo "=== 修改 common-tp-link.mk ==="
sed -i 's/TPLINK_FLASHLAYOUT := 4Mlzma/TPLINK_FLASHLAYOUT := 8Mlzma/g' target/linux/ar71xx/image/common-tp-link.mk
grep "TPLINK_FLASHLAYOUT" target/linux/ar71xx/image/common-tp-link.mk

# ==========================================
# 5. 验证 .config 配置（关键！）
# ==========================================
echo "=== 验证 .config 软件包配置 ==="
grep "CONFIG_PACKAGE_socat" .config
grep "CONFIG_PACKAGE_luci-i18n-base-zh-cn" .config
grep "CONFIG_TARGET_ar71xx" .config

# ==========================================
# 6. 输出 diffconfig（调试用）
# ==========================================
echo "=== diffconfig 输出 ==="
./scripts/diffconfig.sh 2>/dev/null | head -50

