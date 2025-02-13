#!/usr/bin/env bash

echo "[SaaS] Change Session timeout settings"

timeout=15

echo "Updating web.xml's session timeout to ${timeout} minutes"
sed -i -e "s/<session-timeout>.*<\/session-timeout>/<session-timeout>$timeout<\/session-timeout>/" $LIFERAY_HOME/tomcat/webapps/ROOT/WEB-INF/web.xml
sed -i -e "s/<session-timeout>.*<\/session-timeout>/<session-timeout>$timeout<\/session-timeout>/" $LIFERAY_HOME/tomcat/conf/web.xml