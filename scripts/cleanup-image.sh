#!/bin/sh
# 作者：Manta <manta.ops.dstw@gmail.com>
# 清理安装源码和可重建缓存，保留JDK工具、运行库、字体和许可证。
set -eu

java_home="${JAVA_HOME:-/opt/java/oracle}"
rm -f "$java_home/src.zip" "$java_home/javafx-src.zip" "$java_home/lib/src.zip"
for directory in /tmp /var/tmp /var/cache/apk /var/cache/dnf /var/cache/yum /var/cache/libdnf5 /var/lib/apt/lists; do
    if [ -d "$directory" ]; then
        find "$directory" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
    fi
done
rm -f /usr/local/bin/install-jdk /var/log/dnf* /var/log/yum.log /var/log/hawkey.log /var/log/dpkg.log
if [ -d /var/log/apt ]; then
    find /var/log/apt -type f -delete
fi
printf '已清理JDK源码包、临时文件及包管理缓存\n'
