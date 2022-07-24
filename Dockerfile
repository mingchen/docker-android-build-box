FROM ubuntu:18.04

LABEL maintainer="Ming Chen"

ENV ANDROID_HOME="/opt/android-sdk" \
    ANDROID_SDK_HOME="/opt/android-sdk" \
    FLUTTER_HOME="/opt/flutter" \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/ \
    PATH="$PATH:/opt/android-sdk/emulator:/opt/android-sdk/tools/bin:/opt/android-sdk/tools:/opt/android-sdk/platform-tools:/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin"

COPY README.md LICENSE install.sh /
COPY sdk/licenses/* $ANDROID_HOME/licenses/

WORKDIR /tmp

RUN chmod +x /install.sh && /install.sh
