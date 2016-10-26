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

RUN apt-get update

# Installing packages
RUN apt-get install -y \
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
        zlib1g-dev

# Add java repo
RUN apt-add-repository -y ppa:openjdk-r/ppa
RUN apt-get install -y openjdk-8-jdk

# Clean Up Apt-get
RUN apt-get clean

# Install Android SDK
WORKDIR /tmp
RUN wget --quiet --output-document=android-sdk.tgz https://dl.google.com/android/android-sdk_r${ANDROID_SDK_VERSION}-linux.tgz
RUN tar -xzf android-sdk.tgz
RUN rm -fr $ANDROID_HOME    # Remove old one, if exist
RUN mv android-sdk-linux $ANDROID_HOME
RUN rm android-sdk.tgz

# Install Android components
RUN echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-16
RUN echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-17
RUN echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-18
RUN echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-19
RUN echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-20
RUN echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-21
RUN echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-22
RUN echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-23
RUN echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-24
RUN echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter platform-tools
RUN echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter build-tools-${ANDROID_BUILD_TOOLS_VERSION}
RUN echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter extra-android-m2repository
RUN echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter extra-google-google_play_services
RUN echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter extra-google-m2repository

# Install Android NDK
WORKDIR /tmp
RUN wget --quiet --output-document=android-ndk.zip http://dl.google.com/android/repository/android-ndk-r${ANDROID_NDK_VERSION}-linux-x86_64.zip
RUN unzip android-ndk.zip
RUN rm -fr $ANDROID_NDK # Remove old one, if exist
RUN mv android-ndk-r${ANDROID_NDK_VERSION} $ANDROID_NDK
RUN rm android-ndk.zip

# Environment variables
ENV ANDROID_SDK_HOME $ANDROID_HOME
ENV PATH $PATH:$ANDROID_SDK_HOME/tools
ENV PATH $PATH:$ANDROID_SDK_HOME/platform-tools
ENV PATH $PATH:$ANDROID_SDK_HOME/build-tools/${ANDROID_BUILD_TOOLS_VERSION}
ENV PATH $PATH:$ANDROID_NDK

# Export JAVA_HOME variable
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/

# Support Gradle
ENV TERM dumb
ENV JAVA_OPTS "-Xms512m -Xmx1024m"
ENV GRADLE_OPTS "-XX:+UseG1GC -XX:MaxGCPauseMillis=1000"

