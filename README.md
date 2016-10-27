# Docker Android Build Box


[![Build Status](https://travis-ci.org/mingchen/docker-android-build-box.svg?branch=master)](https://travis-ci.org/mingchen/docker-android-build-box)


## Introduction

An **docker** image build with **Android** build environment.


## What's Inside

It include following components:

* Android SDK 16,17,18,19.20,21,22,23,24
* Android build tool 24.0.2
* Android NDK r13
* extra-android-m2repository
* extra-google-google\_play\_services
* extra-google-m2repository


## Docker Pull Command

    docker pull mingc/android-build-box


## Docker Build Image:

    docker build -t android-build-box .


## References

* [Dockerfile reference](https://docs.docker.com/engine/reference/builder/)
* [Build your own image](https://docs.docker.com/engine/getstarted/step_four/)
* [uber android build environment](https://hub.docker.com/r/uber/android-build-environment/)

