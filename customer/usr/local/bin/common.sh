#!/bin/bash
# Ver: 1.1 by Endial Fang (endial@126.com)
# 
# 应用通用业务处理函数

# 加载依赖脚本
. /usr/local/scripts/libcommon.sh       # 通用函数库

. /usr/local/scripts/libfile.sh
. /usr/local/scripts/libfs.sh
. /usr/local/scripts/liblog.sh
. /usr/local/scripts/libos.sh
. /usr/local/scripts/libservice.sh
. /usr/local/scripts/libvalidations.sh

# 函数列表

# 为全局变量创建一个化名(alias)变量
# 参数:
#   $1 - 化名变量名
#   $2 - 原始变量名
kafka_declare_alias_env() {
    local -r alias="${1:?missing environment variable alias}"
    local -r original="${2:?missing original environment variable}"
    if printenv "${original}" > /dev/null; then
        export "$alias"="${!original:-}"
    fi
}

# 为 Kafka 容器全局变量创建新的化名变量，方便配置文件直接使用
# 全局变量:
#   KAFKA_*
kafka_create_alias_environment_variables() {
    suffixes=(
        "ADVERTISED_LISTENERS"
        "AUTO_CREATE_TOPICS_ENABLE"
        "BROKER_ID"
        "DEFAULT_REPLICATION_FACTOR"
        "DELETE_TOPIC_ENABLE"
        "GROUP_INITIAL_REBALANCE_DELAY_MS"
        "INTER_BROKER_LISTENER_NAME"
        "LISTENERS"
        "LISTENER_SECURITY_PROTOCOL_MAP"
        "LOG_DIRS"
        "LOG_FLUSH_INTERVAL_MESSAGES"
        "LOG_FLUSH_INTERVAL_MS"
        "LOG_MESSAGE_FORMAT_VERSION"
        "LOG_RETENTION_BYTES"
        "LOG_RETENTION_CHECK_INTERVALS_MS"
        "LOG_RETENTION_HOURS"
        "LOG_SEGMENT_BYTES"
        "MESSAGE_MAX_BYTES"
        "NUM_IO_THREADS"
        "NUM_NETWORK_THREADS"
        "NUM_PARTITIONS"
        "NUM_RECOVERY_THREADS_PER_DATA_DIR"
        "OFFSETS_TOPIC_REPLICATION_FACTOR"
        "SOCKET_RECEIVE_BUFFER_BYTES"
        "SOCKET_REQUEST_MAX_BYTES"
        "SOCKET_SEND_BUFFER_BYTES"
        "SSL_ENDPOINT_IDENTIFICATION_ALGORITHM"
        "TRANSACTION_STATE_LOG_MIN_ISR"
        "TRANSACTION_STATE_LOG_REPLICATION_FACTOR"
        "ZOOKEEPER_CONNECT"
        "ZOOKEEPER_CONNECTION_TIMEOUT_MS"
    )
    for s in "${suffixes[@]}"; do
        kafka_declare_alias_env "KAFKA_CFG_${s}" "KAFKA_${s}"
    done
}

# 将变量配置更新至配置文件
# 参数:
#   $1 - 文件
#   $2 - 变量
#   $3 - 值（列表）
kafka_common_conf_set() {
    local file="${1:?missing file}"
    local key="${2:?missing key}"
    shift
    shift
    local values=("$@")

    if [[ "${#values[@]}" -eq 0 ]]; then
        LOG_E "missing value"
        return 1
    elif [[ "${#values[@]}" -ne 1 ]]; then
        for i in "${!values[@]}"; do
            kafka_common_conf_set "$file" "${key[$i]}" "${values[$i]}"
        done
    else
        value="${values[0]}"
        # Check if the value was set before
        if grep -q "^[#\\s]*$key\s*=.*" "$file"; then
            # Update the existing key
            replace_in_file "$file" "^[#\\s]*${key}\s*=.*" "${key}=${value}" false
        else
            # 增加一个新的配置项；如果在其他位置有类似操作，需要注意换行
            printf "\n%s=%s" "$key" "$value" >>"$file"
        fi
    fi
}

# 更新 log4j.properties 配置文件中指定变量值
# 变量:
#   $1 - 变量
#   $2 - 值（列表）
kafka_log4j_set() {
    kafka_common_conf_set "${APP_CONF_DIR}/log4j.properties" "$@"
}

