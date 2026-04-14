# XT-Bot 本地部署说明

> 目标：仅本地运行，运行数据不存入 GitHub 代码仓库。

## 1) 数据落盘策略

- 默认数据根目录：`~/.xt-bot-data`
- 可通过环境变量覆盖：`LOCAL_DATA_ROOT=/your/path`
- `sh/local-run.sh` 会自动把以下目录软链接到 `LOCAL_DATA_ROOT`：
  - `Python/dataBase`
  - `Python/output`
  - `Python/downloads`
  - `Python/logs`
  - `TypeScript/data`
  - `TypeScript/tweets`
  - `TypeScript/resp`
  - `TypeScript/logs`
  - `Artifact`

## 2) 首次安装

```bash
# 安装 Bun 依赖
cd TypeScript
bun install

# 安装 Python 依赖
cd ../Python
pip install -r requirements.txt
```

## 3) 环境变量

在项目根目录创建 `.env`（`local-run.sh` 会自动加载）：

```env
AUTH_TOKEN=your_twitter_auth_token
SCREEN_NAME=your_twitter_screen_name
BOT_TOKEN=your_telegram_bot_token
CHAT_ID=your_telegram_chat_id
LARK_KEY=your_lark_key_optional
LOCAL_DATA_ROOT=/absolute/path/to/xt-bot-data
```

## 4) 运行方式

```bash
# 自动流程（推荐）
./sh/local-run.sh auto

# 初始化流程
./sh/local-run.sh init
```

## 5) 定时执行（Linux cron 示例）

```cron
*/30 * * * * cd /path/to/XT-Bot && /bin/bash ./sh/local-run.sh auto >> /path/to/xt-bot-cron.log 2>&1
```

## 6) 手动备份 / 恢复

```bash
# 备份（项目目录 -> 本地数据目录）
python Python/utils/sync_data.py push --data-root "$LOCAL_DATA_ROOT"

# 恢复（本地数据目录 -> 项目目录）
python Python/utils/sync_data.py pull --data-root "$LOCAL_DATA_ROOT"
```
