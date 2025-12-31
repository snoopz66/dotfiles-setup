#!/usr/bin/env bash
set -euo pipefail

# Re-run as root if needed
if [[ "${EUID}" -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

REMOVE_PKGS=(
  1password-beta
  1password-cli
  cups
  cups-browsed
  cups-filters
  cups-pdf
  github-cli
  kdenlive
  mariadb-libs
  obs-studio
  obsidian
  postgresql-libs
  signal-desktop
)

# Official repo installs
INSTALL_PKGS=(
  deluge-gtk
  firefox
  kitty
  steam
  prismlauncher
  zed
  telegram-desktop
  reaper
  reapack
  xwayland-satellite
)

# AUR installs
AUR_PKGS=(
)

log() { printf "\n==> %s\n" "$*"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

detect_aur_helper() {
  if have_cmd paru; then
    echo "paru"
  elif have_cmd yay; then
    echo "yay"
  else
    echo ""
  fi
}

enable_multilib_if_needed() {
  local conf="/etc/pacman.conf"
  if grep -Eq '^\s*\[multilib\]\s*$' "$conf" && grep -Eq '^\s*Include\s*=\s*/etc/pacman\.d/mirrorlist\s*$' "$conf"; then
    # If the section exists but is commented, uncomment it.
    if grep -Eq '^\s*#\s*\[multilib\]\s*$' "$conf"; then
      log "Enabling multilib repo in $conf"
      cp -a "$conf" "${conf}.bak.$(date +%Y%m%d%H%M%S)"
      # Uncomment the [multilib] line and the following Include line
      sed -i \
        -e '/^\s*#\s*\[multilib\]\s*$/s/^\s*#\s*//' \
        -e '/^\s*\[multilib\]\s*$/,/^\s*\[/{/^\s*#\s*Include\s*=\s*\/etc\/pacman\.d\/mirrorlist\s*$/s/^\s*#\s*//}' \
        "$conf"
    fi
  else
    # Section missing entirely: append a standard block.
    if ! grep -Eq '^\s*\[multilib\]\s*$' "$conf"; then
      log "Adding multilib repo block to $conf"
      cp -a "$conf" "${conf}.bak.$(date +%Y%m%d%H%M%S)"
      cat >>"$conf" <<'EOF'

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
    fi
  fi
}

stop_disable_cups_services() {
  log "Stopping/disabling printing services (if present)"
  systemctl disable --now cups.socket cups.service cups-browsed.service 2>/dev/null || true
}

remove_packages_if_installed() {
  local installed=()
  for p in "${REMOVE_PKGS[@]}"; do
    if pacman -Qq "$p" >/dev/null 2>&1; then
      installed+=("$p")
    fi
  done

  if ((${#installed[@]} == 0)); then
    log "No listed packages are installed. Skipping removal."
    return
  fi

  log "Removing packages: ${installed[*]}"
  pacman -Rns --noconfirm "${installed[@]}"
}

install_official_packages() {
  log "Syncing repositories and updating system"
  pacman -Syyu --noconfirm

  log "Installing official packages: ${INSTALL_PKGS[*]}"
  pacman -S --needed --noconfirm "${INSTALL_PKGS[@]}"
}

install_aur_packages() {
  local helper
  helper="$(detect_aur_helper)"

  if [[ -z "$helper" ]]; then
    log "No AUR helper found (paru/yay). Skipping AUR installs: ${AUR_PKGS[*]}"
    log "Install one (e.g., paru or yay) then run:"
    log "  paru -S ${AUR_PKGS[*]}   # or: yay -S ${AUR_PKGS[*]}"
    return
  fi

  log "Installing AUR packages with $helper: ${AUR_PKGS[*]}"
  # Run AUR helper as the invoking user (not root) for best behavior.
  # SUDO_USER is set when running under sudo.
  local user="${SUDO_USER:-root}"
  if [[ "$user" == "root" ]]; then
    log "Warning: running as root without SUDO_USER; attempting AUR install anyway."
    "$helper" -S --needed "${AUR_PKGS[@]}"
  else
    sudo -u "$user" -- "$helper" -S --needed "${AUR_PKGS[@]}"
  fi
}

main() {
  stop_disable_cups_services
  remove_packages_if_installed

  enable_multilib_if_needed
  install_official_packages
  install_aur_packages

  log "Done."
  log "Notes:"
  log "- Steam is in multilib; if you just enabled multilib, the pacman sync above handled it."
  log "- Bitwig Studio is proprietary; the AUR build may require you to download the Bitwig .deb and retry."
}

main "$@"
