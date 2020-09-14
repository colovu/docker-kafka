#!/bin/bash
# Ver: 1.0 by Endial Fang (endial@126.com)
# 
# 容器入口脚本

# 设置 shell 执行参数，可使用'-'(打开）'+'（关闭）控制。常用：
# 	-e: 命令执行错误则报错; -u: 变量未定义则报错; -x: 打印实际待执行的命令行; -o pipefail: 设置管道中命令遇到失败则报错
set -eu
set -o pipefail

. /usr/local/bin/appcommon.sh			# 应用专用函数库

eval "$(app_env)"
LOG_I "** Processing entry.sh **"

kafka_create_alias_environment_variables

if [[ -n "${KAFKA_BROKER_ID_COMMAND:-}" ]]; then
    KAFKA_CFG_BROKER_ID="$(eval "${KAFKA_BROKER_ID_COMMAND:-}")"
    LOG_I "Modify broker ID by KAFKA_BROKER_ID_COMMAND to ${KAFKA_CFG_BROKER_ID}"
    export KAFKA_CFG_BROKER_ID
fi

if ! is_sourced; then
	# 替换命令行中的变量
	set -- $(eval echo "$@")

	[ "${1:0:1}" = '-' ] && set -- "${APP_EXEC:-}" "$@"

	print_image_welcome
	print_command_help "$@"

	if [ "$1" = "${APP_EXEC}" ] && is_root; then
    	/usr/local/bin/setup.sh

		LOG_I "Restart with non-root user: ${APP_USER:-APP_NAME}\n"
		exec gosu "${APP_USER:-APP_NAME}" "$0" "$@"
	fi

	[ "$1" = "${APP_EXEC}" ] && /usr/local/bin/init.sh

	LOG_I "Start container with command: $@"
	exec tini -- "$@"
fi
