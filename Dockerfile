ARG BASE_IMAGE=benyoo/rockylinux:9-20260615
FROM ${BASE_IMAGE} AS openssl-compat

ARG JAVA_VERSION=21
COPY scripts/build-openssl-compat.sh /tmp/build-openssl-compat.sh
RUN sh /tmp/build-openssl-compat.sh

FROM ${BASE_IMAGE}

ENV JAVA_HOME=/opt/java/oracle \
    PATH=/usr/local/bin:/opt/java/oracle/bin:$PATH \
    LD_LIBRARY_PATH=/opt/java/oracle/lib/server:/opt/java/oracle/lib:/opt/java/oracle/jre/lib/amd64/server:/opt/java/oracle/jre/lib/amd64:/opt/java/oracle/jre/lib/aarch64/server:/opt/java/oracle/jre/lib/aarch64 \
    LANG=C.UTF-8 \
    APP_HOME=/app

SHELL ["/bin/sh", "-c"]

COPY scripts/install-jdk.sh /usr/local/bin/install-jdk
COPY scripts/cleanup-image.sh /usr/local/bin/cleanup-image
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY scripts/log-cleaner.sh /usr/local/bin/log-cleaner
COPY scripts/java-wrapper.sh /usr/local/bin/java
COPY jdk-packages.lock /usr/local/share/jdk-packages.lock
COPY --from=openssl-compat /compat-root/ /

RUN set -eux; \
    if command -v dnf >/dev/null 2>&1; then \
        dnf -y upgrade --refresh; \
        dnf -y install \
            bash \
            ca-certificates \
            cronie \
            curl \
            findutils \
            fontconfig \
            freetype \
            dejavu-sans-fonts \
            google-noto-sans-cjk-ttc-fonts \
            libX11 \
            libXext \
            libXi \
            libXrender \
            libXtst \
            gzip \
            tar \
            tzdata \
            glibc-langpack-en; \
        dnf clean all; \
        rm -rf /var/cache/dnf; \
    elif command -v microdnf >/dev/null 2>&1; then \
        microdnf upgrade -y; \
        microdnf install -y \
            bash \
            ca-certificates \
            cronie \
            curl \
            findutils \
            fontconfig \
            freetype \
            dejavu-sans-fonts \
            google-noto-sans-cjk-ttc-fonts \
            libX11 \
            libXext \
            libXi \
            libXrender \
            libXtst \
            gzip \
            tar \
            tzdata \
            glibc-langpack-en; \
        microdnf clean all; \
        rm -rf /var/cache/yum /var/cache/dnf; \
    elif command -v apt-get >/dev/null 2>&1; then \
        export DEBIAN_FRONTEND=noninteractive; \
        apt-get update; \
        apt-get upgrade -y; \
        apt-get install -y --no-install-recommends \
            bash \
            ca-certificates \
            coreutils \
            cron \
            curl \
            findutils \
            fontconfig \
            libfreetype6 \
            fonts-dejavu-core \
            fonts-noto-cjk \
            libx11-6 \
            libxext6 \
            libxi6 \
            libxrender1 \
            libxtst6 \
            gzip \
            tar \
            tzdata; \
        rm -rf /var/lib/apt/lists/*; \
    elif command -v apk >/dev/null 2>&1; then \
        apk upgrade --no-cache; \
        apk add --no-cache \
            bash \
            ca-certificates \
            coreutils \
            curl \
            findutils \
            fontconfig \
            freetype \
            font-dejavu \
            font-noto-cjk \
            libx11 \
            libxext \
            libxi \
            libxrender \
            libxtst \
            gcompat \
            gzip \
            libc6-compat \
            libstdc++ \
            tar \
            tzdata; \
        update-ca-certificates; \
    else \
        echo "ERROR: unsupported base image package manager" >&2; \
        exit 1; \
    fi; \
    fc-cache -f; \
    test -n "$(fc-list :lang=zh family)"

ARG JAVA_VERSION=21
ARG TARGETARCH

RUN set -eux; \
    chmod +x /usr/local/bin/install-jdk /usr/local/bin/docker-entrypoint.sh /usr/local/bin/log-cleaner /usr/local/bin/java; \
    JAVA_VERSION="${JAVA_VERSION}" TARGETARCH="${TARGETARCH}" install-jdk; \
    sh /usr/local/bin/cleanup-image; \
    rm -f /usr/local/bin/cleanup-image; \
    mkdir -p "${APP_HOME}" /config /data /logs; \
    java -version; \
    javac -version

WORKDIR /app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["java", "-version"]
