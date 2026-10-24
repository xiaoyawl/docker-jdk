IMAGE ?= benyoo/jdk
JAVA_VERSION ?= 21
BASE_IMAGE ?= benyoo/rockylinux:9-20260615
OS_VARIANT ?= rockylinux9
PLATFORMS ?= linux/amd64,linux/arm64

.PHONY: build generate-bake bake print-bake print-primary print-mirror print-full-version

build:
	docker buildx build \
		--platform "$(PLATFORMS)" \
		--build-arg BASE_IMAGE="$(BASE_IMAGE)" \
		--build-arg JAVA_VERSION="$(JAVA_VERSION)" \
		-t "$(IMAGE):$(JAVA_VERSION)-$(OS_VARIANT)" \
		.

generate-bake:
	IMAGE="$(IMAGE)" PLATFORMS="$(PLATFORMS)" ./scripts/generate-bake.sh docker-bake.generated.hcl

bake: generate-bake
	IMAGE="$(IMAGE)" docker buildx bake -f docker-bake.generated.hcl

print-bake: generate-bake
	IMAGE="$(IMAGE)" docker buildx bake -f docker-bake.generated.hcl --print

print-primary:
	JAVA_VERSION="$(JAVA_VERSION)" TARGETARCH=amd64 ./scripts/install-jdk.sh --print-primary-url

print-mirror:
	JAVA_VERSION="$(JAVA_VERSION)" TARGETARCH=amd64 ./scripts/install-jdk.sh --print-mirror-url

print-full-version:
	JAVA_VERSION="$(JAVA_VERSION)" TARGETARCH=amd64 ./scripts/install-jdk.sh --print-full-version
