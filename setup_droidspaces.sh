#!/bin/bash
# setup_droidspaces.sh - Патч для поддержки LXC/Namespaces с сохранением kABI
OUT_DIR=${1:-"out"}

echo "[*] Применяем Droidspaces kABI-патч..."

# Качаем проверенный kABI-патч для ядер ниже 6.12
PATCH_NAME="001.GKI-below-6.12-fix_sysvipc_kabi_3_4_5.patch"
PATCH_URL="https://raw.githubusercontent.com/ravindu644/Droidspaces-OSS/main/Documentation/resources/kernel-patches/GKI/below-kernel-6.12/$PATCH_NAME"

curl -sLO "$PATCH_URL"

if patch -p1 <"$PATCH_NAME"; then
    echo "[+] Патч успешно применен"
    rm -f "$PATCH_NAME"
else
    echo "[-] Ошибка наложения патча!"
    rm -f "$PATCH_NAME"
    exit 1
fi

# Включаем обязательные флаги в .config
if [ -f"$OUT_DIR/.config" ]; then
    echo "[*] Включаем namespaces..."
    scripts/config --file "$OUT_DIR/.config" -e CONFIG_SYSVIPC
    scripts/config --file "$OUT_DIR/.config" -e CONFIG_POSIX_MQUEUE
    scripts/config --file "$OUT_DIR/.config" -e CONFIG_IPC_NS
    scripts/config --file "$OUT_DIR/.config" -e CONFIG_PID_NS
    scripts/config --file "$OUT_DIR/.config" -e CONFIG_USER_NS
    scripts/config --file "$OUT_DIR/.config" -e CONFIG_DEVTMPFS
    scripts/config --file "$OUT_DIR/.config" -e CONFIG_NAMESPACES
    scripts/config --file "$OUT_DIR/.config" -e CONFIG_NETFILTER
    scripts/config --file "$OUT_DIR/.config" -e CONFIG_NETFILTER_XT_MATCH_ADDRTYPE
    scripts/config --file "$OUT_DIR/.config" -e CONFIG_TMPFS_POSIX_ACL
    scripts/config --file "$OUT_DIR/.config" -e CONFIG_TMPFS_XATTR
    echo "[+] Флаги Droidspaces добавлены"
else
    echo "[-] .config не найден в $OUT_DIR!"
fi
