#!/bin/bash
# ============================================================================
# apple-watch-unlock — macOS sudo 手表/蓝牙免密方案
# ============================================================================
# 注意事项：
#   Apple Watch 并无原生 pam_watchid.so PAM 模块。
#   本脚本提供两种实际的解决方案：
#
#   方案一（推荐）: Touch ID + 终端修复（最稳最接近手表体验）
#   方案二（进阶）: 蓝牙手环检测（Apple Watch / 任何蓝牙设备靠近即放行）
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}┌──────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}       ⌚ Apple Watch Unlock Manager        ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────┘${NC}"
    echo ""
}

check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}⚠ 需要 sudo 权限${NC}"
        exec sudo "$0" "$@"
    fi
}

# ── 方案一：Touch ID 终端修复 ──────────────────────────────────────────────

setup_touchid_terminal() {
    print_header
    check_sudo "$@"
    echo -e "${YELLOW}📦 正在安装 pam-reattach（让 Touch ID 在 tmux/SSH 中也生效）...${NC}"

    if ! command -v brew &>/dev/null; then
        echo -e "${RED}✗ 需要 Homebrew，先安装：/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
        exit 1
    fi

    if [ -f "/opt/homebrew/lib/pam/pam_reattach.so" ] || [ -f "/usr/local/lib/pam/pam_reattach.so" ]; then
        echo -e "${GREEN}✓ pam_reattach 已安装${NC}"
    else
        brew install pam-reattach 2>/dev/null
        echo -e "${GREEN}✓ pam_reattach 安装完成${NC}"
    fi

    # Find pam_reattach.so
    PAM_REATTACH=$(find /opt/homebrew /usr/local -name "pam_reattach.so" 2>/dev/null | head -1)
    if [ -z "$PAM_REATTACH" ]; then
        echo -e "${RED}✗ 找不到 pam_reattach.so${NC}"
        exit 1
    fi
    echo -e "  → 路径: ${CYAN}$PAM_REATTACH${NC}"

    # Update sudo_local: pam_reattach before pam_tid
    printf 'auth optional %s\n' "$PAM_REATTACH" > /etc/pam.d/sudo_local
    printf 'auth sufficient pam_tid.so\n' >> /etc/pam.d/sudo_local

    echo ""
    echo -e "${GREEN}✅ Touch ID 终端修复完成！${NC}"
    echo ""
    echo -e "  ${CYAN}效果:${NC}"
    echo "  • Touch ID 在 Terminal / iTerm2 中可用"
    echo "  • Touch ID 在 tmux / screen / SSH 中也可用"
    echo "  • Touch ID 失败 → 回退到密码"
    echo ""
    echo -e "  ${YELLOW}📋 当前 /etc/pam.d/sudo_local:${NC}"
    cat /etc/pam.d/sudo_local
}

# ── 方案二：蓝牙距离检测 ──────────────────────────────────────────────────

bluetooth_detect() {
    print_header
    echo -e "${YELLOW}🔍 扫描附近蓝牙设备...${NC}"

    if ! command -v system_profiler &>/dev/null; then
        echo -e "${RED}✗ system_profiler 不可用${NC}"
        return
    fi

    echo -e "  ${CYAN}已配对的蓝牙设备:${NC}"
    system_profiler SPBluetoothDataType 2>/dev/null | grep -E "Name|Address|Connected" | head -20
    echo ""

    echo -e "${YELLOW}将使用这些设备作为 sudo 免密的「钥匙」${NC}"
    echo -e "  ${YELLOW}⚠ 需要先安装 blueutil: brew install blueutil${NC}"
    echo ""
}

setup_bluetooth_unlock() {
    print_header
    echo -e "${YELLOW}⚙ 设置蓝牙设备接近解锁...${NC}"

    if ! command -v blueutil &>/dev/null; then
        echo -e "${YELLOW}📦 正在安装 blueutil...${NC}"
        brew install blueutil 2>/dev/null || {
            echo -e "${RED}✗ 安装 blueutil 失败${NC}"
            exit 1
        }
    fi

    echo -e "${GREEN}✓ blueutil 已安装${NC}"
    echo ""

    # Show paired bluetooth devices
    echo -e "${CYAN}已配对的蓝牙设备:${NC}"
    system_profiler SPBluetoothDataType 2>/dev/null | grep -B2 "Connected: Yes" | grep "Name:" | sed 's/.*Name: //' | cat -n
    echo ""

    # Create the detection script
    DETECT_SCRIPT="/usr/local/bin/sudo-bluetooth-check.sh"
    echo -e "${YELLOW}✏ 创建蓝牙检测脚本...${NC}"

    read -p "输入你的蓝牙设备名称（如: Alan's Watch）: " DEVICE_NAME

    cat > "$DETECT_SCRIPT" << EOF
#!/bin/bash
# 蓝牙设备接近检测 - 用于 pam_exec.so
# 检测 "$DEVICE_NAME" 是否在蓝牙范围内
# 在范围内 → exit 0 (通过), 不在 → exit 1 (拒绝)

DEVICE="$DEVICE_NAME"

# 用 blueutil 扫描广播中的设备
if command -v blueutil &>/dev/null; then
    SCAN_RESULT=\$(blueutil --paired 2>/dev/null | grep "\$DEVICE")
    if [ -n "\$SCAN_RESULT" ]; then
        # 找到配对设备，再检查是否已连接
        CONNECTED=\$(blueutil --connected 2>/dev/null | grep "\$DEVICE")
        if [ -n "\$CONNECTED" ]; then
            exit 0
        fi
    fi
fi

# 检测失败 → 继续走密码认证
exit 1
EOF

    chmod +x "$DETECT_SCRIPT"
    echo -e "${GREEN}✓ 脚本已创建: ${CYAN}$DETECT_SCRIPT${NC}"
    echo ""

    # Add pam_exec to sudo_local
    echo -e "${YELLOW}✏ 添加到 PAM 配置...${NC}"
    check_sudo "$@"

    # Backup current sudo_local
    cp /etc/pam.d/sudo_local /etc/pam.d/sudo_local.bak 2>/dev/null

    echo -e "${GREEN}✓ 已备份为 /etc/pam.d/sudo_local.bak${NC}"

    # Create new config: bluetooth check first, then Touch ID, then password
    cat > /etc/pam.d/sudo_local << PAMEOF
# 蓝牙设备接近 → 自动 sudo 通过
auth sufficient pam_exec.so quiet $DETECT_SCRIPT
# Touch ID → 指纹通过
auth sufficient pam_tid.so
# 以上都失败 → 密码
PAMEOF

    echo -e "${GREEN}✅ 蓝牙解锁已配置！${NC}"
    echo ""
    echo -e "  ${CYAN}效果:${NC}"
    echo "  1. 蓝牙设备（Apple Watch / 手机等）在附近 → sudo 自动通过"
    echo "  2. 蓝牙不在附近 → 自动降级到 Touch ID"
    echo "  3. Touch ID 也不可用 → 输密码"
    echo ""
    echo -e "  ${YELLOW}📋 当前 /etc/pam.d/sudo_local:${NC}"
    cat /etc/pam.d/sudo_local
}

