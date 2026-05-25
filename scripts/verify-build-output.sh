#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-${OUT_DIR:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/../kernel-out"}}"

echo "==> Verifying build outputs in $OUT_DIR..."

IMAGE_FILE="$(find -L "$OUT_DIR" -type f -name Image | head -n 1 || true)"
CONFIG_FILE="$(find -L "$OUT_DIR" -type f \( -name '.config' -o -name '*defconfig*' \) | head -n 1 || true)"

if [[ -z "$IMAGE_FILE" ]]; then
  echo "ERROR: No Image artifact found under $OUT_DIR" >&2
  exit 1
fi

echo "SUCCESS: Found Kernel Image: $IMAGE_FILE"
echo "Image size: $(ls -lh "$IMAGE_FILE" | awk '{print $5}')"

if [[ -n "$CONFIG_FILE" ]]; then
  echo ""
  echo "==> Feature verification:"
  echo "----------------------------------------"

  check_config() {
    local key="$1"
    local label="$2"
    local val
    val=$(grep -E "^${key}=" "$CONFIG_FILE" 2>/dev/null || echo "NOT SET")
    if [[ "$val" == "NOT SET" ]] || [[ "$val" == "# ${key} is not set" ]]; then
      echo "  [MISSING] $label ($key)"
    else
      echo "  [ENABLED] $label -> $val"
    fi
  }

  echo "--- KernelSU ---"
  check_config "CONFIG_KSU" "KernelSU"

  echo "--- SUSFS 2.0 ---"
  check_config "CONFIG_KSU_SUSFS" "SUSFS Core"
  check_config "CONFIG_KSU_SUSFS_SUS_PATH" "SUS Path"
  check_config "CONFIG_KSU_SUSFS_SUS_MOUNT" "SUS Mount"
  check_config "CONFIG_KSU_SUSFS_SUS_KSTAT" "SUS KStat"
  check_config "CONFIG_KSU_SUSFS_SPOOF_UNAME" "Spoof Uname"
  check_config "CONFIG_KSU_SUSFS_OPEN_REDIRECT" "Open Redirect"
  check_config "CONFIG_KSU_SUSFS_SUS_MAP" "SUS Map"
  check_config "CONFIG_KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS" "Hide Symbols"
  check_config "CONFIG_KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG" "Spoof Cmdline"
  check_config "CONFIG_KSU_SUSFS_ENABLE_LOG" "SUSFS Logging"

  echo "--- IPSet / Netfilter ---"
  check_config "CONFIG_IP_SET" "IP Set Core"
  check_config "CONFIG_NETFILTER_XT_SET" "XT Set Match"
  check_config "CONFIG_NETFILTER_XT_MATCH_ADDRTYPE" "XT Addrtype Match"
  check_config "CONFIG_IP_SET_HASH_IP" "Hash IP"
  check_config "CONFIG_IP_SET_HASH_NET" "Hash Net"
  check_config "CONFIG_IP_SET_LIST_SET" "List Set"

  echo "--- BBRv1 TCP Congestion Control ---"
  check_config "CONFIG_TCP_CONG_BBR" "BBR"
  check_config "CONFIG_DEFAULT_BBR" "Default BBR"
  check_config "CONFIG_DEFAULT_TCP_CONG" "Default TCP Congestion"

  echo "--- Baseband Guard ---"
  check_config "CONFIG_BBG" "Baseband Guard"

  echo "--- Additional TCP Congestion ---"
  check_config "CONFIG_TCP_CONG_ADVANCED" "Advanced TCP Congestion"
  check_config "CONFIG_TCP_CONG_CUBIC" "CUBIC"
  check_config "CONFIG_TCP_CONG_BIC" "BIC"
  check_config "CONFIG_TCP_CONG_WESTWOOD" "Westwood"
  check_config "CONFIG_TCP_CONG_HTCP" "HTCP"
  check_config "CONFIG_NET_SCH_FQ" "FQ Qdisc"
  check_config "CONFIG_NET_SCH_FQ_CODEL" "FQ Codel Qdisc"

  echo "--- Netfilter Additional ---"
  check_config "CONFIG_NETFILTER_XT_MATCH_RECENT" "XT Recent Match"
  check_config "CONFIG_NETFILTER_XT_TARGET_LOG" "XT Log Target"
  check_config "CONFIG_IP6_NF_NAT" "IPv6 NAT"
  check_config "CONFIG_IP6_NF_TARGET_MASQUERADE" "IPv6 MASQUERADE"

  echo "----------------------------------------"
else
  echo "WARNING: No config file found under $OUT_DIR"
fi

echo "==> Verification complete."
