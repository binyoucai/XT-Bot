#!/usr/bin/env bash
set -euo pipefail

# 本地运行入口（不依赖 XT-Data 仓库）
# 用法：
#   ./sh/local-run.sh auto   # 主页时间线模式
#   ./sh/local-run.sh init   # 指定用户初始化模式

MODE="${1:-auto}"
ROOT_DIR=$(cd "$(dirname "$0")/.."; pwd)
LOCAL_DATA_ROOT="${LOCAL_DATA_ROOT:-$HOME/.xt-bot-data}"

cd "$ROOT_DIR"

# 自动加载 .env（仅导出简单 KEY=VALUE）
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

ensure_link() {
  local link_path="$1"
  local target_path="$2"

  mkdir -p "$(dirname "$target_path")"
  mkdir -p "$target_path"

  if [[ -L "$link_path" ]]; then
    return 0
  fi

  if [[ -d "$link_path" ]]; then
    # 将历史数据迁移到本地数据目录
    cp -a "$link_path"/. "$target_path"/ 2>/dev/null || true
    rm -rf "$link_path"
  fi

  mkdir -p "$(dirname "$link_path")"
  ln -s "$target_path" "$link_path"
}

prepare_runtime_layout() {
  ensure_link "$ROOT_DIR/Python/dataBase" "$LOCAL_DATA_ROOT/Python/dataBase"
  ensure_link "$ROOT_DIR/Python/output" "$LOCAL_DATA_ROOT/Python/output"
  ensure_link "$ROOT_DIR/Python/downloads" "$LOCAL_DATA_ROOT/Python/downloads"
  ensure_link "$ROOT_DIR/Python/logs" "$LOCAL_DATA_ROOT/Python/logs"

  ensure_link "$ROOT_DIR/TypeScript/data" "$LOCAL_DATA_ROOT/TypeScript/data"
  ensure_link "$ROOT_DIR/TypeScript/tweets" "$LOCAL_DATA_ROOT/TypeScript/tweets"
  ensure_link "$ROOT_DIR/TypeScript/resp" "$LOCAL_DATA_ROOT/TypeScript/resp"
  ensure_link "$ROOT_DIR/TypeScript/logs" "$LOCAL_DATA_ROOT/TypeScript/logs"

  ensure_link "$ROOT_DIR/Artifact" "$LOCAL_DATA_ROOT/Artifact"
}

prepare_runtime_layout

echo "📦 LOCAL_DATA_ROOT=$LOCAL_DATA_ROOT"

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
    echo "[1/2] 获取指定用户推文"
    (cd TypeScript/scripts && bun run fetch-tweets-media.ts)

    echo "[2/2] 处理初始化推文"
    (cd Python/src && python INI-XT-Bot.py)
    ;;

  *)
    echo "不支持的模式: $MODE"
    echo "可选模式: auto | init"
    exit 1
    ;;
esac

echo "✅ 本地任务执行完成"
