# ARGs
# Installed Software Versions
# All _TAGGED can be "latest" or "tagged"
# when _TAGGED is "tagged" the version in _VER copied to _VERSION will be used.

# "9123335" as of 2023/01/11
ARG ANDROID_SDK_TOOLS_TAGGED="latest"
ARG ANDROID_SDK_TOOLS_VERSION="9123335"

# Valid values are last7 or tagged
# last7 will grab the last 7 android-sdks
ARG ANDROID_SDKS="last7"

ARG NDK_TAGGED="latest"
ARG NDK_VERSION="25.2.9519653"

# Use "lts.x" for latest LTS Node
ARG NODE_TAGGED="latest"
ARG NODE_VERSION="16.x"

ARG BUNDLETOOL_TAGGED="latest"
ARG BUNDLETOOL_VERSION="1.14.0"

ARG FLUTTER_TAGGED="latest"
ARG FLUTTER_VERSION="3.7.7"

ARG JENV_TAGGED="latest"
ARG JENV_VERSION="0.5.4"

ARG DIRWORK="/tmp"
ARG FINAL_DIRWORK="/project"

ARG INSTALLED_TEMP="${DIRWORK}/.temp_version"
ARG INSTALLED_VERSIONS="/root/installed-versions.txt"

FROM ubuntu:20.04 as ubuntu
# Ensure ARGs are in this build context
ARG ANDROID_SDK_TOOLS_VERSION
ARG NDK_VERSION
ARG NODE_VERSION
ARG BUNDLETOOL_VERSION
ARG FLUTTER_VERSION
ARG JENV_VERSION

ARG DIRWORK
ARG FINAL_DIRWORK

ARG INSTALLED_TEMP
ARG INSTALLED_VERSIONS

ARG SDK_PACKAGES="${DIRWORK}/packages.txt"

ENV ANDROID_HOME="/opt/android-sdk" \
    ANDROID_SDK_HOME="/opt/android-sdk" \
    ANDROID_NDK="/opt/android-sdk/ndk/latest" \
    ANDROID_NDK_ROOT="/opt/android-sdk/ndk/latest" \
    FLUTTER_HOME="/opt/flutter" \
    JENV_HOME="/root/.jenv"
