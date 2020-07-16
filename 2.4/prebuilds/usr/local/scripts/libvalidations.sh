#!/bin/bash
# Ver: 1.0 by Endial Fang (endial@126.com)
#
# 数据有效性校验函数库

# 加载依赖项
. /usr/local/scripts/liblog.sh          # 日志输出函数库

# 函数列表

# 检测数据是否为整数
# 参数:
#   $1 - 待检测的数据
# 返回值:
#   布尔值
is_int() {
    local -r int="${1:?missing value}"
    if [[ "$int" =~ ^-?[0-9]+ ]]; then
        true
    else
        false
    fi
}

# 检测数据是否为正整数
# 参数:
#   $1 - 待检测的数据
# 返回值:
#   布尔值
is_positive_int() {
    local -r int="${1:?missing value}"
    if is_int "$int" && (( "${int}" >= 0 )); then
        true
    else
        false
    fi
}

# 检测数据是否为布尔值 '1' 或字符串 'yes/true'
# 参数:
#   $1 - 待检测的数据
# 返回值:
#   布尔值
is_boolean_yes() {
    local -r bool="${1:-}"
    # comparison is performed without regard to the case of alphabetic characters
    shopt -s nocasematch
    if [[ "$bool" = 1 || "$bool" =~ ^(yes|true)$ ]]; then
        true
    else
        false
    fi
}

# 检测数据是否为字符串 'yes/no'
# 参数:
#   $1 - 待检测的数据
# 返回值:
#   布尔值
is_yes_no_value() {
    local -r bool="${1:-}"
    if [[ "$bool" =~ ^(yes|no)$ ]]; then
        true
    else
        false
    fi
}

# 检测数据是否为字符串 'true/false'
# 参数:
#   $1 - 待检测的数据
# 返回值:
#   布尔值
is_true_false_value() {
    local -r bool="${1:-}"
    if [[ "$bool" =~ ^(true|false)$ ]]; then
        true
    else
        false
    fi
}

# 检测提供的参数是否为空字符串或未定义
# 参数:
#   $1 - 待检测的数据
# 返回值:
#   布尔值
is_empty_value() {
    local -r val="${1:-}"
    if [[ -z "$val" ]]; then
        true
    else
        false
    fi
}

# 检测数据是否为有效的端口号
# 参数:
#   $1 - 待检测的数据
# 返回值:
#   布尔值 或 错误消息
validate_port() {
    local value
    local unprivileged=0

    # Parse flags
    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -unprivileged)
                unprivileged=1
                ;;
            --)
                shift
                break
                ;;
            -*)
                stderr_print "unrecognized flag $1"
                return 1
                ;;
            *)
                break
                ;;
        esac
        shift
    done

    if [[ "$#" -gt 1 ]]; then
        echo "too many arguments provided"
        return 2
    elif [[ "$#" -eq 0 ]]; then
        stderr_print "missing port argument"
        return 1
    else
        value=$1
    fi

    if [[ -z "$value" ]]; then
        echo "the value is empty"
        return 1
    else
        if ! is_int "$value"; then
            echo "value is not an integer"
            return 2
        elif [[ "$value" -lt 0 ]]; then
            echo "negative value provided"
            return 2
        elif [[ "$value" -gt 65535 ]]; then
            echo "requested port is greater than 65535"
            return 2
        elif [[ "$unprivileged" = 1 && "$value" -lt 1024 ]]; then
            echo "privileged port requested"
            return 3
        fi
    fi
}

# 检测数据是否为有效的IPv4地址
# 参数:
#   $1 - 待检测的数据
# 返回值:
#   布尔值
validate_ipv4() {
    local ip="${1:?ip is missing}"
    local stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
	read -r -a ip_array <<< "$(tr '.' ' ' <<< "$ip")"
        [[ ${ip_array[0]} -le 255 && ${ip_array[1]} -le 255 \
            && ${ip_array[2]} -le 255 && ${ip_array[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

# 校验字符串格式
# 参数:
#   $1 - 待检测的数据
# 返回值:
#   布尔值
validate_string() {
    local string
    local min_length=-1
    local max_length=-1

    # Parse flags
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -min-length)
                shift
                min_length=${1:-}
                ;;
            -max-length)
                shift
                max_length=${1:-}
                ;;
            --)
                shift
                break
                ;;
            -*)
                stderr_print "unrecognized flag $1"
                return 1
                ;;
            *)
                break
                ;;
        esac
        shift
    done

    if [ "$#" -gt 1 ]; then
        stderr_print "too many arguments provided"
        return 2
    elif [ "$#" -eq 0 ]; then
        stderr_print "missing string"
        return 1
    else
        string=$1
    fi

    if [[ "$min_length" -ge 0 ]] && [[ "${#string}" -lt "$min_length" ]]; then
        echo "string length is less than $min_length"
        return 1
    fi
    if [[ "$max_length" -ge 0 ]] && [[ "${#string}" -gt "$max_length" ]]; then
        echo "string length is great than $max_length"
        return 1
    fi
}