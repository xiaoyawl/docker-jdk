#!/usr/bin/env bash
set -Eeuo pipefail

JAVA_VERSION="${JAVA_VERSION:-21}"
TARGETARCH="${TARGETARCH:-$(uname -m)}"
JAVA_HOME="${JAVA_HOME:-/opt/java/oracle}"
MIRROR_ROOT="${JDK_MIRROR_ROOT:-https://mirrors.dtops.co/Java}"
LOCK_FILE="${JDK_LOCK_FILE:-/usr/local/share/jdk-packages.lock}"
if [ ! -f "$LOCK_FILE" ]; then
    LOCK_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/jdk-packages.lock"
fi

case "${JAVA_VERSION}" in
    8|11|17|21|25) ;;
    *)
        echo "ERROR: unsupported JAVA_VERSION=${JAVA_VERSION}; supported: 8, 11, 17, 21, 25" >&2
        exit 1
        ;;
esac

case "${TARGETARCH}" in
    amd64|x86_64)
        ORACLE_ARCH="x64"
        ;;
    arm64|aarch64)
        ORACLE_ARCH="aarch64"
        ;;
    *)
        echo "ERROR: unsupported TARGETARCH=${TARGETARCH}; supported: amd64, arm64" >&2
        exit 1
        ;;
esac

locked_package() {
    [ -f "$LOCK_FILE" ] || return 1
    awk -F '|' -v major="$JAVA_VERSION" -v arch="$ORACLE_ARCH" \
        '$1 == major && $2 == arch {print}' "$LOCK_FILE"
}

primary_url() {
    local package
    package="$(locked_package || true)"
    if [ -n "$package" ]; then
        printf '%s\n' "$package" | cut -d '|' -f 5
    else
        resolve_mirror_url
    fi
}

mirror_base_url() {
    printf '%s/Java%%20SE%%20%s/\n' "${MIRROR_ROOT%/}" "${JAVA_VERSION}"
}

hrefs_from() {
    local url="$1"
    curl -fsSL "$url" \
        | grep -oE 'href="[^"]+"' \
        | cut -d'"' -f2 \
        | grep -Ev '^(\?|#|../|/)' \
        || true
}

select_linux_tarball() {
    grep -E "linux-${ORACLE_ARCH}.*\.tar\.gz$|linux_${ORACLE_ARCH}.*\.tar\.gz$|linux-${ORACLE_ARCH}_bin\.tar\.gz$|linux_${ORACLE_ARCH}_bin\.tar\.gz$" \
        | sort -V \
        | tail -n 1
}

resolve_mirror_url() {
    local base href file dir
    base="$(mirror_base_url)"

    file="$(hrefs_from "$base" | select_linux_tarball || true)"
    if [ -n "$file" ]; then
        printf '%s%s\n' "$base" "$file"
        return 0
    fi

    while IFS= read -r dir; do
        href="$(hrefs_from "${base}${dir}" | select_linux_tarball || true)"
        if [ -n "$href" ]; then
            printf '%s%s%s\n' "$base" "$dir" "$href"
            return 0
        fi
    done < <(hrefs_from "$base" | grep -E '^[0-9][0-9A-Za-z._+-]*/$' | sort -Vr)

    echo "ERROR: no fallback JDK tarball found in ${base} for linux-${ORACLE_ARCH}" >&2
    return 1
}

download_with_retry() {
    local url="$1"
    local dest="$2"

    curl -fL \
        -H 'Cookie: oraclelicense=accept-securebackup-cookie' \
        --connect-timeout 20 \
        --retry 3 \
        --retry-delay 2 \
        --retry-all-errors \
        --max-time 1800 \
        -o "$dest" \
        "$url"
}

download_jdk_archive() {
    local url="$1"
    local dest="$2"

    if ! download_with_retry "$url" "$dest"; then
        return 1
    fi

    gzip -t "$dest" >/dev/null 2>&1
}

