#!/usr/bin/env bash
# Build the KF6 stack needed by angelfish-qt6, in dependency order.
# Runs native arm64 (CI) or qemu. SRC = dir with tarballs, OUT = install prefix.
set -euo pipefail
SRC=${SRC:-/src}
OUT=${OUT:-/kf6}
PFX="-DCMAKE_PREFIX_PATH=$OUT -DCMAKE_INSTALL_PREFIX=$OUT -DCMAKE_BUILD_TYPE=Release -DBUILD_PYTHON_BINDINGS=OFF -GNinja"

build() { # $1 = tarball basename (no ext), $2.. = extra cmake args
  local name="$1"; shift
  if [ -f "$OUT/.done-$name" ]; then echo "== $name (cached)"; return; fi
  echo "== building $name"
  local work=/tmp/kf6work-$name
  rm -rf "$work" && mkdir -p "$work" && cd "$work"
  if [ -f "$SRC/$name.tar.xz" ]; then tar xJf "$SRC/$name.tar.xz"
  elif [ -f "$SRC/$name.tar.gz" ]; then tar xzf "$SRC/$name.tar.gz"
  else echo "missing tarball for $name" >&2; exit 1
  fi
  cd "$(find . -maxdepth 1 -mindepth 1 -type d | head -1)"
  cmake -B build $PFX "$@"
  cmake --build build -j"$(nproc)"
  cmake --install build
  touch "$OUT/.done-$name"
}

build extra-cmake-modules-6.31.0
build plasma-wayland-protocols-1.19.0 -DBUILD_WITH_QT6=ON
build kcoreaddons-6.31.0 -DBUILD_TESTING=OFF
build kconfig-6.31.0 -DBUILD_TESTING=OFF
build ki18n-6.31.0 -DBUILD_TESTING=OFF
build kdbusaddons-6.31.0 -DBUILD_TESTING=OFF
build kwindowsystem-6.31.0 -DBUILD_TESTING=OFF -DKWINDOWSYSTEM_WAYLAND=OFF
build kguiaddons-6.31.0 -DBUILD_TESTING=OFF
build kcolorscheme-6.31.0 -DBUILD_TESTING=OFF
build knotifications-6.31.0 -DBUILD_TESTING=OFF
build kcrash-6.31.0 -DBUILD_TESTING=OFF
build kitemmodels-6.31.0 -DBUILD_TESTING=OFF
build kirigami-6.31.0 -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF
build karchive-6.31.0 -DBUILD_TESTING=OFF
build kwidgetsaddons-6.31.0 -DBUILD_TESTING=OFF
build breeze-icons-6.31.0 -DBUILD_TESTING=OFF
build kiconthemes-6.31.0 -DBUILD_TESTING=OFF
build kglobalaccel-6.31.0 -DBUILD_TESTING=OFF
build kirigami-addons-1.16.1 -DBUILD_TESTING=OFF
build qcoro-0.13.0 -DBUILD_TESTING=OFF -DQCORO_BUILD_EXAMPLES=OFF \
  -DQCORO_WITH_QTDBUS=OFF -DQCORO_WITH_QTNETWORK=OFF \
  -DQCORO_WITH_QTWEBSOCKETS=OFF
build futuresql-main -DBUILD_TESTING=OFF
echo "== KF6 stack complete =="
