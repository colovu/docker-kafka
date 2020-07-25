#!/bin/bash
# Ver: 1.0 by Endial Fang (endial@126.com)
#
# 网络管理函数库

# shellcheck disable=SC1091

# 加载依赖项
. /usr/local/scripts/liblog.sh          # 日志输出函数库

# 函数列表

# 解析主机名为 IP
# 参数:
#   $1 - 待解析的主机名
# 返回值:
#   IP 地址
#########################
dns_lookup() {
    local host="${1:?host is missing}"
    getent ahosts "$host" | awk '/STREAM/ {print $1 }'
}

# 等待主机名解析，并返回 IP
# 参数:
#   $1 - 主机名
#   $2 - 重试次数
#   $3 - 重试间隔（秒）
# 返回值:
#   - IP 地址
wait_for_dns_lookup() {
    local hostname="${1:?hostname is missing}"
    local retries="${2:-5}"
    local seconds="${3:-1}"
    check_host() {
        if [[ $(dns_lookup "$hostname") == "" ]]; then
            false
        else
            true
        fi
    }
    # Wait for the host to be ready
    retry_while "check_host ${hostname}" "$retries" "$seconds"
    dns_lookup "$hostname"
}

# 获取机器的 IP
# 返回值:
#   - IP 地址
get_machine_ip() {
    dns_lookup "$(hostname)"
}

# 检测提供的参数是否为可解析地址的主机名
# 参数:
#   $1 - 待检测值
# 返回值:
#   布尔值
is_hostname_resolved() {
    local -r host="${1:?missing value}"
    if [[ -n "$(dns_lookup "$host")" ]]; then
        true
    else
        false
    fi
}

# 解析 URL
# 参数:
#   $1 - URI 字符串
#   $2 - 待解析参数字符串。有效值 (scheme, authority, userinfo, host, port, path, query or fragment) 
# 返回值:
#   字符串
parse_uri() {
    local uri="${1:?uri is missing}"
    local component="${2:?component is missing}"

    # Solution based on https://tools.ietf.org/html/rfc3986#appendix-B with
    # additional sub-expressions to split authority into userinfo, host and port
    # Credits to Patryk Obara (see https://stackoverflow.com/a/45977232/6694969)
    local -r URI_REGEX='^(([^:/?#]+):)?(//((([^@/?#]+)@)?([^:/?#]+)(:([0-9]+))?))?(/([^?#]*))?(\?([^#]*))?(#(.*))?'
    #                    ||            |  |||            |         | |            | |         |  |        | |
    #                    |2 scheme     |  ||6 userinfo   7 host    | 9 port       | 11 rpath  |  13 query | 15 fragment
    #                    1 scheme:     |  |5 userinfo@             8 :...         10 path     12 ?...     14 #...
    #                                  |  4 authority
    #                                  3 //...
    local index=0
    case "$component" in
        scheme)
            index=2
            ;;
        authority)
            index=4
            ;;
        userinfo)
            index=6
            ;;
        host)
            index=7
            ;;
        port)
            index=9
            ;;
        path)
            index=10
            ;;
        query)
            index=13
            ;;
        fragment)
            index=14
            ;;
        *)
            stderr_print "unrecognized component $component"
            return 1
            ;;
    esac
    [[ "$uri" =~ $URI_REGEX ]] && echo "${BASH_REMATCH[${index}]}"
}
	