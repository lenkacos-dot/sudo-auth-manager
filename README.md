# 🔐 sudo-auth-manager — macOS sudo 认证模式切换工具

一键在 **Touch ID 指纹** 和 **传统密码** 之间切换 sudo 认证方式。

---

## 📥 使用方式

### 方式一：直接运行（无需安装）

```bash
chmod +x sudo-auth-manager.sh
./sudo-auth-manager.sh status
```

### 方式二：装进系统（可选）

```bash
sudo cp sudo-auth-manager.sh /usr/local/bin/sudo-auth-manager
sudo chmod +x /usr/local/bin/sudo-auth-manager
# 之后可以直接:
sudo-auth-manager status
```

---

## 🧭 命令

| 命令 | 效果 | 说明 |
|------|------|------|
| `status` | 查看当前模式 | 显示配置文件内容 |
| `touchid` | 指纹优先 + 密码回退 | 先试指纹，失败→输密码 ✅ **推荐** |
| `password` | 仅密码 | 禁用指纹，回到传统密码 |
| `touchid-only` | 仅指纹 | ⚠ 指纹失败就拒绝，密码不可用 |

---

## ⚙️ 原理

通过修改 `/etc/pam.d/sudo_local` 控制 macOS 的 PAM 认证策略：

```
# 指纹优先 + 密码回退（推荐）
auth sufficient pam_tid.so

# 仅指纹（无密码回退）⚠ 危险
auth required pam_tid.so

# 仅密码（文件为空）
```

PAM 关键词含义：
- **sufficient** → 成功即通过，失败则继续下一认证（回退到密码）
- **required** → 必须成功，失败则直接拒绝

主文件 `/etc/pam.d/sudo` 始终保留 `pam_opendirectory.so`（密码认证）作为底层保障。

---

## 🔒 安全说明

- 修改的是系统级 PAM 配置文件，需要 `sudo` 权限
- 仅影响本机，不会外传任何数据
- `touchid` 模式（指纹+密码回退）是最安全的折中方案
- `touchid-only` 模式风险较高：重启后首次登录前、Touch ID 硬件异常时都会锁死 sudo

---

## 🍎 系统要求

- macOS（支持 Touch ID 的机型：2016 年后的 MacBook Pro / MacBook Air / iMac Pro / Mac mini / Mac Studio / Mac Pro）
- 系统版本不限（PAM 配置兼容所有现代 macOS 版本）

---

**文件列表：**
```
sudo-auth-manager.sh   ← 主脚本（可执行）
README.md              ← 本文档
```

v1.0 | Made with ❤️ for macOS users
