# Ver: 1.0 by Endial Fang (endial@126.com)
#
# 当前 Docker 镜像的编译脚本

current_branch := $(shell git rev-parse --abbrev-ref HEAD)

# Sources List: default / tencent / ustc / aliyun / huawei
build-arg := --build-arg apt_source=tencent

# 设置本地下载服务器路径，加速调试时的本地编译速度
build-arg += --build-arg local_url=http://192.168.48.132/dist-files/

build:
	docker rmi kafka:$(current_branch) || true
	docker build --force-rm $(build-arg) -t kafka:$(current_branch) .
