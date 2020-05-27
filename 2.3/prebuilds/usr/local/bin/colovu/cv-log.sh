#!/bin/bash
#
# 日志处理函数库

# 定义颜色信息
RESET='\033[0m'
RED='\033[38;5;1m'
GREEN='\033[38;5;2m'
YELLOW='\033[38;5;3m'
MAGENTA='\033[38;5;5m'
CYAN='\033[38;5;6m'

# 函数列表

# 输出实际日志信息
# 参数:
#   $1 - 日志类型
#   $2 - 日志信息
LOG_RAW() {
    local type="$1"; shift
    case "${type}" in
        x)  printf "${MAGENTA}%s$ ${CYAN}[%s]${RESET} %b\n" "$(date "+%T.%2N")" "${type}" "${*}" ;;
        I)  printf "${MAGENTA}%s$ ${GREEN}[%s]${RESET} %b\n" "$(date "+%T.%2N")" "${type}" "${*}";;
        W)  printf "${MAGENTA}%s$ ${YELLOW}[%s]${RESET} %b\n" "$(date "+%T.%2N")" "${type}" "${*}";;
        E)  printf "${MAGENTA}%s$ ${RED}[%s]${RESET} %b\n" "$(date "+%T.%2N")" "${type}" "${*}";;
    esac
}

# 输出调试类日志信息，尽量少使用
# 参数:
#   $1 - 日志类型
#   $2 - 日志信息
LOG_D() {
    LOG_RAW x "$@"
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
