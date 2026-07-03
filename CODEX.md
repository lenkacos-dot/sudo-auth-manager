# sudo-auth-manager — macOS sudo auth tool for Codex

## Purpose
Configure macOS sudo to use Touch ID fingerprint + password fallback.

## Quick Start
```bash
chmod +x sudo-auth-manager.sh
./sudo-auth-manager.sh apply   # enable Touch ID for sudo
./sudo-auth-manager.sh status  # check current config
```

## Technical
- Modifies `/etc/pam.d/sudo_local`
- PAM rule: `auth sufficient pam_tid.so`
- `sufficient` = success → auth granted, fail → next auth (password)
- Pure bash, no package manager needed
- macOS only, Touch ID hardware required
