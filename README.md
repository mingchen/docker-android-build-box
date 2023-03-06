# Docker Android Build Box

[![docker icon](https://dockeri.co/image/mingc/android-build-box)](https://hub.docker.com/r/mingc/android-build-box/)
[![Docker Image CI](https://github.com/mingchen/docker-android-build-box/actions/workflows/docker-image.yml/badge.svg)](https://github.com/mingchen/docker-android-build-box/actions/workflows/docker-image.yml)

## Introduction

An optimized **Docker** image that includes the **Android SDK** and **Flutter SDK**.

## What Is Inside

It includes the following components:

* Ubuntu 20.04
* Java - OpenJDK
  * 8 (1.8)
  * 11
  * 17
* Android SDKs for platforms:
  * 26
  * 27
  * 28
  * 29
  * 30
  * 31
  * 32
  * 33
* Android build tools:
  * 26.0.0 26.0.1 26.0.2
  * 27.0.1 27.0.2 27.0.3
  * 28.0.1 28.0.2 28.0.3
  * 29.0.2 29.0.3
  * 30.0.0 30.0.2 30.0.3
  * 31.0.0
  * 32.0.0
  * 33.0.0
* Android NDK (always the latest version, side-by-side install)
* [Android bundletool](https://github.com/google/bundletool)
* Android Emulator
* cmake
* TestNG
* Python 3.8.10
* Node.js 16, npm, React Native
* Ruby, RubyGems
* fastlane
* Flutter 3.0.4
* [jEnv](https://www.jenv.be)

Please also see the [matrixes](COMPATIBILITY.md) file for details on the various software installed for the various tags.

## Pull Docker Image

The docker image is automatically built publicly on *Github Action* based on the `Dockerfile` in this repo, there is no hidden stuff in it.

To pull the latest docker image:

```sh
docker pull mingc/android-build-box:latest
```

**Hint:** You can use a tag to a specific stable version,
rather than `latest` of docker image, to avoid breaking your build.
e.g. `mingc/android-build-box:1.25.0`.

Take a look at the [**Tags List**](https://github.com/mingchen/docker-android-build-box/tags) to see all the available tags, the [Changelog](CHANGELOG.md) to see the changes between tags, and the [Compatibility Matrices](COMPATIBILITY.md) to see matrices of the various software available, that is tag `1.2.0` has SDKs x, y, and z... etc.

## Usage

### Use the image to build an Android project

Please see the [caches section](#caches) for how to use caching.

You can use this docker image to build your Android project with a single docker command:

```sh
cd <android project directory>  # change working directory to your project root directory.
docker run --rm -v `pwd`:/project mingc/android-build-box bash -c 'cd /project; ./gradlew build'
```

To build `.aab` bundle release, use `./gradlew bundleRelease`:

```sh
cd <android project directory>  # change working directory to your project root directory.
docker run --rm -v `pwd`:/project mingc/android-build-box bash -c 'cd /project; ./gradlew bundleRelease'
```

Run docker image with interactive bash shell:

```sh
docker run -v `pwd`:/project -it mingc/android-build-box bash -l
```

### Caches

#### jEnv Cache

To allow for the global java setting via jEnv, the file `/root/.jenv/version`, to be cached the simplest way is to cache the complete jEnv folder, `/root/.jenv/`.

First create the directory on the host where jEnv will be cached. For this example it will be in `~/.dockercache/jenv/`:
```sh
# mkdir ~/.dockercache/jenv
```

Second create a *named volume*, named `jenv-cache`. A *named volume* is necessary to allow the container's contents of jEnv to remain. The simplest manner is as follows:
```sh
# docker volume create --driver local --opt type=none --opt device=~/.dockercache/jenv/ --opt o=bind jenv-cache
```

And finally when you create / run the container, be sure to include the *named volume* by adding the following to the command:
```sh
-v jenv-cache:"/root/.jenv/"
```
e.g.
```sh
# docker run --rm -v jenv-cache:"/root/.jenv/" mingc/android-build-box bash -l `echo "Hello World"`
```

#### Gradle Cache

Add the following arguments to the docker command to cache the home gradle folder:
```sh
-v "$HOME/.dockercache/gradle":"/root/.gradle"
```
e.g.
```sh
docker run --rm -v `pwd`:/project  -v "$HOME/.dockercache/gradle":"/root/.gradle"   mingc/android-build-box bash -c 'cd /project; ./gradlew build'
```

The final step is to turn caching on by adding:
```sh
org.gradle.caching=true
```
to your `gradle.properties`. Either the project's `gradle.properties` or the global `gradle.properties` in `$HOME/.dockercache/gradle/gradle.properties`.

### Suggested gradle.properties

Setting the following `jvmargs` for gradle are suggested:
* `-Xmx8192m`
  * Sets the max memory the JVM may use to 8192m, values of g, that is gb, are supported.
* `-XX:MaxMetaspaceSize=1024m`
  * Must set due to gradle bug gradle/gradle#19750, else is unbounded.
* `-XX:+UseContainerSupport`
  * Allow JVM to know it's in a container, optional as is default.
* `-XX:MaxRAMPercentage=97.5`
  * Allow JVM to use at most 97.5% of the RAM in container, can be set to 1.

The total memory available to the container should be greater than the Xmx value + the MaxMetaspaceSize. For example, if 10gb is allocated to the container, and using the already listed values, then we have 10gb = 8gb (Xmx) + 1gb (MaxMetaspaceSize) + 1gb (overhead / buffer / other). If the container has 4gb of memory available than the following would be reasonable settings: 4gb = 3072m (Xmx) + 756m (MaxMetaspaceSize) + 256mb (overhead / etc).

In total the `gradle.properties` would be:
```sh
org.gradle.jvmargs=-Xmx8192m -XX:MaxMetaspaceSize=1024m -XX:+UseContainerSupport -XX:MaxRAMPercentage=97.5
```
or
```sh
org.gradle.jvmargs=-Xmx3072m -XX:MaxMetaspaceSize=756m -XX:+UseContainerSupport -XX:MaxRAMPercentage=97.5
```

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

    runs-on: ubuntu-20.04
    container: mingc/android-build-box:latest

    steps:
    - uses: actions/checkout@v3
    - uses: actions/cache@v3
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
      uses: actions/upload-artifact@v3
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

```sh
#!/bin/bash

# Arm emulators can be quite slow. For this reason it is convenient
# to increase the adb timeout to avoid errors.
export ADB_INSTALL_TIMEOUT=30

# Download an ARM system image to create an ARM emulator.
sdkmanager "system-images;android-22;default;armeabi-v7a"

# Create an ARM AVD emulator, with a 100 MB SD card storage space. Echo "no"
# because it will ask if you want to use a custom hardware profile, and you don't.
# https://medium.com/@AndreSand/android-emulator-on-docker-container-f20c49b129ef
echo "no" | avdmanager create avd \
    -n Android_5.1_API_22 \
    -k "system-images;android-22;default;armeabi-v7a" \
    -c 100M \
    --force

# Launch the emulator in the background
$ANDROID_HOME/emulator/emulator -avd Android_5.1_API_22 -no-skin -no-audio -no-window -no-boot-anim -gpu off &

# Note: You will have to add a suitable time delay, to wait for the emulator to launch.
```

Note that x86_64 emulators are not currently supported. See [Issue #18](https://github.com/mingchen/docker-android-build-box/issues/18) for details.

### Choose the system Java version

As of `1.23.0`, `jenv` is used to switch `java` versions. Versions prior to `1.23.0` used `update-alternatives`; brief documentation is available [here](https://github.com/mingchen/docker-android-build-box/tree/95fde4a765cecf6d43b084190394fd43bef5bfd1#choose-the-system-java-version). 

Please also see the [installed java versions matrix](COMPATIBILITY.md#Installed-Java-Versions-Matrix) for the installed java versions and [jEnv Cache](#jenv-cache) on how to cache the *global* java version.

The following documentation is for `jenv`. Please note that if the container is removed, that is run with the `-rm` flag, *global* changes will not persist unless jEnv is cached.

List all the available `java` versions:

```sh
# jenv versions
  system
  11
  11.0
  11.0.17
  17
* 17.0 (set by /root/.jenv/version)
  17.0.5
  1.8
  1.8.0.352
  openjdk64-11.0.17
  openjdk64-17.0.5
  openjdk64-1.8.0.352
```

Switch *global* `java` version to **Java 8**:

```sh
root@f7e7773edb7f:/project# jenv global 1.8
root@f7e7773edb7f:/project# java -version
openjdk version "1.8.0_352"
OpenJDK Runtime Environment (build 1.8.0_352-8u352-ga-1~20.04-b08)
OpenJDK 64-Bit Server VM (build 25.352-b08, mixed mode)
```

Switch *global* `java` version to **Java 11**:

```sh
root@f7e7773edb7f:/project# jenv global 11
root@f7e7773edb7f:/project# java -version
openjdk version "11.0.17" 2022-10-18
OpenJDK Runtime Environment (build 11.0.17+8-post-Ubuntu-1ubuntu220.04)
OpenJDK 64-Bit Server VM (build 11.0.17+8-post-Ubuntu-1ubuntu220.04, mixed mode, sharing)
```

Switch local, that is current folder, `java` version to **Java 1.8**:

```sh
root@f7e7773edb7f:/project# jenv local 1.8
root@f7e7773edb7f:/project# java -version
openjdk version "1.8.0_352"
OpenJDK Runtime Environment (build 1.8.0_352-8u352-ga-1~20.04-b08)
OpenJDK 64-Bit Server VM (build 25.352-b08, mixed mode)
root@f7e7773edb7f:/project# cd ..
root@f7e7773edb7f:/# java -version
openjdk version "17.0.5" 2022-10-18
OpenJDK Runtime Environment (build 17.0.5+8-Ubuntu-2ubuntu120.04)
OpenJDK 64-Bit Server VM (build 17.0.5+8-Ubuntu-2ubuntu120.04, mixed mode, sharing)
```

This can also be done by creating a `.java-version` file in the directory. See the SampleProject file [here](test_projects/SampleProject/.java-version) for an example.

## Build the Docker Image

If you want to build the docker image by yourself, you can use following command.
The compressed image itself is around 6 GB and uncompressed it's around 16GB, so check your free disk space before building it.

```sh
docker build -t android-build-box .
```

## Changelog

Please see the dedicated changelog [here](CHANGELOG.md).

## Compatibility

Please see the compatibility matrices [here](COMPATIBILITY.md).

## Contribution

If you want to enhance this docker image or fix something,
feel free to send a [pull request](https://github.com/mingchen/docker-android-build-box/pull/new/master).

Please also preface commits with `DOCS:` when editing any documentation and `CI:` when editing `.github/workflows/`.


## References

* [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
* [Best practices for writing Dockerfiles](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/)
* [Build your own image](https://docs.docker.com/engine/getstarted/step_four/)
* [uber android build environment](https://hub.docker.com/r/uber/android-build-environment/)
* [Refactoring a Dockerfile for image size](https://blog.replicated.com/refactoring-a-dockerfile-for-image-size/)
* [Label Schema](http://label-schema.org/)
