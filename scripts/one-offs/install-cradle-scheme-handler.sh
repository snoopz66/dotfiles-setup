#!/usr/bin/env bash
set -euo pipefail

# Register Cradle Hub OAuth callback URL scheme (app.cradle://) to launch Cradle Hub inside Bottles (Flatpak).
#
# Usage:
#   ./install-cradle-scheme-handler.sh [BOTTLE_NAME] ["PROGRAM_NAME"] [SCHEME]
#
# Defaults:
#   BOTTLE_NAME  = VSTs
#   PROGRAM_NAME = Cradle Hub
#   SCHEME       = app.cradle
#
# Test:
#   xdg-open 'app.cradle://test'
# Verify:
#   xdg-mime query default x-scheme-handler/app.cradle

BOTTLE="${1:-VSTs}"
PROGRAM="${2:-Cradle Hub}"
SCHEME="${3:-app.cradle}"

BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"

HANDLER_SH="${BIN_DIR}/${SCHEME}-handler.sh"
DESKTOP_FILE="${APP_DIR}/${SCHEME}-handler.desktop"

mkdir -p "$BIN_DIR" "$APP_DIR"

cat > "$HANDLER_SH" <<EOF
#!/usr/bin/env bash
set -euo pipefail
url="\${1:-}"
[[ -n "\$url" ]] || exit 0
exec flatpak run --command=bottles-cli com.usebottles.bottles run -b "${BOTTLE}" -p "${PROGRAM}" -a "\$url"
EOF
chmod +x "$HANDLER_SH"

cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Type=Application
Name=Cradle Hub URL Handler (Bottles)
Exec=${HANDLER_SH} %u
NoDisplay=true
Terminal=false
MimeType=x-scheme-handler/${SCHEME};
EOF

update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
xdg-mime default "$(basename "$DESKTOP_FILE")" "x-scheme-handler/${SCHEME}"

echo "Installed scheme handler:"
echo "  Scheme:   ${SCHEME}://"
echo "  Bottle:   ${BOTTLE}"
echo "  Program:  ${PROGRAM}"
echo "  Desktop:  ${DESKTOP_FILE}"
echo
echo "Test with:"
echo "  xdg-open '${SCHEME}://test'"
echo
echo "Verify with:"
echo "  xdg-mime query default x-scheme-handler/${SCHEME}"

