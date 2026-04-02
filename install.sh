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

# ── Step 1: kwinrc ────────────────────────────────────────────────────────────
echo -e "\n${BOLD}Step 1/5 – Installing kwinrc${NC}"
KWINRC_SRC="${SCRIPT_DIR}/kwinrc"
KWINRC_DST="${HOME}/.config/kwinrc"

[[ -f "$KWINRC_SRC" ]] || die "kwinrc not found in ${SCRIPT_DIR}"

backup_file "$KWINRC_DST"
cp "$KWINRC_SRC" "$KWINRC_DST"
success "kwinrc copied to ~/.config/kwinrc"

# ── Step 2: Color scheme ──────────────────────────────────────────────────────
echo -e "\n${BOLD}Step 2/5 – Installing Sweet color scheme${NC}"
COLOR_SRC="${SCRIPT_DIR}/Colors/Sweet.colors"
COLOR_DST_DIR="${HOME}/.local/share/color-schemes"
COLOR_DST="${COLOR_DST_DIR}/Sweet.colors"

[[ -f "$COLOR_SRC" ]] || die "Sweet.colors not found in ${SCRIPT_DIR}/Colors/"

mkdir -p "$COLOR_DST_DIR"
backup_file "$COLOR_DST"
cp "$COLOR_SRC" "$COLOR_DST"
success "Sweet color scheme installed → ${COLOR_DST}"

# ── Step 3: Kvantum application theme ────────────────────────────────────────
echo -e "\n${BOLD}Step 3/5 – Installing Kvantum theme${NC}"
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

# ── Step 4: Window decoration config ─────────────────────────────────────────
echo -e "\n${BOLD}Step 4/5 – Installing Sierra Breeze window decoration config${NC}"
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

# ── Step 5: Panel Colorizer preset ───────────────────────────────────────────
echo -e "\n${BOLD}Step 5/5 – Installing Panel Colorizer preset${NC}"
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
echo "  • Step (original 4): Go to System Settings → Colors & Themes → Plasma Style,"
echo "    click 'Get New', search for 'Sweet' and apply it."
echo "  • Step (original 6): Go to System Settings → Colors & Themes → Icons,"
echo "    click 'Get New' and install your preferred icon pack."
echo ""
if [[ -d "$BACKUP_DIR" ]]; then
    echo -e "  ${BOLD}Your previous config files were backed up to:${NC}"
    echo "  ${BACKUP_DIR}"
    echo ""
fi
