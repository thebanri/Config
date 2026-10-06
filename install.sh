#!/bin/bash
set -euo pipefail  # Hata denetimini sıkılaştır

usage() {
    cat <<'EOF'
Kullanım: ./install.sh [seçenekler]

  (seçeneksiz)        Tema + UFW + NVIDIA saat ayarı + varsayılan terminal (eksik bağımlılıklar otomatik kurulur)
  --apps              install_apps.sh'taki uygulamaları da aynı seferde kur
  --only a,b          Sadece verilen adımları çalıştır
  --skip a,b          Verilen adımları atla
  --no-restart        Sonda KWin/Plasma'yı yeniden yükleme
  -h, --help          Bu yardımı göster

Adımlar: deps kwin colors kvantum decoration panel ufw nvidia terminal
Örnek:   ./install.sh --only ufw      ./install.sh --apps --skip panel
EOF
}

ALL_STEPS=(deps kwin colors kvantum decoration panel ufw nvidia terminal)
ONLY="" SKIP="" WITH_APPS=0 RESTART=1
while (( $# )); do
    case $1 in
        --apps)       WITH_APPS=1 ;;
        --only)       ONLY=${2:?--only bir liste ister}; shift ;;
        --skip)       SKIP=${2:?--skip bir liste ister}; shift ;;
        --no-restart) RESTART=0 ;;
        -h|--help)    usage; exit 0 ;;
        *)            echo "Bilinmeyen seçenek: $1"; usage; exit 1 ;;
    esac
    shift
done

wanted() {
    [[ -n $ONLY && ",$ONLY," != *",$1,"* ]] && return 1
    [[ ",$SKIP," == *",$1,"* ]] && return 1
    return 0
}

STEPS=()
for s in "${ALL_STEPS[@]}"; do wanted "$s" && STEPS+=("$s"); done
TOTAL=${#STEPS[@]}
(( RESTART )) && TOTAL=$((TOTAL + 1))
N=0
step() { N=$((N + 1)); echo; echo "[$N/$TOTAL] $1"; }
ok()   { echo "    ✓ $1"; }
warn() { echo "    ! $1"; }

echo "============================================"
echo "KDE Konfig Otomatik Kurulum Script'i"
echo "============================================"

CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config_backup_$(date +%Y%m%d_%H%M%S)"
REPO_URL="https://github.com/thebanri/Config.git"
TMP_DIR="" SUDO_PID=""
trap '[[ -n $SUDO_PID ]] && kill "$SUDO_PID" 2>/dev/null; [[ -n $TMP_DIR ]] && rm -rf "$TMP_DIR"; true' EXIT

# Repo klasöründen çalıştırılıyorsa dosyaları yerinden kullan, yoksa indir
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || true)
if [[ -f "$SCRIPT_DIR/kwinrc" ]]; then
    SRC="$SCRIPT_DIR"
else
    command -v git &>/dev/null || { echo "Hata: 'git' bulunamadı."; exit 1; }
    TMP_DIR=$(mktemp -d)
    SRC="$TMP_DIR"
    echo "Repository indiriliyor..."
    git clone -q --depth 1 "$REPO_URL" "$SRC"
fi

# sudo şifresini en başta bir kez sor, kurulum boyunca canlı tut
if wanted deps || wanted ufw || wanted nvidia || (( WITH_APPS )); then
    sudo -v
    while true; do sudo -n true; sleep 50; done 2>/dev/null &
    SUDO_PID=$!
fi

# Üzerine yazılacak dosyayı yedekle (yedek klasörü sadece gerekirse oluşur).
# Aynı dosya birden fazla adımda değişiyorsa ilk (orijinal) hâli korunur.
backup() {
    [[ -e $1 && ! -e $BACKUP_DIR/$(basename "$1") ]] || return 0
    mkdir -p "$BACKUP_DIR"
    cp -a "$1" "$BACKUP_DIR/"
}

# --- Adımlar ---------------------------------------------------------------

