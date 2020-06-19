#!/bin/bash
#

# shellcheck disable=SC1091

BOLD='\033[1m'

# 加载依赖项
. /usr/local/scripts/liblog.sh

# 函数列表

# 打印包含包含Logo的欢迎信息
# 全局变量:
#   APP_NAME
print_image_welcome_page() {
    local github_url="https://github.com/colovu/docker-${APP_NAME}"
    if [ x"${WELCOME_MESSAGE:-}" = "x" ]; then
    LOG_I ""
    LOG_I "      ########  ########  ###       ########  ###   ##  ###   ##"
    LOG_I "     ###   ##  ###   ##  ###       ###   ##  ###   ##  ###   ##"
    LOG_I "    ###       ###   ##  ###       ###   ##  ###   ##  ###   ##"
    LOG_I "   ###       ###   ##  ###       ###   ##  ###   ##  ###   ##"
    LOG_I "  ###       ###   ##  ###       ###   ##   ### ##   ###   ##"
    LOG_I " ###   ##  ###   ##  ###       ###   ##    ####    ###   ##"
    LOG_I "########  ########  ########  ########     ##     ########"
    LOG_I ""
        LOG_I "Welcome to the ${BOLD}${APP_NAME}${RESET} container"
    LOG_I "Project on Github: ${BOLD}${github_url}${RESET}"
    LOG_I "Send us your feedback at ${BOLD}endial@126.com${RESET}"
    LOG_I ""

        export WELCOME_MESSAGE=1
    fi
}

# 根据需要打印欢迎信息
# 全局变量:
#   ENV_DISABLE_WELCOME_MESSAGE
#   APP_NAME
docker_print_welcome() {
    if [[ -z "${ENV_DISABLE_WELCOME_MESSAGE:-}" ]]; then
        if [[ -n "$APP_NAME" ]]; then
            print_image_welcome_page
        fi
    fi
}

# 检测可能导致容器执行后直接退出的命令，如"--help"；如果存在，直接返回 0
# 参数:
#   $1 - 待检测的参数表
docker_command_help() {
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
#   docker_process_init_files /src/conf/${APP_NAME}/initdb.d/*
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
# 默认配置文件路径：/etc/${APP_NAME}
# 目标配置文件路径：/srv/conf/${APP_NAME}
# 参数：
#   $* - 文件及目录列表字符串，以" "分割
# 例子: 
#   ensure_config_file_exist /etc/${APP_NAME}/*
ensure_config_file_exist() {
    local f

    LOG_D "Parameter: $@"
    while [ "$#" -gt 0 ]; do
        f="${1}"
        LOG_D "Process ${f}"
        if [ -d ${f} ]; then
            dist="$(echo ${f} | sed -e 's/\/etc/\/srv\/conf/g')"
            [ ! -d "${dist}" ] && LOG_I "Create directory: ${dist}" && mkdir -p "${dist}"
            [[ ! -z $(ls -A "$f") ]] && ensure_config_file_exist ${f}/*
        else
            dist="$(echo ${f} | sed -e 's/\/etc/\/srv\/conf/g')"
            [ ! -e "${dist}" ] && LOG_I "Copy: ${f} ===> ${dist}" && cp "${f}" "${dist}"
        fi
        shift
    done
}

# 检测当前用户是否为 root
# 返回值:
#   布尔值
_is_run_as_root() {
    if [[ "$(id -u)" = "0" ]]; then
        LOG_D "Run as root"
        true
    else
        LOG_D "User id: $(id -u)"
        false
    fi
}

# 检测当前脚本是被直接执行的，还是从其他脚本中使用 "source" 调用的
_is_sourced() {
    [ "${#FUNCNAME[@]}" -ge 2 ] \
    && [ "${FUNCNAME[0]}" = '_is_sourced' ] \
    && [ "${FUNCNAME[1]}" = 'source' ]
}
