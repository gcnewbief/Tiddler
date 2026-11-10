#!/usr/bin/env bash
# Download KF6 + kirigami-addons + futuresql + qcoro sources into kf6-src/
# Tries plain curl first; falls back to DoH-pinned IPs (flaky-DNS hosts).
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p kf6-src
DK=49.12.122.15      # download.kde.org
INV=188.40.133.145   # invent.kde.org
GH=140.82.121.4      # github.com

get() { # $1=out  $2=url
  local out="$1" url="$2"
  [ -f "$out" ] && return 0
  curl -sfL --retry 3 -o "$out" "$url" && return 0
  local host ip
  host=$(echo "$url" | sed -E 's|https?://([^/]+)/.*|\1|')
  case "$host" in
    download.kde.org) ip=$DK ;;
    invent.kde.org)   ip=$INV ;;
    github.com)       ip=$GH ;;
    *) return 1 ;;
  esac
  curl -sfL --retry 3 --resolve "$host:443:$ip" -o "$out" "$url"
}

KF=6.31.0
frameworks="extra-cmake-modules kcoreaddons kconfig ki18n kdbusaddons kwindowsystem kguiaddons kcolorscheme knotifications kcrash kirigami kitemmodels karchive kwidgetsaddons kiconthemes breeze-icons"

for f in $frameworks; do
  get "kf6-src/$f-$KF.tar.xz" "https://download.kde.org/stable/frameworks/${KF%.*}/$f-$KF.tar.xz" && echo "ok: $f"
done
get "kf6-src/kirigami-addons-1.16.1.tar.xz" \
  "https://download.kde.org/stable/kirigami-addons/kirigami-addons-1.16.1.tar.xz" && echo "ok: kirigami-addons"
get "kf6-src/plasma-wayland-protocols-1.19.0.tar.xz" \
  "https://download.kde.org/stable/plasma-wayland-protocols/plasma-wayland-protocols-1.19.0.tar.xz" \
  || echo "warn: plasma-wayland-protocols (optional)"
get "kf6-src/futuresql-main.tar.gz" \
  "https://invent.kde.org/libraries/futuresql/-/archive/master/futuresql-master.tar.gz" && echo "ok: futuresql"
get "kf6-src/qcoro-0.13.0.tar.gz" \
  "https://github.com/qcoro/qcoro/archive/refs/tags/v0.13.0.tar.gz" && echo "ok: qcoro"
