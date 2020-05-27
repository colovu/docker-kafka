#!/bin/bash
#
# 文件操作函数库

# 文件列表

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
