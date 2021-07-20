# Ver: 1.8 by Endial Fang (endial@126.com)
#

# 可变参数 ========================================================================

# 设置当前应用名称及版本
ARG app_name=kafka
ARG app_version=2.5.1

# 设置默认仓库地址，默认为 阿里云 仓库
ARG registry_url="registry.cn-shenzhen.aliyuncs.com"

# 设置 apt-get 源：default / tencent / ustc / aliyun / huawei
ARG apt_source=aliyun

# 编译镜像时指定用于加速的本地服务器地址
ARG local_url=""


# 0. 预处理 ======================================================================
FROM ${registry_url}/colovu/dbuilder as builder

# 声明需要使用的全局可变参数
ARG app_name
ARG app_version
ARG registry_url
ARG apt_source
ARG local_url

ARG scala_version=2.12

ENV APP_NAME=${app_name} \
	APP_VERSION=${app_version}

# 选择软件包源(Optional)，以加速后续软件包安装
RUN select_source ${apt_source};

# 安装依赖的软件包及库(Optional)
#RUN install_pkg xz-utils

# 设置工作目录
WORKDIR /tmp

# 下载并解压软件包 render-template
RUN set -eux; \
	appName="render-template-1.0.0-0-linux-amd64-debian-10.tar.gz"; \
	[ ! -z ${local_url} ] && localURL=${local_url}/bitnami; \
	appUrls="${localURL:-} \
		https://downloads.bitnami.com/files/stacksmith \
		"; \
	download_pkg unpack ${appName} "${appUrls}"; \
	mv /tmp/render-template-1.0.0-0-linux-amd64-debian-10/files/common/bin/render-template /usr/local/bin/; \
	chmod +x /usr/local/bin/render-template;

# 下载并解压软件包 kafka
RUN set -eux; \
	appName="${APP_NAME}_${scala_version}-${APP_VERSION}.tgz"; \
	appKeys="0x3D296268A36FACA1B7EAF110792D43153B5B5147 \
		0x52A7EA3EECAE05B0A8306471790761798F6E35FC \
		0xBBE7232D7991050B54C8EA0ADC08637CA615D22C \
		0x3F7A1D16FA4217B1DC75E1C9FFE35B7F15DFA1BA \
		0x586EFEF859AF2DB190D84080BDB2011E173C31A2 \
		"; \
	[ ! -z ${local_url} ] && localURL=${local_url}/kafka; \
	appUrls="${localURL:-} \
		'https://www.apache.org/dyn/closer.cgi?action=download&filename='${APP_NAME}/${APP_VERSION}/ \
		https://www-us.apache.org/dist/${APP_NAME}/${APP_VERSION}/ \
		https://www.apache.org/dist/${APP_NAME}/${APP_VERSION}/ \
		https://archive.apache.org/dist/${APP_NAME}/${APP_VERSION}/ \
		"; \
	download_pkg unpack ${appName} "${appUrls}"; \
	rm -rf /tmp/${APP_NAME}_${scala_version}-${APP_VERSION}/site-docs;


# 1. 生成镜像 =====================================================================
FROM ${registry_url}/colovu/openjre:8

# 声明需要使用的全局可变参数
ARG app_name
ARG app_version
ARG registry_url
ARG apt_source
ARG local_url


ARG scala_version=2.12

# 镜像所包含应用的基础信息，定义环境变量，供后续脚本使用
ENV APP_NAME=${app_name} \
	APP_EXEC=kafka-server-start.sh \
	APP_VERSION=${app_version}

ENV	APP_HOME_DIR=/usr/local/${APP_NAME} \
	APP_DEF_DIR=/etc/${APP_NAME}

ENV PATH="${APP_HOME_DIR}/sbin:${APP_HOME_DIR}/bin:${PATH}" \
	KAFKA_HOME="${APP_HOME_DIR}"

LABEL \
	"Version"="v${APP_VERSION}" \
	"Description"="Docker image for ${APP_NAME}(v${APP_VERSION})." \
	"Dockerfile"="https://github.com/colovu/docker-${APP_NAME}" \
	"Vendor"="Endial Fang (endial@126.com)"

# 从预处理过程中拷贝软件包(Optional)
COPY --from=builder /usr/local/bin/ /usr/local/bin
COPY --from=builder /tmp/${APP_NAME}_${scala_version}-${APP_VERSION}/ /usr/local/${APP_NAME}

# 拷贝应用使用的客制化脚本，并创建对应的用户及数据存储目录
COPY customer /
RUN set -eux; \
	prepare_env; \
	/bin/bash -c "ln -sf /usr/local/${APP_NAME}/config /etc/${APP_NAME}";

# 选择软件包源(Optional)，以加速后续软件包安装
RUN select_source ${apt_source}

# 安装依赖的软件包及库(Optional)
RUN install_pkg netcat

# 执行预处理脚本，并验证安装的软件包
RUN set -eux; \
	override_file="/usr/local/overrides/overrides-${APP_VERSION}.sh"; \
	[ -e "${override_file}" ] && /bin/bash "${override_file}"; \
	:;

# 默认提供的数据卷
VOLUME ["/srv/conf", "/srv/data", "/srv/datalog", "/srv/cert", "/var/log"]

# 默认non-root用户启动，必须保证端口在1024之上
EXPOSE 9092

# 关闭基础镜像的健康检查
#HEALTHCHECK NONE

# 应用健康状态检查
#HEALTHCHECK --interval=30s --timeout=30s --retries=3 \
#	CMD curl -fs http://localhost:8080/ || exit 1
HEALTHCHECK --interval=10s --timeout=10s --retries=3 \
	CMD netstat -ltun | grep 2181

# 使用 non-root 用户运行后续的命令
USER 1001

# 设置工作目录
WORKDIR /srv/data

# 容器初始化命令
ENTRYPOINT ["/usr/local/bin/entry.sh"]

# 应用程序的启动命令，必须使用非守护进程方式运行
CMD ["/usr/local/bin/run.sh"]

