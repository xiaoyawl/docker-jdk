ARG BASE_IMAGE=benyoo/rockylinux:9-20260615
FROM ${BASE_IMAGE}

ENV JAVA_HOME=/opt/java/oracle \
    PATH=/usr/local/bin:/opt/java/oracle/bin:$PATH \
    LD_LIBRARY_PATH=/opt/java/oracle/lib/server:/opt/java/oracle/lib:/opt/java/oracle/jre/lib/amd64/server:/opt/java/oracle/jre/lib/amd64:/opt/java/oracle/jre/lib/aarch64/server:/opt/java/oracle/jre/lib/aarch64 \
    LANG=C.UTF-8 \
    APP_HOME=/app

SHELL ["/bin/sh", "-c"]

COPY scripts/install-jdk.sh /usr/local/bin/install-jdk
COPY scripts/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY scripts/log-cleaner.sh /usr/local/bin/log-cleaner
COPY scripts/java-wrapper.sh /usr/local/bin/java
COPY jdk-packages.lock /usr/local/share/jdk-packages.lock

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
    fi

ARG JAVA_VERSION=21
ARG TARGETARCH

RUN set -eux; \
    chmod +x /usr/local/bin/install-jdk /usr/local/bin/docker-entrypoint.sh /usr/local/bin/log-cleaner /usr/local/bin/java; \
    JAVA_VERSION="${JAVA_VERSION}" TARGETARCH="${TARGETARCH}" install-jdk; \
    mkdir -p "${APP_HOME}" /config /data /logs; \
    java -version; \
    javac -version

WORKDIR /app

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["java", "-version"]
