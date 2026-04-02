#!/usr/bin/env bash
# KDE Plasma Customization Installer
# Automatically applies all KDE Plasma customizations from this repository.

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Helpers ───────────────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die()     { error "$*"; exit 1; }

# ── Locate script directory (works even when called from another directory) ───
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Timestamp for backups ─────────────────────────────────────────────────────
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="${HOME}/.config/kde-config-backup-${TIMESTAMP}"

# ── Backup a file if it already exists ───────────────────────────────────────
backup_file() {
    local src="$1"
    if [[ -e "$src" ]]; then
        mkdir -p "$BACKUP_DIR"
        cp -a "$src" "$BACKUP_DIR/" 2>/dev/null || true
        info "Backed up $(basename "$src") → $BACKUP_DIR/"
    fi
}

# ── Banner ────────────────────────────────────────────────────────────────────
echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════╗"
echo "║   KDE Plasma Customization Installer         ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Sanity checks ─────────────────────────────────────────────────────────────
[[ -d "$HOME" ]] || die "Cannot determine home directory."
command -v plasmashell &>/dev/null || warn "plasmashell not found – are you running KDE Plasma?"

# ── Detect package manager ────────────────────────────────────────────────────
detect_pkg_manager() {
    if command -v pacman &>/dev/null; then   echo "pacman"
    elif command -v apt-get &>/dev/null; then echo "apt"
    elif command -v dnf &>/dev/null; then    echo "dnf"
    elif command -v zypper &>/dev/null; then echo "zypper"
    else                                     echo "unknown"
    fi
}

# ── Try to install a package with the detected manager (requires sudo) ────────
try_install_pkg() {
    local pkg_pacman="$1" pkg_apt="$2" pkg_dnf="$3" pkg_zypper="$4"
    local mgr
    mgr="$(detect_pkg_manager)"
    case "$mgr" in
        pacman)  sudo pacman -S --noconfirm "$pkg_pacman" 2>/dev/null ;;
        apt)     sudo apt-get install -y "$pkg_apt"     2>/dev/null ;;
        dnf)     sudo dnf install -y "$pkg_dnf"         2>/dev/null ;;
        zypper)  sudo zypper install -y "$pkg_zypper"   2>/dev/null ;;
        *)       return 1 ;;
    esac
}

# ── Step 1: kwinrc ────────────────────────────────────────────────────────────
echo -e "\n${BOLD}Step 1/7 – Installing kwinrc${NC}"
KWINRC_SRC="${SCRIPT_DIR}/kwinrc"
KWINRC_DST="${HOME}/.config/kwinrc"

[[ -f "$KWINRC_SRC" ]] || die "kwinrc not found in ${SCRIPT_DIR}"

backup_file "$KWINRC_DST"
cp "$KWINRC_SRC" "$KWINRC_DST"
success "kwinrc copied to ~/.config/kwinrc"

# ── Step 2: Color scheme ──────────────────────────────────────────────────────
echo -e "\n${BOLD}Step 2/7 – Installing Sweet color scheme${NC}"
COLOR_SRC="${SCRIPT_DIR}/Colors/Sweet.colors"
COLOR_DST_DIR="${HOME}/.local/share/color-schemes"
COLOR_DST="${COLOR_DST_DIR}/Sweet.colors"

[[ -f "$COLOR_SRC" ]] || die "Sweet.colors not found in ${SCRIPT_DIR}/Colors/"

mkdir -p "$COLOR_DST_DIR"
backup_file "$COLOR_DST"
cp "$COLOR_SRC" "$COLOR_DST"
success "Sweet color scheme installed → ${COLOR_DST}"

# ── Step 3: Kvantum application theme ────────────────────────────────────────
echo -e "\n${BOLD}Step 3/7 – Installing Kvantum theme${NC}"
APP_DIR="${SCRIPT_DIR}/Application"
KVANTUM_ARCHIVE="$(find "$APP_DIR" -maxdepth 1 -name '*.tar.xz' 2>/dev/null | head -n1)"
KVANTUM_DIR="${HOME}/.config/Kvantum"

if [[ -z "$KVANTUM_ARCHIVE" ]]; then
    warn "No .tar.xz archive found in ${APP_DIR} – skipping Kvantum theme installation."
else
    command -v tar &>/dev/null || die "tar is required to extract the Kvantum theme."
    mkdir -p "$KVANTUM_DIR"

    THEME_NAME="$(basename "$KVANTUM_ARCHIVE" .tar.xz)"
    backup_file "${KVANTUM_DIR}/${THEME_NAME}"

    if ! tar -xJf "$KVANTUM_ARCHIVE" -C "$KVANTUM_DIR" 2>/tmp/tar_err; then
        warn "tar reported errors: $(cat /tmp/tar_err | grep -v 'LIBARCHIVE.xattr' | head -5)"
    fi
    success "Kvantum theme '${THEME_NAME}' extracted → ${KVANTUM_DIR}"

    if command -v kvantummanager &>/dev/null; then
        kvantummanager --set "$THEME_NAME" 2>/dev/null && \
            success "Kvantum theme '${THEME_NAME}' applied via kvantummanager." || \
            warn "kvantummanager returned a non-zero exit code; theme may still be installed."
    else
        warn "kvantummanager not found – Kvantum theme extracted but not set. Open Kvantum Manager and select '${THEME_NAME}' manually."
    fi