do_deps() {
    step "Bağımlılıklar kuruluyor..."
    local pkgs=(kvantum ufw kwin-decoration-sierra-breeze-enhanced-git plasma6-applets-panel-colorizer xdg-terminal-exec)
    if (( WITH_APPS )); then
        # install_apps.sh'taki listeyi al, tek pakman/AUR çağrısında hepsini kur
        local PACKAGES=()
        eval "$(sed -n '/^PACKAGES=(/,/^)/p' "$SRC/install_apps.sh")"
        pkgs+=("${PACKAGES[@]}")
    fi

    local missing
    mapfile -t missing < <(pacman -T "${pkgs[@]}" || true)
    if (( ${#missing[@]} == 0 )); then
        ok "Hepsi zaten kurulu."
        return
    fi
    echo "    Kurulacak (${#missing[@]}): ${missing[*]}"

    if command -v paru &>/dev/null; then
        paru -S --needed --noconfirm --skipreview "${missing[@]}"
    elif command -v yay &>/dev/null; then
        yay -S --needed --noconfirm --answerdiff None --answerclean None "${missing[@]}"
    else
        warn "paru/yay yok, sadece resmi depodakiler kuruluyor."
        sudo pacman -S --needed --noconfirm "${missing[@]}" || warn "Bazı paketler kurulamadı."
    fi
    ok "Paketler kuruldu."
}

do_kwin() {
    step "kwinrc kopyalanıyor..."
    backup "$CONFIG_DIR/kwinrc"
    cp "$SRC/kwinrc" "$CONFIG_DIR/kwinrc"
    ok "kwinrc yerleştirildi."
}

do_colors() {
    step "Renk teması kuruluyor..."
    backup "$CONFIG_DIR/kdeglobals"
    mkdir -p "$HOME/.local/share/color-schemes"
    cp "$SRC"/Colors/*.colors "$HOME/.local/share/color-schemes/"
    if command -v plasma-apply-colorscheme &>/dev/null; then
        plasma-apply-colorscheme Sweet >/dev/null && ok "Sweet renk şeması uygulandı."
    else
        warn "plasma-apply-colorscheme yok, Sweet'i ayarlardan seç."
    fi
}

do_kvantum() {
    step "Kvantum teması kuruluyor..."
    local archive
    archive=$(find "$SRC/Application" -name '*.tar.xz' -print -quit)
    if [[ -z $archive ]]; then
        warn "Kvantum arşivi bulunamadı, atlanıyor."
        return
    fi
    backup "$CONFIG_DIR/kdeglobals"
    backup "$CONFIG_DIR/Kvantum/kvantum.kvconfig"
    mkdir -p "$CONFIG_DIR/Kvantum"
    tar -xf "$archive" -C "$CONFIG_DIR/Kvantum" 2>/dev/null
    if command -v kvantummanager &>/dev/null; then
        kvantummanager --set Shades-of-purple >/dev/null
        kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle kvantum
        ok "Shades-of-purple aktif, uygulama stili Kvantum yapıldı."
    else
        warn "kvantummanager bulunamadı, temayı manuel seçmelisin."
    fi
}

do_decoration() {
    step "Pencere dekorasyonu ayarlanıyor..."
    backup "$CONFIG_DIR/sierrabreezeenhancedrc"
    cp "$SRC/Window Decorations/"* "$CONFIG_DIR/"
    ok "Sierra Breeze Enhanced ayarları kopyalandı."
}

do_panel() {
    step "Panel Colorizer preset'i kopyalanıyor..."
    local dest="$CONFIG_DIR/panel-colorizer/presets/Panel_Conf"
    mkdir -p "$dest"
    cp "$SRC"/Panel_Conf/* "$dest/"
    ok "Preset hazır. Panel'e Panel Colorizer widget'ını ekleyip Panel_Conf'u seç."
}

do_ufw() {
    step "UFW kuralları uygulanıyor..."
    if ! command -v ufw &>/dev/null; then
        warn "ufw kurulu değil, atlanıyor."
        return
    fi
    if ! sudo ufw status | grep -q 'Status: active'; then
        sudo ufw default deny incoming >/dev/null
        sudo ufw default allow outgoing >/dev/null
        sudo ufw --force enable >/dev/null
        sudo systemctl enable --now ufw.service &>/dev/null || true
        ok "UFW etkinleştirildi (gelen: deny, giden: allow)."
    fi
    local rule desc
    while read -r rule desc; do
        [[ -z $rule || $rule == \#* ]] && continue
        sudo ufw allow "$rule" comment "$desc" >/dev/null
        ok "$rule  ($desc)"
    done < "$SRC/UFW/rules.conf"
    sudo ufw reload >/dev/null
    ok "UFW yeniden yüklendi."
}

do_nvidia() {
    step "NVIDIA saat ayarı kuruluyor..."
    if ! command -v nvidia-smi &>/dev/null; then
        warn "nvidia-smi bulunamadı, atlanıyor."
        return
    fi
    # Servisteki saat değerleri RTX 3060'a göre; başka kartta yanlış olabilir
    local gpu
    gpu=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)
    if [[ $gpu != *"RTX 3060"* ]]; then
        warn "Kart '$gpu', ayarlar RTX 3060 için. NVIDIA/nvidia-clocks.service'i düzenleyip tekrar çalıştır."
        return
    fi
    sudo install -m 644 "$SRC/NVIDIA/nvidia-clocks.service" /etc/systemd/system/nvidia-clocks.service
    sudo systemctl daemon-reload
    sudo systemctl enable nvidia-persistenced.service nvidia-clocks.service &>/dev/null
    sudo systemctl restart nvidia-persistenced.service nvidia-clocks.service
    ok "Çekirdek 600-2100 MHz, bellek min 810 MHz (P5 altına inmez), persistence açık."
}

do_terminal() {
    step "Varsayılan terminal ayarlanıyor..."
    # Terminal=true olan .desktop uygulamaları (ör. cachy-update tray) GLib üzerinden açılır.
    # GLib KDE'nin terminal ayarına bakmaz, önce xdg-terminal-exec'i dener; tercih bu dosyadan okunur.
    backup "$CONFIG_DIR/kde-xdg-terminals.list"
    cp "$SRC/Terminal/kde-xdg-terminals.list" "$CONFIG_DIR/"
    command -v xdg-terminal-exec &>/dev/null || warn "xdg-terminal-exec kurulu değil, 'deps' adımını çalıştır."
    ok "Terminal tercihi: $(head -n1 "$SRC/Terminal/kde-xdg-terminals.list")"
}

do_restart() {
    step "Değişiklikler uygulanıyor..."
    if [[ ${XDG_CURRENT_DESKTOP:-} != *KDE* ]]; then
        warn "Plasma oturumunda değilsin, bir sonraki girişte uygulanacak."
        return
    fi
    qdbus6 org.kde.KWin /KWin reconfigure &>/dev/null || true
    systemctl --user restart plasma-plasmashell.service || warn "Plasma shell manuel başlatılmalı."
    ok "KWin ve Plasma yeniden yüklendi."
}

# --- Çalıştır --------------------------------------------------------------

for s in "${STEPS[@]}"; do "do_$s"; done
(( RESTART )) && do_restart

echo
echo "============================================"
echo "✓ Kurulum tamamlandı!"
[[ -d $BACKUP_DIR ]] && echo "  Eski ayarların yedeği: $BACKUP_DIR"
echo "  Kalan manuel adımlar: Plasma Style (Sweet) ve ikon teması — README'ye bak."
echo "============================================"
