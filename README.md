# Docker Android Build Box

[![docker icon](https://dockeri.co/image/mingc/android-build-box)](https://hub.docker.com/r/mingc/android-build-box/)
[![Build Status](https://travis-ci.org/mingchen/docker-android-build-box.svg?branch=master)](https://travis-ci.org/mingchen/docker-android-build-box)


## Introduction

An optimized **docker** image includes **Android**, **Kotlin**, **Flutter sdk**.


## What Is Inside

It includes the following components:

* Ubuntu 18.04
* Android SDKs
  * 25
  * 26
  * 27
  * 28
  * 29
  * 30
* Android build tools:
  * 25.0.0 25.0.1 25.0.2 25.0.3
  * 26.0.0 26.0.1 26.0.2
  * 27.0.1 27.0.2 27.0.3
  * 28.0.1 28.0.2 28.0.3
  * 29.0.2 29.0.3
  * 30.0.0
* Android NDK r21
* extra-android-m2repository
* extra-google-m2repository
* extra-google-google\_play\_services
* Android Emulator
* Constraint Layout
* TestNG
* Python 2, Python 3
* Node.js, npm, React Native
* Ruby, RubyGems
* fastlane
* Kotlin 1.3
* Flutter 1.17.1


## Pull Docker Image

The docker image is publicly automated build on [Docker Hub](https://hub.docker.com/r/mingc/android-build-box/) 
based on the Dockerfile in this repo, so there is no hidden stuff in it. To pull the latest docker image:

    docker pull mingc/android-build-box:latest

**Hint:** You can use a tag to a specific stable version, rather than `latest` of docker image, to avoid breaking your build. 
e.g. `mingc/android-build-box:1.15.0`. Checkout [**Tags**](#tags) (bottom of this page) to see all the available tags.

## Usage

### Use the image to build an Android project

You can use this docker image to build your Android project with a single docker command:

    cd <android project directory>  # change working directory to your project root directory.
    docker run --rm -v `pwd`:/project mingc/android-build-box bash -c 'cd /project; ./gradlew build'

Run docker image with interactive bash shell:

    docker run -v `pwd`:/project -it mingc/android-build-box bash


### Build an Android project with [Bitbucket Pipelines](https://bitbucket.org/product/features/pipelines)

If you have an Android project in a Bitbucket repository and want to use the pipeline feature to build it, 
you can simply specify this docker image.
Here is an example of `bitbucket-pipelines.yml`:

```yml
image: mingc/android-build-box:latest

pipelines:
  default:
    - step:
        caches:
          - gradle
          - gradle-wrapper
          - android-emulator
        script:
          - bash ./gradlew assemble
definitions:
  caches:
    gradle-wrapper: ~/.gradle/wrapper
    android-emulator: $ANDROID_HOME/system-images/android-21
```

The caches are used to [store downloaded dependencies](https://confluence.atlassian.com/bitbucket/caching-dependencies-895552876.html) from previous builds, to speed up the next builds.

### Build a Flutter project with [Github Actions](https://github.com/features/actions)

Here is an example `.github/workflows/main.yml` to build a Flutter project with this docker image:

```yml
name: CI

on: [push]

jobs:
  build:

    runs-on: ubuntu-18.04
    container: mingc/android-build-box:latest

    steps:
    - uses: actions/checkout@v2
    - uses: actions/cache@v1
      with:
        path: /root/.gradle/caches
        key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle') }}
        restore-keys: |
          ${{ runner.os }}-gradle-
    - name: Build
      run: |
        echo "Work dir: $(pwd)"
        echo "User: $(whoami)"
        flutter --version
        flutter analyze
        flutter build apk
    - name: Archive apk
      uses: actions/upload-artifact@v1
      with:
        name: apk
        path: build/app/outputs/apk
    - name: Test
      run: flutter test
    - name: Clean build to avoid action/cache error
      run: rm -fr build
```

### Run an Android emulator in the Docker build machine

Using guidelines from...

* https://medium.com/@AndreSand/android-emulator-on-docker-container-f20c49b129ef
* https://spin.atomicobject.com/2016/03/10/android-test-script/
* https://paulemtz.blogspot.com/2013/05/android-testing-in-headless-emulator.html

...You can write a script to create and launch an ARM emulator, which can be used for running integration tests or instrumentation tests or unit tests:

```shell
#!/bin/bash

# Download an ARM system image to create an ARM emulator.
sdkmanager "system-images;android-16;default;armeabi-v7a"

# Create an ARM AVD emulator, with a 100 MB SD card storage space. Echo "no"
# because it will ask if you want to use a custom hardware profile, and you don't.
# https://medium.com/@AndreSand/android-emulator-on-docker-container-f20c49b129ef
echo "no" | avdmanager create avd \
    -n Android_4.1_API_16 \
    -k "system-images;android-16;default;armeabi-v7a" \
    -c 100M \
    --force

# Launch the emulator in the background
$ANDROID_HOME/emulator/emulator -avd Android_4.1_API_16 -no-skin -no-audio -no-window -no-boot-anim -gpu off &

# Note: You will have to add a suitable time delay, to wait for the emulator to launch.
```

Note that x86_64 emulators are not currently supported. See [Issue #18](https://github.com/mingchen/docker-android-build-box/issues/18) for details.

## Docker Build Image

If you want to build the docker image by yourself, you can use following command.
The image itself is more than 5 GB, check your free disk space before building it.

    docker build -t android-build-box .

## Tags

You can use a tag to a specific stable version, rather than `latest` of docker image,
to avoid breaking your build. For example `mingc/android-build-box:1.15.0`
or `mingc/android-build-box:v1.15.0`

Note that versions `1.0.0` up to `1.17.0` included every single Build Tool version and every
Android Platform version available. This generated large Docker images, around 5 GB.
Newer versions of `android-build-box` only include a subset of the newest Android Tools,
so the Docker images are smaller.

### 1.17.0

* Add build-tools;29.0.3

### 1.16.0

* Upgrade Flutter to 1.17.1.

### 1.15.0

* PR #41: Update Dockerfile to install Yarn, fastlane using bundler. @mayankkapoor

### 1.14.0

* Upgrade NDK to r21.
* Upgrade nodejs to 12.x.

### 1.13.0

* Upgrade flutter to v1.12.13+hotfix.8.

### 1.12.0

* Add bundler for fastlane.

### 1.11.2

* Fix #34: Add android sdk level 29 license.

### 1.11.1

* Add file, less and tiny-vim

### 1.11.0

* Upgrade NDK from r19 to r20.

### 1.10.0

* Upgrade Flutter from 1.2.1 to 1.5.4.

### 1.9.0

* Upgrade Ubuntu from 17.10 to 18.04.

### 1.8.0

* Upgrade Flutter from 1.0.0 to 1.2.1.

### 1.7.0

* Upgrade ndk from 18b to 19.

### 1.6.0

* Upgrade nodejs from 8.x to 10.x

### 1.5.1

* Do not send flutter analytics

### 1.5.0

* Add Flutter 1.0

### 1.4.0

* Add kotlin 1.3 support.

### 1.3.0

* PR #21: Update sdk to 28.

### 1.2.0

* PR #17: Update sdk to 27.
* PR #20: Fix issue #18 Remove pre-installed x86_64 emulator. Explain how to create and launch an ARM emulator.

### 1.1.2

* Fix License for package not accepted issue


### 1.1.1

* Fix environment variable concatenation


### 1.1.0

* Update to latest sdk 25.2.3 and ndk 13b; add build tools 21.1.2 22.0.1 23.0.1 23.0.2 23.0.3 24 24.0.1 24.0.2 24.0.3 25 25.0.1 25.0.2 25.2.3
* nodejs 7.x and react-native support
* fastlane support


### 1.0.0

* Initial release
* Android SDK 16,17,18,19.20,21,22,23,24
* Android build tool 24.0.2
* Android NDK r13
* extra-android-m2repository
* extra-google-google\_play\_services
* extra-google-m2repository


## Contribution

If you want to enhance this docker image or fix something, 
feel free to send [pull request](https://github.com/mingchen/docker-android-build-box/pull/new/master).


## References

* [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
* [Best practices for writing Dockerfiles](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/)
* [Build your own image](https://docs.docker.com/engine/getstarted/step_four/)
* [uber android build environment](https://hub.docker.com/r/uber/android-build-environment/)
* [Refactoring a Dockerfile for image size](https://blog.replicated.com/refactoring-a-dockerfile-for-image-size/)
* [Label Schema](http://label-schema.org/)