ENV ANDROID_SDK_MANAGER=${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager

ENV TZ=America/Los_Angeles

# Set locale
ENV LANG="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8"

# Variables must be references after they are created
ENV ANDROID_SDK_HOME="$ANDROID_HOME"
ENV ANDROID_NDK_HOME="$ANDROID_NDK"

ENV PATH="${JENV_HOME}/shims:${JENV_HOME}/bin:$JAVA_HOME/bin:$PATH:$ANDROID_SDK_HOME/emulator:$ANDROID_SDK_HOME/cmdline-tools/latest/bin:$ANDROID_SDK_HOME/tools:$ANDROID_SDK_HOME/platform-tools:$ANDROID_NDK:$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin"

FROM ubuntu as pre-base
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

WORKDIR ${DIRWORK}

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
    apt-get -y clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/* && \
    rm -rf ${DIRWORK}/* /var/tmp/*
RUN echo 'debconf debconf/frontend select Dialog' | debconf-set-selections

# preliminary base-base stage
# Install Android SDK CLI
FROM pre-base as base-base
RUN echo '# Installed Versions of Specified Software' >> ${INSTALLED_VERSIONS}

FROM base-base as base-tagged
RUN echo "sdk tools ${ANDROID_SDK_TOOLS_VERSION}" && \
    wget --quiet --output-document=sdk-tools.zip \
        "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_TOOLS_VERSION}_latest.zip" && \
    echo "ANDROID_SDK_TOOLS_VERSION=${ANDROID_SDK_TOOLS_VERSION}" >> ${INSTALLED_VERSIONS}

FROM pre-base as base-latest
RUN TEMP=$(curl -S https://developer.android.com/studio/index.html) && \
    ANDROID_SDK_TOOLS_VERSION=$(echo "$TEMP" | grep commandlinetools-linux | tail -n 1 | cut -d \- -f 3 | tr -d _latest.zip\</em\>\<\/p\>) && \
    echo "sdk tools $ANDROID_SDK_TOOLS_VERSION" && \
    wget --quiet --output-document=sdk-tools.zip \
        "https://dl.google.com/android/repository/commandlinetools-linux-"$ANDROID_SDK_TOOLS_VERSION"_latest.zip" && \
    echo "ANDROID_SDK_TOOLS_VERSION=$ANDROID_SDK_TOOLS_VERSION" >> ${INSTALLED_VERSIONS}

FROM base-${ANDROID_SDK_TOOLS_TAGGED} as base
RUN  mkdir --parents "$ANDROID_HOME" && \
    unzip -q sdk-tools.zip -d "$ANDROID_HOME" && \
    cd "$ANDROID_HOME" && \
    mv cmdline-tools latest && \
    mkdir cmdline-tools && \
    mv latest cmdline-tools && \
    rm --force sdk-tools.zip

# jenv build stage
# Add jenv to control which version of java to use, default to 17.
FROM base as jenv-base

FROM jenv-base as jenv-tagged
RUN git clone --depth 1 --branch ${JENV_RELEASE} https://github.com/jenv/jenv.git ${JENV_HOME} && \
    echo "JENV_RELEASE=${JENV_RELEASE}" >> ${INSTALLED_TEMP}

FROM jenv-base as jenv-latest
RUN git clone  https://github.com/jenv/jenv.git ${JENV_HOME} && \
    cd ${JENV_HOME} && echo "JENV_RELEASE=$(git describe --tags HEAD)" >> ${INSTALLED_TEMP}

FROM jenv-${JENV_TAGGED} as jenv-final
RUN echo '#!/usr/bin/env bash' >> ~/.bash_profile && \
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

# minimal build stage
# intended as a final target
FROM base as minimal
ARG DEBUG
# The `yes` is for accepting all non-standard tool licenses.
RUN mkdir --parents "$ANDROID_HOME/.android/" && \
    echo '### User Sources for Android SDK Manager' > \
        "$ANDROID_HOME/.android/repositories.cfg" && \
    . /etc/jdk.env && \
    yes | $ANDROID_SDK_MANAGER --licenses > /dev/null

# List all available packages.
# redirect to a temp file ${SDK_PACKAGES} for later use and avoid show progress
RUN . /etc/jdk.env && \
    $ANDROID_SDK_MANAGER --list > ${SDK_PACKAGES} && \
    cat ${SDK_PACKAGES} | grep -v '='

# Copy sdk license agreement files.
RUN mkdir -p $ANDROID_HOME/licenses
COPY sdk/licenses/* $ANDROID_HOME/licenses/
RUN echo "platform tools" && \
    . /etc/jdk.env && \
    yes | $ANDROID_SDK_MANAGER ${DEBUG:+--verbose} \
        "platform-tools" > /dev/null

COPY --from=jenv-final ${JENV_HOME} ${JENV_HOME}
COPY --from=jenv-final ${INSTALLED_TEMP} ${DIRWORK}/.jenv_version
COPY --from=jenv-final /root/.bash_profile /root/.bash_profile

RUN git config --global --add safe.directory ${JENV_HOME} && \
    cat ${DIRWORK}/.jenv_version >> ${INSTALLED_VERSIONS} && \
    rm ${DIRWORK}/.*_version

WORKDIR ${FINAL_DIRWORK}

# stage1 build stage
# installs the intended android SDKs
FROM --platform=linux/amd64 minimal as stage1-base
WORKDIR ${DIRWORK}

# seems there is no emulator on arm64
# Warning: Failed to find package emulator
RUN echo "emulator" && \
    if [ "$(uname -m)" != "x86_64" ]; then echo "emulator only support Linux x86 64bit. skip for $(uname -m)"; exit 0; fi && \
    . /etc/jdk.env && \
    yes | $ANDROID_SDK_MANAGER "emulator" > /dev/null

FROM --platform=linux/arm64 minimal as stage1-base
WORKDIR ${DIRWORK}

FROM stage1-base as stage1-tagged
# Install SDKs
# Please keep these in descending order!
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

# ndk-bundle does exist on arm64
# RUN echo "NDK" && \
#     yes | $ANDROID_SDK_MANAGER "ndk-bundle" > /dev/null

FROM stage1-base as stage1-last7
ENV LAST7_PACKAGES="android-sdks.txt"
RUN cat ${SDK_PACKAGES} | grep "platforms;android-[[:digit:]][[:digit:]]\+ " | tail -n7 | awk '{print $1}' \
    >> $LAST7_PACKAGES
RUN TEMP2=$(cat ${SDK_PACKAGES} | grep "platforms;android-[[:digit:]][[:digit:]]\+ " | tail -n7 | awk '{print $1}' | grep -o '[0-9]\+') && \
    cat ${SDK_PACKAGES} | grep "build-tools;$(echo "$TEMP2" | head -n1)" | awk '{print $1}' >> $LAST7_PACKAGES && \
    cat ${SDK_PACKAGES} | grep "build-tools;$(echo "$TEMP2" | head -n2 | tail -n1)" | awk '{print $1}' >> $LAST7_PACKAGES && \
    cat ${SDK_PACKAGES} | grep "build-tools;$(echo "$TEMP2" | head -n3 | tail -n1)" | awk '{print $1}' >> $LAST7_PACKAGES && \
    cat ${SDK_PACKAGES} | grep "build-tools;$(echo "$TEMP2" | head -n4 | tail -n1)" | awk '{print $1}' >> $LAST7_PACKAGES && \
    cat ${SDK_PACKAGES} | grep "build-tools;$(echo "$TEMP2" | head -n5 | tail -n1)" | awk '{print $1}' >> $LAST7_PACKAGES && \
    cat ${SDK_PACKAGES} | grep "build-tools;$(echo "$TEMP2" | head -n6 | tail -n1)" | awk '{print $1}' >> $LAST7_PACKAGES && \
    cat ${SDK_PACKAGES} | grep "build-tools;$(echo "$TEMP2" | head -n7 | tail -n1)" | awk '{print $1}' >> $LAST7_PACKAGES

RUN echo "installing: $(cat $LAST7_PACKAGES)" && \
    . /etc/jdk.env && \
    yes | ${ANDROID_SDK_MANAGER} ${DEBUG:+--verbose} --package_file=$LAST7_PACKAGES

FROM stage1-${ANDROID_SDKS} as stage1-final
RUN echo "Android SDKs, Build tools, etc Installed: " >> ${INSTALLED_TEMP} && \
    ${ANDROID_SDK_MANAGER} --list_installed >> ${INSTALLED_TEMP}

# bundletool build stage
FROM minimal as bundletool-base
WORKDIR ${DIRWORK}
RUN echo "bundletool"

FROM bundletool-base as bundletool-tagged
RUN wget -q https://github.com/google/bundletool/releases/download/${BUNDLETOOL_VERSION}/bundletool-all-${BUNDLETOOL_VERSION}.jar -O $ANDROID_SDK_HOME/cmdline-tools/latest/bundletool.jar
RUN echo "BUNDLETOOL_VERSION=${BUNDLETOOL_VERSION}" >> ${INSTALLED_TEMP}

FROM bundletool-base as bundletool-latest
RUN TEMP=$(curl -s https://api.github.com/repos/google/bundletool/releases/latest) && \
    echo "$TEMP" | grep "browser_download_url.*jar" | cut -d : -f 2,3 | tr -d \" | wget -O $ANDROID_SDK_HOME/cmdline-tools/latest/bundletool.jar -qi - && \
    TAG_NAME=$(echo "$TEMP" | grep "tag_name" | cut -d : -f 2,3 | tr -d \"\ ,) && \
    echo "BUNDLETOOL_VERSION=$TAG_NAME" >> ${INSTALLED_TEMP}

FROM bundletool-${BUNDLETOOL_TAGGED} as bundletool-final
RUN echo "bundletool finished"

# NDK Build Stage
FROM minimal as ndk-base
WORKDIR ${DIRWORK}
RUN echo "NDK"

FROM ndk-base as ndk-tagged
RUN echo "Installing ${NDK_VERSION}" && \
    . /etc/jdk.env && \
    yes | $ANDROID_SDK_MANAGER ${DEBUG:+--verbose} "ndk;${NDK_VERSION}" > /dev/null && \
    ln -sv $ANDROID_HOME/ndk/${NDK_VERSION} ${ANDROID_NDK}
RUN echo "NDK_VERSION=${NDK_VERSION}" >> ${INSTALLED_TEMP}

FROM ndk-base as ndk-latest
RUN NDK=$(grep 'ndk;' ${SDK_PACKAGES} | sort | tail -n1 | awk '{print $1}') && \
    NDK_VERSION=$(echo $NDK | awk -F\; '{print $2}') && \
    echo "Installing $NDK" && \
    . /etc/jdk.env && \
    yes | $ANDROID_SDK_MANAGER ${DEBUG:+--verbose} "$NDK" > /dev/null && \
    ln -sv $ANDROID_HOME/ndk/$NDK_VERSION ${ANDROID_NDK} && \
    echo "NDK_VERSION=$NDK_VERSION" >> ${INSTALLED_TEMP}

FROM ndk-${NDK_TAGGED} as ndk-final
RUN echo "NDK finished"

# Flutter build stage
FROM --platform=linux/amd64 base as flutter-base
WORKDIR ${DIRWORK}
FROM flutter-base as flutter-tagged
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    echo "FLUTTER_VERSION=${FLUTTER_VERSION}" >> ${INSTALLED_TEMP}

FROM flutter-base as flutter-latest
RUN git clone --depth 5 -b stable https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    cd ${FLUTTER_HOME} && echo "FLUTTER_VERSION="$(git describe --tags HEAD) >> ${INSTALLED_TEMP}

FROM flutter-${FLUTTER_TAGGED} as flutter-final
RUN flutter config --no-analytics

# Create some jenkins required directory to allow this image run with Jenkins
FROM ubuntu as stage2
WORKDIR ${DIRWORK}
RUN mkdir -p /var/lib/jenkins/workspace && \
    mkdir -p /home/jenkins && \
    chmod 777 /home/jenkins && \
    chmod 777 /var/lib/jenkins/workspace

# fastlane and node build stage
FROM minimal as stage3
WORKDIR ${DIRWORK}
COPY Gemfile /Gemfile

RUN echo "fastlane" && \
    cd / && \
    gem install bundler --quiet --no-document > /dev/null && \
    mkdir -p /.fastlane && \
    chmod 777 /.fastlane && \
    bundle install --quiet
RUN TEMP=$(bundler exec fastlane --version) && \
    FASTLANE_VERSION=$(echo "$TEMP" | grep fastlane | tail -n 1 | tr -d 'fastlane\ ') && \
    echo "FASTLANE_VERSION=$FASTLANE_VERSION" >> ${INSTALLED_TEMP}

# Node build Stage
FROM stage3 as node-base
RUN echo "nodejs, npm, cordova, ionic, react-native"
ENV NODE_ENV=production

# Install Node
FROM node-base as node-tagged
RUN TEMP=$(curl -sL -k https://deb.nodesource.com/setup_${NODE_VERSION}) && \
        echo "$TEMP" | bash - > /dev/null && \
    NODE_VERSION=$(echo "$TEMP" | grep NODENAME= | cut -d = -f 2 | tr -d \") && \
    echo "NODE_VERSION=$NODE_VERSION" >> ${INSTALLED_TEMP}

FROM node-base as node-latest
RUN TEMP=$(curl -sL -k https://deb.nodesource.com/setup_lts.x) && \
        echo "$TEMP" | bash - > /dev/null && \
    NODE_VERSION=$(echo "$TEMP" | grep NODENAME= | cut -d = -f 2 | tr -d \") && \
    echo "NODE_VERSION=$NODE_VERSION" >> ${INSTALLED_TEMP}

FROM node-${NODE_TAGGED} as node-final
RUN apt-get install -qq nodejs > /dev/null && \
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
    apt-get -y clean && apt-get -y autoremove && rm -rf /var/lib/apt/lists/*

# complete build stage
# intended as a final target
FROM node-final as complete
COPY --from=stage1-final --chmod=775 ${ANDROID_HOME} ${ANDROID_HOME}
COPY --from=stage2 /var/lib/jenkins/workspace /var/lib/jenkins/workspace
COPY --from=stage2 /home/jenkins /home/jenkins
COPY --from=bundletool-final $ANDROID_SDK_HOME/cmdline-tools/latest/bundletool.jar $ANDROID_SDK_HOME/cmdline-tools/latest/bundletool.jar
COPY --from=ndk-final --chmod=775 ${ANDROID_NDK_ROOT}/../ ${ANDROID_NDK_ROOT}/../
COPY --from=jenv-final ${JENV_HOME} ${JENV_HOME}
COPY --from=jenv-final /root/.bash_profile /root/.bash_profile

COPY --from=stage1-final ${INSTALLED_TEMP} ${DIRWORK}/.sdks_version
COPY --from=bundletool-final ${INSTALLED_TEMP} ${DIRWORK}/.bundletool_version
COPY --from=ndk-final ${INSTALLED_TEMP} ${DIRWORK}/.ndk_version
COPY --from=node-final ${INSTALLED_TEMP} ${DIRWORK}/.node_version
COPY --from=jenv-final ${INSTALLED_TEMP} ${DIRWORK}/.jenv_version

COPY README.md /README.md

RUN chmod 775 $ANDROID_HOME $ANDROID_NDK_ROOT/../

RUN git config --global --add safe.directory ${JENV_HOME} && \
    cat ${DIRWORK}/.bundletool_version >> ${INSTALLED_VERSIONS} && \
    cat ${DIRWORK}/.ndk_version >> ${INSTALLED_VERSIONS} && \
    cat ${DIRWORK}/.node_version >> ${INSTALLED_VERSIONS} && \
    cat ${DIRWORK}/.jenv_version >> ${INSTALLED_VERSIONS} && \
    cat ${DIRWORK}/.sdks_version >> ${INSTALLED_VERSIONS} && \
    rm ${DIRWORK}/.*_version

# List sdk and ndk directory content
RUN ls -l $ANDROID_HOME && \
    ls -l $ANDROID_HOME/ndk && \
    ls -l $ANDROID_HOME/ndk/*

RUN du -sh $ANDROID_HOME

WORKDIR ${FINAL_DIRWORK}

# complete-flutter
# intended as a final-target, has complete build stage and flutter
FROM complete as complete-flutter
COPY --from=flutter-final ${FLUTTER_HOME} ${FLUTTER_HOME}
COPY --from=flutter-final /root/.flutter /root/.flutter
COPY --from=flutter-final /root/.config/flutter /root/.config/flutter
COPY --from=flutter-final ${INSTALLED_TEMP} ${DIRWORK}/.flutter_version

RUN git config --global --add safe.directory ${FLUTTER_HOME} && \
    cat ${DIRWORK}/.flutter_version >> ${INSTALLED_VERSIONS} && \
    rm ${DIRWORK}/.*_version


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
LABEL org.label-schema.docker.cmd="docker run --rm -v `pwd`:${FINAL_DIRWORK} mingc/android-build-box bash -c './gradlew build'"
LABEL org.label-schema.build-date="${BUILD_DATE}"
LABEL org.label-schema.vcs-ref="${SOURCE_COMMIT}@${SOURCE_BRANCH}"
