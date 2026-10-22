#!/usr/bin/env bash
set -e

echo "=== [1/3] Применение kABI-патча для SYSVIPC (Linux 6.6) ==="
# Скачиваем официальный патч от Droidspaces, который прячет sysvipc в ANDROID_KABI_RESERVE(6, 7, 8)
PATCH_URL="https://raw.githubusercontent.com/ravindu644/Droidspaces-OSS/main/Documentation/resources/kernel-patches/GKI/below-kernel-6.12/001.GKI-below-6.12-fix_sysvipc_kABI_6_7_8.patch"

curl -LSs "$PATCH_URL" -o sysvipc_kabi.patch

# Проверяем, ложится ли патч чисто
if patch -p1 --dry-run < sysvipc_kabi.patch > /dev/null 2>&1; then
    patch -p1 < sysvipc_kabi.patch
    echo "[+] Патч 6_7_8 успешно применён к include/linux/sched.h!"
else
    echo "[!] Резервы 6_7_8 заняты или изменён контекст, пробуем резервы 3_4_5..."
    curl -LSs "https://raw.githubusercontent.com/ravindu644/Droidspaces-OSS/main/Documentation/resources/kernel-patches/GKI/below-kernel-6.12/001.GKI-below-6.12-fix_sysvipc_kABI_3_4_5.patch" -o sysvipc_kabi.patch
    patch -p1 < sysvipc_kabi.patch
    echo "[+] Патч 3_4_5 успешно применён!"
fi
rm -f sysvipc_kabi.patch

echo "=== [2/3] Интеграция ReSukiSU ==="
curl -LSs "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh" | bash -s main

echo "=== [3/3] Добавление флагов Droidspaces v7.0.0 и ReSukiSU ==="
# Записываем флаги во все базовые конфиги, чтобы они гарантированно попали в финальный .config
for CFG in arch/arm64/configs/gki_defconfig arch/arm64/configs/consolidate.fragment; do
    if [ -f "$CFG" ]; then
        echo "[*] Обновляем $CFG..."
        cat << 'EOF' >> "$CFG"

# Droidspaces v7.0.0 Required Flags (kABI-safe)
CONFIG_NAMESPACES=y
CONFIG_UTS_NS=y
CONFIG_TIME_NS=y
CONFIG_IPC_NS=y
CONFIG_USER_NS=y
CONFIG_PID_NS=y
CONFIG_NET_NS=y
CONFIG_SYSVIPC=y
CONFIG_POSIX_MQUEUE=y
CONFIG_DEVTMPFS=y
CONFIG_CGROUPS=y
CONFIG_MEMCG=y
CONFIG_SECCOMP=y
CONFIG_NETFILTER_XT_MATCH_ADDRTYPE=y

# ReSukiSU Support
CONFIG_KSU=y
CONFIG_KPROBES=y
CONFIG_HAVE_KPROBES=y
CONFIG_KPROBE_EVENTS=y
EOF
    fi
done

echo "[+] Готово! Исходники пропатчены под Droidspaces + ReSukiSU."
