#!/bin/bash
# Ver: 1.0 by Endial Fang (endial@126.com)
# 
# 应用初始化脚本

# 设置 shell 执行参数，可使用'-'(打开）'+'（关闭）控制。常用：
# 	-e: 命令执行错误则报错; -u: 变量未定义则报错; -x: 打印实际待执行的命令行; -o pipefail: 设置管道中命令遇到失败则报错
set -eu
set -o pipefail

. /usr/local/bin/appcommon.sh			# 应用专用函数库

eval "$(app_env)"
LOG_I "** Processing init.sh **"

# 执行应用预初始化操作
app_custom_preinit

# 执行应用初始化操作
app_default_init

# 执行用户自定义初始化脚本
app_custom_init

LOG_I "** Processing init.sh finished! **"
