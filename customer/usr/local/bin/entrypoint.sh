#!/bin/bash
# Ver: 1.0 by Endial Fang (endial@126.com)
# 
# 容器入口脚本

# 设置遇到执行错误则退出执行
set -o errexit
# 设置脚本遇到未初始化或声明的变量退出执行
set -o nounset
# 设置遇到管道命令失败则退出执行
set -o pipefail
# 设置调试信息输出，及命令在执行前先打印命令执行前的命令内容
# set -o xtrace

# 加载依赖脚本
#. /usr/local/scripts/liblog.sh			# 日志输出函数库
#. /usr/local/scripts/libcommon.sh		# 通用函数库
. /usr/local/bin/appcommon.sh			# 应用专用函数库

LOG_D "Process entrypoint.sh..."

# 初始化环境变量。 docker_app_env()函数在文件 appcommon.sh 中定义
eval "$(docker_app_env)"

# 定义容器中使用的默认目录(未定义时设置默认值为空"")
APP_DIRS="${APP_CONF_DIR:-} ${APP_DATA_DIR:-} ${APP_LOG_DIR:-} ${APP_CERT_DIR:-} ${APP_DATA_LOG_DIR:-}"

kafka_create_alias_environment_variables

if [[ -n "${KAFKA_BROKER_ID_COMMAND:-}" ]]; then
    KAFKA_CFG_BROKER_ID="$(eval "${KAFKA_BROKER_ID_COMMAND:-}")"
    LOG_I "Modify broker ID by KAFKA_BROKER_ID_COMMAND to ${KAFKA_CFG_BROKER_ID}"
    export KAFKA_CFG_BROKER_ID
fi

# 打印镜像欢迎信息
docker_print_welcome

# 检测数据卷中相关目录，创建默认的关联目录，并拷贝所必须的默认配置文件及初始化文件
# 全局变量：
# 	APP_*
docker_ensure_dir_and_configs() {
    _is_restart && return

	local user_id; user_id="$(id -u)"

	LOG_D "Check directories..."
	for dir in ${APP_DIRS}; do
    	LOG_D "  Check $dir"
    	ensure_dir_exists "$dir"
	done

	# 检测指定文件是否在配置文件存储目录存在，如果不存在则拷贝（新挂载数据卷、手动删除都会导致不存在）
	LOG_D "Check config files..."
	if [[ ! -z "$(ls -A "${APP_DEF_DIR}")" ]]; then
		ensure_config_file_exist "${APP_DEF_DIR}" $(ls -A "${APP_DEF_DIR}")
	fi
}

_main() {
	# 替换命令行中的变量
	set -- $(eval echo "$@")

	# 如果命令行参数是以配置参数("-")开始，修改执行命令，确保使用可执行应用命令启动服务器
	if [ "${1:0:1}" = '-' ]; then
		set -- "${APP_EXEC}" "$@"
	fi

	# 命令行参数以可执行应用命令起始，且不包含直接返回的命令(如：-V、--version、--help)时，执行初始化操作
	if [ "$1" = "${APP_EXEC}" ] && ! docker_command_help "$@"; then		
		# 检测启动容器时设置的环境变量是否有效
		app_verify_minimum_env

		# 检测应用需要使用的目录及配置文件是否存在
		docker_ensure_dir_and_configs

		# 以root用户运行时，会使用gosu重新以"APP_NAME"用户运行当前脚本
		if _is_run_as_root; then
			LOG_D "Change permissions when run as root"

			# 以root用户启动时，修改相应目录的所属用户信息为 APP_NAME ，确保切换用户时，权限正常
			for dir in ${APP_DIRS}; do
    			chmod 755 ${dir}
    			configure_permissions_ownership "$dir" -u "${APP_NAME}" -g "${APP_NAME}"
				:
			done

			# 解决使用gosu后，nginx: [emerg] open() "/dev/stdout" failed (13: Permission denied)
			LOG_D "Change permissions of stdout/stderr to 0622"
			chmod 0622 /dev/stdout /dev/stderr

			LOG_I ""
			LOG_I "Restart container with default user: ${APP_NAME}"
			LOG_I "  command: $@"
	        export RESTART_FLAG=1
			exec gosu "${APP_NAME}" "$0" "$@"
		fi
		
		# 执行应用初始化操作
		docker_app_init
		
		# 执行用户自定义初始化脚本
		docker_custom_init
	fi

	LOG_I "Start container with command: $@"
	# 执行命令行。
	exec "$@"
}

# 脚本入口命令
if ! _is_sourced; then
	_main "$@"
fi
