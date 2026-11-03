FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN sed -i 's|http://archive.ubuntu.com|http://ports.ubuntu.com|g; s|http://security.ubuntu.com|http://ports.ubuntu.com|g' /etc/apt/sources.list.d/ubuntu.sources && \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake extra-cmake-modules ninja-build pkg-config \
    qtbase5-dev qtdeclarative5-dev qtquickcontrols2-5-dev qtwebengine5-dev \
    qtfeedback5-dev \
    kirigami2-dev libkf5purpose-dev libkf5i18n-dev libkf5config-dev \
    libkf5coreaddons-dev libkf5dbusaddons-dev libkf5windowsystem-dev \
    libkf5notifications-dev kirigami-addons-dev \
    libfuturesql-dev qcoro-qt5-dev \
    cargo rustc corrosion \
 && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends libqt5svg5-dev && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends clang lld && rm -rf /var/lib/apt/lists/* && ln -sf /usr/bin/clang /usr/local/bin/cc
