#!/bin/bash
#

# shellcheck disable=SC1091

BOLD='\033[1m'

# 加载依赖项
. /usr/local/bin/colovu/cv-log.sh

# 函数列表

# 根据需要打印欢迎信息
# 全局变量:
#   DISABLE_WELCOME_MESSAGE
#   APP_NAME
print_welcome_page() {
    if [[ -z "${DISABLE_WELCOME_MESSAGE:-}" ]]; then
        if [[ -n "$APP_NAME" ]]; then
            print_image_welcome_page
        fi
    fi
}

# 打印欢迎信息
# 全局变量:
#   APP_NAME
print_image_welcome_page() {
    local github_url="https://github.com/colovu/docker-${APP_NAME}"

    LOG_I ""
    LOG_I "${BOLD}Welcome to the ${APP_NAME} container${RESET}"
    LOG_I "Subscribe to project updates by watching ${BOLD}${github_url}${RESET}"
    LOG_I "Submit issues and feature requests at ${BOLD}${github_url}/issues${RESET}"
    LOG_I "Send us your feedback at ${BOLD}endial@126.com${RESET}"
    LOG_I ""
}

# 检测可能导致容器执行后直接退出的命令，如"--help"；如果存在，直接返回 0
# 参数:
#   $1 - 待检测的参数表
docker_app_want_help() {
    local arg
    for arg; do
        case "$arg" in
            -'?'|--help|-V|--version)
                return 0
                ;;
        esac
    done
    return 1
}

# 根据脚本扩展名及权限，执行相应的初始化脚本
# 参数:
#   $1 - 文件列表，支持路径通配符
# 使用: 
#   docker_process_init_files [file [file [...]]]
# 例子: 
#   docker_process_init_files /always-initdb.d/*
docker_process_init_files() {
    echo
    local f
    for f; do
        case "$f" in
            *.sh)
                if [ -x "$f" ]; then
                    LOG_I "$0: running $f"
                    "$f"
                else
                    LOG_I "$0: sourcing $f"
                    . "$f"
                fi
                ;;
            *)        LOG_W "$0: ignoring $f" ;;
        esac
        echo
    done
}

# 检测应用相应的配置文件是否存在，如果不存在，则从默认配置文件目录拷贝一份
# 默认配置文件路径：/etc/app-name
# 目标配置文件路径：/srv/conf/app-name
ensure_config_file_exist() {
    local f
    for f; do
        if [ -d ${f} ]; then
            dist="$(echo ${f} | sed -e 's/\/etc/\/srv\/conf/g')"
            LOG_I "Create directory: ${dist}"
            mkdir -p ${dist}
            [[ ! -z $(ls -A "$f") ]] && ensure_confi_file_exist ${f}/*
        else
            dist="$(echo ${f} | sed -e 's/\/etc/\/srv\/conf/g')"
            LOG_I "Copy: ${f} ===> ${dist}"
            [ ! -e ${dist} ] && cp ${f} ${dist}
        fi
    done
}

# 检测当前脚本是被直接执行的，还是从其他脚本中使用 "source" 调用的
_is_sourced() {
    [ "${#FUNCNAME[@]}" -ge 2 ] \
        && [ "${FUNCNAME[0]}" = '_is_sourced' ] \
        && [ "${FUNCNAME[1]}" = 'source' ]
}
