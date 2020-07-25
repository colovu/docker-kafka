#!/bin/bash
# Ver: 1.0 by Endial Fang (endial@126.com)
#
# 文件操作函数库

# 加载依赖项
. /usr/local/scripts/liblog.sh          # 日志输出函数库

# 函数列表

# 检测"*_FILE"文件，并从文件中读取信息作为参数值；环境变量不允许 VAR 与 VAR_FILE 方式并存
# 变量：
#   $1 - 需要设置的环境变量名称
#   $2 - 该变量对应的默认值（Option）
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

# 使用规则表达式在文件中替换数据
# 参数:
#   $1 - 文件名
#   $2 - 正则表达式
#   $3 - 替代数据表达式
#   $4 - 是否使用POSIX表达式. Default: true
replace_in_file() {
    local filename="${1:?filename is required}"
    local match_regex="${2:?match regex is required}"
    local substitute_regex="${3:?substitute regex is required}"
    local posix_regex=${4:-true}

    local result

    # 因部分系统兼容性问题，需要防止使用 'sed in-place' 方式操作
    if [[ $posix_regex = true ]]; then
        result="$(sed -E "s@$match_regex@$substitute_regex@g" "$filename")"
    else
        result="$(sed "s@$match_regex@$substitute_regex@g" "$filename")"
    fi
    echo "$result" > "$filename"
}

# 使用规则表达式在文件中删除数据
# 参数:
#   $1 - 文件名
#   $2 - 正则表达式
#   $3 - 是否使用POSIX表达式. Default: true
remove_in_file() {
    local filename="${1:?filename is required}"
    local match_regex="${2:?match regex is required}"
    local posix_regex=${3:-true}
    local result

    # 因部分系统兼容性问题，需要防止使用 'sed in-place' 方式操作
    if [[ $posix_regex = true ]]; then
        result="$(sed -E "/$match_regex/d" "$filename")"
    else
        result="$(sed "/$match_regex/d" "$filename")"
    fi
    echo "$result" > "$filename"
}
