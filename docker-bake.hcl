variable "IMAGE" {
  default = "benyoo/jdk"
}

variable "PLATFORMS" {
  default = ["linux/amd64", "linux/arm64"]
}

variable "JAVA_VERSIONS" {
  default = ["8", "11", "17", "21", "25"]
}

group "default" {
  targets = ["centos9-stream", "rockylinux9", "alpine3-24"]
}

target "_common" {
  context = "."
  dockerfile = "Dockerfile"
  platforms = PLATFORMS
}

target "centos9-stream" {
  inherits = ["_common"]
  matrix = {
    java = JAVA_VERSIONS
  }
  name = "centos9-stream-jdk${java}"
  args = {
    BASE_IMAGE = "benyoo/centos:9-stream-20260615"
    JAVA_VERSION = java
  }
  tags = [
    "${IMAGE}:${java}-centos9-stream",
    "${IMAGE}:${java}-centos9-stream-20261024",
  ]
}

target "rockylinux9" {
  inherits = ["_common"]
  matrix = {
    java = JAVA_VERSIONS
  }
  name = "rockylinux9-jdk${java}"
  args = {
    BASE_IMAGE = "benyoo/rockylinux:9-20260615"
    JAVA_VERSION = java
  }
  tags = [
    "${IMAGE}:${java}-rockylinux9",
    "${IMAGE}:${java}-rockylinux9-20261024",
  ]
}

target "alpine3-24" {
  inherits = ["_common"]
  matrix = {
    java = JAVA_VERSIONS
  }
  name = "alpine3-24-jdk${java}"
  args = {
    BASE_IMAGE = "benyoo/alpine:3.24.20260615"
    JAVA_VERSION = java
  }
  tags = [
    "${IMAGE}:${java}-alpine3.24",
    "${IMAGE}:${java}-alpine3.24-20261024",
  ]
}
