#!/bin/bash

# Renk tanımlamaları
GREEN='\033[0;32m'
NC='\033[0m' # Renk Yok

echo -e "${GREEN}Kişisel uygulama kurulumu başlatılıyor...${NC}"

# Eğer yay kurulu değilse (CachyOS'ta genelde kuruludur ama kontrol edelim)
if ! command -v yay &> /dev/null
then
    echo "yay bulunamadı, kuruluyor..."
    sudo pacman -S --needed git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd ..
    rm -rf yay
fi

# Uygulama Listesi
APPS=(
    # Geliştirme ve Terminal
    alacritty
    atuin
    aws-cli
    github-cli
    go
    httpie
    micro
    tenv-bin
    zed
    zoxide
    
    # İnternet ve İletişim
    chromium
    firefox
    zen-browser-bin
    telegram-desktop
    thunderbird
    cloudflared-bin
    
    # Grafik ve Medya
    inkscape
    qview
    xnviewmp
    spotify
    spicetify-cli
    yt-dlp
    
    # Verimlilik ve Araçlar
    obsidian
    simplenote-electron-bin
    ticktick
    localsend
    btop
    glances
    espanso-wayland
    opentabletdriver
    nvibrant-bin
    rclone
    steam
)

echo -e "${GREEN}Paketler yükleniyor...${NC}"
yay -S --needed --noconfirm "${APPS[@]}"

echo -e "${GREEN}Kurulum tamamlandı!${NC}"
