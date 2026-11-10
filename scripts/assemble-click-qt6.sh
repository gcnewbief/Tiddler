#!/usr/bin/env bash
# Assemble tiddler Qt6 click dir from installed system files + built KF6 stack.
# Run on arm64 (CI runner or build container). Expects:
#   - angelfish binary at $ANGELFISH_BIN
#   - KF6/qcoro/futuresql stack installed at $KF6_PREFIX
#   - ubports Qt6 debs installed system-wide (/usr/lib/aarch64-linux-gnu)
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
KF6_PREFIX=${KF6_PREFIX:-$ROOT/kf6-out}
ANGELFISH_BIN=${ANGELFISH_BIN:-$ROOT/angelfish-src/angelfish-v26.08.3/build-qt6/bin/angelfish}
ST=${STAGING_DIR:-$ROOT/click-qt6}
LIB=$ST/lib/aarch64-linux-gnu
TRIPLET=aarch64-linux-gnu

rm -rf "$ST"
mkdir -p "$LIB/bin" "$LIB/resources" "$LIB/translations" "$LIB/qt6" "$ST/icons" "$ST/share"

# --- Qt6 + KF6 + ancillary shared libs ---
cp -a /usr/lib/$TRIPLET/libQt6*.so* "$LIB/" 2>/dev/null || true
cp -a /usr/lib/$TRIPLET/libqt6*.so* "$LIB/" 2>/dev/null || true
for pre in /usr/lib/$TRIPLET /usr/lib; do
  cp -a "$pre"/libKF6*.so* "$LIB/" 2>/dev/null || true
  cp -a "$pre"/libQCoro*.so* "$LIB/" 2>/dev/null || true
  cp -a "$pre"/libFutureSQL*.so* "$LIB/" 2>/dev/null || true
  cp -a "$pre"/libKTactileFeedback*.so* "$LIB/" 2>/dev/null || true
done
# KF6 stack from our prefix (covers both lib/ and lib/<triplet>/ layouts)
for d in "$KF6_PREFIX"/lib "$KF6_PREFIX"/lib/$TRIPLET; do
  [ -d "$d" ] || continue
  cp -a "$d"/*.so* "$LIB/" 2>/dev/null || true
done
# non-Qt runtime deps the UT base may lack (mirroring morph click)
for pat in 'libb2.so*' 'libOpenGL.so*' 'libandroid-properties*.so*' \
           'libopenh264*.so*' 'libvpx*.so*' 'libwebp*.so*' 'libminizip*.so*' \
           'libsnappy*.so*' 'libre2*.so*' 'libicui18n*.so*' 'libicuuc*.so*' 'libicudata*.so*' \
           'libdouble-conversion*.so*' 'libharfbuzz*.so*' 'libmd4c*.so*' 'libabsl*.so*' 'libavcodec*.so*' 'libavformat*.so*' 'libavutil*.so*' 'libswresample*.so*'; do
  cp -a /usr/lib/$TRIPLET/$pat "$LIB/" 2>/dev/null || true
done

# --- qt6 plugins + qml modules (system) ---
cp -a /usr/lib/$TRIPLET/qt6/plugins "$LIB/qt6/" 2>/dev/null || true
mkdir -p "$LIB/qt6/qml"
cp -a /usr/lib/$TRIPLET/qt6/qml/. "$LIB/qt6/qml/" 2>/dev/null || true

# --- KF6 qml modules + any kf6 plugin dirs ---
for q in "$KF6_PREFIX"/lib/qml "$KF6_PREFIX"/lib/$TRIPLET/qml "$KF6_PREFIX"/lib/qt6/qml "$KF6_PREFIX"/lib/$TRIPLET/qt6/qml; do
  [ -d "$q" ] && cp -a "$q"/. "$LIB/qt6/qml/"
done
for p in "$KF6_PREFIX"/lib/plugins "$KF6_PREFIX"/lib/$TRIPLET/plugins "$KF6_PREFIX"/lib/qt6/plugins "$KF6_PREFIX"/lib/$TRIPLET/qt6/plugins; do
  [ -d "$p" ] && cp -a "$p"/. "$LIB/qt6/plugins/"
done

# --- webengine process + resources + locales ---
if [ -f /usr/lib/qt6/libexec/QtWebEngineProcess ]; then
  cp -a /usr/lib/qt6/libexec/QtWebEngineProcess "$LIB/bin/"
elif [ -f /usr/lib/$TRIPLET/qt6/libexec/QtWebEngineProcess ]; then
  cp -a /usr/lib/$TRIPLET/qt6/libexec/QtWebEngineProcess "$LIB/bin/"
elif [ -f /usr/lib/qt6/bin/QtWebEngineProcess ]; then
  cp -a /usr/lib/qt6/bin/QtWebEngineProcess "$LIB/bin/"
fi
for r in /usr/lib/qt6/resources /usr/lib/$TRIPLET/qt6/resources /usr/share/qt6/resources; do
  [ -d "$r" ] && cp -a "$r"/. "$LIB/resources/"
done
for t in /usr/share/qt6/translations /usr/lib/qt6/translations; do
  [ -d "$t/qtwebengine_locales" ] && cp -a "$t/qtwebengine_locales" "$LIB/translations/"
  [ -d "$t" ] && cp -a "$t"/*.qm "$LIB/translations/" 2>/dev/null || true
done

# --- KF6 data (icon/notifyrc/etc.) + icons ---
[ -d "$KF6_PREFIX/share" ] && cp -a "$KF6_PREFIX/share/." "$ST/share/" 2>/dev/null || true
cp -a /usr/share/icons/breeze "$ST/icons/" 2>/dev/null || true
cp -a /usr/share/icons/hicolor "$ST/icons/" 2>/dev/null || true

# --- binary + packaging files ---
cp "$ANGELFISH_BIN" "$ST/angelfish"
cp "$ROOT/packaging/wrapper.qt6" "$ST/wrapper"
cp "$ROOT/packaging/manifest.json" "$ST/manifest.json"
cp "$ROOT/packaging/tiddler.desktop" "$ST/tiddler.desktop"
cp "$ROOT/packaging/angelfish.apparmor" "$ST/angelfish.apparmor"
cp "$ROOT/packaging/tiddler.svg" "$ST/tiddler.svg"
chmod +x "$ST/wrapper" "$ST/angelfish"

echo "=== staged files ==="
du -sh "$ST"; find "$ST" -name "*.so*" | wc -l
echo "=== unresolved libs (sanity, needs arm64 ldd) ==="
