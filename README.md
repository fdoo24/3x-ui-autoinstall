# 🚀 VPN Fortress: Ultra-Fast 3x-ui Deployment (VLESS + Trojan)

This script is designed for a fully automated (Zero-Touch) installation of the **3x-ui** panel on a clean Ubuntu server. The result is a ready-to-use, bulletproof architecture for bypassing censorship, completely eliminating the need to manually configure tunnels and certificates.

## ✨ Key Features (Ultimate Edition)
* **Smart Routing:** Primary **VLESS** protocol (on port 443) with a Fallback rule to a hidden **Trojan** (WebSocket, port 8022) for maximum speed and redundancy.
* **Direct SSL Injection:** Let's Encrypt certificates are automatically injected into the panel's SQLite core, preventing the `ERR_SSL_PROTOCOL_ERROR` on the first launch.
* **Camouflage (Nginx):** Automatically downloads a random, professional-looking fake website template from GitHub to mask your node.
* **Scanner Protection:** Aggressive bot and scanner blocking (Nginx returns a `444` response code for unknown requests).
* **Reliability:** Automated daily backups of the panel's database to `/var/backups/`.
* **VoIP Call Support:** UDP traffic (QUIC) is properly routed to ensure flawless audio and video calls (WhatsApp, Telegram, etc.).

## ⚙️ Prerequisites
1. A completely clean **Ubuntu** server (20.04, 22.04, or 24.04).
2. A registered domain pointing to the IP address of your new server (A-record).
3. Open ports **80** and **443** in your cloud provider's external firewall (Security Groups).

## ⚡ Quick Start (1-Click Install)

Connect to your server via SSH as the `root` user and run the following command:

```bash
wget -qO install.sh "[https://raw.githubusercontent.com/fdoo24/3x-ui-autoinstall/refs/heads/main/install.sh](https://raw.githubusercontent.com/fdoo24/3x-ui-autoinstall/refs/heads/main/install.sh)" && bash install.sh
