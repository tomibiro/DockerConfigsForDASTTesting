#!/usr/bin/env bash

function main {
    if [[ "${LOCAL_STACK}" == "true" ]]
    then
        echo "[SaaS] [glowroot] glowroot is disabled because LOCAL_STACK is ${LOCAL_STACK}"
        return
    elif [[ "${LXC_DISABLE_GLOWROOT}" == "true" ]]
    then
        echo "[SaaS] [glowroot] glowroot is disable because LXC_DISABLE_GLOWROOT is ${LXC_DISABLE_GLOWROOT}"
        return
    elif [[ "$LIFERAY_JVM_OPTS" != *"-javaagent:/opt/liferay/glowroot/glowroot.jar"* ]]
    then
        return
    fi

    echo "[SaaS] [glowroot] glowroot is enabled, configuring setup"

    {
        if [ ! -d "/opt/liferay/glowroot" ]; then
            echo '[SaaS] [glowroot] downloading glowroot'
            curl -LO https://github.com/glowroot/glowroot/releases/download/v0.13.6/glowroot-0.13.6-dist.zip

            if [ "$(sha256sum glowroot-0.13.6-dist.zip)" != "f1e76f3ac1b08587a5694fe9fd0b852313177643347e3fd2ec811588129a4968  glowroot-0.13.6-dist.zip" ]; then 
                echo "[SaaS] Glowroow security integrity check failed!"
                return
            fi

            echo '[SaaS] [glowroot] unzipping glowroot'
            unzip -d /opt/liferay glowroot-0.13.6-dist.zip
        else
            echo "[SaaS] [glowroot] glowroot folder exists"
        fi
    }

    if [ ! -f "/opt/liferay/glowroot/config.json" ]; then
        echo "[SaaS] [glowroot] no agent configuration found, configuring agent settings"
    else
        echo "[SaaS] [glowroot] config.json exists, overwriting agent settings"
    fi

    {
        echo '{
              "transactions": {
                "slowThresholdMillis": 2000,
                "profilingIntervalMillis": 1000,
                "captureThreadStats": true
              },
              "jvm": {
                "maskSystemProperties": [
                  "*password*"
                ],
                "maskMBeanAttributes": [
                  "*password*"
                ]
              },
              "uiDefaults": {
                "defaultTransactionType": "Web",
                "defaultPercentiles": [
                  50.0,
                  95.0,
                  99.0
                ],
                "defaultGaugeNames": [
                  "java.lang:type=Memory:HeapMemoryUsage.used"
                ]
              },
              "advanced": {
                "immediatePartialStoreThresholdSeconds": 60,
                "maxTransactionAggregates": 500,
                "maxQueryAggregates": 500,
                "maxServiceCallAggregates": 500,
                "maxTraceEntriesPerTransaction": 2000,
                "maxProfileSamplesPerTransaction": 50000,
                "mbeanGaugeNotFoundDelaySeconds": 60
              },
              "gauges": [
                {
                  "mbeanObjectName": "java.lang:type=Memory",
                  "mbeanAttributes": [
                    {
                      "name": "HeapMemoryUsage.used"
                    }
                  ]
                },
                {
                  "mbeanObjectName": "java.lang:type=GarbageCollector,name=*",
                  "mbeanAttributes": [
                    {
                      "name": "CollectionCount",
                      "counter": true
                    },
                    {
                      "name": "CollectionTime",
                      "counter": true
                    }
                  ]
                },
                {
                  "mbeanObjectName": "java.lang:type=MemoryPool,name=*",
                  "mbeanAttributes": [
                    {
                      "name": "Usage.used"
                    }
                  ]
                },
                {
                  "mbeanObjectName": "java.lang:type=OperatingSystem",
                  "mbeanAttributes": [
                    {
                      "name": "FreePhysicalMemorySize"
                    },
                    {
                      "name": "ProcessCpuLoad"
                    },
                    {
                      "name": "SystemCpuLoad"
                    }
                  ]
                },
                {
                  "mbeanObjectName": "com.zaxxer.hikari:*",
                  "mbeanAttributes": [
                    {
                      "name": "ActiveConnections"
                    },
                    {
                      "name": "IdleConnections"
                    },
                    {
                      "name": "ThreadsAwaitingConnection"
                    },
                    {
                      "name": "TotalConnections"
                    }
                  ]
                }
              ],
              "plugins": [
                {
                  "id": "cassandra",
                  "properties": {
                    "stackTraceThresholdMillis": 1000.0
                  }
                },
                {
                  "id": "elasticsearch",
                  "properties": {
                    "stackTraceThresholdMillis": 1000.0
                  }
                },
                {
                  "id": "java-http-server",
                  "properties": {
                    "captureRequestHeaders": [ ],
                    "maskRequestHeaders": [
                      "Authorization"
                    ],
                    "captureRequestRemoteAddr": false,
                    "captureRequestRemoteHost": false,
                    "captureResponseHeaders": [ ],
                    "traceErrorOn4xxResponseCode": false
                  }
                },
                {
                  "id": "jaxrs",
                  "properties": {
                    "useAltTransactionNaming": false
                  }
                },
                {
                  "id": "jdbc",
                  "properties": {
                    "captureBindParametersIncludes": [
                      ".*"
                    ],
                    "captureBindParametersExcludes": [ ],
                    "captureResultSetNavigate": true,
                    "captureResultSetGet": false,
                    "captureConnectionPoolLeaks": false,
                    "captureConnectionPoolLeakDetails": false,
                    "captureGetConnection": true,
                    "captureConnectionClose": false,
                    "capturePreparedStatementCreation": false,
                    "captureStatementClose": false,
                    "captureTransactionLifecycleTraceEntries": false,
                    "captureConnectionLifecycleTraceEntries": false,
                    "stackTraceThresholdMillis": 1000.0
                  }
                },
                {
                  "id": "liferay-freemarker-templates-plugin",
                  "properties": {
                    "instrumentationLevel": "INFO"
                  }
                },
                {
                  "id": "logger",
                  "properties": {
                    "traceErrorOnErrorWithThrowable": true,
                    "traceErrorOnErrorWithoutThrowable": false,
                    "traceErrorOnWarningWithThrowable": false,
                    "traceErrorOnWarningWithoutThrowable": false
                  }
                },
                {
                  "id": "mongodb",
                  "properties": {
                    "stackTraceThresholdMillis": 1000.0
                  }
                },
                {
                  "id": "play",
                  "properties": {
                    "useAltTransactionNaming": false
                  }
                },
                {
                  "id": "servlet",
                  "properties": {
                    "sessionUserAttribute": "",
                    "captureSessionAttributes": [ ],
                    "captureRequestParameters": [
                      "*"
                    ],
                    "maskRequestParameters": [
                      "*password*"
                    ],
                    "captureRequestHeaders": [ ],
                    "captureResponseHeaders": [ ],
                    "traceErrorOn4xxResponseCode": false,
                    "captureRequestRemoteAddr": false,
                    "captureRequestRemoteHostname": false,
                    "captureRequestRemotePort": false,
                    "captureRequestLocalAddr": false,
                    "captureRequestLocalHostname": false,
                    "captureRequestLocalPort": false,
                    "captureRequestServerHostname": false,
                    "captureRequestServerPort": false
                  }
                },
                {
                  "id": "spring",
                  "properties": {
                    "useAltTransactionNaming": false
                  }
                }
              ],
              "instrumentation": [
                {
                  "className": "com.liferay.portal.kernel.upgrade.UpgradeStep",
                  "methodName": "upgrade",
                  "methodParameterTypes": [ ],
                  "order": 0,
                  "captureKind": "transaction",
                  "transactionType": "Upgrade",
                  "transactionNameTemplate": "Upgrade Step {{this.class.name}}",
                  "alreadyInTransactionBehavior": "capture-new-transaction",
                  "traceEntryMessageTemplate": "Upgrade Step {{this.class.name}}",
                  "timerName": "Upgrade Step Timer"
                },
                {
                  "className": "com.liferay.portal.kernel.upgrade.UpgradeProcess",
                  "methodName": "upgrade",
                  "methodParameterTypes": [ ],
                  "order": 0,
                  "captureKind": "transaction",
                  "transactionType": "Upgrade",
                  "transactionNameTemplate": "Upgrade Process {{this.class.name}}",
                  "alreadyInTransactionBehavior": "capture-new-transaction",
                  "traceEntryMessageTemplate": "Upgrade Process {{this.class.name}}",
                  "timerName": "Upgrade Process Timer"
                }
              ]
            }'
    } > /opt/liferay/glowroot/config.json

    if [ ! -f "/opt/liferay/glowroot/glowroot-template.properties" ]; then
        echo "[SaaS] [glowroot] no properties file found, configuring agent properties"
    else
        echo "[SaaS] [glowroot] glowroot-template.properties exists, overwriting agent properties"
    fi

    {
        LXC_CLUSTER_ID=$(echo $LCP_PROJECT_CLUSTER | cut -d- -f3)
        echo "agent.id=${LCP_PROJECT_ENVIRONMENT}::${HOSTNAME}"
        echo "collector.address=https://glowroot-${LXC_CLUSTER_ID}.lxc.liferay.com:443"
    } > /opt/liferay/glowroot/glowroot-template.properties

    if [ ! -f "/opt/liferay/glowroot/grpc-trusted-root-certs.pem" ]; then
        echo "[SaaS] [glowroot] no certificate file found, configuring certificates"
    else
        echo "[SaaS] [glowroot] grpc-trusted-root-certs.pem exists, overwriting certificates"
    fi

    {
        LXC_CLUSTER_ID=$(echo $LCP_PROJECT_CLUSTER | cut -d- -f3)
        echo | openssl s_client -connect "glowroot-${LXC_CLUSTER_ID}.lxc.liferay.com:443" 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'
    } > /opt/liferay/glowroot/grpc-trusted-root-certs.pem

    if [ ! -f "/opt/liferay/glowroot/glowroot.logback.xml" ]; then
        echo "[SaaS] [glowroot] no logging configuration found, configuring logging"
    else
        echo "[SaaS] [glowroot] glowroot.logback.xml exists, overwriting logging"
    fi

    {
        echo '<?xml version="1.0" encoding="UTF-8"?>
                <!DOCTYPE configuration>
                    <configuration>
                        <appender name="CONSOLE" class="org.glowroot.agent.shaded.ch.qos.logback.core.ConsoleAppender">
                            <encoder>
                                <pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} %-5level %logger{36} - %msg%n</pattern>
                            </encoder>
                        </appender>
                        <logger name="org.glowroot.agent.shaded" level="warn" />
                        <logger name="org.glowroot.agent.embedded.shaded" level="warn" />
                        <logger name="org.glowroot.agent.shaded.io.netty.handler.codec.http2.Http2ConnectionHandler" level="off" />
                        <root level="error">
                            <appender-ref ref="CONSOLE" />
                        </root>
                        <logger name="audit" level="off" />
                    </configuration>'
    } > /opt/liferay/glowroot/glowroot.logback.xml

    envsubst < /opt/liferay/glowroot/glowroot-template.properties > /opt/liferay/glowroot/glowroot.properties
}

main "$@"
