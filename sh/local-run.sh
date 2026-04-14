#!/usr/bin/env bash
set -euo pipefail

# 本地运行入口（不依赖 XT-Data 仓库）
# 用法：
#   ./sh/local-run.sh auto   # 主页时间线模式
#   ./sh/local-run.sh init   # 指定用户初始化模式

MODE="${1:-auto}"
ROOT_DIR=$(cd "$(dirname "$0")/.."; pwd)

cd "$ROOT_DIR"

mkdir -p Artifact
mkdir -p Python/{dataBase,downloads,logs,output}
mkdir -p TypeScript/{data,logs,resp,tweets}

case "$MODE" in
  auto)
    echo "[1/4] 获取关注列表"
    (cd TypeScript/scripts && bun run fetch-following.ts)

    echo "[2/4] 获取主页时间线"
    (cd TypeScript/scripts && bun run fetch-home-latest-timeline.ts)

    echo "[3/4] 处理推文数据"
    (cd Python/src && python X-Bot.py)

    echo "[4/4] 推送 Telegram"
    (cd Python/src && python T-Bot.py)
    ;;

  init)
    echo "[1/3] 获取指定用户推文"
    (cd TypeScript/scripts && bun run fetch-tweets-media.ts)

    echo "[2/3] 处理初始化推文"
    (cd Python/src && python INI-XT-Bot.py)
    ;;

  *)
    echo "不支持的模式: $MODE"
    echo "可选模式: auto | init"
    exit 1
    ;;
esac

echo "✅ 本地任务执行完成"
