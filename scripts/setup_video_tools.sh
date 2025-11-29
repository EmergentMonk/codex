#!/usr/bin/env bash
set -euo pipefail

# One-shot installer for common video tools on Ubuntu 24.04.
# Packages cover playback, capture/streaming, editing, and metadata inspection.

ensure_root() {
  if [[ $(id -u) -eq 0 ]]; then
    return
  fi

  if command -v sudo >/dev/null 2>&1; then
    exec sudo --preserve-env=DEBIAN_FRONTEND "$0" "$@"
  fi

  echo "This script must run as root or with sudo available." >&2
  exit 1
}

main() {
  ensure_root "$@"

  export DEBIAN_FRONTEND=noninteractive

  apt-get update

  local packages=(
    ffmpeg
    gstreamer1.0-plugins-bad
    gstreamer1.0-plugins-ugly
    handbrake
    libavcodec-extra
    mediainfo
    mpv
    obs-studio
    shotcut
    vlc
  )

  apt-get install -y "${packages[@]}"
}

main "$@"
