#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE="${IMAGE:-benyoo/jdk}"
OUTPUT="${1:-docker-bake.generated.hcl}"
BUILD_DATE="${BUILD_DATE:-20261024}"
BASE_IMAGE_DATE="${BASE_IMAGE_DATE:-20260615}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"

JAVA_VERSIONS=(8 11 17 21 25)
BASE_TARGETS=(
    "centos9-stream|centos9-stream|benyoo/centos:9-stream-${BASE_IMAGE_DATE}"
    "rockylinux9|rockylinux9|benyoo/rockylinux:9-${BASE_IMAGE_DATE}"
    "alpine3-24|alpine3.24|benyoo/alpine:3.24.20260615"
)

write_header() {
    local platform_list
    platform_list="$(printf '"%s"' "${PLATFORMS%%,*}")"
    local rest="${PLATFORMS#*,}"
    while [ "$rest" != "$PLATFORMS" ]; do
        platform_list="${platform_list}, \"${rest%%,*}\""
        [ "$rest" = "${rest#*,}" ] && break
        rest="${rest#*,}"
    done

    cat > "$OUTPUT" <<EOF
variable "IMAGE" {
  default = "${IMAGE}"
}

variable "PLATFORMS" {
  default = [${platform_list}]
}

group "default" {
  targets = [
EOF
}

write_target_list_item() {
    local target="$1"
    printf '    "%s",\n' "$target" >> "$OUTPUT"
}

write_common() {
    cat >> "$OUTPUT" <<'EOF'
  ]
}

target "_common" {
  context = "."
  dockerfile = "Dockerfile"
  platforms = PLATFORMS
}

EOF
}

write_target() {
    local target_name="$1"
    local tag_suffix="$2"
    local base_image="$3"
    local major="$4"
    local full="$5"
    local target="${target_name}-jdk${major}"

    cat >> "$OUTPUT" <<EOF
target "${target}" {
  inherits = ["_common"]
  args = {
    BASE_IMAGE = "${base_image}"
    JAVA_VERSION = "${major}"
  }
  tags = [
    "\${IMAGE}:${major}-${tag_suffix}",
    "\${IMAGE}:${full}-${tag_suffix}",
    "\${IMAGE}:${major}-${tag_suffix}-${BUILD_DATE}",
    "\${IMAGE}:${full}-${tag_suffix}-${BUILD_DATE}",
  ]
}

EOF
}

FULL_VERSIONS=()

for major in "${JAVA_VERSIONS[@]}"; do
    FULL_VERSIONS+=("$(JAVA_VERSION="$major" TARGETARCH=amd64 ./scripts/install-jdk.sh --print-full-version)")
done

write_header
for base_target in "${BASE_TARGETS[@]}"; do
    target_name="${base_target%%|*}"
    for major in "${JAVA_VERSIONS[@]}"; do
        write_target_list_item "${target_name}-jdk${major}"
    done
done
write_common

for base_target in "${BASE_TARGETS[@]}"; do
    target_name="${base_target%%|*}"
    rest="${base_target#*|}"
    tag_suffix="${rest%%|*}"
    base_image="${rest#*|}"

    for major in "${JAVA_VERSIONS[@]}"; do
        index=0
        for item in "${JAVA_VERSIONS[@]}"; do
            [ "$item" = "$major" ] && break
            index=$((index + 1))
        done
        write_target "$target_name" "$tag_suffix" "$base_image" "$major" "${FULL_VERSIONS[$index]}"
    done
done

echo "Generated ${OUTPUT}"
index=0
for major in "${JAVA_VERSIONS[@]}"; do
    echo "JDK ${major}: ${FULL_VERSIONS[$index]}"
    index=$((index + 1))
done