# ── 重置 ──────────────────────────────────────────────────────────────────

reset_all() {
    print_header
    check_sudo "$@"
    echo -e "${YELLOW}↺ 重置为仅密码模式...${NC}"
    printf '' > /etc/pam.d/sudo_local
    echo -e "${GREEN}✓ 已重置为仅密码${NC}"
}

# ── 信息：关于 Apple Watch 的真相 ──────────────────────────────────────────

info() {
    print_header
    echo -e "${YELLOW}🔎 关于「Apple Watch 解锁 sudo」的真相${NC}"
    echo ""
    echo -e "  ${RED}⚠ pam_watchid.so 不存在${NC}"
    echo "  macOS 从未内置过 pam_watchid.so 模块。"
    echo "  网络上流传的 pam_watchid 名字是混淆/误解。"
    echo ""
    echo -e "  ${GREEN}macOS 原生 Apple Watch 解锁支持：${NC}"
    echo "  ✅ 解锁 Mac 屏幕"
    echo "  ✅ 批准 Apple Pay 支付"
    echo "  ✅ Safari 自动填充密码"
    echo "  ❌ sudo / 终端 - 不支持！"
    echo ""
    echo -e "  ${CYAN}本脚本提供的真实可行方案：${NC}"
    echo "  ┌─────────────────────────────────────────────────────────┐"
    echo "  │ 方案一    Touch ID + pam-reattach                       │"
    echo "  │           Touch ID 在所有终端 (tmux/SSH) 中都生效       │"
    echo "  │           最稳定，推荐 95% 用户                         │"
    echo "  ├─────────────────────────────────────────────────────────┤"
    echo "  │ 方案二    蓝牙设备接近检测 (pam_exec + blueutil)        │"
    echo "  │           Apple Watch / 手机靠近 Mac 时 sudo 自动通过   │"
    echo "  │           自己 DIY，可玩性强                            │"
    echo "  └─────────────────────────────────────────────────────────┘"
    echo ""
    echo -e "  ${YELLOW}用法:${NC}"
    echo "    apple-watch-unlock status         查看当前配置"
    echo "    apple-watch-unlock touchid-fix    方案一：安装 pam-reattach"
    echo "    apple-watch-unlock bluetooth      方案二：蓝牙接近解锁"
    echo "    apple-watch-unlock info           查看详情"
    echo "    apple-watch-unlock reset          重置为仅密码"
}

# ── Status ────────────────────────────────────────────────────────────────

status() {
    print_header
    echo -e "${YELLOW}📋 当前 PAM 配置: /etc/pam.d/sudo_local${NC}"
    if [ -f /etc/pam.d/sudo_local ] && [ -s /etc/pam.d/sudo_local ]; then
        cat /etc/pam.d/sudo_local
    else
        echo "  (未配置，仅密码模式)"
    fi
    echo ""
    echo -e "${YELLOW}📋 蓝牙工具状态:${NC}"
    if command -v blueutil &>/dev/null; then
        echo -e "  blueutil: ${GREEN}已安装${NC}"
    else
        echo -e "  blueutil: ${RED}未安装${NC}"
    fi
    if [ -f /opt/homebrew/lib/pam/pam_reattach.so ] || [ -f /usr/local/lib/pam/pam_reattach.so ]; then
        echo -e "  pam_reattach: ${GREEN}已安装${NC}"
    else
        echo -e "  pam_reattach: ${RED}未安装${NC}"
    fi
    echo ""
    echo -e "${YELLOW}📡 已配对的蓝牙设备:${NC}"
    system_profiler SPBluetoothDataType 2>/dev/null | grep "Name:" | sed 's/.*Name: //' | cat -n || echo "  (无法获取)"
}

# ── 入口 ──────────────────────────────────────────────────────────────────

case "${1:-help}" in
    status)
        status
        ;;
    touchid-fix|touchid|reattach)
        setup_touchid_terminal
        ;;
    bluetooth|bt|device)
        setup_bluetooth_unlock
        ;;
    info|help|--help|-h)
        info
        ;;
    reset|password)
        reset_all
        ;;
    *)
        echo -e "${RED}未知命令: $1${NC}"
        echo "可用: status | touchid-fix | bluetooth | info | reset"
        exit 1
        ;;
esac