# 更新 server.properties 配置文件中指定变量值
# 变量:
#   $1 - 变量
#   $2 - 值（列表）
kafka_server_conf_set() {
    kafka_common_conf_set "${APP_CONF_DIR}/server.properties" "$@"
}

# 更新 producer.properties 及 consumer.properties 配置文件中指定变量值
# 变量:
#   $1 - 变量
#   $2 - 值（列表）
kafka_producer_consumer_conf_set() {
    kafka_common_conf_set "${APP_CONF_DIR}/producer.properties" "$@"
    kafka_common_conf_set "${APP_CONF_DIR}/consumer.properties" "$@"
}

# 设置环境变量 JVMFLAGS
# 参数:
#   $1 - value
kafka_export_jvmflags() {
    local -r value="${1:?value is required}"

    export JVMFLAGS="${JVMFLAGS} ${value}"
    echo "export JVMFLAGS=\"${JVMFLAGS}\"" > "${APP_CONF_DIR}/java.env"
}

# 配置 HEAP 大小
# 参数:
#   $1 - HEAP 大小
kafka_configure_heap_size() {
    local -r heap_size="${1:?heap_size is required}"

    if [[ "${JVMFLAGS}" =~ -Xm[xs].*-Xm[xs] ]]; then
        LOG_D "Using specified values (JVMFLAGS=${JVMFLAGS})"
    else
        LOG_D "Setting '-Xmx${heap_size}m -Xms${heap_size}m' heap options..."
        kafka_export_jvmflags "-Xmx${heap_size}m -Xms${heap_size}m"
    fi
}

# 生成 JAAS 认证文件
kafka_generate_jaas_authentication_file() {
    local -r internal_protocol="${1:-}"
    local -r client_protocol="${2:-}"

    if [[ ! -f "${APP_CONF_DIR}/kafka_jaas.conf" ]]; then
        LOG_I "Generating JAAS authentication file"
        if [[ "${client_protocol:-}" =~ SASL ]]; then
            cat >> "${APP_CONF_DIR}/kafka_jaas.conf" <<EOF
KafkaClient {
   org.apache.kafka.common.security.plain.PlainLoginModule required
   username="${KAFKA_CLIENT_USER:-}"
   password="${KAFKA_CLIENT_PASSWORD:-}";
   };
EOF
        fi
        if [[ "${client_protocol:-}" =~ SASL ]] && [[ "${internal_protocol:-}" =~ SASL ]]; then
            cat >> "${APP_CONF_DIR}/kafka_jaas.conf" <<EOF
KafkaServer {
   org.apache.kafka.common.security.plain.PlainLoginModule required
   username="${KAFKA_INTER_BROKER_USER:-}"
   password="${KAFKA_INTER_BROKER_PASSWORD:-}"
   user_${KAFKA_INTER_BROKER_USER:-}="${KAFKA_INTER_BROKER_PASSWORD:-}"
   user_${KAFKA_CLIENT_USER:-}="${KAFKA_CLIENT_PASSWORD:-}";

   org.apache.kafka.common.security.scram.ScramLoginModule required;
   };
EOF
        elif [[ "${client_protocol:-}" =~ SASL ]]; then
            cat >> "${APP_CONF_DIR}/kafka_jaas.conf" <<EOF
KafkaServer {
   org.apache.kafka.common.security.plain.PlainLoginModule required
   user_${KAFKA_CLIENT_USER:-}="${KAFKA_CLIENT_PASSWORD:-}";

   org.apache.kafka.common.security.scram.ScramLoginModule required;
   };
EOF
        elif [[ "${internal_protocol:-}" =~ SASL ]]; then
            cat >> "${APP_CONF_DIR}/kafka_jaas.conf" <<EOF
KafkaServer {
   org.apache.kafka.common.security.plain.PlainLoginModule required
   username="${KAFKA_INTER_BROKER_USER:-}"
   password="${KAFKA_INTER_BROKER_PASSWORD:-}"
   user_${KAFKA_INTER_BROKER_USER:-}="${KAFKA_INTER_BROKER_PASSWORD:-}";

   org.apache.kafka.common.security.scram.ScramLoginModule required;
   };
EOF
        fi
        if [[ -n "$KAFKA_ZOOKEEPER_USER" ]] && [[ -n "$KAFKA_ZOOKEEPER_PASSWORD" ]]; then
            cat >> "${APP_CONF_DIR}/kafka_jaas.conf" <<EOF
Client {
   org.apache.kafka.common.security.plain.PlainLoginModule required
   username="${KAFKA_ZOOKEEPER_USER:-}"
   password="${KAFKA_ZOOKEEPER_PASSWORD:-}";
   };
EOF
        fi
    else
        LOG_I "Custom JAAS authentication file detected. Skipping generation."
        LOG_W "The following environment variables will be ignored: KAFKA_CLIENT_USER, KAFKA_CLIENT_PASSWORD, KAFKA_INTER_BROKER_USER, KAFKA_INTER_BROKER_PASSWORD, KAFKA_ZOOKEEPER_USER and KAFKA_ZOOKEEPER_PASSWORD"
    fi
}

