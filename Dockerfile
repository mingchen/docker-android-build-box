# ARGs
# All _TAGGED can be "latest" or "tagged"
ARG NDK_TAGGED="latest"
ARG NDK_VER="25.2.9519653"

ARG NODE_VER="16.x"

ARG BUNDLETOOL_TAGGED="latest"
ARG BUNDLETOOL_VER="1.14.0"

ARG FLUTTER_TAGGED="latest"
ARG FLUTTER_VER="3.7.7"

ARG JENV_TAGGED="latest"
ARG JENV_VER="0.5.4"

FROM ubuntu:20.04 as ubuntu
# Ensure ARGs are in this build context
ARG NDK_VER
ARG NODE_VER
ARG BUNDLETOOL_VER
ARG FLUTTER_VER
ARG JENV_VER

# ANDROID_HOME is deprecated
ENV ANDROID_HOME="/opt/android-sdk" \
    ANDROID_SDK_HOME="/opt/android-sdk" \
    ANDROID_SDK_ROOT="/opt/android-sdk" \
    ANDROID_NDK="/opt/android-sdk/ndk/latest" \
    ANDROID_NDK_ROOT="/opt/android-sdk/ndk/latest" \
    FLUTTER_HOME="/opt/flutter"
ENV ANDROID_SDK_MANAGER=${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager

ENV TZ=America/Los_Angeles

# Set locale
ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"

# Variables must be references after they are created
ENV ANDROID_SDK_HOME="$ANDROID_HOME"
ENV ANDROID_NDK_HOME="$ANDROID_NDK"

ENV PATH="$JAVA_HOME/bin:$PATH:$ANDROID_SDK_HOME/emulator:$ANDROID_SDK_HOME/cmdline-tools/latest/bin:$ANDROID_SDK_HOME/tools:$ANDROID_SDK_HOME/platform-tools:$ANDROID_NDK:$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin"

# Installed Software Versions
# Get the latest version from https://developer.android.com/studio/index.html
# "9123335" as of 2023/01/11
ENV ANDROID_SDK_TOOLS_VERSION="9123335"

# Enivornment variables for configed software
ENV NDK_VERSION=${NDK_VER}
ENV NODE_VERSION=${NODE_VER}
ENV BUNDLETOOL_VERSION=${BUNDLETOOL_VER}
ENV FLUTTER_VERSION=${FLUTTER_VER}
ENV JENV_RELEASE=${JENV_VER}

FROM ubuntu as base
ARG TERM=dumb \
    DEBIAN_FRONTEND=noninteractive

RUN uname -a && uname -m

# support amd64 and arm64
RUN JDK_PLATFORM=$(if [ "$(uname -m)" = "aarch64" ]; then echo "arm64"; else echo "amd64"; fi) && \
    echo export JDK_PLATFORM=$JDK_PLATFORM >> /etc/jdk.env && \
    echo export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-$JDK_PLATFORM/" >> /etc/jdk.env && \
    echo . /etc/jdk.env >> /etc/bash.bashrc && \
    echo . /etc/jdk.env >> /etc/profile

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get clean && \
    apt-get update -qq && \
    apt-get install -qq -y apt-utils locales && \
    locale-gen $LANG

WORKDIR /tmp

# Installing packages
RUN apt-get update -qq > /dev/null && \
    apt-get install -qq locales > /dev/null && \
    locale-gen "$LANG" > /dev/null && \
    apt-get install -qq --no-install-recommends \
        autoconf \
        build-essential \
        cmake \
        curl \
        file \
        git \
        git-lfs \
        gpg-agent \
        less \
        libc6-dev \
        libgmp-dev \
        libmpc-dev \
        libmpfr-dev \
        libxslt-dev \
        libxml2-dev \
        m4 \
        ncurses-dev \
        ocaml \
        openjdk-8-jdk \
        openjdk-11-jdk \
        openjdk-17-jdk \
        openssh-client \
        pkg-config \
        ruby-full \
        software-properties-common \
        tzdata \
        unzip \
        vim-tiny \
        wget \
        zip \
        zipalign \
        s3cmd \
        python3-pip \
        zlib1g-dev > /dev/null && \
    git lfs install > /dev/null && \
    echo "JVM directories: `ls -l /usr/lib/jvm/`" && \
    . /etc/jdk.env && \
    echo "Java version (default):" && \
    java -version && \
    echo "set timezone" && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    echo "nodejs, npm, cordova, ionic, react-native" && \
    curl -sL -k https://deb.nodesource.com/setup_${NODE_VERSION} \
        | bash - > /dev/null && \
    apt-get install -qq nodejs > /dev/null && \
    curl -sS -k https://dl.yarnpkg.com/debian/pubkey.gpg \
        | apt-key add - > /dev/null && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" \
        | tee /etc/apt/sources.list.d/yarn.list > /dev/null && \
    apt-get update -qq > /dev/null && \
    apt-get install -qq yarn > /dev/null && \
    rm -rf /var/lib/apt/lists/ && \
    npm install --quiet -g npm > /dev/null && \
    npm install --quiet -g \
        bower \
        cordova \
        eslint \
        gulp \
        ionic \
        jshint \
        karma-cli \
        mocha \
        node-gyp \
        npm-check-updates \
        react-native-cli > /dev/null && \
    npm cache clean --force > /dev/null && \
    apt-get -y clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* /var/tmp/*
RUN echo 'debconf debconf/frontend select Dialog' | debconf-set-selections

# Install Android SDK CLI
RUN echo "sdk tools ${ANDROID_SDK_TOOLS_VERSION}" && \
    wget --quiet --output-document=sdk-tools.zip \
        "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip" && \
    mkdir --parents "$ANDROID_HOME" && \
    unzip -q sdk-tools.zip -d "$ANDROID_HOME" && \
    cd "$ANDROID_HOME" && \
    mv cmdline-tools latest && \
    mkdir cmdline-tools && \
    mv latest cmdline-tools && \
    rm --force sdk-tools.zip

FROM base as minimal
ARG DEBUG
# Install SDKs
# Please keep these in descending order!
# The `yes` is for accepting all non-standard tool licenses.
RUN mkdir --parents "$ANDROID_HOME/.android/" && \
    echo '### User Sources for Android SDK Manager' > \
        "$ANDROID_HOME/.android/repositories.cfg" && \
    . /etc/jdk.env && \
    yes | $ANDROID_SDK_MANAGER --licenses > /dev/null

# List all available packages.
# redirect to a temp file `packages.txt` for later use and avoid show progress
RUN . /etc/jdk.env && \
    $ANDROID_SDK_MANAGER --list > /tmp/packages.txt && \
    cat /tmp/packages.txt | grep -v '='

# Copy sdk license agreement files.
RUN mkdir -p $ANDROID_HOME/licenses
COPY sdk/licenses/* $ANDROID_HOME/licenses/
RUN echo "platform tools" && \
    . /etc/jdk.env && \
    yes | $ANDROID_SDK_MANAGER ${DEBUG:+--verbose} \
        "platform-tools" > /dev/null

FROM minimal as stage1
#
# https://developer.android.com/studio/command-line/sdkmanager.html
#
RUN echo "platforms" && \
    . /etc/jdk.env && \
    yes | $ANDROID_SDK_MANAGER ${DEBUG:+--verbose} \
        "platforms;android-33" \
        "platforms;android-32" \
        "platforms;android-31" \
        "platforms;android-30" \
        "platforms;android-29" \
        "platforms;android-28" \
        "platforms;android-27" \
        > /dev/null

RUN echo "build tools 27-33" && \
    . /etc/jdk.env && \
    yes | $ANDROID_SDK_MANAGER ${DEBUG:+--verbose} \
        "build-tools;33.0.0" \
        "build-tools;32.0.0" \
        "build-tools;31.0.0" \
        "build-tools;30.0.0" "build-tools;30.0.2" "build-tools;30.0.3" \
        "build-tools;29.0.3" "build-tools;29.0.2" \
        "build-tools;28.0.3" "build-tools;28.0.2" \
        "build-tools;27.0.3" "build-tools;27.0.2" "build-tools;27.0.1" > /dev/null

# seems there is no emulator on arm64
# Warning: Failed to find package emulator
RUN echo "emulator" && \
    if [ "$(uname -m)" != "x86_64" ]; then echo "emulator only support Linux x86 64bit. skip for $(uname -m)"; exit 0; fi && \
    . /etc/jdk.env && \
    yes | $ANDROID_SDK_MANAGER "emulator" > /dev/null

# ndk-bundle does exist on arm64
# RUN echo "NDK" && \
#     yes | $ANDROID_SDK_MANAGER "ndk-bundle" > /dev/null

FROM minimal as bundletool-base
RUN echo "bundletool"

FROM bundletool-base as bundletool-tagged
RUN wget -q https://github.com/google/bundletool/releases/download/${BUNDLETOOL_VERSION}/bundletool-all-${BUNDLETOOL_VERSION}.jar -O $ANDROID_SDK_HOME/cmdline-tools/latest/bundletool.jar

FROM bundletool-base as bundletool-latest
RUN curl -s https://api.github.com/repos/google/bundletool/releases/latest | grep "browser_download_url.*jar" | cut -d : -f 2,3 | tr -d \" | wget -O $ANDROID_SDK_HOME/cmdline-tools/latest/bundletool.jar -qi -

FROM bundletool-${BUNDLETOOL_TAGGED} as bundletool-final
RUN echo "bundletool finished"

FROM minimal as ndk-base
RUN echo "NDK"

FROM ndk-base as ndk-tagged
RUN echo "Installing $NDK_VERSION" && \
    . /etc/jdk.env && \
    yes | $ANDROID_SDK_MANAGER ${DEBUG:+--verbose} "ndk;${NDK_VERSION}" > /dev/null && \
    ln -sv $ANDROID_HOME/ndk/${NDK_VERSION} ${ANDROID_NDK}

FROM ndk-base as ndk-latest
RUN NDK=$(grep 'ndk;' /tmp/packages.txt | sort | tail -n1 | awk '{print $1}') && \
    NDK_VERSION=$(echo $NDK | awk -F\; '{print $2}') && \
    echo "Installing $NDK" && \
    . /etc/jdk.env && \
    yes | $ANDROID_SDK_MANAGER ${DEBUG:+--verbose} "$NDK" > /dev/null && \
    ln -sv $ANDROID_HOME/ndk/${NDK_VERSION} ${ANDROID_NDK}

FROM ndk-${NDK_TAGGED} as ndk-final

# List sdk and ndk directory content
RUN ls -l $ANDROID_HOME && \
    ls -l $ANDROID_HOME/ndk && \
    ls -l $ANDROID_HOME/ndk/*

RUN du -sh $ANDROID_HOME

# Flutter Instalation
FROM --platform=linux/amd64 base as flutter-base
FROM flutter-base as flutter-tagged
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME}

FROM flutter-base as flutter-latest
RUN git clone --depth 5 -b stable https://github.com/flutter/flutter.git ${FLUTTER_HOME}

FROM flutter-${FLUTTER_TAGGED} as flutter-final
RUN flutter config --no-analytics

# Create some jenkins required directory to allow this image run with Jenkins
FROM ubuntu as stage2
RUN mkdir -p /var/lib/jenkins/workspace && \
    mkdir -p /home/jenkins && \
    chmod 777 /home/jenkins && \
    chmod 777 /var/lib/jenkins/workspace

# fastlane installation
FROM minimal as stage3
COPY Gemfile /Gemfile

RUN echo "fastlane" && \
    cd / && \
    gem install bundler --quiet --no-document > /dev/null && \
    mkdir -p /.fastlane && \
    chmod 777 /.fastlane && \
    bundle install --quiet

# Add jenv to control which version of java to use, default to 17.
FROM stage3 as jenv-base
ENV PATH="/root/.jenv/shims:/root/.jenv/bin${PATH:+:${PATH}}"

FROM jenv-base as jenv-tagged
RUN git clone --depth 1 --branch ${JENV_RELEASE} https://github.com/jenv/jenv.git ~/.jenv

FROM jenv-base as jenv-latest
RUN git clone  https://github.com/jenv/jenv.git ~/.jenv
ENV JENV_RELEASE="see 'jenv --version'"

FROM jenv-${JENV_TAGGED} as jenv-final
RUN git config --global --add safe.directory ~/.jenv && \
    echo '#!/usr/bin/env bash' >> ~/.bash_profile && \
    echo 'eval "$(jenv init -)"' >> ~/.bash_profile && \
    . ~/.bash_profile && \
    . /etc/jdk.env && \
    java -version && \
    jenv add /usr/lib/jvm/java-8-openjdk-$JDK_PLATFORM && \
    jenv add /usr/lib/jvm/java-11-openjdk-$JDK_PLATFORM && \
    jenv add /usr/lib/jvm/java-17-openjdk-$JDK_PLATFORM && \
    jenv versions && \
    jenv global 17.0 && \
    java -version

FROM jenv-final as complete
COPY --from=stage1 ${ANDROID_HOME} ${ANDROID_HOME}
COPY --from=stage2 /var/lib/jenkins/workspace /var/lib/jenkins/workspace
COPY --from=stage2 /home/jenkins /home/jenkins
COPY --from=bundletool-final $ANDROID_SDK_HOME/cmdline-tools/latest/bundletool.jar $ANDROID_SDK_HOME/cmdline-tools/latest/bundletool.jar
COPY --from=ndk-final ${ANDROID_NDK_ROOT}/../ ${ANDROID_NDK_ROOT}/../
COPY README.md /README.md
RUN    chmod -R 775 $ANDROID_HOME

WORKDIR /project

FROM complete as complete-flutter
COPY --from=flutter-final ${FLUTTER_HOME} ${FLUTTER_HOME}
COPY --from=flutter-final /root/.flutter /root/.flutter
COPY --from=flutter-final /root/.config/flutter /root/.config/flutter
RUN git config --global --add safe.directory ${FLUTTER_HOME}

ARG BUILD_DATE=""
ARG SOURCE_BRANCH=""
ARG SOURCE_COMMIT=""
ARG DOCKER_TAG=""

ENV BUILD_DATE=${BUILD_DATE} \
    SOURCE_BRANCH=${SOURCE_BRANCH} \
    SOURCE_COMMIT=${SOURCE_COMMIT} \
    DOCKER_TAG=${DOCKER_TAG}


# labels, see http://label-schema.org/
LABEL maintainer="Ming Chen"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name="mingc/android-build-box"
LABEL org.label-schema.version="${DOCKER_TAG}"
LABEL org.label-schema.usage="/README.md"
LABEL org.label-schema.docker.cmd="docker run --rm -v `pwd`:/project mingc/android-build-box bash -c 'cd /project; ./gradlew build'"
LABEL org.label-schema.build-date="${BUILD_DATE}"
LABEL org.label-schema.vcs-ref="${SOURCE_COMMIT}@${SOURCE_BRANCH}"
