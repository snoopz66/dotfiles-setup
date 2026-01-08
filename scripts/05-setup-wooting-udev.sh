#!/usr/bin/env bash
set -euo pipefail

# Re-run as root if needed
if [[ "${EUID}" -ne 0 ]]; then
  exec sudo -E bash "$0" "$@"
fi

RULES_PATH="/etc/udev/rules.d/70-wooting.rules"

log() { printf "\n==> %s\n" "$*"; }

write_rules() {
  cat <<'EOF'
# Wooting One Legacy
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff01", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff01", TAG+="uaccess"

# Wooting One update mode
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2402", TAG+="uaccess"

# Wooting Two Legacy
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff02", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="ff02", TAG+="uaccess"

# Wooting Two update mode
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03eb", ATTRS{idProduct}=="2403", TAG+="uaccess"

# Generic Wooting devices
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="31e3", TAG+="uaccess"
SUBSYSTEM=="usb", ATTRS{idVendor}=="31e3", TAG+="uaccess"
EOF
}

log "Writing Wooting udev rules to $RULES_PATH"
install -d -m 0755 /etc/udev/rules.d
write_rules > "$RULES_PATH"

log "Reloading udev rules"
udevadm control --reload-rules
udevadm trigger

log "Done. If Wootility is open, unplug/replug the device or restart Wootility."
