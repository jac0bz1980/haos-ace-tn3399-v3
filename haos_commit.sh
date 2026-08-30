#!/bin/bash

## 用于编译成功后提交本地仓库源码到远端仓库
## 使用格式：haos_commit 18.2，18.2是版本号

set -e

# 颜色定义（用于美化输出）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 显示用法
usage() {
    cat << EOF
用法: $0 <版本号> [选项]

参数说明:
  <版本号>        HAOS 版本号，如 18.2
  [选项]          -f  强制提交（允许有未暂存的修改）
                   -p  提交后推送到远程仓库

示例:
  $0 18.2              # 提交到本地仓库
  $0 18.2 -p           # 提交并推送到远程
  $0 18.2 -f           # 强制提交（忽略警告）

EOF
}

# 检查参数
if [ -z "$1" ]; then
    echo -e "${RED}错误: 请指定版本号${NC}"
    usage
    exit 1
fi

VERSION="$1"
shift  # 移除版本号参数

# 解析选项
FORCE=false
PUSH=false

while [ $# -gt 0 ]; do
    case "$1" in
        -f|--force)
            FORCE=true
            shift
            ;;
        -p|--push)
            PUSH=true
            shift
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "提交 HAOS 版本: ${VERSION}"
echo "=========================================="

# 1. 检查工作区状态
echo ""
echo "[1/5] 检查工作区状态..."
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo -e "${YELLOW}警告: 工作区有未提交的修改${NC}"
    echo ""
    git status --short
    echo ""
    
    if [ "$FORCE" = false ]; then
        read -p "是否继续提交? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}提交已取消${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}强制提交模式已启用，继续...${NC}"
    fi
else
    echo -e "${GREEN}工作区干净${NC}"
fi

# 2. 确保在正确的分支上
echo ""
echo "[2/5] 检查当前分支..."
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "当前分支: ${BRANCH}"

# 3. 添加所有修改
echo ""
echo "[3/5] 暂存所有修改..."
git add -A

# 4. 检查是否有内容可以提交
if git diff --cached --quiet; then
    echo -e "${YELLOW}没有需要提交的内容${NC}"
    echo "如果只需要更新版本号，请先修改文件"
    exit 0
fi

# 5. 提交
echo ""
echo "[4/5] 提交到本地仓库..."
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
git commit -m "chore: update HAOS to ${VERSION} (${TIMESTAMP})

- 更新 HAOS 版本到 ${VERSION}
- 包含完整的构建输出
- 提交时间: ${TIMESTAMP}"

COMMIT_HASH=$(git rev-parse --short HEAD)
echo -e "${GREEN}提交成功: ${COMMIT_HASH}${NC}"

# 6. 推送到远程（如果指定）
echo ""
echo "[5/5] 推送到远程仓库..."
if [ "$PUSH" = true ]; then
    echo "推送到远程仓库..."
    git push origin "${BRANCH}"
    echo -e "${GREEN}推送成功!${NC}"
else
    echo -e "${YELLOW}跳过推送 (如需推送请加 -p 参数)${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}提交完成!${NC}"
echo "版本: ${VERSION}"
echo "分支: ${BRANCH}"
echo "提交: ${COMMIT_HASH}"
echo "=========================================="

# 显示最近提交
echo ""
git log -1 --oneline --decorate