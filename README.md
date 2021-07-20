# Kafka

针对 [Kafka](https://kafka.apache.org/) 应用的 Docker 镜像，用于提供 Kafka 服务。

详细信息可参照：[官方文档](https://kafka.apache.org/documentation)

![logo](img/kafka-logo.png)

**版本信息**：

- 2.5（Scala 2.12）、latest 
- 2.4（Scala 2.12）
- 2.3（Scala 2.12）

**镜像信息**

* 镜像地址：
  - Aliyun仓库：registry.cn-shenzhen.aliyuncs.com/colovu/kafka:latest
  - DockerHub：colovu/kafka:latest
  * 依赖镜像：colovu/openjre:8

> 后续相关命令行默认使用`[Docker Hub](https://hub.docker.com)`镜像服务器做说明



## TL;DR

Docker 快速启动命令：

```shell
$ docker run -d colovu/kafka:latest
```

Docker-Compose 快速启动命令：

```shell
# 从 Gitee 下载 Compose 文件
$ curl -sSL -o https://gitee.com/colovu/docker-kafka/raw/master/docker-compose.yml

# 从 Github 下载 Compose 文件
$ curl -sSL -o https://raw.githubusercontent.com/colovu/docker-kafka/master/docker-compose.yml

# 创建并启动容器
$ docker-compose up -d
```



---



## 默认对外声明

### 端口

- 9092：Kafka 业务客户端访问端口

### 数据卷

镜像默认提供以下数据卷定义，默认数据分别存储在自动生成的应用名对应`kafka`子目录中：

```shell
/var/log                # 日志输出，应用日志输出，非数据日志输出
/srv/conf               # 配置文件
/srv/cert               # 证书文件目录
/srv/datalog            # 数据操作日志文件
```

如果需要持久化存储相应数据，需要**在宿主机建立本地目录**，并在使用镜像初始化容器时进行映射。宿主机相关的目录中如果不存在对应应用 Kafka 的子目录或相应数据文件，则容器会在初始化时创建相应目录及文件。



## 容器配置

在初始化 Kafka 容器时，如果配置文件不存在，可以在命令行中使用相应参数对默认参数进行修改。类似命令如下：

```shell
$ docker run -d -e "KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181" --name kafka1 colovu/kafka:latest
```



### 常规配置参数

常使用的环境变量主要包括：

- **KAFKA_ZOOKEEPER_CONNECT**：默认值：**localhost:2181**。设置 Zookeeper 链接地址。可以为多个 Zookeeper 服务器地址，使用逗号分隔
- **KAFKA_ZOOKEEPER_USER**：默认值：**无**。设置 Zookeeper 链接用户名，根据实际情况设置
- **KAFKA_ZOOKEEPER_PASSWORD**：默认值：**无**。设置 Zookeeper 链接用户密码，根据实际情况设置
- **KAFKA_ZOOKEEPER_CONNECTION_TIMEOUT_MS**：默认值：**6000**。设置 Zookeeper 链接超时时间



- **KAFKA_LISTENERS**：默认值：**INTERNAL://:9092**。设置默认的监听器
- **KAFKA_ADVERTISED_LISTENERS**：默认值：**INTERNAL://:9092**。设置发布 Broker 信息至 Zookeeper 的监听器
- **KAFKA_LISTENER_SECURITY_PROTOCOL_MAP**：默认值：**INTERNAL:PLAINTEXT,CLIENT:PLAINTEXT**。设置监听器加密方式。

> 以 Key/Value 形式配置的：
>
> - Key 为 Listener 的名称
> - Value 取值范围为：PLAINTEXT、SSL、SASL_PLAINTEXT、SASL_SSL

- **KAFKA_AUTO_CREATE_TOPICS_ENABLE**：默认值：**true**。设置是否自动创建 Topics
- **ALLOW_PLAINTEXT_LISTENER**：默认值：**no**。设置是否允许匿名登录
- **KAFKA_CLIENT_USER**：默认值：**colovu**。设置客户端访问用户名
- **KAFKA_CLIENT_PASSWORD**：默认值：**pas4colovu**。设置客户端访问用户密码
- **KAFKA_INTER_BROKER_USER**:默认值：**colovu**。设置内部 broker 访问用户名
- **KAFKA_INTER_BROKER_PASSWORD**:默认值：**pas4colovu**。设置内部 broker 访问用户密码
- **ENV_DEBUG**：默认值：**false**。设置是否输出容器调试信息。可设置为：1、true、yes



### 可选配置参数

如果没有必要，可选配置参数可以不用定义，直接使用对应的默认值，主要包括：

- **KAFKA_PORT**：默认值：**9092**。设置服务默认的客户端访问端口
- **KAFKA_SOCKET_SEND_BUFFER_BYTES**：默认值：**102400**。设置 Socket 发送缓存大小
- **KAFKA_SOCKET_RECEIVE_BUFFER_BYTES**：默认值：**102400**。设置 Socket 接收缓存大小
- **KAFKA_SOCKET_REQUEST_MAX_BYTES**：默认值：**104857600**。设置 Socket 请求的最大字节数
- **KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR**：默认值：**1**
- **KAFKA_TRANSACTION_STATE_LOG_MIN_ISR**：默认值：**1**
- **KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR**：默认值：**1**
- **KAFKA_NUM_PARTITIONS**：默认值：**1**
- **KAFKA_NUM_RECOVERY_THREADS_PER_DATA_DIR**：默认值：**1**
- **KAFKA_NUM_NETWORK_THREADS**：默认值：**3**
- **KAFKA_NUM_IO_THREADS**：默认值：**8**
- **KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS**：默认值：**0**
- **KAFKA_LOG_DIRS**：默认值：**/srv/datalog/kafka**。设置数据日志输出目录
- **KAFKA_LOG_SEGMENT_BYTES**：默认值：**1073741824**
- **KAFKA_LOG_FLUSH_INTERVAL_MESSAGES**：默认值：**10000**
- **KAFKA_LOG_FLUSH_INTERVAL_MS**：默认值：**1000**
- **KAFKA_LOG_RETENTION_HOURS**：默认值：**168**
- **KAFKA_LOG_RETENTION_BYTES**：默认值：**1073741824**
- **KAFKA_LOG_RETENTION_CHECK_INTERVALS_MS**：默认值：**300000**
- **JVMFLAGS**：默认值：**无**。设置服务默认的 JVMFLAGS
- **HEAP_SIZE**：默认值：**1024**。设置以 MB 为单位的 Java Heap 参数（Xmx 与 Xms）。如果在 JVMFLAGS 中已经设置了 Xmx 与 Xms，则当前设置会被忽略。



### 集群配置参数

使用 Kafka 镜像，可以很容易的建立一个 Kafka 集群。针对 集群模式，有以下参数可以配置：

- **KAFKA_BROKER_ID**：默认值：**1**。介于1~255之间的唯一值，用于标识服务器ID
- **KAFKA_BROKER_ID_COMMAND**：默认值：**无**。用于生成ID的命令。

> KAFKA_BROKER_ID_COMMAND: "hostname | awk -F'-' '{print $$2}'"
>
> 在未定义 Broker ID 时，会自动生成一个 ID 供容器使用，详细参见[文档](https://issues.apache.org/jira/browse/KAFKA-1070)。当使用这种方式时，可以支持容器的扩容或缩容。使用时，建议同时使用 Docker Compose的 `--no-recreate` 参数，保证容器的 ID 及容器名不会重复创建。



### TLS配置参数

使用证书加密传输时，相关配置参数如下：

- **KAFKA_KEYSTORE_FILE**：默认值：**kafka.keystore.jks**。证书文件名，默认存放在容器中的`/srv/cert/kafka`目录
- **KAFKA_TRUSTSTORE_FILE**：默认值：**kafka.truststore.jks**。证书文件名，默认存放在容器中的`/srv/cert/kafka`目录
- **KAFKA_CERTIFICATE_PASSWORD**：默认值：**无**。证书秘钥。



## 安全

### 用户及密码

Kafka 镜像默认禁用了无密码访问功能，在实际生产环境中建议使用用户名及密码控制访问；如果为了测试需要，可以使用以下环境变量启用无密码访问功能：

```shell
ALLOW_PLAINTEXT_LISTENER=yes
```



如果需要配置访问认证，需要配置相应的监听器参数，相关监听器主要有：

- INTERNAL: 用于 broker 内通讯
- CLIENT: 用于与在同一网络中的 消费者/生产者 通讯
- (optional) EXTERNAL: 用于与在不同网络中的 消费者/生产者 通讯



以下为一个客户端访问使用`SASL_SSL`方式，Broker 访问使用`SSL`方式，相应的配置参数:

```shell
KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=INTERNAL:SSL,CLIENT:SASL_SSL
KAFKA_LISTENERS=INTERNAL://:9093,CLIENT://:9092
KAFKA_ADVERTISED_LISTENERS=INTERNAL://:9093,CLIENT://kafka:9092
KAFKA_CLIENT_USER=user
KAFKA_CLIENT_PASSWORD=password
```

在上述配置中，**必须**使用相应的证书文件。相应的证书文件需要放在`/srv/cert/kafka`目录中（或主机映射数据卷时使用的目录中）。如果证书使用了密码保护，需要同时使用以下环境变量指定对应的密码：

```shell
KAFKA_CERTIFICATE_PASSWORD=myCertificatePassword
```

以下脚本可用于生成JKS证书文件:

* [kafka-generate-ssl.sh](https://raw.githubusercontent.com/confluentinc/confluent-platform-security-tools/master/kafka-generate-ssl.sh)

建议:

* 在使用密码时，建议相关证书都使用同一个密码。
* 将 CommonName 或 FQDN 设置为容器的 host那么，如： `kafka.example.com`。这样，在后续针对问题 "What is your first and last name?"，可以输入同样的名字。
* 在配置集群时，如果需要每个 Broker 使用不同的证书，需要重复相应的步骤，以生成不同的证书。

针对如何使用 JKS 证书（同时使用了 `certificatePassword123`密码保护）配置容器，以及如何配置容器 hostname ，举例如下：

```yaml
version: '3.6'

services:
  zookeeper:
    image: 'colovu/zookeeper:latest'
    ports:
     - '2181:2181'
    environment:
      - ZOO_ENABLE_AUTH=yes
      - ZOO_SERVER_USERS=kafka
      - ZOO_SERVER_PASSWORDS=kafka_password
  kafka:
    image: 'colovu/kafka:latest'
    hostname: kafka.example.com
    ports:
      - '9092'
    environment:
      - KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=INTERNAL:SSL,CLIENT:SASL_SSL
      - KAFKA_ZOOKEEPER_CONNECT=zookeeper:2181
      - KAFKA_LISTENERS=INTERNAL://:9093,CLIENT://:9092
      - KAFKA_ADVERTISED_LISTENERS=INTERNAL://kafka.example.com:9093,CLIENT://kafka.example.com:9092
      - KAFKA_ZOOKEEPER_USER=kafka
      - KAFKA_ZOOKEEPER_PASSWORD=kafka_password
      - KAFKA_CLIENT_USER=user
      - KAFKA_CLIENT_PASSWORD=password
      - KAFKA_CERTIFICATE_PASSWORD=certificatePassword123
    volumes:
      - './kafka.keystore.jks:/srv/cert/kafka/kafka.keystore.jks:ro'
      - './kafka.truststore.jks:/srv/cert/kafka/kafka.truststore.jks:ro'
```

生产者与消费者在访问客户端使用数据时，需要同样提供对应的用户名及密码。

生产者使用加密方式访问时，在容器中执行如下命令:

```shell
export KAFKA_OPTS="-Djava.security.auth.login.config=/srv/conf/kafka/kafka_jaas.conf"
kafka-console-producer.sh --broker-list 127.0.0.1:9092 --topic test --producer.config /srv/conf/kafka/producer.properties
```

消费者使用加密方式访问时，在容器中执行如下命令：

```shell
export KAFKA_OPTS="-Djava.security.auth.login.config=/srv/conf/kafka/kafka_jaas.conf"
kafka-console-consumer.sh --bootstrap-server 127.0.0.1:9092 --topic test --consumer.config /srv/conf/kafka/consumer.properties
```



#### Kafka 的内部 Broker 访问配置

在内部 Broker 之间的通讯启用 `SASL`或 `SASL_SSL`认证时，可以使用以下参数配置:

* `KAFKA_INTER_BROKER_USER`: 内部 Broker 访问用户名
* `KAFKA_INTER_BROKER_PASSWORD`: 内部 Broker 访问用户密码

#### Kafka 的客户端访问配置

在与客户端的通讯启用 `SASL`或 `SASL_SSL`认证时，可以使用以下参数配置:

* `KAFKA_CLIENT_USER`: 客户端访问用户名
* `KAFKA_CLIENT_PASSWORD`: 客户端访问用户密码

#### Kafka 的 Zookeeper 访问配置

在 Zookeeper 服务启用用户认证时，可以使用以下参数配置:

* `KAFKA_ZOOKEEPER_USER`: Kafka 用于访问 Zookeeper 的用户名
* `KAFKA_ZOOKEEPER_PASSWORD`: Kafka 用于访问 Zookeeper 的用户密码

### 容器安全

本容器默认使用`non-root`运行应用，以加强容器的安全性。在使用`non-root`用户运行容器时，相关的资源访问会受限；应用仅能操作镜像创建时指定的路径及数据。使用`non-root`方式的容器，更适合在生产环境中使用。



如果需要切换为`root`方式运行应用，可以在启动命令中增加`-u root`以指定运行的用户。



## 注意事项

- 容器中应用的启动参数不能配置为后台运行，如果应用使用后台方式运行，则容器的启动命令会在运行后自动退出，从而导致容器退出



## 更新记录

- 2.5.0、latest
- 2.4.1
- 2.3.1



----

本文原始来源 [Endial Fang](https://github.com/colovu) @ [Github.com](https://github.com)
