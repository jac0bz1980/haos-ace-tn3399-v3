#!/bin/bash

# 脚本使用格式：haos_update 指定版本参数，例如：haos_update 18.2
# 功能：删除编译构建产物，更新拉取指定版本的haos源码

set -e  # 遇到错误立即退出

# 检查参数
if [ -z "$1" ]; then
    echo "错误: 请指定版本号"
    echo "用法: $0 <版本号>"
    echo "示例: $0 18.2"
    exit 1
fi

VERSION="$1"
HAOS_DIR="operating-system"

echo "=========================================="
echo "开始更新 HAOS 到版本: ${VERSION}"
echo "=========================================="

# 检查目录是否存在
if [ ! -d "${HAOS_DIR}" ]; then
    echo "错误: ${HAOS_DIR} 目录不存在"
    exit 1
fi

cd "${HAOS_DIR}"

# 1. 清理构建产物（忽略失败，因为可能还未构建）
echo "步骤 1: 清理构建产物..."
make distclean 2>/dev/null || echo "  警告: make distclean 失败，跳过（可能尚未构建）"

# 2. 获取远程更新
echo "步骤 2: 获取远程代码..."
git fetch --all

# 3. 检查版本是否存在
echo "步骤 3: 检查版本 ${VERSION} 是否存在..."
if ! git rev-parse "refs/tags/${VERSION}" >/dev/null 2>&1; then
    echo "错误: 版本 ${VERSION} 不存在"
    echo "可用的标签列表："
    git tag | head -20
    exit 1
fi

# 4. 切换到指定版本
echo "步骤 4: 切换到版本 ${VERSION}..."
git checkout "tags/${VERSION}"

# 5. 更新子模块
echo "步骤 5: 更新子模块..."
git submodule update --init --recursive

# 返回主目录
cd ..

# 6. 提交更新
echo "步骤 6: 提交子模块更新..."
git add "${HAOS_DIR}"
git commit -m "chore: update HAOS submodule to ${VERSION}"

echo "=========================================="
echo "更新完成! HAOS 已切换到版本 ${VERSION}"
echo "=========================================="

# 可选：显示当前状态
git log -1 --oneline

# 添加升级认证证书
cp ~/cert_rauc/*.pem "${HAOS_DIR}"