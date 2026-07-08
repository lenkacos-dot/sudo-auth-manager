<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License">
  <img src="https://img.shields.io/badge/platform-macOS-brightgreen" alt="macOS">
  <img src="https://img.shields.io/badge/dependencies-0-green" alt="Zero Dependencies">
  <img src="https://img.shields.io/badge/version-v2.0-orange" alt="v2.0">
  <img src="https://img.shields.io/github/stars/lenkacos-dot/sudo-auth-manager?style=social" alt="GitHub Stars">
</p>

<br/>

<h1 align="center">🔐 sudo-auth-manager</h1>
<h3 align="center">Touch ID First · Password Fallback · macOS</h3>
<h4 align="center">设置 macOS sudo <strong>指纹优先 + 密码回退</strong></h4>

<br/>

---

## 📖 中文 / Chinese

### 这是什么？

一个轻量脚本，让 macOS 的 `sudo` 优先使用 **Touch ID（指纹）** 认证，失败时自动回退到密码。

**你只需要：**
- 刷指纹 → sudo 直接通过 ✅
- 指纹失败 → 自动让输密码
- 刚重启未解锁 → 直接输密码

---

## 🏗️ Architecture / 架构

```
                    ┌─────────────────────────────────────┐
                    │         PAM Authentication Flow     │
                    └─────────────────────────────────────┘

  sudo command
       │
       ▼
  ┌──────────┐      ┌────────────────────────────────────┐
  │ /etc/pam │ ───► │ auth sufficient pam_tid.so         │
  │ .d/sudo  │      │         (Touch ID)                 │
  └──────────┘      │         ↓ 失败?                    │
       │            │ auth required pam_opendirectory.so  │
       │            │         (Password)                 │
       │            └────────────────────────────────────┘
       │
       ▼
  ┌──────────┐      ┌──────────────┐
  │  Touch   │ ──►  │   sudo ✓    │
  │  ID ✓    │      └──────────────┘
  └──────────┘
       │ 失败
       ▼
  ┌──────────┐      ┌──────────────┐
  │ Password │ ──►  │   sudo ✓    │
  │    ✓     │      └──────────────┘
  └──────────┘
```

**原理：** 修改 `/etc/pam.d/sudo_local`，写入 `auth sufficient pam_tid.so`。
`sufficient` = Touch ID 成功即通过，失败则走下一认证（密码）。

主文件 `/etc/pam.d/sudo` 始终保留 `pam_opendirectory.so`（密码认证）作为底层保障。

---

## ⚔️ 效果对比 / Before vs After

| 场景 | 改造前 | 改造后 |
|------|--------|--------|
| 刷指纹 → sudo | ❌ 必须输密码 | ✅ 指纹直接过 |
| 指纹失败 | N/A | ✅ 自动输密码 |
| 刚重启未解锁 | 输密码 | 输密码（正常） |
| 安全性 | 密码唯一 | 指纹 + 密码双保险 |

---

## 📁 What's Inside / 文件结构

```
sudo-auth-manager/
├── sudo-auth-manager.sh    ← 主脚本（可执行）
├── README.md               ← 本文档（中文）
├── README.en.md            ← English version
```

---

## ⚡ 快速开始 / Quick Start

```bash
chmod +x sudo-auth-manager.sh
./sudo-auth-manager.sh status    # 查看当前状态
./sudo-auth-manager.sh apply     # 设置指纹优先 + 密码回退
```

### 装进系统（可选）

```bash
sudo cp sudo-auth-manager.sh /usr/local/bin/sudo-auth-manager
sudo chmod +x /usr/local/bin/sudo-auth-manager
# 之后直接敲：
sudo-auth-manager status
sudo-auth-manager apply
```

---

## 🔧 System Requirements / 系统要求

| Requirement | Detail |
|------------|--------|
| **OS** | macOS (2016+ 带 Touch ID 的 Mac) |
| **Dependencies** | None (pure shell) |
| **Sudo** | Admin privileges required |

---

## 🔗 Related / 相关

| Resource | Link |
|----------|------|
| **GitHub Repo** | [https://github.com/lenkacos-dot/sudo-auth-manager](https://github.com/lenkacos-dot/sudo-auth-manager) |
| **Apple PAM Docs** | [https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man8/pam.8.html](https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man8/pam.8.html) |

---

## 📄 License

```
MIT License

Copyright (c) 2025 lenkacos-dot

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

> **v2.0** | 仅保留「指纹优先 + 密码回退」| MIT — Do what you want. Credit if you find it useful.