# 配置 Kafka SSL 参数
kafka_configure_ssl() {
    # Set Kafka configuration
    kafka_server_conf_set ssl.keystore.location "$APP_CERT_DIR/KAFKA_KEYSTORE_FILE"
    kafka_server_conf_set ssl.keystore.password "$KAFKA_CERTIFICATE_PASSWORD"
    kafka_server_conf_set ssl.truststore.location "$APP_CERT_DIR/$KAFKA_TRUSTSTORE_FILE"
    kafka_server_conf_set ssl.truststore.password "$KAFKA_CERTIFICATE_PASSWORD"
    kafka_server_conf_set ssl.key.password "$KAFKA_CERTIFICATE_PASSWORD"
    # Set producer/consumer configuration
    kafka_producer_consumer_conf_set ssl.keystore.location "$APP_CERT_DIR/$KAFKA_KEYSTORE_FILE"
    kafka_producer_consumer_conf_set ssl.keystore.password "$KAFKA_CERTIFICATE_PASSWORD"
    kafka_producer_consumer_conf_set ssl.truststore.location "$APP_CERT_DIR/$KAFKA_TRUSTSTORE_FILE"
    kafka_producer_consumer_conf_set ssl.truststore.password "$KAFKA_CERTIFICATE_PASSWORD"
    kafka_producer_consumer_conf_set ssl.key.password "$KAFKA_CERTIFICATE_PASSWORD"
}

# 为 Kafka 配置 broker 内部监听器通讯参数
# 参数:
#   $1 - 内部监听器使用的协议
kafka_configure_internal_communications() {
    local -r protocol="${1:?missing environment variable protocol}"
    local -r allowed_protocols=("PLAINTEXT" "SASL_PLAINTEXT" "SASL_SSL" "SSL")
    LOG_I "Configuring Kafka for inter-broker communications with ${protocol} authentication."

    if [[ "${allowed_protocols[*]}" =~ $protocol ]]; then
        kafka_server_conf_set security.inter.broker.protocol "$protocol"
        if [[ "$protocol" = "PLAINTEXT" ]]; then
            LOG_W "Inter-broker communications are configured as PLAINTEXT. This is not safe for production environments."
        fi
        if [[ "$protocol" = "SASL_PLAINTEXT" ]] || [[ "$protocol" = "SASL_SSL" ]]; then
            # The below lines would need to be updated to support other SASL implementations (i.e. GSSAPI)
            # IMPORTANT: Do not confuse SASL/PLAIN with PLAINTEXT
            # For more information, see: https://docs.confluent.io/current/kafka/authentication_sasl/authentication_sasl_plain.html#sasl-plain-overview)
            kafka_server_conf_set sasl.mechanism.inter.broker.protocol PLAIN
        fi
        if [[ "$protocol" = "SASL_SSL" ]] || [[ "$protocol" = "SSL" ]]; then
            kafka_configure_ssl
            # We need to enable 2 way authentication on SASL_SSL so brokers authenticate each other.
            # It won't affect client communications unless the SSL protocol is for them.
            kafka_server_conf_set ssl.client.auth required
        fi
    else
        LOG_E "Authentication protocol ${protocol} is not supported!"
        exit 1
    fi
}

