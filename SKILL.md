---
name: "sudo-touchid"
description: "🖐️ macOS sudo 指纹认证 — 一行配置告别反复输密码，指纹优先+密码回退"
version: "1.0.0"
author: "alan"
---

# 🖐️ sudo-touchid

macOS sudo 指纹认证技能——改一行配置，手指放上去就通过。

## 效果

- 刷指纹 → sudo 直接通过 ✅
- 指纹失败 → 自动回退到密码
- 刚重启未解锁 → 直接输密码，不耽误事

零第三方依赖，纯改系统一行配置，安全性和以前一模一样。

## 用法

```bash
sudo-touchid status    # 查看当前认证状态
sudo-touchid apply     # 设置指纹优先 + 密码回退
```

## 原理

修改 `/etc/pam.d/sudo_local`，写入一行 PAM 规则：

```
auth sufficient pam_tid.so
```

- **sufficient** = Touch ID 成功即通过，失败继续走密码认证
- `/etc/pam.d/sudo` 始终保留 `pam_opendirectory.so`（密码）做保底

## 系统要求

macOS（2016 年后带 Touch ID 的 MacBook Pro / MacBook Air / iMac / Mac mini / Mac Studio）

## 文件

```
~/.hermes/skills/redskill-sudo-touchid/
├── DESCRIPTION.md        ← 技能简介
├── SKILL.md              ← 本文件（完整说明）
└── sudo-touchid.sh       ← 主脚本
```

## 分享

[GitHub: lenkacos-dot/sudo-auth-manager](https://github.com/lenkacos-dot/sudo-auth-manager)
