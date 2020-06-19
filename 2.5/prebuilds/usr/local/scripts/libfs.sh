#!/bin/bash
#
# 文件管理函数库

# 加载依赖项
. /usr/local/scripts/liblog.sh

# 函数列表

# Ensure a file/directory is owned (user and group) but the given user
# Arguments:
#   $1 - filepath
#   $2 - owner
ensure_owned_by() {
    local path="${1:?path is missing}"
    local owner="${2:?owner is missing}"

    chown "$owner":"$owner" "$path"
}

# 检测目录是否存在，如果不存在则创建，同时修改为指定的用户
# Arguments:
#   $1 - directory
#   $2 - owner
ensure_dir_exists() {
    local dir="${1:?directory is missing}"
    local owner="${2:-}"

    mkdir -p "${dir}"
    if [[ -n $owner ]]; then
        ensure_owned_by "$dir" "$owner"
    fi
}

# 检测目录是否存在或为空
# 参数:
#   $1 - 目录路径
# 返回值:
#   布尔值
is_dir_empty() {
    local dir="${1:?missing directory}"

    if [[ ! -e "$dir" ]] || [[ -z "$(ls -A "$dir")" ]]; then
        true
    else
        false
    fi
}

# 循环设置目录中子目录及文件权限
# 参数:
#   $1 - paths (as a string).
# Flags:
#   -f|--file-mode - 文件权限模式
#   -d|--dir-mode - 目录权限模式
#   -u|--user - 用户
#   -g|--group - 用户组
configure_permissions_ownership() {
    local -r paths="${1:?paths is missing}"
    local dir_mode=""
    local file_mode=""
    local user=""
    local group=""

    # Validate arguments
    shift 1
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -f|--file-mode)
                shift
                file_mode="${1:?missing mode for files}"
                ;;
            -d|--dir-mode)
                shift
                dir_mode="${1:?missing mode for directories}"
                ;;
            -u|--user)
                shift
                user="${1:?missing user}"
                ;;
            -g|--group)
                shift
                group="${1:?missing group}"
                ;;
            *)
                LOG_E "Invalid command line flag $1" >&2
                return 1
                ;;
        esac
        shift
    done

    read -r -a filepaths <<< "$paths"
    for p in "${filepaths[@]}"; do
        if [[ -e "$p" ]]; then
            LOG_D "Check directory $p"
            if [[ -n $dir_mode ]]; then
                LOG_D "Change permissions to 755 of directories in $p"
                find -L "$p" -type d -exec chmod "$dir_mode" '{}' +
            fi
            if [[ -n $file_mode ]]; then
                LOG_D "Change permissions to 755 of files in $p"
                find -L "$p" -type f -exec chmod "$file_mode" '{}' +
            fi
            if [[ -n $user ]] && [[ -n $group ]]; then
                LOG_D "Change ownership to ${user}:${group} of files and directories in $p"
                find -L "$p" \! -user ${user} -or \! -group ${group} -exec chown -L "$user":"$group" '{}' +
            elif [[ -n $user ]] && [[ -z $group ]]; then
                LOG_D "Change user to ${user} of files and directories in $p"
                find -L "$p" \! -user ${user} -exec chown -L "$user" '{}' +
            elif [[ -z $user ]] && [[ -n $group ]]; then
                LOG_D "Change groupto ${group} of files and directories in $p"
                find -L "$p" \! -group ${group} -exec chgrp -L "$group" '{}' +
            fi
        else
            LOG_E "$p does not exist"
        fi
    done
}