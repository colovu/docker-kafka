# 指定原始系统镜像，常用镜像为 colovu/ubuntu:18.04、colovu/debian:10-buster、colovu/alpine:3.11
FROM colovu/openjdk:8u242-jre

ARG kafka_version=2.5.0
ARG scala_version=2.12

ENV APP_NAME=kafka \
	APP_EXEC=kafka-server-start.sh \
	APP_USER=kafka \
	APP_GROUP=kafka \
	APP_VERSION=${kafka_version}

ENV	APP_BASE_DIR=/usr/local/${APP_NAME} \
	APP_DEF_DIR=/etc/${APP_NAME} \
	APP_CONF_DIR=/srv/conf/${APP_NAME} \
	APP_CERT_DIR=/srv/cert/${APP_NAME} \
	APP_DATA_DIR=/srv/data/${APP_NAME} \
	APP_CACHE_DIR=/var/cache/${APP_NAME} \
	APP_RUN_DIR=/var/run/${APP_NAME} \
	APP_LOG_DIR=/var/log/${APP_NAME} \
	PATH="/usr/local/bin/colovu:/usr/local/bin/app:${PATH}"

# 设置KAFKA需要的环境变量
ENV KAFKA_VERSION=${kafka_version} \
	SCALA_VERSION=${scala_version} \
	KAFKA_HOME=${APP_BASE_DIR} \
	PATH="${APP_BASE_DIR}/bin:${PATH}"

LABEL \
	"Version"="v${APP_VERSION}" \
	"Description"="Docker image for ${APP_NAME} ${APP_VERSION} (scala: ${scala_version})." \
	"Dockerfile"="https://github.com/colovu/docker-${APP_NAME}" \
	"Vendor"="Endial Fang (endial@126.com)"

COPY prebuilds /

RUN set -eux; \
# 设置程序使用静默安装，而非交互模式；类似tzdata等程序需要使用静默安装
	export DEBIAN_FRONTEND=noninteractive; \
	\
# 为应用创建对应的组、用户、相关目录
	groupadd -r ${APP_GROUP}; \
	useradd -r -g ${APP_GROUP} -s /usr/sbin/nologin -d /usr/cache/${APP_NAME} ${APP_USER}; \
	mkdir -p ${APP_DEF_DIR} ${APP_CONF_DIR} ${APP_CERT_DIR} ${APP_DATA_DIR} ${APP_CACHE_DIR} ${APP_LOG_DIR} ${APP_RUN_DIR} /usr/local/kafka; \
	\
# 安装临时使用的软件包，在使用完后会进行删除
	fetchDeps=" \
		curl \
	"; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends ${fetchDeps}; \
	\
	\
# 使用下载方式安装软件
	# export APP_URL="https://www.apache.org/dyn/closer.cgi?path=/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz&as_json=1"; \
	export APP_URL="https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz"; \
	curl --progress-bar -L -o kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz ${APP_URL}; \
	\
	tar xfz kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /usr/local/kafka --strip-components=1; \
	ln -sf /usr/local/kafka/config /etc/kafka; \
	rm kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz; \
	\
# 设置临时目录的权限信息，设置为777是为了保证后续使用`--user`或`gosu`时，可以更改目录对应的用户属性信息；运行时会被更改为700或755
	chown -Rf ${APP_USER}:${APP_GROUP} ${APP_DEF_DIR} ${APP_CONF_DIR} ${APP_CERT_DIR} ${APP_DATA_DIR} ${APP_CACHE_DIR} ${APP_LOG_DIR} ${APP_RUN_DIR}; \
	chmod 777 ${APP_DEF_DIR} ${APP_CONF_DIR} ${APP_CERT_DIR} ${APP_DATA_DIR} ${APP_CACHE_DIR} ${APP_LOG_DIR} ${APP_RUN_DIR}; \
	\
# 查找新安装的应用依赖软件包，并标识为'manual'，防止后续自动清理时被删除
	apt-mark auto '.*' > /dev/null; \
	{ [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; }; \
	find /usr/local -type f -executable -exec ldd '{}' ';' \
		| awk '/=>/ { print $(NF-1) }' \
		| sort -u \
		| xargs -r dpkg-query --search \
		| cut -d: -f1 \
		| sort -u \
		| xargs -r apt-mark manual; \
	\
# 删除安装的临时依赖软件包，清理缓存
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false ${fetchDeps}; \
	apt-get autoclean -y; \
	rm -rf /var/lib/apt/lists/*; \
	\
# 验证安装的软件是否可以正常运行，常规情况下放置在命令行的最后
	: ;


VOLUME ["/srv/conf", "/srv/data", "/var/log", "/var/run"]

# 默认使用gosu切换为新建用户启动，必须保证端口在1024之上
EXPOSE 8080

# 容器初始化命令，默认存放在：/usr/local/bin/app/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# 应用程序的服务命令，必须使用非守护进程方式运行
CMD [ "kafka-server-start.sh", "/srv/conf/kafka/server.properties" ]
