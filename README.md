# 多版本JDK Docker镜像

基于Ubuntu 24.04的精简JDK Docker镜像，支持JDK 19、20、21、22、23、24版本。

## 支持的JDK版本

- JDK 19 (LTS)
- JDK 20 
- JDK 21 (LTS)
- JDK 22
- JDK 23
- JDK 24

## 快速开始

### 使用构建脚本（推荐）

```bash
# 构建JDK 21（默认版本）
./build.sh

# 构建指定版本的JDK
./build.sh 19.0.2
./build.sh 20.0.2
./build.sh 22.0.1
./build.sh 23.0.1
./build.sh 24.0.1

# 指定自定义镜像标签
./build.sh 21.0.7 mycompany/jdk

# 批量构建所有版本
./build-all.sh

# 批量构建并指定镜像标签
./build-all.sh mycompany/jdk
```

### 直接使用Docker命令

```bash
# 构建JDK 21
docker build --build-arg JDK_VERSION=21.0.7 -t benyoo/jdk:21.0.7-ubuntu24.04-20250807 .

# 构建JDK 19
docker build --build-arg JDK_VERSION=19.0.2 -t benyoo/jdk:19.0.2-ubuntu24.04-20250807 .

# 构建JDK 24
docker build --build-arg JDK_VERSION=24.0.1 -t benyoo/jdk:24.0.1-ubuntu24.04-20250807 .
```

## 使用方法

### 运行容器

```bash
# 运行JDK 21容器
docker run --rm benyoo/jdk:21.0.7-ubuntu24.04-20250807 java -version

# 运行JDK 19容器
docker run --rm benyoo/jdk:19.0.2-ubuntu24.04-20250807 java -version

# 进入容器交互模式
docker run -it benyoo/jdk:21.0.7-ubuntu24.04-20250807 bash
```

### 在Dockerfile中使用

```dockerfile
# 使用JDK 21
FROM benyoo/jdk:21-ubuntu24.04-20250807
COPY . /app
WORKDIR /app
CMD ["java", "-jar", "app.jar"]

# 使用JDK 19
FROM benyoo/jdk:19-ubuntu24.04-20250807
COPY . /app
WORKDIR /app
CMD ["java", "-jar", "app.jar"]
```

## 镜像特性

- **精简体积**: 基于Ubuntu 24.04精简镜像，移除不必要的文件
- **多版本支持**: 支持JDK 19-24的所有版本
- **快速构建**: 使用国内镜像源加速下载
- **标准化**: 统一的JAVA_HOME和PATH配置

## 环境变量

- `JAVA_HOME`: `/opt/java`
- `PATH`: 包含Java可执行文件路径

## 构建参数

- `JDK_VERSION`: JDK版本号（如：21.0.7、19.0.2等）

## 示例

### 构建所有支持的JDK版本

```bash
# 使用批量构建脚本（推荐）
./build-all.sh

# 或者手动构建
#!/bin/bash
versions=("19.0.2" "20.0.2" "21.0.7" "22.0.1" "23.0.1" "24.0.1")

for version in "${versions[@]}"; do
    echo "构建JDK $version..."
    ./build.sh $version
done
```

### 测试所有版本

```bash
#!/bin/bash
versions=("19" "20" "21" "22" "23" "24")

for version in "${versions[@]}"; do
    echo "测试JDK $version..."
    docker run --rm benyoo/jdk:$version-ubuntu24.04-20250807 java -version
done
```

## 注意事项

1. 确保构建脚本有执行权限：`chmod +x build.sh`
2. 首次构建可能需要较长时间下载JDK安装包
3. 建议使用国内镜像源以提高下载速度
4. 镜像会自动清理临时文件以减小体积