# 为 Kafka 配置客户端通讯参数
# 参数:
#   $1 - 客户端监听器使用的协议
kafka_configure_client_communications() {
    local -r protocol="${1:?missing environment variable protocol}"
    local -r allowed_protocols=("PLAINTEXT" "SASL_PLAINTEXT" "SASL_SSL" "SSL")
    LOG_I "Configuring Kafka for client communications with ${protocol} authentication."

    if [[ "${allowed_protocols[*]}" =~ ${protocol} ]]; then
        kafka_server_conf_set security.inter.broker.protocol "$protocol"
        kafka_producer_consumer_conf_set security.protocol "$protocol"
        if [[ "$protocol" = "PLAINTEXT" ]]; then
            LOG_W "Client communications are configured using PLAINTEXT listeners. For safety reasons, do not use this in a production environment."
        fi
        if [[ "$protocol" = "SASL_PLAINTEXT" ]] || [[ "$protocol" = "SASL_SSL" ]]; then
            # The below lines would need to be updated to support other SASL implementations (i.e. GSSAPI)
            # IMPORTANT: Do not confuse SASL/PLAIN with PLAINTEXT
            # For more information, see: https://docs.confluent.io/current/kafka/authentication_sasl/authentication_sasl_plain.html#sasl-plain-overview)
            kafka_server_conf_set sasl.mechanism.inter.broker.protocol PLAIN
            kafka_producer_consumer_conf_set sasl.mechanism PLAIN
        fi
        if [[ "$protocol" = "SASL_SSL" ]] || [[ "$protocol" = "SSL" ]]; then
            kafka_configure_ssl
        fi
        if [[ "$protocol" = "SSL" ]]; then
            kafka_server_conf_set ssl.client.auth required
        fi
    else
        LOG_E "Authentication protocol ${protocol} is not supported!"
        exit 1
    fi
}

# 使用环境变量中的配置值更新配置文件
kafka_configure_from_environment_variables() {
    # Map environment variables to config properties
    for var in "${!KAFKA_CFG_@}"; do
        key="$(echo "$var" | sed -e 's/^KAFKA_CFG_//g' -e 's/_/\./g' | tr '[:upper:]' '[:lower:]')"
        value="${!var}"
        kafka_server_conf_set "$key" "$value"
    done
}

