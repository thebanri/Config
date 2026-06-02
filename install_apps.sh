#!/bin/bash

# CachyOS varsayılan kurulumuna dahil olmayan, 
# kullanıcı tarafından eklenmiş araçlar ve AUR paketleri.

PACKAGES=(
    # --- Terminal ve CLI Araçları ---
    "alacritty"
    "atuin"
    "aws-cli"
    "btop"
    "duf"
    "fastfetch"
    "github-cli"
    "go"
    "httpie"
    "micro"
    "rclone"
    "ripgrep"
    "tenv-bin"
    "terax-bin"
    "yt-dlp"
    "zoxide"
    "cloudflared-bin"
    
    # --- Geliştirme ve Üretkenlik ---
    "obsidian"
    "simplenote-electron-bin"
    "ticktick"
    "zed"

    # --- İnternet ve İletişim ---
    "chromium"
    "firefox"
    "thunderbird"
    "telegram-desktop"
    "zen-browser-bin"

    # --- Medya, Grafik ve Oyun ---
    "inkscape"
    "kdenlive"
    "kolourpaint"
    "qview"
    "xnviewmp"
    "spotify"
    "spicetify-cli"
    "steam"
    
    # --- Sistem Araçları ve Diğer ---
    "espanso-wayland"
    "localsend"
    "nvibrant-bin"
    "opentabletdriver"
    "whosthere-bin"
    
    # --- Fontlar ---
    "awesome-terminal-fonts"
    "ttf-meslo-nerd"
)

echo "📦 Kurulum başlatılıyor..."

# Paru veya Yay kontrolü
if command -v paru &> /dev/null; then
    AUR_HELPER="paru"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
else
    echo "❌ Hata: Sistemde 'paru' veya 'yay' bulunamadı."
    echo "Lütfen önce bir AUR yardımcısı kurun."
    exit 1
fi

echo "✅ Kullanılan paket yöneticisi: $AUR_HELPER"
echo "----------------------------------------"

# Paketleri tek seferde kurma
$AUR_HELPER -S --needed "${PACKAGES[@]}"

echo "----------------------------------------"
echo "🎉 Kurulum tamamlandı!"
