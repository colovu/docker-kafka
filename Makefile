# Ver: 1.4 by Endial Fang (endial@126.com)
#
# 当前 Docker 镜像的编译脚本

app_name :=colovu/kafka

# 生成镜像TAG，类似：
# 	<镜像名>:<分支名>-<Git ID>		# Git 仓库且无文件修改直接编译 	
# 	<镜像名>:<分支名>-<年月日>-<时分秒>		# Git 仓库有文件修改后的编译
# 	<镜像名>:latest-<年月日>-<时分秒>		# 非 Git 仓库编译
current_subversion:=$(shell if [ ! `git status >/dev/null 2>&1` ]; then git rev-parse --short HEAD; else date +%y%m%d-%H%M%S; fi)
current_tag:=$(shell if [ ! `git status >/dev/null 2>&1` ]; then git rev-parse --abbrev-ref HEAD | sed -e 's/master/latest/'; else echo "latest"; fi)-$(current_subversion)

# Sources List: default / tencent / ustc / aliyun / huawei
build-arg:=--build-arg apt_source=tencent

# 设置本地下载服务器路径，加速调试时的本地编译速度
local_ip:=`ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $$2}'|tr -d "addr:"`
build-arg+=--build-arg local_url=http://$(local_ip)/dist-files

.PHONY: build build-debian build-alpine clean clearclean upgrade

build: build-debian build-alpine
	@echo "Build complete"

build-debian:
	@echo "Build $(app_name):$(current_tag)-deb"
	@docker build --force-rm $(build-arg) -t $(app_name):$(current_tag)-deb .
	@echo "Add tag: $(app_name):latest-deb"
	@docker tag $(app_name):$(current_tag)-deb $(app_name):latest-deb

build-alpine:
	@echo "Build $(app_name):$(current_tag)"
	@docker build --force-rm $(build-arg) -t $(app_name):$(current_tag) ./alpine
	@echo "Add tag: $(app_name):latest"
	@docker tag $(app_name):$(current_tag) $(app_name):latest

# 清理悬空的镜像（无TAG）及停止的容器 
clearclean: clean
	@echo "Clean untaged images and stoped containers..."
	@docker ps -a | grep "Exited" | awk '{print $$1}' | sort -u | xargs -L 1 docker rm
	@docker images | grep '<none>' | awk '{print $$3}' | sort -u | xargs -L 1 docker rmi -f

# 为了防止删除前缀名相同的镜像，在过滤条件中加入一个空格进行过滤
clean:
	@echo "Clean all images for current application..."
	@docker images | grep "$(app_name) " | awk '{print $$3}' | sort -u | xargs -L 1 docker rmi -f

tag:
	@echo "Add tag: $(local_registory)/$(app_name):latest"
	@docker tag $(app_name):latest $(local_registory)/$(app_name):latest

push: tag
	@echo "Push: $(local_registory)/$(app_name):latest"
	@docker push $(local_registory)/$(app_name):latest
	@echo "Push: $(app_name):latest"
	@docker push $(app_name):latest

# 更新所有 colovu 仓库的镜像 
upgrade: 
	@echo "Upgrade all images..."
	@docker images | grep 'colovu' | grep -v '<none>' | grep -v "latest-" | awk '{print $$1":"$$2}' | sort -u | xargs -L 1 docker pull

