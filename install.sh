#!/bin/sh

# ============================================
#  Полная установка: AdGuard + Zapret + Ru
#  для OpenWrt (Xiaomi AX3600)
# ============================================

echo "=================================="
echo "🚀 Начинаю установку..."
echo "=================================="

# 1. Обновление пакетов
echo "📦 Обновление пакетов..."
opkg update

# 2. Установка русского языка
echo "🇷🇺 Установка русского языка..."
opkg install luci-i18n-base-ru luci-i18n-firewall-ru luci-i18n-attendedsysupgrade-ru luci-i18n-adguardhome-ru

# 3. Установка зависимостей
echo "📦 Установка зависимостей..."
opkg install wget tar iptables

# 4. Скачивание и установка AdGuard Home
echo "🛡️ Установка AdGuard Home..."
cd /tmp
wget https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.107.65/AdGuardHome_linux_amd64.tar.gz -O AdGuardHome.tar.gz
tar -xvf AdGuardHome.tar.gz
mkdir -p /usr/bin/AdGuardHome
mv AdGuardHome/* /usr/bin/AdGuardHome/

# 5. Настройка AdGuard Home на 127.0.0.10:53
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

# 6. Установка сервиса AdGuard
cd /usr/bin/AdGuardHome
./AdGuardHome -s install
service AdGuardHome start

# 7. Настройка dnsmasq на форвардинг в AdGuard
uci set dhcp.@dnsmasq[0].port='53'
uci add_list dhcp.@dnsmasq[0].server='127.0.0.10#53'
uci commit dhcp
/etc/init.d/dnsmasq restart

# 8. Установка Zapret Manager
echo "🔧 Установка Zapret Manager..."
sh <(wget -O - https://raw.githubusercontent.com/StressOzz/Zapret-Manager/main/Zapret-Manager.sh)

# ===== НОВЫЙ БЛОК: Автозапуск и фикс Zapret =====
echo "🚀 Запускаю Zapret и применяю фикс..."

# Поиск Zapret
if [ -f /opt/zapret/zapret.sh ]; then
    echo "✅ Zapret найден, запускаю..."
    /opt/zapret/zapret.sh start
    /opt/zapret/zapret.sh enable
    echo "✅ Zapret запущен и добавлен в автозагрузку."
elif [ -f /etc/init.d/zapret ]; then
    echo "✅ Zapret (init) найден, запускаю..."
    /etc/init.d/zapret start
    /etc/init.d/zapret enable
    echo "✅ Zapret запущен и добавлен в автозагрузку."
else
    echo "⚠️ Zapret не найден. Проверь установку вручную."
fi

# Применение стратегии (если есть Zapret Manager)
if [ -f /opt/zapret/zapret-manager.sh ]; then
    echo "🔧 Применяю стратегию v4 (лучшая)..."
    /opt/zapret/zapret-manager.sh --apply v4 || echo "⚠️ Не удалось применить стратегию"
fi

# Проверка статуса
echo "📋 Статус Zapret:"
ps | grep -E "zapret|nfqws" | grep -v grep || echo "❌ Zapret не запущен"

# ============================================

# 9. Проверка
echo "=================================="
echo "✅ Готово!"
echo "🌐 AdGuard: http://192.168.1.1:3000"
echo "📋 Русский язык включён"
echo "🛡️ Zapret установлен и запущен"
echo "=================================="
