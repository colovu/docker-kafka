#!/bin/bash
# Ver: 1.2 by Endial Fang (endial@126.com)
# 
# 容器入口脚本

# 设置 shell 执行参数，可使用'-'(打开）'+'（关闭）控制。常用：
# 	-e: 命令执行错误则报错(errexit); -u: 变量未定义则报错(nounset); -x: 打印实际待执行的命令行; -o pipefail: 设置管道中命令遇到失败则报错
set -eu
set -o pipefail

. /usr/local/scripts/libcommon.sh		# 加载通用函数库

. /usr/local/bin/common.sh              # 加载应用函数库

LOG_I "** Processing entry.sh **"

kafka_create_alias_environment_variables

if [[ -n "${KAFKA_BROKER_ID_COMMAND:-}" ]]; then
    KAFKA_CFG_BROKER_ID="$(eval "${KAFKA_BROKER_ID_COMMAND:-}")"
    LOG_I "Modify broker ID by KAFKA_BROKER_ID_COMMAND to ${KAFKA_CFG_BROKER_ID}"
    export KAFKA_CFG_BROKER_ID
fi

if [[ "$*" = "/usr/local/bin/run.sh" ]]; then
	print_image_welcome

    LOG_I "** Starting ${APP_NAME} setup **"
    /usr/local/bin/setup.sh
    /usr/local/bin/init.sh
    LOG_I "** ${APP_NAME} setup finished! **"
fi

# 检测是否仅打印帮助信息
[ "${1:0:1}" = '-' ] && set -- "${APP_EXEC:-/bin/bash}" "$@"
print_command_help "$@"

LOG_I "Start container with command: $@"
exec "$@"
