#!/bin/bash
# Авторазвертывание V7.0: 3x-ui + VLESS + Trojan + Nginx + Fail2ban + LogLimits

# 1. Интерактивный запрос домена
DOMAIN=$1
if [ -z "$DOMAIN" ]; then
    echo -n "🌐 Пожалуйста, введите ваш домен (например, mysite.com) и нажмите Enter: "
    read DOMAIN
    if [ -z "$DOMAIN" ]; then
        echo "❌ Ошибка: Домен не может быть пустым! Установка прервана."
        exit 1
    fi
fi

EMAIL="admin@$DOMAIN"
echo "🚀 Начинаем установку VPN-Крепости для $DOMAIN..."

# 2. Пакеты базовые + защита
apt update && apt upgrade -y
apt install -y nginx curl socat sqlite3 uuid-runtime openssl unzip fail2ban

# 3. Активная защита (Fail2ban и лимиты логов)
echo "🛡 Настройка защиты от брутфорса (Fail2ban) и лимитов логов..."
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

sed -i 's/.*SystemMaxUse.*/SystemMaxUse=100M/' /etc/systemd/journald.conf
sed -i 's/.*MaxRetentionSec.*/MaxRetentionSec=10day/' /etc/systemd/journald.conf
systemctl restart systemd-journald
journalctl --vacuum-size=100M 2>/dev/null

# 4. Скачивание случайного шаблона сайта-заглушки
echo "🎨 Установка корпоративного дизайна заглушки..."
cd /var/www/html
wget -qO master.zip https://github.com/GFW4Fun/randomfakehtml/archive/refs/heads/master.zip
unzip -q master.zip
RandomHTML=$(ls randomfakehtml-master | grep -v "\." | shuf -n1)
cp -a randomfakehtml-master/$RandomHTML/. /var/www/html/
rm -rf master.zip randomfakehtml-master
cd /root

# 5. Настройка Nginx (Блокировка ботов)
echo "⚙️ Настройка Nginx..."
cat << EOF > /etc/nginx/nginx.conf
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;
events { worker_connections 768; }
http {
    sendfile on; tcp_nopush on; types_hash_max_size 2048;
    include /etc/nginx/mime.types; default_type application/octet-stream;
    
    server {
        listen 80; server_name $DOMAIN;
        if (\$host !~* ^(.+\.)?$DOMAIN\$ ){ return 444; }
        location ^~ /.well-known/acme-challenge/ { root /var/www/html; default_type "text/plain"; }
        location / { return 301 https://\$host\$request_uri; }
    }
    
    server {
        listen 127.0.0.1:8080; server_name $DOMAIN;
        if (\$host !~* ^(.+\.)?$DOMAIN\$ ){ return 444; }
        location / { root /var/www/html; index index.html; }
    }
}
EOF
systemctl restart nginx && systemctl enable nginx

# 6. Выпуск сертификатов (с хуком на перезапуск 3x-ui)
echo "🔐 Выпуск вечных сертификатов..."
curl https://get.acme.sh | sh -s email=$EMAIL
source ~/.bashrc
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
/root/.acme.sh/acme.sh --issue -d $DOMAIN --webroot /var/www/html

mkdir -p /etc/x-ui/certs
/root/.acme.sh/acme.sh --install-cert -d $DOMAIN \
--key-file /etc/x-ui/certs/server.key \
--fullchain-file /etc/x-ui/certs/fullchain.cer \
--reloadcmd "systemctl restart x-ui"

# 7. Установка 3x-ui
echo "🛠 Установка 3x-ui..."
yes "" | bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)

# 8. Безопасность панели (Генерация данных)
PANEL_USER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
PANEL_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
PANEL_PORT=$((RANDOM % 5000 + 20000))
PANEL_PATH="/$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)/"

/usr/local/x-ui/x-ui setting -username "$PANEL_USER" -password "$PANEL_PASS"

# 9. Прямая инъекция настроек в SQLite
echo "💉 Внедрение сертификатов и туннелей в базу данных..."
systemctl stop x-ui
DB_PATH="/etc/x-ui/x-ui.db"
UUID=$(uuidgen)
TROJAN_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
SNIFFING_JSON='{"enabled": true, "destOverride": ["http", "tls", "quic"], "routeOnly": false}'

