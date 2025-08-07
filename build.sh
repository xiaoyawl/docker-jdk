#!/bin/bash

# JDK 多版本构建脚本
# 使用方法: ./build.sh [JDK_VERSION] [IMAGE_TAG]

# 默认参数
DEFAULT_JDK_VERSION="21.0.7"
DEFAULT_IMAGE_TAG="benyoo/jdk"
BASE_IMAGE_VERSION="ubuntu24.04-20250807"

# 获取参数
JDK_VERSION=${1:-$DEFAULT_JDK_VERSION}
IMAGE_TAG=${2:-$DEFAULT_IMAGE_TAG}

# 支持的JDK版本列表
SUPPORTED_VERSIONS=("19" "20" "21" "22" "23" "24")

# 检查JDK版本是否支持
JDK_MAJOR=$(echo $JDK_VERSION | cut -d. -f1)
SUPPORTED=false

for version in "${SUPPORTED_VERSIONS[@]}"; do
    if [ "$version" = "$JDK_MAJOR" ]; then
        SUPPORTED=true
        break
    fi
done

if [ "$SUPPORTED" = false ]; then
    echo "错误: 不支持的JDK版本 $JDK_VERSION"
    echo "支持的版本: ${SUPPORTED_VERSIONS[*]}"
    exit 1
fi

# 构建完整的镜像标签
FULL_IMAGE_TAG="$IMAGE_TAG:$JDK_VERSION-$BASE_IMAGE_VERSION"
MAJOR_VERSION_TAG="$IMAGE_TAG:$JDK_MAJOR-$BASE_IMAGE_VERSION"

echo "开始构建JDK $JDK_VERSION 镜像..."
echo "镜像标签: $FULL_IMAGE_TAG"

# 构建Docker镜像
docker build \
    --build-arg JDK_VERSION=$JDK_VERSION \
    -t "$FULL_IMAGE_TAG" \
    -t "$MAJOR_VERSION_TAG" \
    .

if [ $? -eq 0 ]; then
    echo "✅ 构建成功!"
    echo "镜像标签:"
    echo "  - $FULL_IMAGE_TAG"
    echo "  - $MAJOR_VERSION_TAG"
    echo ""
    echo "运行测试:"
    echo "  docker run --rm $FULL_IMAGE_TAG"
else
    echo "❌ 构建失败!"
    exit 1
fi
