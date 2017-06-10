# Java SE Development Kit For Docker


This repository contains **Dockerfile** of [Java](https://www.java.com/) for [Docker](https://www.docker.com/)'s [automated build](https://hub.docker.com/r/benyoo/jdk/tags/) published to the public [Docker Hub Registry](https://registry.hub.docker.com/).


### Base Docker Image

* [benyoo/alpine](https://hub.docker.com/r/benyoo/alpine/)


### Docker Tags

`benyoo/jdk` provides multiple tagged images:

* `latest` (default): OpenJDK Java 7 JDK (alias to `alpine.1.7.80.b15`)

* `benyoo/jdk:alpine.1.7.80.b15`: Oracle Java 6 JDK 1.7.80.b15
* `benyoo/jdk:alpine.1.8.131.b11`: Oracle Java 8 JDK 1.8.131.b11

For example, you can run a `Oracle Java 8` container with the following command:

```bash
[lookback@MacBook-Pro ~]$ docker run -it --rm benyoo/jdk:alpine.1.8.131.b11 java -version
java version "1.8.0_131"
Java(TM) SE Runtime Environment (build 1.8.0_131-b11)
Java HotSpot(TM) 64-Bit Server VM (build 25.131-b11, mixed mode)
```

### Installation

1. Install [Docker](https://www.docker.com/).

2. Download [automated build](https://hub.docker.com/r/benyoo/jdk/tags/) from public [Docker Hub Registry](https://registry.hub.docker.com/): `docker pull benyoo/jdk`

   (alternatively, you can build an image from Dockerfile: `docker build -t="benyoo/jdk" github.com/xiaoyawl/docker-jdk`)


### Usage

    docker run -it --rm benyoo/jdk bash

#### Run `java`

    docker run -it --rm benyoo/jdk java

#### Run `javac`

    docker run -it --rm benyoo/jdk javac
#### Build container

```bash
docker build -t benyoo/jdk github.com/xiaoyawl/docker-jdk
```
##### Build specify the version container
```bash
docker build -t benyoo/jdk:alpine.1.7.79.b15 --build-arg JAVA_VERSION_MAJOR=7 --build-arg JAVA_VERSION_MINOR=79 --build-arg JAVA_VERSION_BUILD=15 github.com/xiaoyawl/docker-jdk

docker build -t benyoo/jdk:alpine.1.8.131.b11 --build-arg JAVA_VERSION_MAJOR=8 --build-arg JAVA_VERSION_MINOR=131 --build-arg JAVA_VERSION_BUILD=11 github.com/xiaoyawl/docker-jdk
```

