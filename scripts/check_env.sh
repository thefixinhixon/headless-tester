#!/usr/bin/env bash
# check_env.sh: read-only probe of this machine for headless game testing.
# usage: scripts/check_env.sh [game-executable-name]
# Prints "key: value" lines so an agent can answer interview questions without asking the user.
# It changes nothing: no installs, no displays started, no devices opened.
set -u
GAME="${1:-}"
say() { printf '%-22s %s\n' "$1:" "$2"; }
have() { command -v "$1" >/dev/null 2>&1; }

echo "== system"
say os "$( (. /etc/os-release 2>/dev/null && echo "$PRETTY_NAME") || uname -sr)"
say kernel "$(uname -r)"
say cpus "$(nproc 2>/dev/null)"
say session "${XDG_SESSION_TYPE:-unknown} (WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-unset}, DISPLAY=${DISPLAY:-unset})"
pm=unknown; for p in apt-get dnf pacman zypper; do have $p && { pm=$p; break; }; done
say package-manager "$pm"

echo "== tools"
declare -A pkg_apt=([Xvfb]=xvfb [xdotool]=xdotool [import]=imagemagick [gdb]=gdb [eu-stack]=elfutils
  [taskset]=util-linux [lsusb]=usbutils [vulkaninfo]=vulkan-tools [glxinfo]=mesa-utils [gcc]=gcc [git]=git)
missing=()
for t in Xvfb xdotool import gdb eu-stack taskset lsusb vulkaninfo glxinfo gcc git; do
  if have "$t"; then say "$t" ok; else say "$t" MISSING; missing+=("${pkg_apt[$t]}"); fi
done
[ ${#missing[@]} -gt 0 ] && say install-hint "($pm) ${missing[*]}  [apt names; dnf/pacman names differ]"

echo "== gpu"
have lspci && lspci 2>/dev/null | grep -iE 'vga|3d|display' | sed 's/^/gpu:                   /'
if have vulkaninfo; then
  vulkaninfo --summary 2>/dev/null | grep -E 'deviceName|driverName|apiVersion' | sort -u | sed 's/^ */vulkan:                /'
fi
have glxinfo && [ -n "${DISPLAY:-}" ] && say opengl "$(glxinfo -B 2>/dev/null | grep -m1 'OpenGL renderer' | cut -d: -f2-)"

echo "== limits"
say perf_event_paranoid "$(cat /proc/sys/kernel/perf_event_paranoid 2>/dev/null || echo n/a) (>=3 blocks perf; use eu-stack, guide §6)"
say ptrace_scope "$(cat /proc/sys/kernel/yama/ptrace_scope 2>/dev/null || echo n/a) (1 = parent only; use ptracer.so)"
say dev-shm "$(df -h /dev/shm 2>/dev/null | awk 'NR==2 {print $3 " used of " $2}')"
say tmp-free "$(df -h /tmp 2>/dev/null | awk 'NR==2 {print $4}')"

echo "== x displays in use"
ls /tmp/.X11-unix 2>/dev/null | sed 's/^X/display:               :/'
pgrep -a Xvfb 2>/dev/null | sed 's/^/xvfb:                  /'

echo "== controller candidates (vendor match can include keyboards/mice: confirm with the user)"
if have lsusb; then
  # Microsoft, Sony, Nintendo, Valve, Logitech, 8BitDo, PDP, PowerA (2), Hori, Razer, Nacon, Thrustmaster
  lsusb | grep -iE 'ID (045e|054c|057e|28de|046d|2dc8|0e6f|24c6|20d6|0f0d|1532|146b|044f):|gamepad|controller|joystick' |
    sed 's/^/usb:                   /'
fi
grep -iE '^N: Name=.*(pad|controller|joystick|x-?box|dualsense|dualshock|pro controller)' /proc/bus/input/devices 2>/dev/null |
  sed 's/^N: Name=/input:                 /'
ls /dev/input/js* 2>/dev/null | sed 's/^/joystick-node:         /'
have bluetoothctl && bluetoothctl devices Connected 2>/dev/null | sed 's/^/bluetooth:             /'

if [ -n "$GAME" ]; then
  echo "== running copies of $GAME"
  for p in $(pgrep -x "${GAME:0:15}"); do say "pid $p" "cwd=$(readlink /proc/$p/cwd 2>/dev/null)"; done
fi
