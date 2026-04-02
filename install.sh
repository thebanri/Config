#!/bin/bash
set -euo pipefail  # Hata denetimini sıkılaştır

echo "============================================"
echo "KDE Konfig Otomatik Kurulum Script'i"
echo "============================================"

# Bağımlılık kontrolü
for cmd in git tar find; do
    if ! command -v $cmd &>/dev/null; then
        echo "Hata: '$cmd' komutu bulunamadı. Lütfen yükleyip tekrar deneyin."
        exit 1
    fi
done

CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
REPO_URL="https://github.com/thebanri/Config.git"
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "[1/7] Repository indiriliyor..."
git clone --depth 1 "$REPO_URL" "$TEMP_DIR"

echo "[2/7] Yedek alınıyor..."
mkdir -p "$BACKUP_DIR"
[ -f "$CONFIG_DIR/kwinrc" ] && cp "$CONFIG_DIR/kwinrc" "$BACKUP_DIR/"

# Adım 1: kwinrc
echo "[3/7] kwinrc kopyalanıyor..."
cp "$TEMP_DIR/kwinrc" "$CONFIG_DIR/kwinrc"

# Adım 2: Colors
echo "[4/7] Renk teması kuruluyor..."
if [ -d "$TEMP_DIR/Colors" ]; then
    mkdir -p "$HOME/.local/share/color-schemes"
    # Sadece .colors uzantılı dosyaları kopyala
    find "$TEMP_DIR/Colors" -name "*.colors" -exec cp {} "$HOME/.local/share/color-schemes/" \;
fi

# Adım 3: Kvantum
echo "[5/7] Kvantum dosyaları hazırlanıyor..."
if [ -d "$TEMP_DIR/Application" ]; then
    APP_FILE=$(find "$TEMP_DIR/Application" -name "*.tar.xz" | head -1)
    if [ -z "$APP_FILE" ]; then
        echo "    ! Kvantum arşivi bulunamadı, atlanıyor."
    else
        mkdir -p "$HOME/.config/Kvantum"
        tar -xf "$APP_FILE" -C "$HOME/.config/Kvantum"
        echo "    ✓ Kvantum dosyaları çıkarıldı."
    fi
fi

# Adım 5: Window Decorations
echo "[6/7] Window Decorations kopyalanıyor..."
if [ -d "$TEMP_DIR/Window Decorations" ]; then
    # Klasör ismindeki boşluğa dikkat ederek kopyala
    cp -r "$TEMP_DIR/Window Decorations/"* "$CONFIG_DIR/" 2>/dev/null || true
fi

# SON ADIM: Restart (En sona alındı)
echo "[7/7] Değişiklikler uygulanıyor..."
if command -v systemctl &>/dev/null; then
    systemctl --user restart plasma-plasmashell.service || echo "Shell manuel başlatılmalı."
fi

echo "============================================"
echo "✓ Kurulum Tamamlandı! Lütfen manual adımları takip edin."
echo "============================================"
