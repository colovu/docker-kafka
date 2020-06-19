#!/bin/bash -e

# Kafka 0.9.x.x has a 'listeners' config by default. We need to remove this
# as the user may be configuring via the host.name / advertised.host.name properties
echo "Process overrides for default configs..."
sed -i -E 's/^listeners=//g' "$APP_DEF_DIR/server.properties"

# 修改默认Log输出目录
sed -i -E 's/^log.dirs=\/tmp\/kafka-logs*/log.dirs=\/var\/log\/kafka/g' "$APP_DEF_DIR/server.properties"

echo "Add kafka.logs.dir to log4j.properties"
sed -i -E 's/^log4j.rootLogger=*/kafka.logs.dir=.\nlog4j.rootLogger=/g' "$APP_DEF_DIR/log4j.properties"

echo "Modify LOG_DIR defination in kafka-run-class.sh"
sed -i -E 's/LOG_DIR/APP_LOG_DIR/g' "${APP_BASE_DIR}/bin/kafka-run-class.sh"
