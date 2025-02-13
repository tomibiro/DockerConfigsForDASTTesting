FROM liferay/dxp:2024.q3.7-d7.1.0-20241029202135
COPY resources/usr/local/liferay/scripts /usr/local/liferay/scripts

USER root
RUN apt-get update && apt-get install -y --no-install-recommends mysql-client postgresql-client
USER liferay

# Any instructions here will be appended to the end of the Dockerfile created by `createDockerfile`.

RUN cd /opt/liferay/tomcat/webapps/ROOT/WEB-INF/shielded-container-lib && \
    curl -O https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-layout-template-json/2.17.2/log4j-layout-template-json-2.17.2.jar && \
    curl -O https://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-core/2.16.2/jackson-core-2.16.2.jar && \
    curl -O https://repo1.maven.org/maven2/com/fasterxml/jackson/core/jackson-annotations/2.16.2/jackson-annotations-2.16.2.jar

RUN cd /opt/liferay/tomcat/lib && \
    curl -O https://repo1.maven.org/maven2/co/elastic/logging/jul-ecs-formatter/1.6.0/jul-ecs-formatter-1.6.0.jar && \
    curl -O https://repo1.maven.org/maven2/co/elastic/logging/ecs-logging-core/1.6.0/ecs-logging-core-1.6.0.jar

RUN echo '\nalias sumysql="mysql -u ${LCP_SECRET_DATABASE_USER} -p${LCP_SECRET_DATABASE_PASSWORD}"' >> /home/liferay/.bashrc

RUN rm -fr /opt/liferay/patching-tool && \
    cd /opt/liferay && \
    curl -O https://releases-cdn.liferay.com/tools/patching-tool/patching-tool-4.0.5.zip && \
    unzip patching-tool-4.0.5.zip

# To install a hotfix, specify the hotfix number below and remove the # before the RUN command if it present


# OSGi state should be deleted after the hotfix is installed
RUN rm -rf /opt/liferay/osgi/state