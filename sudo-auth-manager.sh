#!/bin/bash
# ============================================================================
# sudo-auth-manager.sh — 管理 macOS sudo 认证模式（指纹/密码切换）
# ============================================================================
# 下载后首次使用：
#   chmod +x sudo-auth-manager.sh
#   ./sudo-auth-manager.sh status
#
# 用法:
#   ./sudo-auth-manager.sh status         # 查看当前模式
#   ./sudo-auth-manager.sh touchid        # 指纹优先 + 密码回退（推荐）
#   ./sudo-auth-manager.sh password       # 仅密码（禁用指纹）
#   ./sudo-auth-manager.sh touchid-only   # 仅指纹（禁用密码回退）
# ============================================================================

SUDO_LOCAL="/etc/pam.d/sudo_local"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}⚠ 需要 sudo 权限，正在提权...${NC}"
        exec sudo "$0" "$@"
    fi
}

get_mode() {
    if [ ! -f "$SUDO_LOCAL" ] || [ ! -s "$SUDO_LOCAL" ]; then
        echo "password-only"
        return
    fi
    if grep -q "^auth\s\+sufficient\s\+pam_tid.so" "$SUDO_LOCAL" 2>/dev/null; then
        echo "touchid+password"
    elif grep -q "pam_tid.so" "$SUDO_LOCAL" 2>/dev/null; then
        echo "touchid-only"
    else
        echo "password-only"
    fi
}

mode_label() {
    case "$1" in
        touchid+password) echo "指纹优先 + 密码回退" ;;
        touchid-only)     echo "仅指纹（无密码回退）" ;;
        password-only)    echo "仅密码" ;;
    esac
}

mode_emoji() {
    case "$1" in
        touchid+password) echo "🔑🔐" ;;
        touchid-only)     echo "🔑" ;;
        password-only)    echo "🔐" ;;
    esac
}

status() {
    local mode=$(get_mode)
    echo -e "${CYAN}┌──────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}         🔐 sudo-auth-manager              ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "当前模式: $(mode_emoji "$mode") ${GREEN}$(mode_label "$mode")${NC}"
    echo ""
    echo -e "${YELLOW}📄 $SUDO_LOCAL${NC}"
    [ -f "$SUDO_LOCAL" ] && cat "$SUDO_LOCAL" || echo "  (文件不存在)"
    echo ""
    echo -e "${YELLOW}📄 /etc/pam.d/sudo${NC}"
    cat /etc/pam.d/sudo 2>/dev/null || echo "  (文件不存在)"
}

touchid() {
    check_sudo "$@"
    printf 'auth sufficient pam_tid.so\n' > "$SUDO_LOCAL"
    echo -e "${GREEN}✅ 已切换为「指纹优先 + 密码回退」模式${NC}"
    echo "指纹成功 → 直接通过 | 指纹失败 → 自动回退到密码"
}

password() {
    check_sudo "$@"
    printf '' > "$SUDO_LOCAL"
    echo -e "${GREEN}✅ 已切换为「仅密码」模式${NC}"
    echo "已禁用 Touch ID 指纹，sudo 只接受密码输入"
}

touchid_only() {
    check_sudo "$@"
    printf 'auth required pam_tid.so\n' > "$SUDO_LOCAL"
    echo -e "${GREEN}✅ 已切换为「仅指纹」模式${NC}"
    echo -e "${YELLOW}⚠ 警告: 指纹失败将无法 sudo，无密码回退！重启后首次登录前需小心${NC}"
}

case "${1:-help}" in
    status|st)
        status
        ;;
    touchid|touch|finger)
        touchid "$@"
        ;;
    password|pwd|pass)
        password "$@"
        ;;
    touchid-only|touchid_only|tid)
        touchid_only "$@"
        ;;
    help|--help|-h)
        echo "用法: ./sudo-auth-manager.sh <命令>"
        echo ""
        echo "命令:"
        echo "  status         查看当前 sudo 认证模式"
        echo "  touchid        指纹优先 + 密码回退 ${GREEN}(推荐)${NC}"
        echo "  password       仅密码（禁用 Touch ID）"
        echo "  touchid-only   仅指纹（禁用密码回退）${YELLOW}⚠${NC}"
        echo ""
        echo "配置文件: /etc/pam.d/sudo_local"
        echo "原理: pam_tid.so(sufficient)=指纹通过即过,失败走密码"
        echo "      pam_tid.so(required)=指纹必过,失败拒绝"
        echo "      sudo_local为空=仅密码"
        ;;
    *)
        echo -e "${RED}未知命令: $1${NC}"
        echo "可用: status | touchid | password | touchid-only"
        exit 1
        ;;
esac
