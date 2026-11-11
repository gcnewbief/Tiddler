# Tiddler — an Ubuntu Touch browser port

A port of KDE's **Angelfish** browser (23.08.5, the last Qt5/KF5 series) to Ubuntu Touch 24.04,
running on a MediaTek aarch64 device. Renamed/branded **Tiddler**.

## Repo layout (~/ubtouch)

- `angelfish-src/angelfish-23.08.5/` — upstream source, with local patches:
  - `src/contents/ui/mobile.qml` — window title → "Tiddler"
  - `src/contents/ui/NavigationEntrySheet.qml` — `fullHeight` now accounts for
    `Qt.inputMethod.keyboardRectangle.height` so the URL sheet isn't pushed off-screen
    when the OSK opens; contains a temporary `NavSheet geom:` debug log
  - `src/rs/adblock/.cargo/config.toml` — forces `-fuse-ld=lld` (avoids a qemu-user
    collect2 segfault when building under emulation)
- `buildenv/Dockerfile` — arm64 noble build env (qt5/kf5 dev, corrosion, rust, clang shim)
- `tiddler.svg` — app icon (cyber fish)
- On-device working dir: `phablet@<phone>:~/angelfish-port/`
  - `debs/` — downloaded noble arm64 packages
  - `rootfs/` — extracted deb contents (repkage staging)
  - `click/` — click package source (binary, lib/, icons/, wrapper, manifest, desktop, apparmor)

## Device access

- `ssh ubtouch` → `phablet@192.168.0.188` (host alias in ~/.ssh/config,
  IdentityFile `~/ubtouch/ubt`)
- `adb` also works (developer mode enabled)
- NOTE: `sudo` on device requires the PIN — unavailable from ssh; use unprivileged paths.

## How the port works

- The UT 24.04 base is **Qt5.15/KF5 5.115** (not Qt6) and already ships
  `qml-module-org-kde-kirigami2`, `libqt5webengine5` (UBports-patched 5.15.19),
  `qml-module-qtfeedback`, all needed `libkf5*`.
- The noble `angelfish 23.08.5-0ubuntu3` deb is a Qt5/KF5 build, so the port =
  repackaging + a handful of bundled deps (`libfuturesql5-0`, `libqcoro5quick0t64`,
  `libkf5purpose5`, kirigami-addons QML modules) rather than cross-compiling.
- Click packaging: `manifest.json` framework `ubuntu-touch-24.04-1.x`,
  `"template": "unconfined"` apparmor (same as morph — needed for QtWebEngine),
  `Exec=wrapper ./angelfish %u` where `wrapper` sets:
  - `LD_LIBRARY_PATH=$(pwd)/lib/aarch64-linux-gnu`
  - `QML2_IMPORT_PATH=$(pwd)/lib/aarch64-linux-gnu/qt5/qml`
  - `QT_IM_MODULE=maliit`, `QT_OPENGL_VARIANT=gles`,
    `QT_QUICK_CONTROLS_MOBILE=true`, `QT_QUICK_CONTROLS_STYLE=Material`
  - `XDG_DATA_DIRS=$(pwd):$XDG_DATA_DIRS` (icon lookup)
- Icons: Kirigami `icon.name` → `QIcon::fromTheme` must resolve under whatever theme the
  platform reports. Bulletproof = ship icons in **`icons/hicolor/`** (universal fallback,
  `<size>/<context>/` transposed layout + generated index.theme), plus breeze theme and
  suru/Adwaita `index.theme` shims with `Inherits=breeze,hicolor`.

## Gotchas learned (important)

- **`QT_QUICK_CONTROLS_STYLE=Suru` breaks kirigami-addons mobileform**: Lomiri forces the
  Suru QQC2 style; Suru's custom `ComboBox` lacks `currentValue`/`valueRole`/`indexOfValue`
  → `Invalid alias target location` at startup (fatal on the mobile.qml path via
  `PrintPreview` inside `WebView`). Fixed by forcing `Material`.
