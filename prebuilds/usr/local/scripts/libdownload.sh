#!/bin/bash
# Ver: 1.0 by Endial Fang (endial@126.com)
#
# 从服务器（列表）下载相应软件包

# Constants
#CV_BASE="http://archive.colovu.com/dist-files/"
#CV_BASE="http://10.37.129.2/dist-files/"
CV_BASE=""

# 检测软件包签名是否正确
# 参数：
#   $1 - 软件包签名文件
#   $2 - 软件包文件
#   $3 - PGPKEY
check_pgp() {
    local name_asc=${1:?missing asc file name}
    local name=${2:?missing file name}
    local keys="${3:?missing key id}"

    GNUPGHOME="$(mktemp -d)"
    for key in $keys; do
        gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "${key}" || 
        gpg --batch --keyserver pgp.mit.edu --recv-keys "${key}" || 
        gpg --batch --keyserver keys.gnupg.net --recv-keys "${key}" || 
        gpg --batch --keyserver keyserver.pgp.com --recv-keys "${key}"; 
    done
    gpg --batch --verify "$name_asc" "$name"
    command -v gpgconf > /dev/null && gpgconf --kill all
    rm -rf "$GNUPGHOME" "$name_asc"
}

# 从私有服务器下载软件包，如果不存在，则从官网服务器下载
# 参数：
#   $1 - 软件包全名(字符串)
#   $2 - 官网路径(字符串)
#   $3 - "-c"/"--checksum"
#   $4 - 软件包SHA256值
#   $3 - "-g"/"--pgpkey"
#   $4 - 用于软件包签名的KEY ID
# 例子：
#   . /usr/local/scripts/libdownload.sh && download_dist "java" "11.0.7-0" --checksum 02a1fc9b79b11617ad39221667f6a34209f5c45ca908268f8ba6c264a2577ee2
download_dist() {
    local name="${1:?name is required}"
    local base_urls="${2:?url is required}"
    local package_sha256=""
    local pgp_key=""
    local success=""

    # 获取SHA256或PGP KEY
    shift 2
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -c|--checksum)
                shift
                package_sha256="${1:?missing package checksum}"
                ;;
            -g|--pgpkey)
                shift
                pgp_key="${1:?missing package PGP key}"
                ;;
            *)
                echo "Invalid command line flag $1" >&2
                return 1
                ;;
        esac
        shift
    done

    echo "Downloading $name package"
    for url in $CV_BASE $base_urls; do
        if wget -O "$name" "$url$name" && [ -s "$name" ]; then
            if [ -n "$pgp_key" ]; then
                wget -O "$name.asc" "$url$name.asc"
                if [ ! -e "$name.asc" ]; then
                    wget -O "$name.asc" "$url$name.sig"
                fi
            fi
            success=1
            break
        fi
    done

    if [ -n "$success" ]; then
        if [ -n "$package_sha256" ]; then
            echo "Verifying package whith sha256"
            echo "$package_sha256 *${name}" | sha256sum --check -
        fi

        if [ -n "$pgp_key" ]; then
            echo "Verifying package with PGP"
            check_pgp "$name.asc" "$name" "$pgp_key"
        fi
    else
        [ -n "$success" ]
    fi
}
