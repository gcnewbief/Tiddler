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
