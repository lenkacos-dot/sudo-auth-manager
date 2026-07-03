#!/bin/bash
# ============================================================================
# sudo-auth-manager — 设置 sudo 指纹优先 + 密码回退
# ============================================================================
# 用法:
#   sudo-auth-manager status         # 查看当前模式
#   sudo-auth-manager apply          # 设置指纹优先 + 密码回退
# ============================================================================

SUDO_LOCAL="/etc/pam.d/sudo_local"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        exec sudo "$0" "$@"
    fi
}

status() {
    echo -e "${CYAN}┌──────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}         🔐 sudo-auth-manager              ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────┘${NC}"
    echo ""
    if [ -f "$SUDO_LOCAL" ] && grep -q "^auth\s\+sufficient\s\+pam_tid.so" "$SUDO_LOCAL" 2>/dev/null; then
        echo -e "${GREEN}✅ 当前模式：指纹优先 + 密码回退${NC}"
    elif [ -f "$SUDO_LOCAL" ] && grep -q "pam_tid.so" "$SUDO_LOCAL" 2>/dev/null; then
        echo -e "${YELLOW}⚠ 当前：其他 Touch ID 配置${NC}"
    else
        echo -e "${YELLOW}⚠ 当前：仅密码模式（未启用 Touch ID）${NC}"
    fi
    echo ""
    echo -e "${YELLOW}📄 $SUDO_LOCAL${NC}"
    cat "$SUDO_LOCAL" 2>/dev/null || echo "  (文件不存在)"
}

apply() {
    check_sudo "$@"
    printf 'auth sufficient pam_tid.so\n' > "$SUDO_LOCAL"
    echo -e "${GREEN}✅ 已设置：指纹优先 + 密码回退${NC}"
    echo "  • 指纹成功 → 直接通过 sudo"
    echo "  • 指纹失败 → 自动回退到输入密码"
    echo "  • 指纹不可用（如刚重启未解锁）→ 直接输密码"
}

case "${1:-status}" in
    status|st)
        status
        ;;
    apply|set|touchid)
        apply "$@"
        ;;
    help|--help|-h)
        echo "用法: sudo-auth-manager <命令>"
        echo ""
        echo "命令:"
        echo "  status         查看当前 sudo 认证状态"
        echo "  apply          设置为: 指纹优先 + 密码回退"
        echo ""
        echo "配置文件: /etc/pam.d/sudo_local"
        echo "原理: auth sufficient pam_tid.so"
        echo "      sufficient = 成功即通过, 失败继续下一认证（回退密码）"
        ;;
    *)
        echo -e "${RED}未知命令: $1${NC}"
        echo "可用: status | apply | help"
        exit 1
        ;;
esac
