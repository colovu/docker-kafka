#!/bin/bash
#
# 服务管理函数库

# shellcheck disable=SC1091

# Load Generic Libraries
. /usr/local/scripts/libvalidations.sh

# 函数列表

# 获取并返回服务 PID
# 参数:
#   $1 - PID 文件   
# 返回值:
#   PID
get_pid_from_file() {
    local pid_file="${1:?pid file is missing}"

    if [[ -f "$pid_file" ]]; then
        if [[ -n "$(< "$pid_file")" ]] && [[ "$(< "$pid_file")" -gt 0 ]]; then
            echo "$(< "$pid_file")"
        fi
    fi
}

# 检测 PID 对应的服务是否在运行中 
# 参数:
#   $1 - PID
# 返回值:
#   Boolean
is_service_running() {
    local pid="${1:?pid is missing}"

    kill -0 "$pid" 2>/dev/null
}

# 通过发送信号停止一个指定的服务
# 参数:
#   $1 - PID 文件
#   $2 - 信号 (可选)
stop_service_using_pid() {
    local pid_file="${1:?pid file is missing}"
    local signal="${2:-}"
    local pid

    pid="$(get_pid_from_file "$pid_file")"
    [[ -z "$pid" ]] || ! is_service_running "$pid" && return

    if [[ -n "$signal" ]]; then
        kill "-${signal}" "$pid"
    else
        kill "$pid"
    fi

    local counter=10
    while [[ "$counter" -ne 0 ]] && is_service_running "$pid"; do
        sleep 1
        counter=$((counter - 1))
    done
}

# 为指定的服务生成一个监控配置文件
# Arguments:
#   $1 - 服务名
#   $2 - PID 文件
#   $3 - 启动命令
#   $4 - 停止命令
# Flags:
#   --disabled - Whether to disable the monit configuration
generate_monit_conf() {
    local service_name="${1:?service name is missing}"
    local pid_file="${2:?pid file is missing}"
    local start_command="${3:?start command is missing}"
    local stop_command="${4:?stop command is missing}"
    local monit_conf_dir="/etc/monit/conf.d"
    local disabled="no"

    # Parse optional CLI flags
    shift 4
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            --disabled)
                shift
                disabled="$1"
                ;;
            *)
                echo "Invalid command line flag ${1}" >&2
                return 1
                ;;
        esac
        shift
    done

    is_boolean_yes "$disabled" && conf_suffix=".disabled"
    mkdir -p "$monit_conf_dir"
    cat >"${monit_conf_dir}/${service_name}.conf${conf_suffix:-}" <<EOF
check process ${service_name}
  with pidfile "${pid_file}"
  start program = "${start_command}" with timeout 90 seconds
  stop program = "${stop_command}" with timeout 90 seconds
EOF
}

# 生成一个 Logrotate 配置文件
# Arguments:
#   $1 - 日志路径
#   $2 - Period
#   $3 - Rotations 存储的数量
#   $4 - 其他参数 (可选)
generate_logrotate_conf() {
    local service_name="${1:?service name is missing}"
    local log_path="${2:?log path is missing}"
    local period="${3:-weekly}"
    local rotations="${4:-150}"
    local extra_options="${5:-}"
    local logrotate_conf_dir="/etc/logrotate.d"

    mkdir -p "$logrotate_conf_dir"
    cat >"${logrotate_conf_dir}/${service_name}" <<EOF
${log_path} {
  ${period}
  rotate ${rotations}
  dateext
  compress
  copytruncate
  missingok
  ${extra_options}
}
EOF
}