- Launching via ssh: `ubuntumirclient` rejects non-app connections ("not accepted by
  server"); `xcb` via Xwayland works for unconfined smoke tests
  (`DISPLAY=:0 QT_QPA_PLATFORM=xcb` + the env above).
- Click install without pkcon/sudo:
  `dbus-send --session ... com.lomiri.URLDispatcher.DispatchURL "file:///...click" ""`
  → opens the system installer UI; still needs a screen tap to confirm.
- Device `apt` indexes are empty by default; fetch them user-side:
  `apt -o Dir::State::Lists=$HOME/aptlists -o Dir::Cache=$HOME/aptcache update`
  then `apt <same opts> download <pkg>` — gets noble arm64 debs with no root.
- Docker on this host: **container NAT is broken** (TCP handshakes complete, data never
  returns). Always use `docker run/build --network host`. qemu binfmt was registered via
  `docker run --rm --privileged multiarch/qemu-user-static --reset -p yes`.
- Emulated build pain: `apt`+`dpkg` under qemu-aarch64 are slow but work; `collect2`
  segfaults under qemu → shim `cc`→`clang` + cargo `-fuse-ld=lld`. The `adblock` crate +
  `angelfish-adblock` wrapper together took ~1.5h emulated.

## Status

- **v23.08.5.8 shipped & verified working** (`tiddler.entropy`): source build via
  `build2` (Corrosion disabled → no adblock yet).
- Confirmed working by user: browse, tabs, downloads, video/YouTube, background audio
  with screen off, URL-entry sheet (fixed), context drawer menu (fixed), version
  item in 3-dots menu.
- Repo: `github.com/gcnewbief/tiddler` (pushed, remote `origin`). Token in `.env`
  (`GITHUBKEY`, gitignored; has repo+workflow scope).
- GitHub Actions arm64 CI: `.github/workflows/build.yml` on `ubuntu-24.04-arm`
  (native, builds adblock rust crate properly). First run built the binary but
  failed in "Assemble click dir" — fixed by dropping sudo from
  `apt-get download`/`dpkg-deb -x`; re-triggered.
- Local emulated adblock build was abandoned (rust crate pathological under qemu,
  9h+). Future adblock builds come from CI or native arm64.

## Qt6 port status (2026-11-10 — WORKING, some UI issues open)

**v26.08.3.1 is built, installed, and launches on device** — `tiddler.entropy`
26.08.3.1 lives at `/opt/click.ubuntu.com/tiddler.entropy/26.08.3.1/` with full
bundled Qt6 runtime (ubports 24.04-2.x: Qt base 6.10.2 + WebEngine 6.11.2 =
~Chromium 140). angelfish + QtWebEngineProcess spawn under `ubuntumirclient`,
pages load, session restores. The OpenStore "Error Installing" toast was noise —
the package actually installs fine via the URLDispatcher flow.

**Source**: `angelfish-src/angelfish-v26.08.3/` — patches applied: Tiddler
branding (title/About/main.cpp), NavSheet OSK fix (`fullHeight: parent.height` +
top-anchored editRow — carried over), ShareSheet replaced with a copy-URL dialog
(Purpose removed entirely — no Purpose plugins exist on UT; avoids the KIO chain).
ContextDrawer topMargin pin REMOVED — it caused a binding loop against kirigami
6.31's `root.handle.y > 0` guard → zero-height menu ("missing menus" symptom).

**Pipeline (CI-first, all pushed to `gcnewbief/Tiddler`)**:
- `.github/workflows/build-qt6.yml` — `ubuntu-24.04-arm` runner (native arm64,
  ~12-15 min/cycle): ubports 24.04-2.x repo + pin preferences, apt Qt6 dev stack
  (`--allow-downgrades` needed — runner image has newer mesa/apparmor), fetch +
  build KF6 6.31 stack, build angelfish, `assemble-click-qt6.sh`, upload
  `tiddler-qt6-click` artifact.
- `fetch-kf6.sh` — KDE tarball fetcher with `curl --resolve` fallback
  (download.kde.org 49.12.122.15, invent.kde.org 188.40.133.145 — host DNS is flaky).
- `kf6-src/build-kf6.sh` — builds into `kf6-out/`: ECM → plasma-wayland-protocols →
  kcoreaddons → kconfig → ki18n → kdbusaddons → kwindowsystem
  (`-DKWINDOWSYSTEM_WAYLAND=OFF`, we run on ubuntumirclient) → kguiaddons →
  kcolorscheme → knotifications → kcrash → kitemmodels → kirigami → karchive →
  kwidgetsaddons → breeze-icons → kiconthemes → kglobalaccel → kirigami-addons
  1.16.1 → qcoro 0.13 → futuresql (master). Global flags:
  `-DBUILD_PYTHON_BINDINGS=OFF -DBUILD_TESTING=OFF`.
- `scripts/assemble-click-qt6.sh` — bundles binary + all libQt6*, qt6 plugins/QML,
  KF6 prefix, `QtWebEngineProcess`, resources, locales → click layout.
- `packaging/wrapper.qt6` — morph-style env: LD_LIBRARY_PATH,
  QTWEBENGINEPROCESS/RESOURCES/LOCALES_PATH, QT_PLUGIN_PATH, QML_IMPORT_PATH,
  QT_IM_MODULE=maliit, QT_OPENGL_VARIANT=gles, Material style, **QT_SCALE_FACTOR**.
- `buildenv-qt6/Dockerfile` — local fallback image (`tiddler-builder-qt6`);
  cmake tarball ≥3.30 needed (noble ships 3.28, KF6 6.31 requires 3.30+).

**Dep fixes made through CI iterations** (all in the scripts now):
`libxfixes/xrender/xext-dev` (kwindowsystem X11), `libcanberra-dev`
(knotifications), `liblzma/zstd/bz2-dev` (karchive), `python3-lxml`
(breeze-icons icon generator), `BUILD_PYTHON_BINDINGS=OFF` (kcoreaddons wants
shiboken6), `KWINDOWSYSTEM_WAYLAND=OFF` (needs wayland-protocols ≥1.46; noble has 1.45).

**OPEN ISSUES (next session)**:
- **App still looks "stock angelfish" / wrong to the user** — specifics TBD. Scale
  went 1.5 → 1.8 (`QT_SCALE_FACTOR` in wrapper) — UT uses GRID_UNIT_PX=21 vs
  kirigami gridUnit=18px; likely needs tuning further or a different knob.
- ContextDrawer in kirigami 6.31 throws `width of null` (line 166 delegate
  `required property`) + a topMargin binding loop (line 135) even WITHOUT our pin —
  menu opens but may render/misbehave; needs a look at the new delegate code path.
- `module "QtFeedback" is not installed` → no haptics (HapticsEffectWrapper.qml);
  `qml6-module-ktactilefeedback` exists in 24.04-2.x if wanted.
- `WebGL1 blocklisted` — Chromium GPU context fatal failure on Mali; may need
  `QTWEBENGINE_CHROMIUM_FLAGS` (morph sets some) or a QtWebEngine flag.
- `libxcb-cursor0` needed to bundle for xcb ssh smoke tests (cosmetic).
- `libQt6WebEngineCore.so.6.10.2` filename is misleading — ubports' 6.11.2
  package ships that ABI name; the click does contain the new 6.11.2 core.
- Corrosion/adblock still disabled in the Qt6 build (`-DCMAKE_BUILD_TYPE=Release`
  only); re-enable once UI is stable.
- Debug `NavSheet geom:` log still in source (from Qt5 days — re-check if the
  same debug print exists in 26.08.3 source and strip it).

**Quick iteration path** (≈2-3 min/cycle, no CI wait):
`~/t6test/` on the phone is a writable extracted-click staging dir — patch
files in place (e.g. `~/t6test/wrapper`), `cd ~ && click build t6test`, then
the DispatchURL dbus-send → tap install → relaunch. Full click rebuilds for
real work go through CI artifact → scp → DispatchURL.

## Known issues / papercuts

- FIXED: address-bar sheet — maliit keyboard reports `keyboardRectangle=831` leaving a
  36-unit "safe strip"; Qt pushes focused input into it (pageH collapses to 36).
  Fix: `fullHeight: parent.height` + `editRow` anchored at top with `smallSpacing`
  margin so the field sits inside the strip. Debug `NavSheet geom:` log still in
  source — remove once confirmed stable.
- FIXED: context drawer whitespace/overflow — `ContextDrawer.qml`'s internal menu
  sets `topMargin = menu.height - menu.contentHeight` (bottom-aligns above the
  handle) which misfires on UT. Worked around in `mobile.qml` by finding the
  internal ListView and pinning `topMargin = 0`.
- `qrc:/NavigationEntrySheet.qml:124 "Unable to assign null to double"` — benign.
- `kf.kirigami: Failed to find a Kirigami platform plugin` — cosmetic, harmless.
- `qrc:/Tabs.qml:0 ReferenceError: contents is not defined` — upstream quirk.

## Future plans

1. **Qt6 build** — the important one for security: Qt5WebEngine ≈ Chromium ~87;
   Qt6WebEngine ≈ ~120+. Pattern proven by `morph-browser-qt6` click on the device
   (bundles full Qt6 runtime under `lib/aarch64-linux-gnu/` + `QTWEBENGINEPROCESS_PATH`
   etc. in its wrapper). Target angelfish 26.x + KF6 + bundled Qt6 — heavier click but
   current upstream + current-ish Chromium. Do before logging into sensitive sites.
2. **GitHub repo + Actions CI** — `ubuntu-24.04-arm` runners are free/native arm64 on
   public repos → builds the click as an artifact; kills the emulation tax entirely
   and becomes the update pipeline. Can auto-publish releases.
3. **OpenStore submission** — gives users update notifications.
4. Optional: strip debug `NavSheet geom` log, dedupe authorized_keys on device,
   integrate angelfish-webapp binary into packaging if webapps are wanted.

## Build commands (repeatable)

```bash
# image (rebuild only when Dockerfile changes)
docker build --network host --platform linux/arm64 -t angelfish-builder ~/ubtouch/buildenv

# compile (mounts source + output)
docker run --rm --network host --platform linux/arm64 \
  -v ~/ubtouch/angelfish-src/angelfish-23.08.5:/src \
  -v ~/ubtouch/build-out:/out \
  angelfish-builder bash -c 'cd /src && cmake -B build -GNinja \
    -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/out/stage && \
    cmake --build build -j$(nproc)'

# on device: repackage + install
ssh ubtouch 'cd ~/angelfish-port && cp <new-binary> click/ && click build click'
ssh ubtouch 'dbus-send --session ... DispatchURL "file:///home/phablet/angelfish-port/<pkg>.click" ""'
```
