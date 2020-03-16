# Docker Android Build Box

[![docker icon](https://dockeri.co/image/mingc/android-build-box)](https://hub.docker.com/r/mingc/android-build-box/)
[![Build Status](https://travis-ci.org/mingchen/docker-android-build-box.svg?branch=flutter)](https://travis-ci.org/mingchen/docker-android-build-box)

## Introduction

This branch (`flutter`) **only** includes **Android**, **Kotlin**, **Flutter sdk**, no **NDK** and other tools.
Checkout `master` branch for full set of tools.

## What Is Inside

It includes the following components:

* Ubuntu 18.04
* Android SDK 28 29
* Android build tools:
  * 28.0.3
  * 29.0.2
* extra-android-m2repository
* extra-google-m2repository
* extra-google-google\_play\_services
* Google API add-ons
* Android Emulator
* Constraint Layout
* Kotlin 1.3
* Flutter 1.12.13+hotfix.8

## Pull Docker Image

The docker image is publicly automated build on [Docker Hub](https://hub.docker.com/r/mingc/android-build-box/)
based on the Dockerfile in this repo, so there is no hidden stuff in it. To pull the latest docker image:

```bash
docker pull mingc/android-build-box:flutter-latest
```

## Usage

see https://github.com/mingchen/docker-android-build-box#usage

## Docker Build Image

If you want to build the docker image by yourself, you can use following command.

```bash
docker build -t android-build-box:flutter-latest .
```

## Tags

see https://github.com/mingchen/docker-android-build-box#tags

## Contribution

If you want to enhance this docker image or fix something, feel free to send [pull request](https://github.com/mingchen/docker-android-build-box/pull/new/flutter).

## References

* [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
* [Best practices for writing Dockerfiles](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/)
* [Build your own image](https://docs.docker.com/engine/getstarted/step_four/)
* [uber android build environment](https://hub.docker.com/r/uber/android-build-environment/)
* [Refactoring a Dockerfile for image size](https://blog.replicated.com/refactoring-a-dockerfile-for-image-size/)
