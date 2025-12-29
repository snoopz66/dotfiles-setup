#!/usr/bin/env bash
set -euo pipefail

# Free Linux plugins for metal/rock mixing (Arch):
# - LSP Plugins (VST3): EQ, compressors, limiter, gate, de-esser, analyzers, etc.
# - ZamAudio plugins (VST3): extra dynamics/EQ/tools
# - Airwindows Consolidated (CLAP + VST3 + LV2): huge free suite
#
# Installs into:
#   ~/.vst3  ~/.clap  ~/.lv2
#
# Notes:
# - Bitwig: VST3 + CLAP are native. LV2 requires a bridge (e.g., Carla) if you ever want it.
# - Reaper: VST3 native; LV2 also supported on Linux.
#
# Requirements: curl, jq, unzip, pacman

echo "==> Installing packages (pacman)"
sudo pacman -S --needed --noconfirm \
  curl jq unzip \
  lsp-plugins-vst3 \
  zam-plugins-vst3

# Create user plugin dirs (Bitwig/Reaper will typically scan these)
mkdir -p "$HOME/.vst3" "$HOME/.clap" "$HOME/.lv2"

echo "==> Installing Airwindows Consolidated (CLAP/VST3/LV2) from GitHub release"

# This repo is used by the Arch AUR package and hosts the Linux zip asset. :contentReference[oaicite:4]{index=4}
GH_OWNER="baconpaul"
GH_REPO="airwin2rack"
TAG="DAWPlugin"

API_URL="https://api.github.com/repos/${GH_OWNER}/${GH_REPO}/releases/tags/${TAG}"

tmpdir="$(mktemp -d)"
cleanup() { rm -rf "$tmpdir"; }
trap cleanup EXIT

zip_url="$(
  curl -fsSL "$API_URL" \
  | jq -r '.assets[].browser_download_url' \
  | grep -E 'AirwindowsConsolidated-.*-Linux\.zip$' \
  | head -n 1
)"

if [[ -z "${zip_url:-}" ]]; then
  echo "ERROR: Could not find Airwindows Consolidated Linux zip asset from GitHub API."
  echo "Check the releases for ${GH_OWNER}/${GH_REPO} tag ${TAG}."
  exit 1
fi

echo "==> Downloading: $zip_url"
curl -fL "$zip_url" -o "$tmpdir/awcons.zip"

echo "==> Extracting"
unzip -q "$tmpdir/awcons.zip" -d "$tmpdir/awcons"

# The zip usually contains awcons-products/ with:
#   "Airwindows Consolidated.clap"
#   "Airwindows Consolidated.vst3"
#   "Airwindows Consolidated.lv2"
prod_dir="$tmpdir/awcons/awcons-products"
if [[ ! -d "$prod_dir" ]]; then
  # Fallback: try to locate it
  prod_dir="$(find "$tmpdir/awcons" -maxdepth 3 -type d -name 'awcons-products' | head -n 1 || true)"
fi
if [[ -z "${prod_dir:-}" || ! -d "$prod_dir" ]]; then
  echo "ERROR: Could not locate 'awcons-products' in the Airwindows zip."
  exit 1
fi

# Install CLAP
if [[ -e "$prod_dir/Airwindows Consolidated.clap" ]]; then
  echo "==> Installing CLAP to ~/.clap"
  cp -a "$prod_dir/Airwindows Consolidated.clap" "$HOME/.clap/"
fi

# Install VST3
if [[ -d "$prod_dir/Airwindows Consolidated.vst3" ]]; then
  echo "==> Installing VST3 to ~/.vst3"
  cp -a "$prod_dir/Airwindows Consolidated.vst3" "$HOME/.vst3/"
fi

# Install LV2 (optional, but harmless to install)
if [[ -d "$prod_dir/Airwindows Consolidated.lv2" ]]; then
  echo "==> Installing LV2 to ~/.lv2"
  cp -a "$prod_dir/Airwindows Consolidated.lv2" "$HOME/.lv2/"
fi

echo
echo "=================================================="
echo "DONE."
echo
echo "Installed:"
echo "  - LSP Plugins (VST3)          -> system VST3 path (Arch package)"
echo "  - ZamAudio plugins (VST3)     -> system VST3 path (Arch package)"
echo "  - Airwindows Consolidated:"
echo "      ~/.clap/Airwindows Consolidated.clap"
echo "      ~/.vst3/Airwindows Consolidated.vst3"
echo "      ~/.lv2/Airwindows Consolidated.lv2"
echo
echo "Next:"
echo "  - Re-scan plugins in Reaper/Bitwig."
echo "  - In Bitwig: Settings -> Locations -> Plug-ins -> ensure ~/.vst3 and ~/.clap are scanned."
echo "=================================================="

