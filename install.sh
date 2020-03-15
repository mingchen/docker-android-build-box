#!/bin/sh -x

env

apt-get clean
apt-get update -qq
apt-get install -qq -y apt-utils locales

# Set locale
export LANG="en_US.UTF-8"
export LANGUAGE="en_US.UTF-8"

# Get the latest version from https://developer.android.com/studio/index.html
export ANDROID_SDK_TOOLS_VERSION="4333796"
export DEBIAN_FRONTEND="noninteractive"
export TERM=dumb

locale-gen $LANG

apt-get install -qq --no-install-recommends \
    build-essential \
    autoconf \
    curl \
    git \
    file \
    less \
    vim-tiny \
    gpg-agent \
    lib32stdc++6 \
    lib32z1 \
    lib32z1-dev \
    lib32ncurses5 \
    libc6-dev \
    libgmp-dev \
    libmpc-dev \
    libmpfr-dev \
    libxslt-dev \
    libxml2-dev \
    m4 \
    openjdk-8-jdk \
    openssh-client \
    pkg-config \
    software-properties-common \
    unzip \
    wget \
    zip \
    zlib1g-dev >/dev/null
rm -rf /var/lib/apt/lists/
rm -rf /tmp/* /var/tmp/*

# Install Android SDK
echo "Installing sdk tools ${ANDROID_SDK_TOOLS_VERSION}"
wget --quiet --output-document=sdk-tools.zip \
    "https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS_VERSION}.zip"
mkdir --parents "$ANDROID_HOME"
unzip -q sdk-tools.zip -d "$ANDROID_HOME"
rm --force sdk-tools.zip

# Install SDKs
# Please keep these in descending order!
# The `yes` is for accepting all non-standard tool licenses.

mkdir -p "$HOME/.android/"

echo '### User Sources for Android SDK Manager' >"$HOME/.android/repositories.cfg"

yes | "$ANDROID_HOME"/tools/bin/sdkmanager --licenses >/dev/null

echo "Installing platforms"
yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
    "platforms;android-29" \
    "platforms;android-28" >/dev/null

echo "Installing platform tools "
yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
    "platform-tools" >/dev/null

echo "Installing build tools "
yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
    "build-tools;29.0.2" \
    "build-tools;28.0.3" >/dev/null

echo "Installing build tools "
yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
    "build-tools;23.0.3" "build-tools;23.0.2" "build-tools;23.0.1" \
    "build-tools;22.0.1" >/dev/null

echo "Installing extras "
yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
    "extras;android;m2repository" \
    "extras;google;m2repository" >/dev/null

echo "Installing play services "
yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
    "extras;google;google_play_services" \
    "extras;m2repository;com;android;support;constraint;constraint-layout;1.0.2" >/dev/null

echo "Installing Google APIs"
yes | "$ANDROID_HOME"/tools/bin/sdkmanager \
    "add-ons;addon-google_apis-google-24" \
    "add-ons;addon-google_apis-google-23" >/dev/null

echo "Installing emulator "
yes | "$ANDROID_HOME"/tools/bin/sdkmanager "emulator" >/dev/null

echo "Installing kotlin"
wget --quiet -O sdk.install.sh "https://get.sdkman.io"
bash -c "bash ./sdk.install.sh > /dev/null && source ~/.sdkman/bin/sdkman-init.sh && sdk install kotlin"
rm -f sdk.install.sh

# Install Flutter sdk
cd /opt
wget --quiet https://storage.googleapis.com/flutter_infra/releases/stable/linux/flutter_linux_v1.12.13+hotfix.8-stable.tar.xz -O flutter.tar.xz
tar xf flutter.tar.xz
rm -f flutter.tar.xz
flutter config --no-analytics
flutter config
