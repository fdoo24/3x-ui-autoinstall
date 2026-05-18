# 🚀 VPN Fortress

> **Zero‑Touch Deployment for 3x‑ui** • VLESS + Trojan + TLS + Nginx 444 + Fail2ban 

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%20|%2022.04%20|%2024.04-orange)](https://ubuntu.com)
[![Version](https://img.shields.io/badge/Version-7.0_Fortress-green)](https://github.com/fdoo24/3x-ui-autoinstall/releases)
[![Stars](https://img.shields.io/github/stars/fdoo24/3x-ui-autoinstall?style=social)](https://github.com/fdoo24/3x-ui-autoinstall)

<p align="center">
  <strong>VPN Fortress</strong> — fully automated, hardened deployment script for 
  <a href="https://github.com/MHSanaei/3x-ui">3x‑ui</a>, designed to create a 
  censorship‑resistant, production‑grade VPN node in a single command.
</p>

<p align="center">
  <sub>Fortress Edition (V7.0) — optimized for stealth, reliability, and high‑performance traffic</sub>
</p>

This script is designed for a fully automated (Zero-Touch) installation of the **3x-ui** panel on a clean Ubuntu server. The result is a ready-to-use, bulletproof architecture for bypassing censorship, completely eliminating the need to manually configure tunnels and certificates.

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🔐 **Auto TLS + DB Injection** | Let's Encrypt certificate issued and injected directly into 3x‑ui SQLite — no `ERR_SSL_PROTOCOL_ERROR` |
| 🛰 **Dual‑Protocol Stack** | VLESS/TLS (443) + hidden Trojan‑WS (8022) with automatic Xray fallback routing |
| 🎭 **Camouflage Mode** | Random corporate HTML template deployed to `/var/www/html` — server looks like a normal website |
| 🛡 **Nginx 444 Firewall** | Unknown hosts get instant HTTP 444 (connection drop) — blocks bots, scanners, CDN spoofing |
| 👮 **Fail2ban Protection** | Blocks SSH bruteforce attacks out of the box (5 retries = 1 hour IP ban) |
| 🧹 **Log Management** | Limits systemd journal logs to 100MB / 10 days to prevent server disk overflow |
| 📞 **VoIP Support** | Properly routes UDP (QUIC) traffic to ensure flawless audio/video calls |
| 🔧 **Hardened Panel** | Random username, password, port (20k–25k), hidden base path — all written directly to DB |
| 💾 **Daily Backups** | Cron job snapshots `x-ui.db` with 7‑day retention |
| ⚡ **Zero‑Touch Install** | Fully automatic with domain (`install.sh YOUR_DOMAIN`), or interactive mode if run without arguments |

---

## ⚙️ Prerequisites
1. A completely clean **Ubuntu** server (20.04, 22.04, or 24.04).
2. A registered domain pointing to the IP address of your new server (A-record).
3. Open ports **80** and **443** in your cloud provider's external firewall (Security Groups).

---

## 🛡 What You Get After Installation
At the end of the process, the script will output the following directly to your console:
1. A secure HTTPS link to access your 3x-ui web panel, along with the generated login and password.
2. A ready-to-use vless:// link for your primary high-speed connection.
3. A ready-to-use trojan:// link for your hidden fallback tunnel.

---

## ⚡ Quick Start (1-Click Install)

Connect to your server via SSH as the `root` user and run the following command:
```bash
curl -fsSL https://raw.githubusercontent.com/fdoo24/3x-ui-autoinstall/refs/heads/main/install.sh | bash
```

```bash
wget -qO install.sh https://raw.githubusercontent.com/fdoo24/3x-ui-autoinstall/refs/heads/main/install.sh && bash install.sh
```
Установка ноды для MySuperVPN 2:
```bash
curl -fsSL https://raw.githubusercontent.com/fdoo24/3x-ui-autoinstall/refs/heads/main/setup_node.sh | bash
```

