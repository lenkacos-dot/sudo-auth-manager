# sudo-auth-manager — macOS sudo authentication

This project configures macOS sudo to use **Touch ID first, password fallback**.

## Quick commands

```bash
# Apply Touch ID + password fallback
./sudo-auth-manager.sh apply

# Check current status
./sudo-auth-manager.sh status
```

## How it works

Writes `auth sufficient pam_tid.so` to `/etc/pam.d/sudo_local`.

- `sufficient` = Touch ID grants auth; if it fails, password fallback runs
- Password is always available via `pam_opendirectory.so` in `/etc/pam.d/sudo`

## Requirements

macOS with Touch ID (2016+ Macs). Requires `sudo` to modify PAM config.

## Key files

| File | Purpose |
|------|---------|
| `sudo-auth-manager.sh` | Main executable script |
| `README.md` | Documentation (Chinese) |
| `README.en.md` | Documentation (English) |