fi

# ── Step 4: Sierra Breeze Enhanced window decoration ─────────────────────────
echo -e "\n${BOLD}Step 4/7 – Installing Sierra Breeze Enhanced window decoration${NC}"
SIERRA_LIB_DIRS=( "/usr/lib/qt/plugins/org.kde.kdecoration2"
                  "/usr/lib64/qt/plugins/org.kde.kdecoration2"
                  "/usr/lib/x86_64-linux-gnu/qt6/plugins/org.kde.kdecoration2"
                  "${HOME}/.local/lib64/qt6/plugins/org.kde.kdecoration2"
                  "${HOME}/.local/lib/qt6/plugins/org.kde.kdecoration2" )
sierra_installed() {
    for d in "${SIERRA_LIB_DIRS[@]}"; do
        [[ -f "${d}/sierrabreezeenhanced.so" ]] && return 0
    done
    return 1
}

if sierra_installed; then
    success "Sierra Breeze Enhanced is already installed – skipping."
else
    info "Trying to install Sierra Breeze Enhanced via package manager…"
    # Arch: sierrabreezeenhanced (AUR – needs an AUR helper), Debian/Ubuntu: no official pkg,
    # openSUSE: might be in KDE repos. We try common package names first.
    if try_install_pkg "sierrabreezeenhanced" "sierrabreezeenhanced" "kwin-decoration-sierra-breeze-enhanced" "sierrabreezeenhanced" 2>/dev/null; then
        success "Sierra Breeze Enhanced installed via package manager."
    else
        info "Package manager install not available – building from source…"
        BUILD_DEPS_OK=true
        for dep in git cmake make g++; do
            command -v "$dep" &>/dev/null || { warn "Build dependency missing: $dep"; BUILD_DEPS_OK=false; }
        done

        if [[ "$BUILD_DEPS_OK" == true ]]; then
            SIERRA_BUILD_DIR="$(mktemp -d /tmp/sierrabreeze-build.XXXXXX)"
            (
                set -e
                git clone --depth=1 https://github.com/kupiqu/SierraBreezeEnhanced.git "$SIERRA_BUILD_DIR/src"
                mkdir -p "$SIERRA_BUILD_DIR/build"
                cd "$SIERRA_BUILD_DIR/build"
                cmake ../src -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
                make -j"$(nproc)"
                sudo make install
            ) && success "Sierra Breeze Enhanced built and installed from source." \
              || warn "Build failed. Install Sierra Breeze Enhanced manually: https://github.com/kupiqu/SierraBreezeEnhanced"
            rm -rf "$SIERRA_BUILD_DIR"
        else
            warn "Cannot build Sierra Breeze Enhanced – missing build tools. Install it manually:"
            warn "  https://github.com/kupiqu/SierraBreezeEnhanced"
        fi
    fi
fi

# ── Step 5: Window decoration config ─────────────────────────────────────────
echo -e "\n${BOLD}Step 5/7 – Installing Sierra Breeze window decoration config${NC}"
WD_DIR="${SCRIPT_DIR}/Window Decorations"
WD_RC_SRC="$(find "$WD_DIR" -maxdepth 1 -type f ! -name '*.png' 2>/dev/null | head -n1)"
WD_RC_DST=""

if [[ -z "$WD_RC_SRC" ]]; then
    warn "No window decoration config found in '${WD_DIR}' – skipping."
else
    WD_RC_DST="${HOME}/.config/$(basename "$WD_RC_SRC")"
    backup_file "$WD_RC_DST"
    cp "$WD_RC_SRC" "$WD_RC_DST"
    success "Window decoration config copied → ${WD_RC_DST}"
fi

# ── Step 6: Download and install Panel Colorizer plasmoid ────────────────────
echo -e "\n${BOLD}Step 6/7 – Installing Panel Colorizer plasmoid${NC}"
PANEL_PKG_ID="luisbocanegra.panel.colorizer"

panel_colorizer_installed() {
    if command -v kpackagetool6 &>/dev/null; then
        kpackagetool6 --list --type Plasma/Applet 2>/dev/null | grep -q "$PANEL_PKG_ID"
    elif command -v kpackagetool5 &>/dev/null; then
        kpackagetool5 --list --type Plasma/Applet 2>/dev/null | grep -q "$PANEL_PKG_ID"
    else
        return 1
    fi
}

if panel_colorizer_installed; then
    success "Panel Colorizer is already installed – skipping."
