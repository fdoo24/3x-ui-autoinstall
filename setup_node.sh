#!/bin/bash

echo "🚀 Установка 3x-ui (v2.8.11) + xhttp + Fail2ban + Авто-SSL..."

export DEBIAN_FRONTEND=noninteractive
apt-get update -q
apt-get install -y -q python3 curl sqlite3 jq unzip fail2ban

echo "🛡 Настраиваем защиту от подбора паролей (Fail2ban)..."
cat << EOF > /etc/fail2ban/jail.local
[DEFAULT]
bantime  = 3600
findtime = 3600
maxretry = 5

[sshd]
enabled = true
port    = ssh
backend = systemd
EOF
systemctl restart fail2ban
systemctl enable fail2ban

PANEL_VERSION="v2.8.11"
echo "🛠 Устанавливаем панель..."
echo -e "y\nn\n" | bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) $PANEL_VERSION > /dev/null 2>&1

PANEL_USER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
PANEL_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
PANEL_PORT=$((RANDOM % 5000 + 40000))
PANEL_PATH="/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)/"

/usr/local/x-ui/x-ui setting -username "$PANEL_USER" -password "$PANEL_PASS" -port $PANEL_PORT -webBasePath "$PANEL_PATH"

echo "🔑 Генерируем ключи Reality..."
XRAY_BIN=$(find /usr/local/x-ui/ -name "xray*" -type f -executable | head -n 1)
REALITY_KEYS=$($XRAY_BIN x25519 2>&1)
PRIVATE_KEY=$(echo "$REALITY_KEYS" | grep -i "Private" | cut -d ':' -f2 | tr -d ' ' | tr -d '\r')
PUBLIC_KEY=$(echo "$REALITY_KEYS" | grep -i "Public" | cut -d ':' -f2 | tr -d ' ' | tr -d '\r')
SHORT_ID=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 16 | head -n 1)

echo "⚙️ Настраиваем инбаунд xhttp..."
cat << EOF > /tmp/setup_inbound.py
import sqlite3, json

stream = {
    "network": "xhttp",
    "security": "reality",
    "realitySettings": {
        "maxClientVer": "",
        "maxTimediff": 0,
        "minClientVer": "",
        "mldsa65Seed": "",
        "privateKey": "$PRIVATE_KEY",
        "serverNames": ["www.nvidia.com"],
        "shortIds": ["$SHORT_ID"],
        "show": False,
        "target": "www.nvidia.com:443",
        "xver": 0
    },
    "xhttpSettings": {
        "headers": {},
        "host": "",
        "mode": "packet-up",
        "noSSEHeader": False,
        "path": "/",
        "scMaxBufferedPosts": 30,
        "scMaxEachPostBytes": "1000000",
        "scStreamUpServerSecs": "20-80",
        "seqKey": "",
        "seqPlacement": "",
        "sessionKey": "",
        "sessionPlacement": "",
        "uplinkChunkSize": 0,
        "uplinkDataKey": "",
        "uplinkDataPlacement": "",
        "uplinkHTTPMethod": "",
        "xPaddingBytes": "100-1000",
        "xPaddingHeader": "",
        "xPaddingKey": "",
        "xPaddingMethod": "",
        "xPaddingObfsMode": False,
        "xPaddingPlacement": ""
    }
}

settings = {
    "clients": [],
    "decryption": "none",
    "encryption": "none"
}

sniffing = {
    "destOverride": ["http", "tls", "quic", "fakedns"],
    "enabled": True,
    "metadataOnly": False,
    "routeOnly": False
}

conn = sqlite3.connect('/etc/x-ui/x-ui.db')
c = conn.cursor()
c.execute("DELETE FROM inbounds WHERE port = 443 OR id = 1")
c.execute(
    "INSERT INTO inbounds (user_id, up, down, total, remark, enable, expiry_time, listen, port, protocol, settings, stream_settings, tag, sniffing) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    (1, 0, 0, 0, "VLESS_Reality", 1, 0, "", 443, "vless", json.dumps(settings), json.dumps(stream), "inbound-443", json.dumps(sniffing))
)
conn.commit()
conn.close()
EOF

python3 /tmp/setup_inbound.py
rm /tmp/setup_inbound.py

systemctl restart x-ui

SERVER_IP=$(curl -s -4 icanhazip.com || curl -s -4 ifconfig.me)

echo ""
echo "======================================================="
echo "✅ СЕРВЕР УСПЕШНО УСТАНОВЛЕН И НАСТРОЕН!"
echo "======================================================="
echo "🌐 Адрес панели: https://$SERVER_IP:$PANEL_PORT$PANEL_PATH"
echo "👤 Логин:        $PANEL_USER"
echo "🔑 Пароль:       $PANEL_PASS"
echo "======================================================="
echo ""
echo "👇 СКОПИРУЙ ЭТОТ JSON И ОТПРАВЬ ЕГО БОТУ В ТЕЛЕГРАМ 👇"
echo ""
cat << EOF
{
  "ip": "$SERVER_IP",
  "display_name": "Новая Локация",
  "api_port": $PANEL_PORT,
  "api_path": "$PANEL_PATH",
  "username": "$PANEL_USER",
  "password": "$PANEL_PASS",
  "transport_type": "xhttp",
  "inbound_id": 1,
  "public_key": "$PUBLIC_KEY",
  "short_id": "$SHORT_ID",
  "sni": "www.nvidia.com"
}
EOF
echo ""
