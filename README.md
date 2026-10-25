# DSTW Docker JDK

![Docker](https://img.shields.io/badge/docker-buildx-blue)
![Arch](https://img.shields.io/badge/arch-amd64%20%7C%20arm64-green)
![Java](https://img.shields.io/badge/java-8%20%7C%2011%20%7C%2017%20%7C%2021%20%7C%2025-orange)

公开源码：[xiaoyawl/docker-jdk](https://github.com/xiaoyawl/docker-jdk)。历史实现的许可证文本保留在 [alpine/LICENSE](https://github.com/xiaoyawl/docker-jdk/blob/master/alpine/LICENSE)，Oracle JDK 安装包许可保留包内原始声明。

## Overview

基于 `xiaoyawl/docker-jdk` 的单 Dockerfile 思路重做为多系统、多架构、多 JDK 版本镜像工程。默认支持 `benyoo/centos:9-stream-20260615`、`benyoo/rockylinux:9-20260615` 和 `benyoo/alpine:3.24.20260615`，后续增加 Ubuntu 只需要在 `docker-bake.hcl` 追加一个 target。

构建时只安装 Oracle JDK，优先使用自有镜像站 `https://mirrors.dtops.co/Java/`。本次安全重建使用 `jdk-packages.lock` 固定两种架构的完整版本、运行时构建号、下载地址和 SHA-256；下载失败、校验不符或包内版本不符时立即停止，不自动回退旧包。

## JDK Source Policy

| 下载阶段 | 来源 | 实际 JDK 发行版 | 版本策略 |
|---|---|---|---|
| 安装 | `mirrors.dtops.co` | Oracle JDK | 使用锁定清单指定的包，并核对 SHA-256 和包内运行时版本 |
| 发现候选 | `--print-mirror-url` | 待核实的 Oracle JDK 包 | 扫描版本目录及子目录，结果须经内容核实后更新锁定清单 |

注意：镜像只接受 Oracle JDK，不安装其他 JDK 发行版。锁定清单中的 SHA-256 来自自有镜像站下载实测，用于保证后续构建输入一致，不代表已独立验证 Oracle 发布者签名。

## 本次安全重建

安装包基线为 JDK 8u511-b32、11.0.33.0.2、17.0.21.0.2、21.0.13.0.2、25.0.5.0.2，两种架构均已读取包内 `release` 文件核实。

Dockerfile 会更新系统软件包，并按 [Oracle 2026-10-23 指引](https://ops.java/emudhra) 从默认 Java 信任库移除 `emsigneccrootcag3 [jdk]` 和 `comodoaaaca [jdk]`。这会影响依赖这些根证书的连接，业务升级前须验证实际 HTTPS 接口；业务挂载的自定义信任库需要单独检查。现有容器需要重新构建或拉取新业务镜像并重建容器，才能使用修复后的运行时。

`tests/RuntimeSmoke.java` 用于检查实际运行时版本、时区、SHA-256 和正常 HTTPS；证书信任使用 Oracle `CheckCerts.java` 单独验收。构建成功、运行验证和外部发布分别记录，不以版本号代替漏洞验收。

本次 JDK 8、11、17、21、25 的三个系统变体均已发布，均包含 linux/amd64、linux/arm64。每个版本线均已从 Docker Hub 重新拉取并验证运行时及默认信任库。arm64 使用 QEMU 验证，实际 Tomcat 应用需单独验收。

完整发布说明与 Tomcat 后续构建方法见 [Docker Hub 仓库概览](docs/DockerHub仓库概览-全版本安全维护-20261024200027-20261025192337.md)。

## JDK8 / Alpine 的旧本地库兼容

JDK8 / Alpine 构建额外提供 OpenSSL 1.0.0 ABI 兼容库，放置于 `/opt/compat/openssl-1.0.0s/lib`，并通过 `/usr/local/lib` 中的版本化链接供动态链接器发现。系统现有 OpenSSL 保持独立，镜像不包含业务 `libCryption.so`，该组件继续由业务 JAR 提供。

源码来自 [OpenSSL 官方历史发布](https://mirror.openssl-library.org/source/old/1.0.0/index.html)，构建脚本固定完整地址和 SHA-256。该旧版本已结束支持，仅用于既有 JNI 兼容，不能视为安全升级，也不应供新应用使用。原始许可证随库保留。其他 JDK 版本和系统变体不安装这些兼容库。

This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit (http://www.openssl.org/). This product includes cryptographic software written by Eric Young (eay@cryptsoft.com).

业务启动脚本可显式声明依赖目录，并保留镜像原有搜索路径：

```bash
export LD_LIBRARY_PATH="/opt/compat/openssl-1.0.0s/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
```

`System.load(绝对路径)` 仍加载业务指定的顶层文件；上述设置用于查找其传递依赖。镜像的双架构能力不代表业务 JAR 内的本地组件也支持双架构。

本次 JDK8 / Alpine 兼容库镜像已完成 amd64 原生、arm64 QEMU 运行验证，并沿用 `20261024` 标签重新发布；`latest` 与 `8u511-b32-alpine3.24-20261024` 均指向 `sha256:beb274782161887ff2ef328789b2245a24a83e7f123dd2553d872fcdd4b6d030`。旧版 OpenSSL 测试中，CMS 项的固定测试证书已于 2016 年过期，该项单独记录为未通过；其余测试及最终镜像加载、运行时、信任库和图形检查通过。

## 图形与字体支持

三种系统变体安装 DejaVu、Noto CJK 字体、fontconfig、FreeType，以及 AWT 使用的 X11 运行库（X11、Xext、Xi、Xrender、Xtst），构建时刷新字体缓存并检查中文字体可发现。JDK 的安全版本及默认信任库处置保持不变。

`tests/GraphicsSmoke.java` 检查默认 SansSerif 的中英文字形、实际文字绘制、PNG/JPEG/GIF 编解码，以及 `libawt_xawt.so` 的动态依赖加载。测试须对每个 JDK、系统和架构分别执行：

```bash
javac -encoding UTF-8 -d /tmp tests/GraphicsSmoke.java
java -Djava.awt.headless=true -cp /tmp GraphicsSmoke
java -Djava.awt.headless=true -cp /tmp GraphicsSmoke --load-awt
```

验证码、图表和图片生成可使用无显示模式；AWT/Swing 桌面窗口仍需有效的 DISPLAY 和显示服务。安装图形运行库不代表容器自带桌面或显示服务器。字体包会增加镜像体积。

本次图形修复的 15 个多架构镜像、30 个平台组合均已完成构建及 Docker Hub 重拉验证，覆盖 JDK 8/11/17/21/25 与三种系统。amd64 原生执行，arm64 使用 QEMU。

本次图形修复沿用 `20261024` 标签。拉取后必须重建容器才能使用新内容；需要固定可复现输入时，记录已验收的镜像 digest。

## Capability Matrix

| 能力 | amd64 | arm64 | 说明 |
|---|---:|---:|---|
| JDK 8 | yes | yes | Oracle JDK，使用自有镜像站锁定包 |
| JDK 11 | yes | yes | Oracle JDK，使用自有镜像站锁定包 |
| JDK 17 | yes | yes | Oracle JDK，使用自有镜像站锁定包 |
| JDK 21 | yes | yes | Oracle JDK，使用自有镜像站锁定包 |
| JDK 25 | yes | yes | Oracle JDK，使用自有镜像站锁定包 |
| CentOS Stream 9 | yes | yes | `benyoo/centos:9-stream-20260615` |
| Rocky Linux 9 | yes | yes | `benyoo/rockylinux:9-20260615` |
| Alpine 3.24 | yes | yes | `benyoo/alpine:3.24.20260615` |

## Tags

| Tag | 基础镜像 | Java |
|---|---|---|
| `benyoo/jdk:<java>-centos9-stream` | `benyoo/centos:9-stream-20260615` | 8 / 11 / 17 / 21 / 25 |
| `benyoo/jdk:<full-java>-centos9-stream` | `benyoo/centos:9-stream-20260615` | 8u511 / 11.0.33.0.2 / 17.0.21.0.2 / 21.0.13.0.2 / 25.0.5.0.2 |
| `benyoo/jdk:<java>-rockylinux9` | `benyoo/rockylinux:9-20260615` | 8 / 11 / 17 / 21 / 25 |
| `benyoo/jdk:<full-java>-rockylinux9` | `benyoo/rockylinux:9-20260615` | 8u511 / 11.0.33.0.2 / 17.0.21.0.2 / 21.0.13.0.2 / 25.0.5.0.2 |
| `benyoo/jdk:<java>-alpine3.24` | `benyoo/alpine:3.24.20260615` | 8 / 11 / 17 / 21 / 25 |
| `benyoo/jdk:<full-java>-alpine3.24` | `benyoo/alpine:3.24.20260615` | 8u511 / 11.0.33.0.2 / 17.0.21.0.2 / 21.0.13.0.2 / 25.0.5.0.2 |
| `benyoo/jdk:<java>-centos9-stream-20261024` | `benyoo/centos:9-stream-20260615` | 8 / 11 / 17 / 21 / 25 |
| `benyoo/jdk:<full-java>-centos9-stream-20261024` | `benyoo/centos:9-stream-20260615` | 8u511 / 11.0.33.0.2 / 17.0.21.0.2 / 21.0.13.0.2 / 25.0.5.0.2 |
| `benyoo/jdk:<java>-rockylinux9-20261024` | `benyoo/rockylinux:9-20260615` | 8 / 11 / 17 / 21 / 25 |
| `benyoo/jdk:<full-java>-rockylinux9-20261024` | `benyoo/rockylinux:9-20260615` | 8u511 / 11.0.33.0.2 / 17.0.21.0.2 / 21.0.13.0.2 / 25.0.5.0.2 |
| `benyoo/jdk:<java>-alpine3.24-20261024` | `benyoo/alpine:3.24.20260615` | 8 / 11 / 17 / 21 / 25 |
| `benyoo/jdk:<full-java>-alpine3.24-20261024` | `benyoo/alpine:3.24.20260615` | 8u511 / 11.0.33.0.2 / 17.0.21.0.2 / 21.0.13.0.2 / 25.0.5.0.2 |

## Build

默认多架构构建目标是 `linux/amd64,linux/arm64`。

```bash
IMAGE="benyoo/jdk"

./scripts/generate-bake.sh docker-bake.generated.hcl
docker buildx bake -f docker-bake.generated.hcl --print
for JAVA_VERSION in 8 11 17 21 25; do
    docker buildx bake -f docker-bake.generated.hcl \
        "rockylinux9-jdk${JAVA_VERSION}" \
        "centos9-stream-jdk${JAVA_VERSION}" \
        "alpine3-24-jdk${JAVA_VERSION}" || exit 1
done
```

只构建一个版本：

```bash
IMAGE="benyoo/jdk"
JAVA_VERSION="21"
BASE_IMAGE="benyoo/rockylinux:9-20260615"

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --build-arg BASE_IMAGE="${BASE_IMAGE}" \
  --build-arg JAVA_VERSION="${JAVA_VERSION}" \
  -t "${IMAGE}:${JAVA_VERSION}-rockylinux9" \
  .
```

获得发布授权后，按 8 → 11 → 17 → 21 → 25 逐版发布。每一版远端 manifest 和必要运行验证通过后再继续下一版，失败即停止；不能用默认 group 一次并发推送全部版本。

```bash
IMAGE="benyoo/jdk"
JAVA_VERSION="8"

./scripts/generate-bake.sh docker-bake.generated.hcl
docker buildx bake -f docker-bake.generated.hcl --push \
    "rockylinux9-jdk${JAVA_VERSION}" \
    "centos9-stream-jdk${JAVA_VERSION}" \
    "alpine3-24-jdk${JAVA_VERSION}"
```

## Verify Download Resolver

不下载大包，检查锁定安装地址、镜像站候选地址和锁定版本：

```bash
JAVA_VERSION="21" TARGETARCH="amd64" ./scripts/install-jdk.sh --print-primary-url
JAVA_VERSION="21" TARGETARCH="amd64" ./scripts/install-jdk.sh --print-mirror-url
JAVA_VERSION="21" TARGETARCH="arm64" ./scripts/install-jdk.sh --print-mirror-url
JAVA_VERSION="21" TARGETARCH="amd64" ./scripts/install-jdk.sh --print-full-version
```

## 默认入口与 Tomcat 后续构建

`latest` 沿用原有 JDK 8 / Alpine 定位，现指向本次已验收的 `8u511-b32-alpine3.24-20261024` 双架构镜像。JDK 11、17、21、25 请使用各自的明确版本线标签。

旧 `latest` 的 JAVA_HOME 为 `/opt/jdk`；本项目当前镜像统一为 `/opt/java/oracle`，下游应读取 `JAVA_HOME`，避免硬编码旧目录。

需要 Tomcat 每次重建跟随对应 JDK 主版本的已发布补丁时，使用主版本移动别名，例如：

```dockerfile
ARG JDK_IMAGE=benyoo/jdk:8-alpine3.24
FROM ${JDK_IMAGE}
```

在指定构建节点执行时增加 `--pull`：

```bash
docker buildx build \
    --pull \
    --platform linux/amd64,linux/arm64 \
    --build-arg JDK_IMAGE=benyoo/jdk:8-alpine3.24 \
    .
```

版本线也可以替换为 `11`、`17`、`21`、`25`，系统后缀可使用 `rockylinux9`、`centos9-stream`、`alpine3.24`。仅替换为业务已兼容的版本线。

维护顺序为：更新并验收 JDK 安装包锁定清单 → 发布对应主版本别名 → Tomcat 构建解析该别名的远端 digest → 用该 digest 完成本次构建并记录实际 Java 版本 → 验收及发布 Tomcat。固定日期标签或固定 digest 需由流水线更新后才会跟随新补丁。`--pull` 获取仓库已有新镜像；上游 Java 发布新版本后仍须先完成 JDK 镜像维护。本次未配置后台自动更新，也未修改下游 Tomcat 项目。

生产重现可使用精确版本日期标签，或记录本次构建解析到的 digest。现有运行容器需使用重建后的 Tomcat 镜像并重建容器，才能使用新 JVM。

维护者：Manta <manta.ops.dstw@gmail.com>。

## Usage

镜像默认把 Oracle JDK 加入 `PATH`，可以直接运行 `java`、`javac` 或进入 shell：

```bash
docker run --rm benyoo/jdk:21-rockylinux9 java -version
docker run --rm benyoo/jdk:21-rockylinux9 javac -version
docker run -it --rm benyoo/jdk:21-rockylinux9 bash
```

作为业务基础镜像：

```dockerfile
FROM benyoo/jdk:21-rockylinux9

WORKDIR /app
COPY target/app.jar /app/app.jar

ENV JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75" \
    APP_JAR="/app/app.jar"

CMD []
```

运行业务 Jar：

```bash
docker run -d \
  --name java-app \
  --restart always \
  -p 8080:8080 \
  -e TIMEZONE="Asia/Shanghai" \
  -e JAVA_TOOL_OPTIONS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75" \
  -e JAVA_OPTS="-Dfile.encoding=UTF-8 -Duser.timezone=Asia/Shanghai" \
  -e APP_JAR="/app/app.jar" \
  -e APP_ARGS="--spring.config.additional-location=/config/" \
  -e LOG_CLEANUP_CRON="0 3 * * *" \
  -e LOG_CLEANUP_DIRS="/logs" \
  -e LOG_CLEANUP_RETENTION_DAYS="30" \
  -v "$PWD/app:/app" \
  -v "$PWD/config:/config:ro" \
  -v "$PWD/data:/data" \
  -v "$PWD/logs:/logs" \
  benyoo/jdk:21-rockylinux9
```

## Runtime Entrypoints

| 接入口 | 用途 |
|---|---|
| `TIMEZONE` | 推荐使用的时区入口；entrypoint 会自动导出为 `TZ` 以兼容 Linux/JVM 常规读取方式 |
| `TZ` | 标准 Linux 时区变量；仅在兼容第三方镜像或已有部署时需要显式设置 |
| `JAVA_TOOL_OPTIONS` | JVM 标准参数入口，推荐放容器内存、GC、编码等参数 |
| `JAVA_OPTS` | entrypoint 传给 `java` 的简单参数 |
| `JAVA_ARG_FILTER_ENABLED` | Java 参数兼容过滤开关，默认 `true`；会按 JDK 大版本过滤明显不兼容的模块/native-access 参数 |
| `APP_JAR` | 指定 `/app/app.jar` 这类业务 Jar |
| `APP_ARGS` | 传给业务 Jar 的简单启动参数 |
| `APP_MAIN_CLASS` | 使用 classpath + main class 启动 |
| `APP_CLASSPATH` | 默认 `/app/classes:/app/libs/*` |
| `APP_START_SCRIPT` | 指定自定义启动脚本，例如 `/app/start.sh` |
| `LOG_CLEANUP_CRON` | 日志清理计划任务，例如 `0 3 * * *`；支持多行或用 `;` 分隔多个计划 |
| `CRON_TASKS` | 自定义 root crontab 任务，支持多行，例如 `*/10 * * * * /app/scripts/check.sh` |
| `CUSTOM_CRON_TASKS` | `CRON_TASKS` 的兼容别名 |
| `LOG_CLEANUP_DIRS` | 要清理的日志目录，多个目录用空格分隔，默认 `/logs` |
| `LOG_CLEANUP_RETENTION_DAYS` | 删除超过多少天的历史日志，默认 `30` |
| `LOG_CLEANUP_PATTERNS` | 清理文件名匹配，默认 `*.20??-??-??.log *.log.* *.log-*.gz *.out.* *.err.* *.gz` |
| `LOG_CLEANUP_MAX_DEPTH` | 查找目录深度，默认 `1` |
| `LOG_CLEANUP_DRY_RUN` | `true` 时只打印将删除的文件，不实际删除 |
| `/config` | 配置挂载目录 |
| `/data` | 业务数据挂载目录 |
| `/logs` | 日志挂载目录 |

## Log Cleanup

镜像内置的是“历史日志清理”，不强行切割业务正在写入的当前日志文件。日志切割建议继续交给业务框架的 logback/log4j2；镜像负责按保留天数清理已经滚动出来的历史文件。

```yaml
environment:
  LOG_CLEANUP_CRON: "0 3 * * *"
  LOG_CLEANUP_DIRS: "/data/java-app/logs"
  LOG_CLEANUP_RETENTION_DAYS: "30"
```

多个日志清理计划可以用多行或分号：

```yaml
environment:
  LOG_CLEANUP_CRON: |
    0 3 * * *
    30 15 * * 0
  LOG_CLEANUP_DIRS: "/data/java-app/logs"
  LOG_CLEANUP_RETENTION_DAYS: "30"
```

自定义计划任务使用标准 root crontab 语法：

```yaml
environment:
  CRON_TASKS: |
    */10 * * * * /app/scripts/check.sh >> /logs/check.log 2>&1
    0 4 * * * find /tmp -type f -mtime +3 -delete
```

如果要先观察会删除哪些文件：

```yaml
environment:
  LOG_CLEANUP_CRON: "0 3 * * *"
  LOG_CLEANUP_DIRS: "/data/java-app/logs"
  LOG_CLEANUP_RETENTION_DAYS: "30"
  LOG_CLEANUP_DRY_RUN: "true"
```

## Troubleshooting

### UnsupportedClassVersionError

如果业务日志出现类似下面的错误：

```text
java.lang.UnsupportedClassVersionError: ... has been compiled by a more recent version of the Java Runtime (class file version 61.0), this version of the Java Runtime only recognizes class file versions up to 52.0
```

这表示业务 Jar 是用更高版本 Java 编译的，当前运行时 JDK 太低。`class file version 61.0` 对应 Java 17，`52.0` 对应 Java 8，所以这类 Jar 不能用 JDK 8 镜像运行，需要切换到 JDK 17、21 或 25 镜像。

示例：

```yaml
services:
  java-app:
    image: benyoo/jdk:17-rockylinux9
```

## Docker Compose

```bash
docker compose up -d
docker compose logs -f java-app
docker compose --profile debug run --rm java-shell
```

## Notes

- 禁止提交真实业务部署配置、内部节点或业务目录信息；`examples/` 已从版本控制和构建上下文排除，文档仅使用通用示例。
- 文档命令默认在 root 环境执行，不加 `sudo`。
- 构建时默认保留完整 JDK，不删除 `javac`、`jcmd`、`jmap`、`include` 或 `src.zip`。
- Alpine 镜像使用 Oracle JDK 的 glibc 二进制包，镜像内会安装 `gcompat`、`libc6-compat`、`libstdc++` 并设置 JDK 动态库路径。
- `mirrors.dtops.co` 是本次安全重建的安装包来源；发现候选时匹配 Oracle JDK Linux tarball 文件名，实际安装只接受锁定清单中的包。
- 如果多架构中某个 JDK 上游或镜像站缺少 arm64 包，构建会失败，不会静默降级为 amd64。
