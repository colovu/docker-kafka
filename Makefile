# Ver: 1.0 by Endial Fang (endial@126.com)
#
# 当前 Docker 镜像的编译脚本

app_name := kafka
current_branch := $(shell git rev-parse --abbrev-ref HEAD)

# Sources List: default / tencent / ustc / aliyun / huawei
build-arg := --build-arg apt_source=tencent

# 设置本地下载服务器路径，加速调试时的本地编译速度
# local_ip=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`
build-arg += --build-arg local_url=http://192.168.1.131/dist-files/

build:
	docker rmi $(app_name):$(current_branch) || true
	docker build --force-rm $(build-arg) -t $(app_name):$(if $(current_branch),$(current_branch),latest) .