sqlite3 $DB_PATH "DELETE FROM settings WHERE key IN ('webPort', 'webBasePath', 'webCertFile', 'webKeyFile');"
sqlite3 $DB_PATH "INSERT INTO settings (key, value) VALUES ('webPort', '$PANEL_PORT'), ('webBasePath', '$PANEL_PATH'), ('webCertFile', '/etc/x-ui/certs/fullchain.cer'), ('webKeyFile', '/etc/x-ui/certs/server.key');"

SETTINGS_TROJAN="{\"clients\": [{\"password\": \"$TROJAN_PASS\",\"email\": \"trojan-user\"}],\"fallbacks\": []}"
STREAM_TROJAN="{\"network\": \"ws\",\"security\": \"none\",\"wsSettings\": {\"acceptProxyProtocol\": false,\"path\": \"/my-trojan\",\"headers\": {}}}"
sqlite3 $DB_PATH "INSERT INTO inbounds (user_id, up, down, total, remark, enable, expiry_time, listen, port, protocol, settings, stream_settings, tag, sniffing) VALUES (1, 0, 0, 0, 'Trojan-Hidden', 1, 0, '127.0.0.1', 8022, 'trojan', '$SETTINGS_TROJAN', '$STREAM_TROJAN', 'inbound-8022', '$SNIFFING_JSON');"

SETTINGS_VLESS="{\"clients\": [{\"id\": \"$UUID\",\"flow\": \"\",\"email\": \"admin\"}],\"decryption\": \"none\",\"fallbacks\": [{\"dest\": \"127.0.0.1:8080\",\"xver\": 0}, {\"path\": \"/my-trojan\",\"dest\": 8022,\"xver\": 0}]}"
STREAM_VLESS="{\"network\": \"tcp\",\"security\": \"tls\",\"tlsSettings\": {\"serverName\": \"$DOMAIN\",\"certificates\": [{\"certificateFile\": \"/etc/x-ui/certs/fullchain.cer\",\"keyFile\": \"/etc/x-ui/certs/server.key\"}],\"alpn\": [\"http/1.1\"]}}"
sqlite3 $DB_PATH "INSERT INTO inbounds (user_id, up, down, total, remark, enable, expiry_time, listen, port, protocol, settings, stream_settings, tag, sniffing) VALUES (1, 0, 0, 0, 'VLESS_Main', 1, 0, '', 443, 'vless', '$SETTINGS_VLESS', '$STREAM_VLESS', 'inbound-443', '$SNIFFING_JSON');"

systemctl start x-ui

# 10. Автобэкапы
echo "💾 Добавление автобэкапа базы данных..."
(crontab -l 2>/dev/null | grep -v "x-ui.db"; echo "0 2 * * * mkdir -p /var/backups && cp /etc/x-ui/x-ui.db /var/backups/x-ui.db.\$(date +\%F-\%H-\%M) && find /var/backups -name \"x-ui.db.*\" -mtime +7 -delete") | crontab -

VLESS_URL="vless://$UUID@$DOMAIN:443?type=tcp&security=tls&fp=random&alpn=http/1.1&sni=$DOMAIN#VLESS_$DOMAIN"
TROJAN_URL="trojan://$TROJAN_PASS@$DOMAIN:443?security=tls&type=ws&path=%2Fmy-trojan&sni=$DOMAIN&alpn=http%2F1.1#Trojan_$DOMAIN"

ACCESS_FILE="/root/vpn_access.txt"
cat << EOF > $ACCESS_FILE

=======================================================
✅ УСТАНОВКА УСПЕШНО ЗАВЕРШЕНА (ULTIMATE V7.0)
=======================================================
🛡 ДОСТУП К ПАНЕЛИ:
Адрес панели:  https://$DOMAIN:$PANEL_PORT$PANEL_PATH
Логин:         $PANEL_USER
Пароль:        $PANEL_PASS
-------------------------------------------------------
🔗 1. ОСНОВНАЯ ССЫЛКА (VLESS на 443 порту):
$VLESS_URL

🔗 2. РЕЗЕРВНАЯ ССЫЛКА (Trojan, замаскированный под 443):
$TROJAN_URL
=======================================================
EOF
cat $ACCESS_FILE
