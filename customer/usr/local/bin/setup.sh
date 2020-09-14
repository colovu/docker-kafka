#!/bin/bash
# Ver: 1.0 by Endial Fang (endial@126.com)
# 
# 应用环境及依赖文件设置脚本

# 设置 shell 执行参数，可使用'-'(打开）'+'（关闭）控制。常用：
# 	-e: 命令执行错误则报错; -u: 变量未定义则报错; -x: 打印实际待执行的命令行; -o pipefail: 设置管道中命令遇到失败则报错
set -eu
set -o pipefail

. /usr/local/bin/appcommon.sh			# 应用专用函数库

eval "$(app_env)"
LOG_I "** Processing setup.sh **"

APP_DIRS="${APP_CONF_DIR:-} ${APP_DATA_DIR:-} ${APP_LOG_DIR:-} ${APP_CERT_DIR:-} ${APP_DATA_LOG_DIR:-}"
for dir in ${APP_DIRS}; do
	ensure_dir_exists ${dir}
done

app_verify_minimum_env

# 检测指定文件是否在配置文件存储目录存在，如果不存在则拷贝（新挂载数据卷、手动删除都会导致不存在）
LOG_I "Check config files in: ${APP_CONF_DIR}"
if [[ ! -z "$(ls -A "${APP_DEF_DIR}")" ]]; then
	ensure_config_file_exist "${APP_DEF_DIR}" $(ls -A "${APP_DEF_DIR}")
fi

for dir in ${APP_DIRS}; do
	configure_permissions_ownership "$dir" -u "${APP_USER}" -g "${APP_USER}"
done

# 解决使用gosu后，nginx: [emerg] open() "/dev/stdout" failed (13: Permission denied)
LOG_D "Change permissions of stdout/stderr to 0622"
chmod 0622 /dev/stdout /dev/stderr

LOG_I "** Processing setup.sh finished! **"
