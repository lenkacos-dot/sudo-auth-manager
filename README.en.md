# 🔐 sudo-auth-manager

> **Toggle macOS sudo authentication mode** — Touch ID fingerprint vs. traditional password.

A single bash script to switch between fingerprint-first and password-only authentication for `sudo` on macOS by modifying the PAM configuration.

---

## 🚀 Quick Start

```bash
chmod +x sudo-auth-manager.sh
./sudo-auth-manager.sh status       # check current mode
./sudo-auth-manager.sh touchid      # fingerprint first, fallback to password ✅
./sudo-auth-manager.sh password     # password only (disable Touch ID)
./sudo-auth-manager.sh touchid-only # fingerprint only (no password fallback) ⚠
```

### Optional: install system-wide

```bash
sudo cp sudo-auth-manager.sh /usr/local/bin/sudo-auth-manager
sudo chmod +x /usr/local/bin/sudo-auth-manager
# then use from anywhere:
sudo-auth-manager status
```

---

## 📋 Commands

| Command | Effect | Detail |
|---------|--------|--------|
| `status` | Show current mode | Display PAM config file contents |
| `touchid` | Fingerprint + password fallback | Try Touch ID first; if fail → ask password ✅ **Recommended** |
| `password` | Password only | Disable Touch ID, classic password prompt |
| `touchid-only` | Fingerprint only | ⚠ If Touch ID fails, sudo is denied. No password fallback |

---

## ⚙️ How It Works

Modifies `/etc/pam.d/sudo_local` — the macOS PAM authentication config for `sudo`:

```
# Fingerprint first + password fallback (recommended)
auth sufficient pam_tid.so

# Fingerprint only (no fallback) ⚠ Dangerous
auth required pam_tid.so

# Password only (file is empty)
```

**PAM keyword meanings:**

- **`sufficient`** — If this module succeeds, auth is granted. If it fails, the next module runs (password fallback).
- **`required`** — This module MUST succeed. Failure means immediate denial.

The main `/etc/pam.d/sudo` always retains `pam_opendirectory.so` (password auth) as the system-level safety net.

---

## 🔒 Security Notes

- Modifies a system PAM config file — `sudo` permission required
- Local scope only, no data is sent anywhere
- `touchid` mode (fingerprint + password fallback) is the **safest balance** of convenience and security
- `touchid-only` is **risky**: if Touch ID is unavailable (after reboot before login, or hardware failure), `sudo` becomes impossible

---

## 🍎 Requirements

- **macOS** with Touch ID hardware: 2016+ MacBook Pro / MacBook Air / iMac Pro / Mac mini M1+ / Mac Studio / Mac Pro
- All modern macOS versions supported

---

## 📁 Files

```
sudo-auth-manager.sh   ← Main script (executable)
README.md              ← You're reading it
```

## 📦 Alternative: Hermes Agent Skill

This tool is also packaged as a **Hermes Agent skill** at `~/.hermes/skills/sudo-auth-manager/` with an alias `sudo-auth-manager` in `.zshrc`. The skill version is identical in function — just an additional integration layer for Hermes Agent users.

---

## 🏗️ Credits & License

v1.0 — Built for macOS users who want to control their authentication flow. MIT.
