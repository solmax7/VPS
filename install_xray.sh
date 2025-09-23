#!/bin/bash
# Автоматическая установка Xray VLESS + Reality на Ubuntu/Debian
# Автор: ChatGPT

set -e

echo "=== Обновление системы ==="
sudo apt update && sudo apt upgrade -y
sudo apt install curl wget unzip -y

echo "=== Установка Xray ==="
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)"

echo "=== Генерация UUID ==="
UUID=$(xray uuid)
echo "Сгенерированный UUID: $UUID"

echo "=== Генерация ключей X25519 для Reality ==="
KEYS=$(xray x25519)
PUB_KEY=$(echo "$KEYS" | grep "Public" | awk '{print $3}')
PRI_KEY=$(echo "$KEYS" | grep "Private" | awk '{print $3}')
echo "Public Key: $PUB_KEY"
echo "Private Key: $PRI_KEY"

echo "=== Создание конфигурации Xray ==="
CONFIG_DIR="/usr/local/etc/xray"
sudo mkdir -p $CONFIG_DIR
sudo tee $CONFIG_DIR/config.json > /dev/null <<EOF
{
  "log": { "level": "info", "timestamp": true },
  "inbounds": [
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "$UUID" }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "publicKey": "$PUB_KEY",
          "shortIds": ["sid1"],
          "serverName": "www.vk.com"
        }
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "settings": {} }
  ]
}
EOF

echo "=== Создание systemd-сервиса ==="
sudo tee /etc/systemd/system/xray.service > /dev/null <<EOF
[Unit]
Description=Xray Service
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/xray -config /usr/local/etc/xray/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "=== Запуск и включение автозапуска ==="
sudo systemctl daemon-reload
sudo systemctl enable xray
sudo systemctl start xray

echo "=== Установка завершена ==="
echo "UUID: $UUID"
echo "Public Key: $PUB_KEY"
echo "Private Key: $PRI_KEY"
echo "Сервер готов к подключению через VLESS + Reality!"
