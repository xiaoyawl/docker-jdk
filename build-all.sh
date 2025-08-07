#!/bin/bash

# 批量构建所有支持的JDK版本
# 使用方法: ./build-all.sh [IMAGE_TAG]

# 默认镜像标签
DEFAULT_IMAGE_TAG="benyoo/jdk"
IMAGE_TAG=${1:-$DEFAULT_IMAGE_TAG}

# 支持的JDK版本列表
VERSIONS=("19.0.2" "20.0.2" "21.0.7" "22.0.1" "23.0.1" "24.0.1")

echo "开始批量构建所有JDK版本..."
echo "镜像标签前缀: $IMAGE_TAG"
echo "支持的版本: ${VERSIONS[*]}"
echo ""

# 记录构建结果
SUCCESS_COUNT=0
FAILED_VERSIONS=()

for version in "${VERSIONS[@]}"; do
    echo "=========================================="
    echo "构建JDK $version..."
    echo "=========================================="
    
    if ./build.sh $version $IMAGE_TAG; then
        echo "✅ JDK $version 构建成功"
        ((SUCCESS_COUNT++))
    else
        echo "❌ JDK $version 构建失败"
        FAILED_VERSIONS+=($version)
    fi
    
    echo ""
done

# 输出构建总结
echo "=========================================="
echo "构建完成总结"
echo "=========================================="
echo "成功构建: $SUCCESS_COUNT/${#VERSIONS[@]} 个版本"

if [ ${#FAILED_VERSIONS[@]} -gt 0 ]; then
    echo "失败的版本: ${FAILED_VERSIONS[*]}"
    exit 1
else
    echo "🎉 所有版本构建成功!"
    echo ""
    echo "生成的镜像标签:"
    for version in "${VERSIONS[@]}"; do
        major_version=$(echo $version | cut -d. -f1)
        echo "  - $IMAGE_TAG:$version-ubuntu24.04-20250807"
        echo "  - $IMAGE_TAG:$major_version-ubuntu24.04-20250807"
    done
fi
