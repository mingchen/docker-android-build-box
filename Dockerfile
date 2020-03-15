FROM ubuntu:18.04

MAINTAINER Ming Chen

ENV ANDROID_HOME="/opt/android-sdk" \
    FLUTTER_HOME="/opt/flutter" \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/ \
    ANDROID_SDK_HOME="$ANDROID_HOME" \
    # Get the latest version from https://developer.android.com/studio/index.html
    ANDROID_SDK_TOOLS_VERSION="4333796" \
    DEBIAN_FRONTEND="noninteractive" \
    TERM=dumb \
    PATH="$PATH:$ANDROID_SDK_HOME/emulator:$ANDROID_SDK_HOME/tools/bin:$ANDROID_SDK_HOME/tools:$ANDROID_SDK_HOME/platform-tools:$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin"

COPY README.md /README.md
COPY sdk/licenses/* $ANDROID_HOME/licenses/
COPY install.sh /install.sh

WORKDIR /tmp

RUN chmod +x /install.sh && /install.sh
