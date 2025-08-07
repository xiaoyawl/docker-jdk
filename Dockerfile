# 基于自定义的 Ubuntu 24.04 精简基础镜像
FROM benyoo/ubuntu:24.04-20250807

# 支持通过构建参数传递 JDK 版本
ARG JDK_VERSION=21.0.7

# JDK 版本到下载地址的映射
ENV JDK_DOWNLOAD_URLS="\
19=https://mirrors.dtops.co/Java/Java%20SE%2019/jdk-19.0.2_linux-x64_bin.tar.gz;\
20=https://mirrors.dtops.co/Java/Java%20SE%2020/jdk-20.0.2_linux-x64_bin.tar.gz;\
21=https://mirrors.dtops.co/Java/Java%20SE%2021/jdk-21.0.7_linux-x64_bin.tar.gz;\
22=https://mirrors.dtops.co/Java/Java%20SE%2022/jdk-22.0.1_linux-x64_bin.tar.gz;\
23=https://mirrors.dtops.co/Java/Java%20SE%2023/jdk-23.0.1_linux-x64_bin.tar.gz;\
24=https://mirrors.dtops.co/Java/Java%20SE%2024/jdk-24.0.1_linux-x64_bin.tar.gz"

# 配置 JAVA_HOME 和 PATH
ENV JAVA_HOME="/opt/java" \
    PATH="/opt/java/bin:$PATH"

# 安装必要的工具（wget、ca-certificates、tar、gzip），安装后立即清理缓存，减小镜像体积
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget ca-certificates tar gzip && \
    rm -rf /var/lib/apt/lists/*

# 根据JDK版本获取对应的下载地址并下载安装
RUN mkdir -p /opt/java && \
    JDK_MAJOR_VERSION=$(echo $JDK_VERSION | cut -d. -f1) && \
    JDK_URL=$(echo "$JDK_DOWNLOAD_URLS" | tr ';' '\n' | grep "^$JDK_MAJOR_VERSION=" | cut -d= -f2) && \
    if [ -z "$JDK_URL" ]; then \
        echo "不支持的JDK版本: $JDK_VERSION" && exit 1; \
    fi && \
    echo "下载JDK版本: $JDK_VERSION, URL: $JDK_URL" && \
    wget -q "$JDK_URL" -O /tmp/jdk.tar.gz && \
    tar -xzf /tmp/jdk.tar.gz -C /opt/java --strip-components=1 && \
    rm /tmp/jdk.tar.gz

# 可选：删除 JDK 中无用的目录和文件，进一步瘦身
RUN rm -rf /opt/java/demo /opt/java/sample /opt/java/man \
    /opt/java/lib/src.zip /opt/java/legal /opt/java/include

# 验证 JDK 安装是否成功
RUN java -version

# 默认启动命令，显示 Java 版本
CMD ["java", "-version"]