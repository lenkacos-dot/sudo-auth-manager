# 🖐️ sudo-touchid

**macOS sudo 指纹认证 — 告别反复输密码**

```
┌──────────────────────────────┐
│   🖐️  sudo-touchid             │
│                               │
│   ✅ 指纹优先 + 密码回退       │
│   🔧 一行配置，无需第三方      │
│   📦 纯 bash，Hermes/手动均可  │
└──────────────────────────────┘
```

## 效果

| 场景 | 行为 |
|:----|:----|
| 刷指纹 | sudo 直接通过 ✅ |
| 指纹失败 | 自动弹密码框 |
| 刚重启未解锁 | 直接输密码 |

## 一秒安装

```bash
# Hermes Agent 用户
bash ~/.hermes/skills/redskill-sudo-touchid/sudo-touchid.sh apply

# 所有人的通用方式
curl -O https://raw.githubusercontent.com/lenkacos-dot/sudo-auth-manager/main/sudo-auth-manager.sh
chmod +x sudo-auth-manager.sh
./sudo-auth-manager.sh apply
```

## 原理

写一行到 `/etc/pam.d/sudo_local`：
```
auth sufficient pam_tid.so
```

`sufficient` = Touch ID 通过就放行，失败就继续走密码。

**零第三方依赖，零隐私收集，改的是你自己电脑的配置文件。**

---

✅ **RedSkill 参赛作品**  
📦 GitHub: [lenkacos-dot/sudo-auth-manager](https://github.com/lenkacos-dot/sudo-auth-manager)  
🔖 #RedSkill #小红说 #HermesAgent #macOS #TouchID
