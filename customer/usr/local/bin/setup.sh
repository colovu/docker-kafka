#!/bin/bash
# Ver: 1.2 by Endial Fang (endial@126.com)
# 
# 应用环境及依赖文件设置脚本

# 设置 shell 执行参数，可使用'-'(打开）'+'（关闭）控制。常用：
# 	-e: 命令执行错误则报错(errexit); -u: 变量未定义则报错(nounset); -x: 打印实际待执行的命令行; -o pipefail: 设置管道中命令遇到失败则报错
set -eu
set -o pipefail

. /usr/local/scripts/libcommon.sh		# 加载通用函数库
. /usr/local/scripts/libfs.sh			# 加载文件操作函数库
. /usr/local/scripts/libos.sh			# 加载系统管理函数库

. /usr/local/bin/environment.sh 		# 设置环境变量

LOG_I "** Processing setup.sh **"

APP_DIRS="${APP_CONF_DIR:-} ${APP_DATA_DIR:-} ${APP_LOG_DIR:-} ${APP_CERT_DIR:-} ${APP_DATA_LOG_DIR:-}"

LOG_I "Ensure directory exists: ${APP_DIRS}"
for dir in ${APP_DIRS}; do
	ensure_dir_exists ${dir}
done

# 检测指定文件是否在配置文件存储目录存在，如果不存在则拷贝（新挂载数据卷、手动删除都会导致不存在）
LOG_I "Check config files in: ${APP_CONF_DIR}"
if [[ ! -z "$(ls -A "${APP_DEF_DIR}")" ]]; then
	ensure_config_file_exist "${APP_DEF_DIR}" $(ls -A "${APP_DEF_DIR}")
fi

is_root && ensure_user_exists "$APP_DAEMON_USER" -g "$APP_DAEMON_GROUP"

LOG_I "** Processing setup.sh finished! **"
