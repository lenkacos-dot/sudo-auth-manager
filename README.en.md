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

<br/>

---

## What is this?

A lightweight shell script that makes macOS `sudo` prefer **Touch ID** authentication, falling back to password when fingerprint fails.

**The experience:**
- Touch fingerprint → sudo passes immediately ✅
- Fingerprint fails → automatically prompts for password
- Just rebooted (unlocked) → directly asks for password

---

## Architecture

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
  └──────────┘      │         ↓ on fail?                 │
       │            │ auth required pam_opendirectory.so  │
       │            │         (Password)                 │
       │            └────────────────────────────────────┘
       │
       ▼
  ┌──────────┐      ┌──────────────┐
  │  Touch   │ ──►  │   sudo ✓    │
  │  ID ✓    │      └──────────────┘
  └──────────┘
       │ fail
       ▼
  ┌──────────┐      ┌──────────────┐
  │ Password │ ──►  │   sudo ✓    │
  │    ✓     │      └──────────────┘
  └──────────┘
```

**How it works:** Modifies `/etc/pam.d/sudo_local`, adding `auth sufficient pam_tid.so`.
`sufficient` = if Touch ID succeeds, authenticate; if it fails, proceed to next auth method (password).

The main `/etc/pam.d/sudo` always retains `pam_opendirectory.so` (password auth) as the underlying guarantee.

---

## Before vs After

| Scenario | Before | After |
|----------|--------|-------|
| Touch ID → sudo | ❌ Must type password | ✅ Fingerprint passes |
| Fingerprint fails | N/A | ✅ Falls back to password |
| Just rebooted | Type password | Type password (normal) |
| Security | Password only | Fingerprint + password |

---

## What's Inside

```
sudo-auth-manager/
├── sudo-auth-manager.sh    ← Main script (executable)
├── README.md               ← Chinese documentation
├── README.en.md            ← This file (English)
```

---

## Quick Start

```bash
chmod +x sudo-auth-manager.sh
./sudo-auth-manager.sh status    # Check current state
./sudo-auth-manager.sh apply     # Enable Touch ID + password fallback
```

### System-wide install (optional)

```bash
sudo cp sudo-auth-manager.sh /usr/local/bin/sudo-auth-manager
sudo chmod +x /usr/local/bin/sudo-auth-manager
# Then just type:
sudo-auth-manager status
sudo-auth-manager apply
```

---

## System Requirements

| Requirement | Detail |
|------------|--------|
| **OS** | macOS (2016+ Mac with Touch ID) |
| **Dependencies** | None (pure shell) |
| **Sudo** | Admin privileges required |

---

## License

MIT — Do what you want. Credit if you find it useful.

---

> **v2.0** | Touch ID first, password fallback | MIT
