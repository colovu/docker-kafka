# Ver: 1.2 by Endial Fang (endial@126.com)
#

# 预处理 =========================================================================
FROM colovu/abuilder as builder

# sources.list 可使用版本：default / tencent / ustc / aliyun / huawei
ARG apt_source=default

# 编译镜像时指定用于加速的本地服务器地址
ARG local_url=""

ARG scala_version=2.12

ENV APP_NAME=kafka \
	APP_VERSION=2.5.0

WORKDIR /usr/local

RUN select_source ${apt_source};
#RUN install_pkg xz-utils

# 下载并解压软件包
RUN set -eux; \
	appName="render-template-1.0.0-0-linux-amd64-debian-10.tar.gz"; \
	[ ! -z ${local_url} ] && localURL=${local_url}/bitnami; \
	appUrls="${localURL:-} \
		https://downloads.bitnami.com/files/stacksmith \
		"; \
	download_pkg unpack ${appName} "${appUrls}"; \
	mv /usr/local/render-template-1.0.0-0-linux-amd64-debian-10/files/common/bin/render-template /usr/local/bin/; \
	chmod +x /usr/local/bin/render-template;

# 下载并解压软件包
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
	download_pkg unpack ${appName} "${appUrls}";

# 镜像生成 ========================================================================
FROM colovu/openjre:1.8

ARG apt_source=default
ARG local_url=""

ARG scala_version=2.12

ENV APP_NAME=kafka \
	APP_USER=kafka \
	APP_EXEC=kafka-server-start.sh \
	APP_VERSION=2.5.0

ENV	APP_HOME_DIR=/usr/local/${APP_NAME} \
	APP_DEF_DIR=/etc/${APP_NAME} \
	APP_CONF_DIR=/srv/conf/${APP_NAME} \
	APP_DATA_DIR=/srv/data/${APP_NAME} \
	APP_DATA_LOG_DIR=/srv/datalog/${APP_NAME} \
	APP_CACHE_DIR=/var/cache/${APP_NAME} \
	APP_RUN_DIR=/var/run/${APP_NAME} \
	APP_LOG_DIR=/var/log/${APP_NAME} \
	APP_CERT_DIR=/srv/cert/${APP_NAME}

ENV 	PATH="${APP_HOME_DIR}/bin:${PATH}" \
	KAFKA_HOME="${APP_HOME_DIR}"

LABEL \
	"Version"="v${APP_VERSION}" \
	"Description"="Docker image for ${APP_NAME}(v${APP_VERSION})." \
	"Dockerfile"="https://github.com/colovu/docker-${APP_NAME}" \
	"Vendor"="Endial Fang (endial@126.com)"

COPY customer /

# 以包管理方式安装软件包(Optional)
RUN select_source ${apt_source}
#RUN install_pkg bash tini sudo libssl1.1

RUN create_user && prepare_env

# 从预处理过程中拷贝软件包(Optional)
COPY --from=builder /usr/local/bin/ /usr/local/bin
COPY --from=builder /usr/local/${APP_NAME}_${scala_version}-${APP_VERSION}/ /usr/local/${APP_NAME}
COPY --from=builder /usr/local/${APP_NAME}_${scala_version}-${APP_VERSION}/config/ /etc/${APP_NAME}

# 执行预处理脚本，并验证安装的软件包
RUN set -eux; \
	override_file="/usr/local/overrides/overrides-${APP_VERSION}.sh"; \
	[ -e "${override_file}" ] && /bin/bash "${override_file}"; \
	:;

# 默认提供的数据卷
VOLUME ["/srv/conf", "/srv/data", "/srv/datalog", "/srv/cert", "/var/log"]

# 默认使用gosu切换为新建用户启动，必须保证端口在1024之上
EXPOSE 9092

# 容器初始化命令，默认存放在：/usr/local/bin/entry.sh
ENTRYPOINT ["entry.sh"]

# 应用程序的服务命令，必须使用非守护进程方式运行。如果使用变量，则该变量必须在运行环境中存在（ENV可以获取）
CMD [ "${APP_EXEC}", "${APP_CONF_FILE}" ]

