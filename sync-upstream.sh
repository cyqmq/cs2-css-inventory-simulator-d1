#!/usr/bin/env bash
# 本地同步上游 ianlucas/cs2-css-inventory-simulator 到我们的 fork 定制版。
#
# 保护机制:
#   ConVars.cs 是我们的定制文件(URL/invsim_apikey 指向 D1 worker)，
#   合并时始终保留本地版本，避免上游合入覆盖我们的后台配置。
#
# 用法:
#   ./sync-upstream.sh            # 同步并入 + 构建验证
#   ./sync-upstream.sh --build    # 同步并入 + 构建验证
#   ./sync-upstream.sh --no-build # 只同步并入，不构建

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

UPSTREAM_URL="https://github.com/ianlucas/cs2-css-inventory-simulator.git"
UPSTREAM_REMOTE="upstream"
CUSTOM_FILE="source/InventorySimulator/Services/ConVars.cs"

BUILD=1
for arg in "$@"; do
  case "$arg" in
    --no-build) BUILD=0 ;;
    --build) BUILD=1 ;;
  esac
done

# 1. 确保 upstream remote 存在
if ! git remote | grep -qx "$UPSTREAM_REMOTE"; then
  echo ">> 添加 upstream remote"
  git remote add "$UPSTREAM_REMOTE" "$UPSTREAM_URL"
fi

# 2. 配置 merge driver（保持 ConVars.cs 为我们的版本）
if ! git config --get merge.keepMine.driver >/dev/null 2>&1; then
  echo ">> 配置 ConVars.cs merge 保护 (keepMine)"
  git config merge.keepMine.driver 'cp %O %A'
fi

# 3. 准备工作区（防止本地未提交改动干扰）
if ! git diff --quiet; then
  echo "!! 存在未提交改动，先提交或暂存后再同步。"
  echo "   当前未提交改动："
  git status --short
  exit 1
fi

# 4. 拉取上游
echo ">> 拉取上游 $UPSTREAM_URL"
git fetch "$UPSTREAM_REMOTE" --tags --prune

# 5. 合并（ConVars.cs 由 .gitattributes 的 keepMine driver 保护）
echo ">> 合并 upstream/main"
git merge "$UPSTREAM_REMOTE/main"

# 6. 构建验证
if [ "$BUILD" -eq 1 ]; then
  echo ">> 构建验证"
  export DOTNET_ROOT="$HOME/.dotnet"
  export PATH="$DOTNET_ROOT:$PATH"
  dotnet build
fi

echo ""
echo ">> 同步完成。改动概览："
git log --oneline -3
echo ""
echo ">> 确认 ConVars.cs 仍是定制版本 (未回退到官方 inventory.cstrike.app):"
if grep -n "inventory.cstrike.app" "$CUSTOM_FILE"; then
  echo "!! 警告: ConVars.cs 已回退到官方 URL，同步请检查"
else
  echo "OK: ConVars.cs 保持定制（未使用官方 URL）"
fi
