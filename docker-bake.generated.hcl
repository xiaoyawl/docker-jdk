variable "IMAGE" {
  default = "benyoo/jdk"
}

variable "PLATFORMS" {
  default = ["linux/amd64", "linux/arm64"]
}

group "default" {
  targets = [
    "centos9-stream-jdk8",
    "centos9-stream-jdk11",
    "centos9-stream-jdk17",
    "centos9-stream-jdk21",
    "centos9-stream-jdk25",
    "rockylinux9-jdk8",
    "rockylinux9-jdk11",
    "rockylinux9-jdk17",
    "rockylinux9-jdk21",
    "rockylinux9-jdk25",
    "alpine3-24-jdk8",
    "alpine3-24-jdk11",
    "alpine3-24-jdk17",
    "alpine3-24-jdk21",
    "alpine3-24-jdk25",
  ]
}

target "_common" {
  context = "."
  dockerfile = "Dockerfile"
  platforms = PLATFORMS
}

target "centos9-stream-jdk8" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "benyoo/centos:9-stream-20260615"
    JAVA_VERSION = "8"
  }
  tags = [
    "${IMAGE}:8-centos9-stream",
    "${IMAGE}:8u511-centos9-stream",
    "${IMAGE}:8-centos9-stream-20261024",
    "${IMAGE}:8u511-centos9-stream-20261024",
  ]
}

target "centos9-stream-jdk11" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "benyoo/centos:9-stream-20260615"
    JAVA_VERSION = "11"
  }
  tags = [
    "${IMAGE}:11-centos9-stream",
    "${IMAGE}:11.0.33.0.2-centos9-stream",
    "${IMAGE}:11-centos9-stream-20261024",
    "${IMAGE}:11.0.33.0.2-centos9-stream-20261024",
  ]
}

target "centos9-stream-jdk17" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "benyoo/centos:9-stream-20260615"
    JAVA_VERSION = "17"
  }
  tags = [
    "${IMAGE}:17-centos9-stream",
    "${IMAGE}:17.0.21.0.2-centos9-stream",
    "${IMAGE}:17-centos9-stream-20261024",
    "${IMAGE}:17.0.21.0.2-centos9-stream-20261024",
  ]
}

target "centos9-stream-jdk21" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "benyoo/centos:9-stream-20260615"
    JAVA_VERSION = "21"
  }
  tags = [
    "${IMAGE}:21-centos9-stream",
    "${IMAGE}:21.0.13.0.2-centos9-stream",
    "${IMAGE}:21-centos9-stream-20261024",
    "${IMAGE}:21.0.13.0.2-centos9-stream-20261024",
  ]
}

target "centos9-stream-jdk25" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "benyoo/centos:9-stream-20260615"
    JAVA_VERSION = "25"
  }
  tags = [
    "${IMAGE}:25-centos9-stream",
    "${IMAGE}:25.0.5.0.2-centos9-stream",
    "${IMAGE}:25-centos9-stream-20261024",
    "${IMAGE}:25.0.5.0.2-centos9-stream-20261024",
  ]
}

target "rockylinux9-jdk8" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "benyoo/rockylinux:9-20260615"
    JAVA_VERSION = "8"
  }
  tags = [
    "${IMAGE}:8-rockylinux9",
    "${IMAGE}:8u511-rockylinux9",
    "${IMAGE}:8-rockylinux9-20261024",
    "${IMAGE}:8u511-rockylinux9-20261024",
  ]
}

target "rockylinux9-jdk11" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "benyoo/rockylinux:9-20260615"
    JAVA_VERSION = "11"
  }
  tags = [
    "${IMAGE}:11-rockylinux9",
    "${IMAGE}:11.0.33.0.2-rockylinux9",
    "${IMAGE}:11-rockylinux9-20261024",
    "${IMAGE}:11.0.33.0.2-rockylinux9-20261024",
  ]
}

target "rockylinux9-jdk17" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "benyoo/rockylinux:9-20260615"
    JAVA_VERSION = "17"
  }
  tags = [
    "${IMAGE}:17-rockylinux9",
    "${IMAGE}:17.0.21.0.2-rockylinux9",
    "${IMAGE}:17-rockylinux9-20261024",
    "${IMAGE}:17.0.21.0.2-rockylinux9-20261024",
  ]
}

target "rockylinux9-jdk21" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "benyoo/rockylinux:9-20260615"
    JAVA_VERSION = "21"
  }
  tags = [
    "${IMAGE}:21-rockylinux9",
    "${IMAGE}:21.0.13.0.2-rockylinux9",
    "${IMAGE}:21-rockylinux9-20261024",
    "${IMAGE}:21.0.13.0.2-rockylinux9-20261024",
  ]
}

target "rockylinux9-jdk25" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "benyoo/rockylinux:9-20260615"
    JAVA_VERSION = "25"
  }
  tags = [
    "${IMAGE}:25-rockylinux9",
    "${IMAGE}:25.0.5.0.2-rockylinux9",
    "${IMAGE}:25-rockylinux9-20261024",
    "${IMAGE}:25.0.5.0.2-rockylinux9-20261024",
  ]
}

target "alpine3-24-jdk8" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "benyoo/alpine:3.24.20260615"
    JAVA_VERSION = "8"
  }
  tags = [
    "${IMAGE}:8-alpine3.24",
    "${IMAGE}:8u511-alpine3.24",
    "${IMAGE}:8-alpine3.24-20261024",
    "${IMAGE}:8u511-alpine3.24-20261024",
  ]
}

target "alpine3-24-jdk11" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "benyoo/alpine:3.24.20260615"
    JAVA_VERSION = "11"
  }
  tags = [
    "${IMAGE}:11-alpine3.24",
    "${IMAGE}:11.0.33.0.2-alpine3.24",
    "${IMAGE}:11-alpine3.24-20261024",
    "${IMAGE}:11.0.33.0.2-alpine3.24-20261024",
  ]
}

target "alpine3-24-jdk17" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "benyoo/alpine:3.24.20260615"
    JAVA_VERSION = "17"
  }
  tags = [
    "${IMAGE}:17-alpine3.24",
    "${IMAGE}:17.0.21.0.2-alpine3.24",
    "${IMAGE}:17-alpine3.24-20261024",
    "${IMAGE}:17.0.21.0.2-alpine3.24-20261024",
  ]
}

target "alpine3-24-jdk21" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "benyoo/alpine:3.24.20260615"
    JAVA_VERSION = "21"
  }
  tags = [
    "${IMAGE}:21-alpine3.24",
    "${IMAGE}:21.0.13.0.2-alpine3.24",
    "${IMAGE}:21-alpine3.24-20261024",
    "${IMAGE}:21.0.13.0.2-alpine3.24-20261024",
  ]
}

target "alpine3-24-jdk25" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "benyoo/alpine:3.24.20260615"
    JAVA_VERSION = "25"
  }
  tags = [
    "${IMAGE}:25-alpine3.24",
    "${IMAGE}:25.0.5.0.2-alpine3.24",
    "${IMAGE}:25-alpine3.24-20261024",
    "${IMAGE}:25.0.5.0.2-alpine3.24-20261024",
  ]
}