else
    PLASMOID_URL=""
    if command -v curl &>/dev/null; then
        PLASMOID_URL="$(curl -fsSL "https://api.github.com/repos/luisbocanegra/plasma-panel-colorizer/releases/latest" 2>/dev/null \
            | grep '"browser_download_url"' | grep '\.plasmoid"' | head -n1 | cut -d '"' -f4)" || true
    fi

    if [[ -z "$PLASMOID_URL" ]]; then
        warn "Could not determine Panel Colorizer download URL. Install it manually from:"
        warn "  https://github.com/luisbocanegra/plasma-panel-colorizer/releases"
    else
        PLASMOID_TMP="$(mktemp /tmp/panel-colorizer.XXXXXX.plasmoid)"
        info "Downloading Panel Colorizer from GitHub…"
        if curl -fsSL -o "$PLASMOID_TMP" "$PLASMOID_URL"; then
            KPKG=""
            command -v kpackagetool6 &>/dev/null && KPKG="kpackagetool6"
            command -v kpackagetool5 &>/dev/null && [[ -z "$KPKG" ]] && KPKG="kpackagetool5"

            if [[ -z "$KPKG" ]]; then
                warn "kpackagetool6/kpackagetool5 not found – cannot install plasmoid automatically."
                warn "  Downloaded file kept at: ${PLASMOID_TMP}"
                warn "  Install manually with: kpackagetool6 --install ${PLASMOID_TMP}"
            elif "$KPKG" --install "$PLASMOID_TMP" 2>/dev/null; then
                success "Panel Colorizer installed via ${KPKG}."
                rm -f "$PLASMOID_TMP"
            elif "$KPKG" --upgrade "$PLASMOID_TMP" 2>/dev/null; then
                success "Panel Colorizer upgraded via ${KPKG}."
                rm -f "$PLASMOID_TMP"
            else
                warn "kpackagetool install failed. Try manually:"
                warn "  ${KPKG} --install ${PLASMOID_TMP}"
            fi
        else
            warn "Download failed. Install Panel Colorizer manually from:"
            warn "  https://github.com/luisbocanegra/plasma-panel-colorizer/releases"
            rm -f "$PLASMOID_TMP"
        fi
    fi
fi

# ── Step 7: Panel Colorizer preset ───────────────────────────────────────────
echo -e "\n${BOLD}Step 7/7 – Installing Panel Colorizer preset${NC}"
PANEL_SRC_DIR="${SCRIPT_DIR}/Panel_Conf"
PANEL_DST_DIR="${HOME}/.config/panel-colorizer/presets"
PANEL_JSON_SRC="${PANEL_SRC_DIR}/settings.json"

if [[ ! -f "$PANEL_JSON_SRC" ]]; then
    warn "Panel Colorizer settings.json not found in ${PANEL_SRC_DIR} – skipping."
else
    mkdir -p "$PANEL_DST_DIR"
    backup_file "${PANEL_DST_DIR}/settings.json"
    cp "$PANEL_JSON_SRC" "${PANEL_DST_DIR}/settings.json"
    success "Panel Colorizer preset copied → ${PANEL_DST_DIR}/settings.json"
fi

# ── Restart Plasma shell ──────────────────────────────────────────────────────
echo -e "\n${BOLD}Restarting Plasma shell to apply changes…${NC}"
if command -v systemctl &>/dev/null && systemctl --user is-active plasma-plasmashell.service &>/dev/null; then
    systemctl --user restart plasma-plasmashell.service && \
        success "plasma-plasmashell.service restarted." || \
        warn "Failed to restart plasma-plasmashell.service via systemctl."
elif command -v plasmashell &>/dev/null; then
    # Try graceful quit first, then fall back to kill
    if command -v kquitapp6 &>/dev/null; then
        kquitapp6 plasmashell 2>/dev/null || true
    elif command -v kquitapp5 &>/dev/null; then
        kquitapp5 plasmashell 2>/dev/null || true
    else
        killall plasmashell 2>/dev/null || true
    fi
    nohup plasmashell &>/dev/null &
    success "Plasma shell restarted."
else
    warn "Could not restart Plasma shell automatically. Please log out and back in, or run:"
    warn "  systemctl --user restart plasma-plasmashell.service"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}✓ Installation complete!${NC}"
echo ""
echo -e "  ${BOLD}Manual steps still required:${NC}"
echo "  • Plasma Style: Go to System Settings → Colors & Themes → Plasma Style,"
echo "    click 'Get New', search for 'Sweet' and apply it."
echo "  • Icons: Go to System Settings → Colors & Themes → Icons,"
echo "    click 'Get New' and install your preferred icon pack."
echo "  • Panel Colorizer widget: Add the Panel Colorizer widget to your panel,"
echo "    open its settings, and select the 'Panel_Conf' preset from the list."
echo ""
if [[ -d "$BACKUP_DIR" ]]; then
    echo -e "  ${BOLD}Your previous config files were backed up to:${NC}"
    echo "  ${BACKUP_DIR}"
    echo ""
fi
