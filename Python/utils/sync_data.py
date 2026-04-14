import sys
import os
import shutil
import argparse
from pathlib import Path

# 将项目根目录添加到模块搜索路径
_project_root = Path(__file__).resolve().parent.parent
sys.path.append(str(_project_root))
from utils.log_utils import LogUtils

logger = LogUtils().get_logger()
logger.info("🔄 Sync_Data 初始化完成")


def sync_dirs(source, dest):
    """同步目录的核心函数"""
    source = os.path.normpath(source)
    dest = os.path.normpath(dest)

    if not os.path.exists(source):
        raise FileNotFoundError(f"源目录不存在：'{source}'")

    source_files = set()
    for root, dirs, files in os.walk(source):
        rel_path = os.path.relpath(root, source)
        for file in files:
            file_rel_path = os.path.join(rel_path, file) if rel_path != '.' else file
            source_files.add(file_rel_path)

    for file_rel in source_files:
        src_path = os.path.join(source, file_rel)
        dest_path = os.path.join(dest, file_rel)
        dest_dir = os.path.dirname(dest_path)

        os.makedirs(dest_dir, exist_ok=True)

        if os.path.exists(dest_path):
            src_stat = os.stat(src_path)
            dest_stat = os.stat(dest_path)
            if src_stat.st_mtime <= dest_stat.st_mtime and src_stat.st_size == dest_stat.st_size:
                continue

        shutil.copy2(src_path, dest_path)
        logger.debug(f"📥 已复制：{src_path} -> {dest_path}")

    dest_files = set()
    for root, dirs, files in os.walk(dest):
        rel_path = os.path.relpath(root, dest)
        for file in files:
            file_rel_path = os.path.join(rel_path, file) if rel_path != '.' else file
            dest_files.add(file_rel_path)

    for file_rel in (dest_files - source_files):
        file_path = os.path.join(dest, file_rel)
        try:
            os.remove(file_path)
            logger.debug(f"🗑️ 已删除：{file_path}")
        except Exception as e:
            logger.error(f"⚠ 删除文件失败：{file_path} - {str(e)}")

    for root, dirs, files in os.walk(dest, topdown=False):
        if not os.listdir(root):
            try:
                os.rmdir(root)
                logger.debug(f"📁 已删除空目录：{root}")
            except Exception as e:
                logger.error(f"⚠ 删除目录失败：{root} - {str(e)}")


def _build_task_groups(local_data_root: str):
    """构建本地数据同步任务组。

    pull: 从本地运行数据目录同步到项目目录（用于恢复运行现场）
    push: 从项目目录同步回本地运行数据目录（用于备份）
    """
    local_data_root = os.path.normpath(local_data_root)

    return {
        "pull": [
            {"source": f"{local_data_root}/config", "dest": "config"},
            {"source": f"{local_data_root}/Python/dataBase", "dest": "Python/dataBase"},
            {"source": f"{local_data_root}/Python/output", "dest": "Python/output"},
            {"source": f"{local_data_root}/TypeScript/data", "dest": "TypeScript/data"},
            {"source": f"{local_data_root}/TypeScript/tweets", "dest": "TypeScript/tweets"},
        ],
        "push": [
            {"dest": f"{local_data_root}/config", "source": "config"},
            {"dest": f"{local_data_root}/Python/dataBase", "source": "Python/dataBase"},
            {"dest": f"{local_data_root}/Python/output", "source": "Python/output"},
            {"dest": f"{local_data_root}/TypeScript/data", "source": "TypeScript/data"},
            {"dest": f"{local_data_root}/TypeScript/tweets", "source": "TypeScript/tweets"},
        ]
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'task_group',
        nargs='?',
        default='pull',
        choices=['pull', 'push'],
        help="选择同步任务组(pull/push)"
    )
    parser.add_argument(
        '--data-root',
        default=os.getenv('LOCAL_DATA_ROOT', '../XT-Bot-LocalData'),
        help='本地运行数据根目录（默认：环境变量 LOCAL_DATA_ROOT 或 ../XT-Bot-LocalData）'
    )

    args = parser.parse_args()
    task_groups = _build_task_groups(args.data_root)

    logger.info(f"🔄 正在执行任务组 [{args.task_group}] | data_root={os.path.normpath(args.data_root)}")
    for task in task_groups[args.task_group]:
        src = task["source"]
        dst = task["dest"]
        logger.debug(f"→ 同步任务: {src} => {dst}")
        try:
            sync_dirs(src, dst)
        except Exception as e:
            logger.error(f"⚠ 同步失败：{src} => {dst} - {str(e)}")
            continue


if __name__ == "__main__":
    main()