# 检测用户参数信息是否满足条件; 针对部分权限过于开放情况，打印提示信息
kafka_verify_minimum_env() {
    local error_code=0

    LOG_D "Validating settings in KAFKA_* env vars..."

    print_validation_error() {
        LOG_E "$1"
        error_code=1
    }

    local internal_port
    local client_port
    check_allowed_listener_port() {
        local -r total="$#"
        for i in $(seq 1 "$((total - 1))"); do
            for j in $(seq "$((i + 1))" "$total"); do
                if (( "${!i}" == "${!j}" )); then
                    print_validation_error "There are listeners bound to the same port"
                fi
            done
        done
    }
    check_conflicting_listener_ports() {
        local validate_port_args=()
        ! is_root && validate_port_args+=("-unprivileged")
        if ! err=$(validate_port "${validate_port_args[@]}" "$1"); then
            print_validation_error "An invalid port was specified in the environment variable KAFKA_CFG_LISTENERS: $err"
        fi
    }

    if [[ ${KAFKA_CFG_LISTENERS:-} =~ INTERNAL://:([0-9]*) ]]; then
        internal_port="${BASH_REMATCH[1]}"
        check_allowed_listener_port "$internal_port"
    fi
    if [[ ${KAFKA_CFG_LISTENERS:-} =~ CLIENT://:([0-9]*) ]]; then
        client_port="${BASH_REMATCH[1]}"
        check_allowed_listener_port "$client_port"
    fi
    [[ -n ${internal_port:-} && -n ${client_port:-} ]] && check_conflicting_listener_ports "$internal_port" "$client_port"
    if [[ -n "${KAFKA_PORT_NUMBER:-}" ]] || [[ -n "${KAFKA_CFG_PORT:-}" ]]; then
        LOG_W "The environment variables KAFKA_PORT_NUMBER and KAFKA_CFG_PORT are deprecated, you can specify the port number to use for each listener using the KAFKA_CFG_LISTENERS environment variable instead."
    fi

    if is_boolean_yes "$ALLOW_PLAINTEXT_LISTENER"; then
        LOG_W "You have set the environment variable ALLOW_PLAINTEXT_LISTENER=$ALLOW_PLAINTEXT_LISTENER. For safety reasons, do not use this flag in a production environment."
    fi
    if [[ "${KAFKA_CFG_LISTENERS:-}" =~ SSL ]] || [[ "${KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP:-}" =~ SSL ]]; then
        # DEPRECATED. Check for jks files in old conf directory to maintain compatibility with Helm chart.
        if ([[ ! -f "$APP_CERT_DIR/$KAFKA_KEYSTORE_FILE" ]] || [[ ! -f "$APP_CERT_DIR/$KAFKA_TRUSTSTORE_FILE" ]]) \
            && ([[ ! -f "$APP_CERT_DIR/$KAFKA_KEYSTORE_FILE" ]] || [[ ! -f "$APP_CERT_DIR/$KAFKA_TRUSTSTORE_FILE" ]]); then
            print_validation_error "In order to configure the TLS encryption for Kafka you must mount your kafka.keystore.jks and kafka.truststore.jks certificates to the ${APP_CERT_DIR} directory."
        fi
    elif [[ "${KAFKA_CFG_LISTENERS:-}" =~ SASL ]] || [[ "${KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP:-}" =~ SASL ]]; then
        if [[ -z "$KAFKA_CLIENT_PASSWORD" ]] && [[ -z "$KAFKA_INTER_BROKER_PASSWORD" ]]; then
            print_validation_error "In order to configure SASL authentication for Kafka, you must provide the SASL credentials. Set the environment variables KAFKA_CLIENT_USER and KAFKA_CLIENT_PASSWORD, to configure the credentials for SASL authentication with clients, or set the environment variables KAFKA_INTER_BROKER_USER and KAFKA_INTER_BROKER_PASSWORD, to configure the credentials for SASL authentication between brokers."
        fi
    elif ! is_boolean_yes "$ALLOW_PLAINTEXT_LISTENER"; then
        print_validation_error "The KAFKA_CFG_LISTENERS environment variable does not configure a secure listener. Set the environment variable ALLOW_PLAINTEXT_LISTENER=yes to allow the container to be started with a plaintext listener. This is only recommended for development."
    fi

    [[ "$error_code" -eq 0 ]] || exit "$error_code"
}

# 更改默认监听地址为 "*" 或 "0.0.0.0"，以对容器外提供服务；默认配置文件应当为仅监听 localhost(127.0.0.1)
kafka_enable_remote_connections() {
    LOG_D "Modify default config to enable all IP access"
	
}

# 以后台方式启动应用服务，并等待启动就绪
kafka_start_server_bg() {
    kafka_is_server_running && return
    LOG_I "Starting ${APP_NAME} in background..."

	# 使用内置脚本启动服务
    #local start_command="zkServer.sh start"
    #if is_boolean_yes "${ENV_DEBUG}"; then
    #    $start_command &
    #else
    #    $start_command >/dev/null 2>&1 &
    #fi
	
	# 使用内置命令启动服务
	# if [[ "${ENV_DEBUG:-false}" = true ]]; then
    #    debug_execute "rabbitmq-server" &
    #else
    #    debug_execute "rabbitmq-server" >/dev/null 2>&1 &
    #fi

	# 通过命令或特定端口检测应用是否就绪
    LOG_I "Checking ${APP_NAME} ready status..."
    # wait-for-port --timeout 60 "$ZOO_PORT_NUMBER"

    LOG_D "${APP_NAME} is ready for service..."
}

# 停止应用服务
kafka_stop_server() {
    kafka_is_server_running || return
    LOG_I "Stopping ${APP_NAME}..."
    
    # 使用 PID 文件 kill 进程
    stop_service_using_pid "$APP_PID_FILE"

	# 使用内置命令停止服务
    #debug_execute "rabbitmqctl" stop

    # 使用内置脚本关闭服务
    #if [[ "$ENV_DEBUG" = true ]]; then
    #    "zkServer.sh" stop
    #else
    #    "zkServer.sh" stop >/dev/null 2>&1
    #fi

	# 检测停止是否完成
	local counter=10
    while [[ "$counter" -ne 0 ]] && kafka_is_server_running; do
        LOG_D "Waiting for ${APP_NAME} to stop..."
        sleep 1
        counter=$((counter - 1))
    done
}

# 检测应用服务是否在后台运行中
kafka_is_server_running() {
    LOG_D "Check if ${APP_NAME} is running..."
    local pid
    pid="$(get_pid_from_file "${APP_PID_FILE}")"

    if [[ -z "${pid}" ]]; then
        false
    else
        is_service_running "${pid}"
    fi
}

kafka_is_server_not_running() {
    ! kafka_is_server_running
}

# 清理初始化应用时生成的临时文件
kafka_clean_tmp_file() {
    LOG_D "Clean ${APP_NAME} tmp files for init..."

}

# 在重新启动容器时，删除标志文件及必须删除的临时文件 (容器重新启动)
kafka_clean_from_restart() {
    LOG_D "Clean ${APP_NAME} tmp files for restart..."
    local -r -a files=(
        "/var/run/${APP_NAME}/${APP_NAME}.pid"
    )

    for file in ${files[@]}; do
        if [[ -f "$file" ]]; then
            LOG_I "Cleaning stale $file file"
            rm "$file"
        fi
    done
}

# 应用默认初始化操作
# 执行完毕后，生成文件 ${APP_CONF_DIR}/.app_init_flag 及 ${APP_DATA_DIR}/.data_init_flag 文件
kafka_default_init() {
	kafka_clean_from_restart
    LOG_D "Check init status of ${APP_NAME}..."

    # 检测配置文件是否存在
    if [[ ! -f "${APP_CONF_DIR}/.app_init_flag" ]]; then
        LOG_I "No injected configuration file found, creating default config files..."

        kafka_server_conf_set "log.dirs" "${KAFKA_LOG_DIRS}"
        kafka_log4j_set "kafka.logs.dir" "${APP_LOG_DIR}"

        #export LOG_DIR=${APP_LOG_DIR}
        kafka_configure_from_environment_variables
        #kafka_configure_heap_size "$HEAP_SIZE"

        # 当配置 Kafka 为有多个 broker 的集群时，有以下几种监听器：
        # - INTERNAL: 用于 broker 内通讯
        # - CLIENT: 用于与在同一网络中的 消费者/生产者 通讯
        # - (optional) EXTERNAL: 用于与在不同网络中的 消费者/生产者 通讯
        local internal_protocol
        local client_protocol
        if [[ "${KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP:-}" = *"INTERNAL"* ]] || [[ "${KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP:-}" = *"CLIENT"* ]]; then
            if [[ ${KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP:-} =~ INTERNAL:([a-zA-Z_]*) ]]; then
                internal_protocol="${BASH_REMATCH[1]}"
                kafka_configure_internal_communications "$internal_protocol"
            fi
            if [[ ${KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP:-} =~ CLIENT:([a-zA-Z_]*) ]]; then
                client_protocol="${BASH_REMATCH[1]}"
                kafka_configure_client_communications "$client_protocol"
            fi
        fi
        if [[ "${internal_protocol:-}" =~ SASL ]] || [[ "${client_protocol:-}" =~ SASL ]] || [[ -n "$KAFKA_ZOOKEEPER_USER" && -n "$KAFKA_ZOOKEEPER_PASSWORD" ]]; then
            kafka_server_conf_set sasl.enabled.mechanisms PLAIN,SCRAM-SHA-256,SCRAM-SHA-512
            kafka_generate_jaas_authentication_file "${internal_protocol:-}" "${client_protocol:-}"
        fi
        # Remove security.inter.broker.protocol if KAFKA_CFG_INTER_BROKER_LISTENER_NAME is configured
        if [[ -n "${KAFKA_CFG_INTER_BROKER_LISTENER_NAME:-}" ]]; then
            remove_in_file "$APP_CONF_FILE" "security.inter.broker.protocol" false
        fi

        touch ${APP_CONF_DIR}/.app_init_flag
        echo "$(date '+%Y-%m-%d %H:%M:%S') : Init success." >> ${APP_CONF_DIR}/.app_init_flag
    else
        LOG_I "User injected custom configuration detected!"
    fi

    if [[ ! -f "${APP_DATA_DIR}/.data_init_flag" ]]; then
        LOG_I "Deploying ${APP_NAME} from scratch..."

		# 检测服务是否运行中如果未运行，则启动后台服务
        kafka_is_server_running || kafka_start_server_bg

        # TODO: 根据需要生成相应初始化数据

        touch ${APP_DATA_DIR}/.data_init_flag
        echo "$(date '+%Y-%m-%d %H:%M:%S') : Init success." >> ${APP_DATA_DIR}/.data_init_flag
    else
        LOG_I "Deploying ${APP_NAME} with persisted data..."
    fi
}

# 用户自定义的前置初始化操作，依次执行目录 preinitdb.d 中的初始化脚本
# 执行完毕后，生成文件 ${APP_DATA_DIR}/.custom_preinit_flag
kafka_custom_preinit() {
    LOG_D "Check custom pre-init status of ${APP_NAME}..."

    # 检测用户配置文件目录是否存在 preinitdb.d 文件夹，如果存在，尝试执行目录中的初始化脚本
    if [ -d "/srv/conf/${APP_NAME}/preinitdb.d" ]; then
        # 检测数据存储目录是否存在已初始化标志文件；如果不存在，检索可执行脚本文件并进行初始化操作
        if [[ -n $(find "/srv/conf/${APP_NAME}/preinitdb.d/" -type f -regex ".*\.\(sh\)") ]] && \
            [[ ! -f "${APP_DATA_DIR}/.custom_preinit_flag" ]]; then
            LOG_I "Process custom pre-init scripts from /srv/conf/${APP_NAME}/preinitdb.d..."

            # 检索所有可执行脚本，排序后执行
            find "/srv/conf/${APP_NAME}/preinitdb.d/" -type f -regex ".*\.\(sh\)" | sort | process_init_files

            touch ${APP_DATA_DIR}/.custom_preinit_flag
            echo "$(date '+%Y-%m-%d %H:%M:%S') : Init success." >> ${APP_DATA_DIR}/.custom_preinit_flag
            LOG_I "Custom preinit for ${APP_NAME} complete."
        else
            LOG_I "Custom preinit for ${APP_NAME} already done before, skipping initialization."
        fi
    fi

    # 检测依赖的服务是否就绪
    #for i in ${SERVICE_PRECONDITION[@]}; do
    #    app_wait_service "${i}"
    #done
}

# 用户自定义的应用初始化操作，依次执行目录initdb.d中的初始化脚本
# 执行完毕后，生成文件 ${APP_DATA_DIR}/.custom_init_flag
kafka_custom_init() {
    LOG_D "Check custom init status of ${APP_NAME}..."

    # 检测用户配置文件目录是否存在 initdb.d 文件夹，如果存在，尝试执行目录中的初始化脚本
    if [ -d "/srv/conf/${APP_NAME}/initdb.d" ]; then
    	# 检测数据存储目录是否存在已初始化标志文件；如果不存在，检索可执行脚本文件并进行初始化操作
    	if [[ -n $(find "/srv/conf/${APP_NAME}/initdb.d/" -type f -regex ".*\.\(sh\|sql\|sql.gz\)") ]] && \
            [[ ! -f "${APP_DATA_DIR}/.custom_init_flag" ]]; then
            LOG_I "Process custom init scripts from /srv/conf/${APP_NAME}/initdb.d..."

            # 检测服务是否运行中；如果未运行，则启动后台服务
            kafka_is_server_running || kafka_start_server_bg

            # 检索所有可执行脚本，排序后执行
    		find "/srv/conf/${APP_NAME}/initdb.d/" -type f -regex ".*\.\(sh\|sql\|sql.gz\)" | sort | while read -r f; do
                case "$f" in
                    *.sh)
                        if [[ -x "$f" ]]; then
                            LOG_D "Executing $f"; "$f"
                        else
                            LOG_D "Sourcing $f"; . "$f"
                        fi
                        ;;
                    #*.sql)    LOG_D "Executing $f"; postgresql_execute "$PG_DATABASE" "$PG_INITSCRIPTS_USERNAME" "$PG_INITSCRIPTS_PASSWORD" < "$f";;
                    #*.sql.gz) LOG_D "Executing $f"; gunzip -c "$f" | postgresql_execute "$PG_DATABASE" "$PG_INITSCRIPTS_USERNAME" "$PG_INITSCRIPTS_PASSWORD";;
                    *)        LOG_D "Ignoring $f" ;;
                esac
            done

            touch ${APP_DATA_DIR}/.custom_init_flag
    		echo "$(date '+%Y-%m-%d %H:%M:%S') : Init success." >> ${APP_DATA_DIR}/.custom_init_flag
    		LOG_I "Custom init for ${APP_NAME} complete."
    	else
    		LOG_I "Custom init for ${APP_NAME} already done before, skipping initialization."
    	fi
    fi

    # 检测服务是否运行中；如果运行，则停止后台服务
	kafka_is_server_running && kafka_stop_server

    # 删除第一次运行生成的临时文件
    kafka_clean_tmp_file

	# 绑定所有 IP ，启用远程访问
    kafka_enable_remote_connections
}

