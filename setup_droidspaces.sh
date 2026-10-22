#!/bin/bash
# setup_droidspaces.sh v2 — kABI-safe Droidspaces для crDroid sm8735 (CAF 6.6)
set -e
OUT_DIR=${1:-"out"}
SCHED_H="include/linux/sched.h"

echo "[*] Droidspaces: правим task_struct без поломки kABI..."

python3 - "$SCHED_H" <<'EOF'
import re, sys
p = sys.argv[1]
s = open(p).read()

# Hunk 1: убираем sysvsem/sysvshm из основного тела struct task_struct
old1 = re.compile(r'#ifdef CONFIG_SYSVIPC\n(\s*)struct sysv_sem(\s+)sysvsem;\n(\s*)struct sysv_shm(\s+)sysvshm;\n#endif')
s, n1 = old1.subn(lambda m: f'#ifdef CONFIG_SYSVIPC\n{m.group(1)}// struct sysv_sem{m.group(2)}sysvsem;\n{m.group(3)}// struct sysv_shm{m.group(4)}sysvshm;\n#endif', s, count=1)
if n1 != 1:
    sys.exit("[!] Hunk 1 (sysvsem/sysvshm) не найден в sched.h!")

# Hunk 2: суём sysvsem/sysvshm в KABI-паддинг (слоты 3,4,5).
# Раскладка task_struct не меняется ни на байт -> стоковые модули живы.
old2 = re.compile(r'\tANDROID_KABI_RESERVE\(3\);\n\tANDROID_KABI_RESERVE\(4\);\n\tANDROID_KABI_RESERVE\(5\);\n\tANDROID_KABI_RESERVE\(6\);\n')
new2 = ('#ifdef CONFIG_SYSVIPC\n'
        '\tANDROID_KABI_USE(3, struct sysv_sem sysvsem);\n'
        '\t_ANDROID_KABI_REPLACE(ANDROID_KABI_RESERVE(4); ANDROID_KABI_RESERVE(5), struct sysv_shm sysvshm);\n'
        '#else\n'
        '\tANDROID_KABI_RESERVE(3);\n'
        '\tANDROID_KABI_RESERVE(4);\n'
        '\tANDROID_KABI_RESERVE(5);\n'
        '#endif\n'
        '\tANDROID_KABI_RESERVE(6);\n')
s, n2 = old2.subn(new2, s, count=1)
if n2 != 1:
    sys.exit("[!] Hunk 2 (KABI reserves 3-6) не найден в sched.h!")

open(p, 'w').write(s)
print("[+] sched.h пропатчен: sysvsem/sysvshm в KABI-паддинге, раскладка не тронута")
EOF

echo "[*] Включаем флаги Droidspaces в $OUT_DIR/.config..."
CFG="$OUT_DIR/.config"
for c in NAMESPACES PID_NS IPC_NS SYSVIPC POSIX_MQUEUE DEVTMPFS USER_NS \
         NETFILTER NETFILTER_XT_MATCH_ADDRTYPE NETFILTER_XT_TARGET_REJECT \
         NETFILTER_XT_TARGET_LOG NETFILTER_XT_MATCH_RECENT IP_SET IP_SET_HASH_IP \
         IP_SET_HASH_NET NETFILTER_XT_SET TMPFS_POSIX_ACL TMPFS_XATTR; do
    scripts/config --file "$CFG" -e CONFIG_$c
done
echo "[+] Droidspaces готов"
