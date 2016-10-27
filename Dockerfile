FROM ubuntu:16.04

MAINTAINER Ming Chen

ENV ANDROID_HOME /opt/android-sdk
ENV ANDROID_NDK  /opt/android-ndk

ENV ANDROID_BUILD_TOOLS_VERSION="24.0.2"
ENV ANDROID_SDK_VERSION="24.4.1"

# Get the latest version from https://developer.android.com/ndk/downloads/index.html
ENV ANDROID_NDK_VERSION="13"

ENV LANG en_US.UTF-8
RUN locale-gen $LANG

COPY README.md /README.md

WORKDIR /tmp

# Installing packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        autoconf \
        git \
        curl \
        wget \
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
        ncurses-dev \
        ocaml \
        openssh-client \
        pkg-config \
        python-software-properties \
        software-properties-common \
        unzip \
        zip \
        zlib1g-dev && \
    apt-add-repository -y ppa:openjdk-r/ppa && \
    apt-get install -y openjdk-8-jdk && \
    rm -rf /var/lib/apt/lists/ && \
    apt-get clean && \

    wget -q -O android-sdk.tgz https://dl.google.com/android/android-sdk_r${ANDROID_SDK_VERSION}-linux.tgz  && \
    tar -xzf android-sdk.tgz && \
    rm -fr $ANDROID_HOME android-sdk.tgz && \
    mv android-sdk-linux $ANDROID_HOME && \

    # Install Android components
    echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-16 && \
    echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-17 && \
    echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-18 && \
    echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-19 && \
    echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-20 && \
    echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-21 && \
    echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-22 && \
    echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-23 && \
    echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-24 && \
    echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter platform-tools && \
    echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter build-tools-${ANDROID_BUILD_TOOLS_VERSION} && \
    echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter extra-android-m2repository && \
    echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter extra-google-google_play_services && \
    echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter extra-google-m2repository

# Install Android NDK, put it in a separate RUN to avoid travis-ci timeout in 10 minutes.
RUN wget -q -O android-ndk.zip http://dl.google.com/android/repository/android-ndk-r${ANDROID_NDK_VERSION}-linux-x86_64.zip && \
    unzip -q android-ndk.zip && \
    rm -fr $ANDROID_NDK android-ndk.zip && \
    mv android-ndk-r${ANDROID_NDK_VERSION} $ANDROID_NDK

# Add android commands to PATH
ENV ANDROID_SDK_HOME $ANDROID_HOME
ENV PATH $PATH:$ANDROID_SDK_HOME/tools:$ANDROID_SDK_HOME/platform-tools:$ANDROID_SDK_HOME/build-tools/${ANDROID_BUILD_TOOLS_VERSION}:$ANDROID_NDK

# Export JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

# Support Gradle
ENV TERM dumb
ENV JAVA_OPTS "-Xms512m -Xmx1024m"
ENV GRADLE_OPTS "-XX:+UseG1GC -XX:MaxGCPauseMillis=1000"

