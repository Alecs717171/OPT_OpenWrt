#!/bin/sh

# ============================================
#  Полная установка: AdGuard + Zapret + Ru
#  для OpenWrt (Xiaomi AX3600)
# ============================================

echo "=================================="
echo "🚀 Начинаю установку..."
echo "=================================="

# 1. Предложение сделать бэкап перед началом
echo "⚠️  Рекомендуется сделать бэкап текущей конфигурации."
read -p "   Сделать бэкап сейчас? (y/n): " choice
if [ "$choice" = "y" ] || [ "$choice" = "Y" ]; then
    BACKUP_FILE="/root/backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    echo "📦 Создаю бэкап в $BACKUP_FILE ..."
    sysupgrade -b "$BACKUP_FILE"
    echo "✅ Бэкап создан."
else
    echo "⏩ Пропускаем бэкап."
fi

# 2. Обновление пакетов
echo "📦 Обновление списка пакетов..."
apk update

# 3. Установка русского языка
echo "🇷🇺 Установка русского языка..."
apk add luci-i18n-attendedsysupgrade-ru \
        luci-i18n-firewall-ru \
        luci-i18n-package-manager-ru \
        luci-i18n-base-ru

# 4. Установка зависимостей
echo "📦 Установка зависимостей..."
apk add wget tar iptables

# 5. Скачивание и установка AdGuard Home
echo "🛡️ Установка AdGuard Home..."
cd /tmp
wget https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.107.65/AdGuardHome_linux_arm64.tar.gz -O AdGuardHome.tar.gz
tar -xvf AdGuardHome.tar.gz
mkdir -p /usr/bin/AdGuardHome
mv AdGuardHome/* /usr/bin/AdGuardHome/

# 6. Настройка AdGuard Home на 127.0.0.10:53
ip addr add 127.0.0.10/32 dev lo 2>/dev/null

cat > /usr/bin/AdGuardHome/AdGuardHome.yaml <<EOF
http:
  address: 0.0.0.0:3000
dns:
  bind_hosts:
    - 127.0.0.10
  port: 53
users: []
EOF

# 7. Установка сервиса AdGuard
cd /usr/bin/AdGuardHome
./AdGuardHome -s install
service AdGuardHome start

# 8. Настройка dnsmasq на форвардинг в AdGuard
uci set dhcp.@dnsmasq[0].port='53'
uci add_list dhcp.@dnsmasq[0].server='127.0.0.10#53'
uci commit dhcp
/etc/init.d/dnsmasq restart

# 9. Установка Zapret Manager
echo "🔧 Установка Zapret Manager..."
sh <(wget -O - https://raw.githubusercontent.com/StressOzz/Zapret-Manager/main/Zapret-Manager.sh)

# 10. Предложение сделать бэкап после установки
echo "=================================="
echo "✅ Установка завершена!"
echo "=================================="
read -p "   Сделать бэкап всей системы? (y/n): " choice2
if [ "$choice2" = "y" ] || [ "$choice2" = "Y" ]; then
    BACKUP2_FILE="/root/fullbackup-$(date +%Y%m%d-%H%M%S).tar.gz"
    echo "📦 Создаю полный бэкап в $BACKUP2_FILE ..."
    sysupgrade -b "$BACKUP2_FILE"
    echo "✅ Бэкап создан."
else
    echo "⏩ Пропускаем бэкап."
fi

# ===== НОВЫЙ БЛОК: Автозапуск Zapret =====
echo "🚀 Запускаю Zapret..."
if [ -f /opt/zapret/zapret.sh ]; then
    /opt/zapret/zapret.sh start
    /opt/zapret/zapret.sh enable
    echo "✅ Zapret запущен и добавлен в автозагрузку."
elif [ -f /etc/init.d/zapret ]; then
    /etc/init.d/zapret start
    /etc/init.d/zapret enable
    echo "✅ Zapret (init) запущен и добавлен в автозагрузку."
else
    echo "⚠️ Zapret не найден. Возможно, он установится позже или требует перезагрузки."
fi

# Проверка статуса
echo "📋 Статус Zapret:"
ps | grep -E "zapret|nfqws" | grep -v grep || echo "❌ Zapret не запущен"

# ============================================

echo "=================================="
echo "🌐 AdGuard: http://192.168.1.1:3000"
echo "📋 Русский язык включён"
echo "🛡️ Zapret установлен и запущен"
echo "=================================="
