#!/bin/bash
#
# 日志处理函数库

# 定义颜色信息
RESET='\033[0m'
RED='\033[31;1m'
GREEN='\033[32;2m'
YELLOW='\033[33;1m'
MAGENTA='\033[36;2m'
CYAN='\033[35;2m'
BLUE='\033[34;2m'

# 函数列表

# 输出实际日志信息
# 参数:
#   $1 - 日志类型
#   $2 - 日志信息
LOG_RAW() {
    local type="$1"; shift
    case "${type}" in
        x)  printf "${CYAN}${APP_NAME:-} ${MAGENTA}%s ${RESET}${BLUE}DEBUG${RESET} %b\n" "$(date "+%T.%2N")" "${*}" ;;
        I)  printf "${CYAN}${APP_NAME:-} ${MAGENTA}%s ${RESET}${GREEN}INFO ${RESET} %b\n" "$(date "+%T.%2N")" "${*}";;
        W)  printf "${CYAN}${APP_NAME:-} ${MAGENTA}%s ${RESET}${YELLOW}WARN ${RESET} %b\n" "$(date "+%T.%2N")" "${*}";;
        E)  printf "${CYAN}${APP_NAME:-} ${MAGENTA}%s ${RESET}${RED}ERROR${RESET} %b\n" "$(date "+%T.%2N")" "${*}";;
    esac
}

# 输出调试类日志信息，尽量少使用
# 参数:
#   $1 - 日志类型
#   $2 - 日志信息
LOG_D() {
    local -r bool="${ENV_DEBUG:-false}"
    shopt -s nocasematch
    if [[ "$bool" = 1 || "$bool" =~ ^(yes|true)$ ]]; then
        LOG_RAW x "$@"
    fi   
}

# 输出提示信息类日志信息
# 参数:
#   $1 - 日志类型
#   $2 - 日志信息
LOG_I() {
    shopt -s nocasematch
    LOG_RAW I "$@"
}

# 输出警告类日志信息至sterr
# 参数:
#   $1 - 日志类型
#   $2 - 日志信息
LOG_W() {
    LOG_RAW W "$@" >&2
}

# 输出错误类日志信息至sterr，并退出脚本
# 参数:
#   $1 - 日志类型
#   $2 - 日志信息
LOG_E() {
    LOG_RAW E "$@" >&2
}
