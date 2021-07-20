# Ver: 1.11 by Endial Fang (endial@126.com)
#
# 当前 Docker 镜像的编译脚本

# 定义镜像名称
image_name :=colovu/kafka

# 定义默认镜像仓库地址
registry_url :=docker.io

# 定义系统默认使用的源服务器，包含：default / tencent / ustc / aliyun / huawei
apt_source :=tencent

# 定义镜像TAG，类似：
# 	<镜像名>:<分支名>-<7位Git ID>		# Git 仓库且无文件修改直接编译 	
# 	<镜像名>:<分支名>-<年月日>-<时分秒>		# Git 仓库有文件修改后的编译
# 	<镜像名>:latest-<年月日>-<时分秒>		# 非 Git 仓库编译
current_subversion:=$(shell if [ ! `git status >/dev/null 2>&1` ]; then git rev-parse --short HEAD; else date +%y%m%d-%H%M%S; fi)
image_tag:=$(shell if [ ! `git status >/dev/null 2>&1` ]; then git rev-parse --abbrev-ref HEAD | sed -e 's/master/latest/'; else echo "latest"; fi)-$(current_subversion)

build-arg:=--build-arg registry_url=$(registry_url)
build-arg+=--build-arg apt_source=$(apt_source)

# 设置本地下载服务器路径，加速调试时的本地编译速度
local_ip:=`echo "en0 eth0" | xargs -n1 ip addr show 2>/dev/null | grep inet | grep -v 127.0.0.1 | grep -v inet6 | tr "/" " " | awk '{print $$2}'`
build-arg+=--build-arg local_url=http://$(local_ip)/dist-files

.PHONY: build clean clearclean upgrade

# 屏蔽 "Use 'docker scan' to run Snyk tests against images to find vulnerabilities and learn how to fix them"
export DOCKER_SCAN_SUGGEST=false

build:
	@echo "Build $(image_name):$(image_tag)"
	@docker build --progress plain --force-rm $(build-arg) -t $(image_name):$(image_tag) .
	@echo "Add tag: $(image_name):latest"
	@docker tag $(image_name):$(image_tag) $(image_name):latest
	@echo "Build complete"

# 清理悬空的镜像（无TAG）及停止的容器 
clearclean: clean
	@echo "Clean untaged images and stoped containers..."
	@docker ps -a | grep "Exited" | awk '{print $$1}' | sort -u | xargs -L 1 docker rm
	@docker images | grep '<none>' | awk '{print $$3}' | sort -u | xargs -L 1 docker rmi -f

# 为了防止删除前缀名相同的镜像，在过滤条件中加入一个空格进行过滤
clean:
	@echo "Clean all images for current application..."
	@docker images | grep "$(image_name) " | awk '{print $$3}' | sort -u | xargs -L 1 docker rmi -f

# 更新所有 colovu 仓库的镜像 
upgrade: 
	@echo "Upgrade all images..."
	@docker images | grep 'colovu' | grep -v '<none>' | grep -v "latest-" | awk '{print $$1":"$$2}' | sort -u | xargs -L 1 docker pull

