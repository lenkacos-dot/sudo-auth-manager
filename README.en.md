# 🔐 sudo-auth-manager

Configure macOS sudo: **Touch ID first, password fallback**.

## Usage

```bash
chmod +x sudo-auth-manager.sh
./sudo-auth-manager.sh status    # check current mode
./sudo-auth-manager.sh apply     # set Touch ID + password fallback
```

### Install system-wide (optional)

```bash
sudo cp sudo-auth-manager.sh /usr/local/bin/sudo-auth-manager
sudo chmod +x /usr/local/bin/sudo-auth-manager
# then:
sudo-auth-manager status
```

## Behavior

- Touch ID success → sudo granted ✅
- Touch ID fails → fallback to password
- After reboot (before first unlock) → password directly

## How it works

Writes to `/etc/pam.d/sudo_local`:
```
auth sufficient pam_tid.so
```

PAM `sufficient` = if this module succeeds, auth is granted; if it fails, the next module (password) runs.

`/etc/pam.d/sudo` always keeps `pam_opendirectory.so` (password) as the system-level safety net.

## Requirements

macOS with Touch ID hardware (2016+ Macs)

## Files

```
sudo-auth-manager.sh    ← Main script (executable)
README.md               ← Chinese docs
README.en.md             ← English docs (this file)
```

v2.0 | Touch ID + password fallback only