version_from_url() {
    local url="$1"
    local name version
    name="${url##*/}"

    if [[ "$name" =~ jdk-(8u[0-9]+)-linux ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
    fi

    if [[ "$name" =~ jdk-([0-9]+(\.[0-9]+)+)_linux ]]; then
        printf '%s\n' "${BASH_REMATCH[1]}"
        return 0
    fi

    return 1
}

version_from_oracle_downloads_page() {
    local version="$1"
    curl -fsSL "https://www.oracle.com/java/technologies/downloads/" \
        | grep -oE "Java SE Development Kit ${version}[.0-9]+ downloads" \
        | head -n 1 \
        | awk '{print $5}'
}

resolved_jdk_version() {
    local url version package

    package="$(locked_package || true)"
    if [ -n "$package" ]; then
        printf '%s\n' "$package" | cut -d '|' -f 3
        return 0
    fi

    case "${JAVA_VERSION}" in
        21|25)
            version="$(version_from_oracle_downloads_page "$JAVA_VERSION" || true)"
            if [ -n "$version" ]; then
                printf '%s\n' "$version"
                return 0
            fi
            ;;
    esac

    url="$(primary_url)"
    version="$(version_from_url "$url" || true)"
    if [ -n "$version" ]; then
        printf '%s\n' "$version"
        return 0
    fi

    url="$(resolve_mirror_url)"
    version_from_url "$url"
}

if [ "${1:-}" = "--print-primary-url" ]; then
    primary_url
    exit 0
fi

if [ "${1:-}" = "--print-mirror-url" ]; then
    resolve_mirror_url
    exit 0
fi

if [ "${1:-}" = "--print-full-version" ]; then
    resolved_jdk_version
    exit 0
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

jdk_archive="${tmp_dir}/jdk.tar.gz"
package="$(locked_package || true)"
if [ -z "$package" ]; then
    echo "错误：缺少 JDK ${JAVA_VERSION}/${ORACLE_ARCH} 的安装包锁定记录" >&2
    exit 1
fi
IFS='|' read -r locked_major locked_arch locked_version expected_runtime source_url expected_sha256 <<< "$package"

echo "安装 Oracle JDK ${locked_version}，目标架构 linux/${TARGETARCH}"
echo "使用已锁定安装包：${source_url}"
download_jdk_archive "$source_url" "$jdk_archive"
printf '%s  %s\n' "$expected_sha256" "$jdk_archive" | sha256sum -c -

rm -rf "$JAVA_HOME"
mkdir -p "$JAVA_HOME"
tar -xzf "$jdk_archive" -C "$JAVA_HOME" --strip-components=1

actual_runtime="$(sed -n 's/^JAVA_RUNTIME_VERSION="\([^"]*\)"/\1/p' "$JAVA_HOME/release")"
if [ "$actual_runtime" != "$expected_runtime" ]; then
    echo "错误：安装包运行时版本不符合锁定记录：${actual_runtime}，预期 ${expected_runtime}" >&2
    exit 1
fi

if [ "$JAVA_VERSION" = 8 ]; then
    cacerts="$JAVA_HOME/jre/lib/security/cacerts"
else
    cacerts="$JAVA_HOME/lib/security/cacerts"
fi
cp "$cacerts" "$tmp_dir/cacerts.before"
"$JAVA_HOME/bin/keytool" -list -keystore "$cacerts" -storepass changeit >/dev/null
for alias in 'emsigneccrootcag3 [jdk]' 'comodoaaaca [jdk]'; do
    if "$JAVA_HOME/bin/keytool" -list -keystore "$cacerts" -storepass changeit -alias "$alias" >/dev/null 2>&1; then
        "$JAVA_HOME/bin/keytool" -delete -keystore "$cacerts" -storepass changeit -alias "$alias"
        echo "已按 Oracle 安全指引移除根证书：${alias}"
    fi
done

echo "Oracle JDK 安装及证书处置完成：${actual_runtime}"
"${JAVA_HOME}/bin/java" -version
"${JAVA_HOME}/bin/javac" -version
