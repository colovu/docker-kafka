#!/bin/bash
# 
# 容器入口脚本

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purpose

# 加载依赖脚本
. /usr/local/bin/colovu/cv-log.sh
. /usr/local/bin/colovu/cv-common.sh
. /usr/local/bin/app/app-common.sh

# 加载环境变量, app_env函数在文件 app-common.sh 中定义
eval "$(docker_app_env)"

print_welcome_page

# 创建默认的数据目录，并拷贝所必须的默认配置文件及初始化文件
docker_create_user_directories() {
	local user_id; user_id="$(id -u)"

	for dir in "${APP_DEF_DIR}" "${APP_CONF_DIR}" "${APP_CERT_DIR}" "${APP_DATA_DIR}" "${APP_CACHE_DIR}" "${APP_LOG_DIR}" "${APP_RUN_DIR}"; do
    	ensure_dir_exists "$dir"
	done

	

	# 检测指定文件是否在配置文件存储目录存在，如果不存在则拷贝（新挂载数据卷、手动删除都会导致不存在）
	ensure_confi_file_exist ${APP_DEF_DIR}/*.properties
}

_main() {
	# 如果命令行参数是以配置参数("-")开始，修改执行命令，确保使用可执行应用命令启动服务器
	if [ "${1:0:1}" = '-' ]; then
		set -- ${APP_EXEC} "$@"
	fi

	# 命令行参数以可执行应用命令起始，且不包含直接返回的命令(如：-V、--version、--help)时，执行初始化操作
	if [ "$1" = "${APP_EXEC}" ] && ! docker_app_want_help "$@"; then
		docker_setup_env

		# 创建并设置数据存储目录与权限
		docker_create_user_directories

		# 以root用户运行时，会使用gosu重新以"APP_USER"用户运行当前脚本
		if is_run_as_root; then
			# 以root用户启动时，修改相应目录的所属用户信息为APP_USER，确保切换用户时，权限正常
			for dir in "${APP_DEF_DIR}" "${APP_CONF_DIR}" "${APP_CERT_DIR}" "${APP_DATA_DIR}" "${APP_CACHE_DIR}" "${APP_LOG_DIR}" "${APP_RUN_DIR}"; do
    			configure_permissions_ownership -f 755 -d 755 -u "${APP_USER}" "$dir"
			done
			# 解决使用gosu后，nginx: [emerg] open() "/dev/stdout" failed (13: Permission denied)
			chmod 0622 /dev/stdout /dev/stderr

			LOG_I "Restart container with default user: ${APP_USER}'"
			exec gosu "${APP_USER}" "$0" "$@"
		fi
		
		# 执行应用初始化操作
		docker_app_init
		
		# 执行用户自定义初始化脚本
		docker_app_custom_init
	fi

	LOG_I "Start container with: $@"
	# 执行命令行
	exec "$@"
}

# 脚本入口命令
if ! _is_sourced; then
	_main "$@"
fi
