#!/bin/bash
#
# 系统运行环境控制函数库

# shellcheck disable=SC1091

# 加载依赖项
. /usr/local/bin/colovu/cv-log.sh

# 函数列表

# 检测"_FILE"文件，并从文件中读取信息作为参数值；环境变量不允许 VAR 与 VAR_FILE 方式并存
# 变量：
# 	1: 需要设置的环境变量名称
# 	2: 该变量对应的默认值（Option）
# 	
# 使用: file_env ENV_VAR [DEFAULT]
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		LOG_E "Both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi

	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi

	export "$var"="$val"
	unset "$fileVar"
}
