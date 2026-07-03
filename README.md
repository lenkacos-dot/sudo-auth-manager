# 🔐 sudo-auth-manager

设置 macOS sudo **指纹优先 + 密码回退**。

## 用法

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
```

## 效果

- 刷指纹 → sudo 直接通过 ✅
- 指纹失败 → 自动让输密码
- 刚重启未解锁 → 直接输密码

## 原理

修改 `/etc/pam.d/sudo_local`，写入：
```
auth sufficient pam_tid.so
```

`sufficient` = Touch ID 成功即通过，失败则走下一认证（密码）。

主文件 `/etc/pam.d/sudo` 始终保留 `pam_opendirectory.so`（密码认证）作为底层保障。

## 系统要求

macOS（2016 年后带 Touch ID 的 Mac）

## 文件

```
sudo-auth-manager.sh    ← 主脚本（可执行）
README.md               ← 本文档
README.en.md             ← 英文版
```

v2.0 | 仅保留「指纹优先 + 密码回退」
