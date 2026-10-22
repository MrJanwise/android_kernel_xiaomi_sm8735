#!/usr/bin/env bash
set -e

echo "=== [1/3] Скачивание и запуск setup_droidspaces.sh из konoha-kernel-gki ==="
curl -fLSs "https://raw.githubusercontent.com/onyx-oss/konoha-kernel-gki/gki/setup_droidspaces.sh" -o konoha_droidspaces.sh
chmod +x konoha_droidspaces.sh
./konoha_droidspaces.sh
rm -f konoha_droidspaces.sh

echo "=== [2/3] Интеграция ReSukiSU ==="
curl -fLSs "https://raw.githubusercontent.com/ReSukiSU/ReSukiSU/main/kernel/setup.sh" | bash -s main

echo "=== [3/3] Добавление флагов в базовые конфиги ==="
for CFG in arch/arm64/configs/gki_defconfig arch/arm64/configs/consolidate.fragment; do
    if [ -f "$CFG" ]; then
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

echo "[+] Все патчи успешно применены!"
