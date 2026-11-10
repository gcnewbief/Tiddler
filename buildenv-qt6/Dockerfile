FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# arm64 -> ports mirror (same as qt5 env)
RUN sed -i 's|http://archive.ubuntu.com|http://ports.ubuntu.com|g; s|http://security.ubuntu.com|http://ports.ubuntu.com|g' /etc/apt/sources.list.d/ubuntu.sources

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl gnupg && rm -rf /var/lib/apt/lists/*

# UBports repo — suite 24.04-2.x carries their Qt6 stack (6.10.2 base + 6.11.2 webengine)
RUN curl -fsSL http://repo.ubports.com/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/ubports.gpg && \
    chmod 644 /usr/share/keyrings/ubports.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/ubports.gpg] http://repo.ubports.com/ 24.04-2.x main" > /etc/apt/sources.list.d/ubports.list && \
    printf 'Package: *\nPin: origin "repo.ubports.com"\nPin-Priority: 1500\n' > /etc/apt/preferences.d/ubports.pref

# Qt6 dev stack. Base/declarative/etc top out at 6.10.2 in this suite;
# webengine has a 6.11.2 build that only requires qt6-base >= 6.10.2 — pin it.
RUN apt-get update && apt-get install -y --no-install-recommends -o Acquire::Retries=5 \
    build-essential cmake ninja-build pkg-config git \
    clang lld \
    qt6-base-dev qt6-base-private-dev qt6-base-dev-tools \
    qt6-declarative-dev qt6-declarative-private-dev qt6-declarative-dev-tools \
    qt6-tools-dev qt6-tools-dev-tools qt6-l10n-tools \
    qt6-svg-dev qt6-shadertools-dev \
    qt6-wayland-dev qt6-wayland-private-dev qt6-wayland \
    qt6-5compat-dev qt6-webchannel-dev qt6-positioning-dev \
    'qt6-webengine-dev=6.11.2*' 'qt6-webengine-dev-tools=6.11.2*' \
    'libqt6webenginecore6=6.11.2*' 'libqt6webenginequick6=6.11.2*' \
    'libqt6webenginewidgets6=6.11.2*' 'qml6-module-qtwebengine=6.11.2*' \
    'qml6-module-qtwebengine-controlsdelegates=6.11.2*' \
    'libqt6webengine6-data=6.11.2*' \
    libqt6webenginecore6-bin libqt6sql6-sqlite \
    qtubuntu-qt6 maliit-inputcontext-qt6 \
    libktactilefeedback1 qml6-module-ktactilefeedback \
    qml6-module-qt5compat-graphicaleffects \
    qml6-module-qtquick-controls qml6-module-qtquick-layouts \
    qml6-module-qtquick-templates qml6-module-qt-labs-settings \
    qml6-module-qtcore qml6-module-qtqml-workerscript \
 && rm -rf /var/lib/apt/lists/*

# KF6 build deps (noble arm64) + ECM 6.31 (noble only ships ECM 5.115)
RUN apt-get update && apt-get install -y --no-install-recommends -o Acquire::Retries=5 \
    gettext libwayland-dev wayland-protocols libxkbcommon-dev libxkbcommon-x11-dev \
    libxcb1-dev libxcb-util-dev libxcb-keysyms1-dev libxcb-res0-dev libxcb-icccm4-dev \
    libxcb-ewmh-dev libxcb-image0-dev libxcb-render-util0-dev libxcb-xkb-dev \
    libxcb-cursor-dev libxcb-randr0-dev libxcb-xfixes0-dev libxcb-shape0-dev \
    libxcb-sync-dev libxcb-xinerama0-dev libxcb-xtest0-dev libxcb-record0-dev \
    libxcb-screensaver0-dev libxcb-present-dev libxcb-dri3-dev libxcb-composite0-dev \
    libxcb-damage0-dev libxcb-render0-dev libxcb-shm0-dev libxcb-glx0-dev \
    libxcb-xinput-dev libxcb-xv0-dev libxcb-dri2-0-dev libxfixes-dev libxrender-dev libxext-dev \
 && rm -rf /var/lib/apt/lists/*

COPY kf6-src/extra-cmake-modules-6.31.0.tar.xz /tmp/
RUN cd /tmp && tar xJf extra-cmake-modules-6.31.0.tar.xz && \
    cmake -S extra-cmake-modules-6.31.0 -B ecm-build -DCMAKE_INSTALL_PREFIX=/usr && \
    cmake --build ecm-build && cmake --install ecm-build && \
    rm -rf /tmp/extra-cmake-modules-6.31.0* /tmp/ecm-build && \
    ln -sf /usr/bin/clang /usr/local/bin/cc
