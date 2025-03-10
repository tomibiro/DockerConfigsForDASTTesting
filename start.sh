#!/bin/bash

# Check database container first
./mysql_check.sh

STATUS=$?  # The status of the Mysql check
LIFERAY_VERSION=$1
ID_NAME=$2
LOCALHOST_PORT=$3
IMAGE_NAME=$(echo "$LIFERAY_VERSION" | tr -d ":")

if [[ $STATUS -eq 1 ]]; then
    docker start mysql
	sleep 5
fi

./mysql_check.sh
STATUS=$?

if [[ $STATUS -eq 0 ]]; then
    echo "✅ Mysql connection is established."
	echo "Start a new database: $ID_NAME" 
    ./init_new_database.sh $ID_NAME  
	
DOCKER_COMMAND="docker run -d \
  --name \"$ID_NAME\" \
  --network env-tiger_liferay-net \
  --hostname liferay-docker2 \
  -e LCP_SECRET_DATABASE_HOST=mysql \
  -e LCP_SECRET_DATABASE_PASSWORD=password \
  -e LCP_SECRET_DATABASE_USER=root \
  -e LCP_PROJECT_ENVIRONMENT=spinner_modl \
  -e LIFERAY_DISABLE_TRIAL_LICENSE=false \
  -e LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_DRIVER_UPPERCASEC_LASS_UPPERCASEN_AME=org.mariadb.jdbc.Driver \
  -e LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_URL=\"jdbc:mysql://mysql/${ID_NAME}?characterEncoding=UTF-8&dontTrackOpenResources=true&holdResultsOpenOverStatementClose=true&passwordCharacterEncoding=UTF-8&permitMysqlScheme&serverTimezone=GMT&useFastDateParsing=false&useUnicode=true\" \
  -e LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_USERNAME=root \
  -e LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_PASSWORD=password \
  -e LIFERAY_JPDA_ENABLED=true \
  -e LIFERAY_UPGRADE_ENABLED=false \
  -e LIFERAY_USERS_PERIOD_REMINDER_PERIOD_QUERIES_PERIOD_ENABLED=false \
  -e LIFERAY_VIRTUAL_PERIOD_HOSTS_PERIOD_VALID_PERIOD_HOSTS=* \
  -e LIFERAY_WORKSPACE_ENVIRONMENT=workspace_env \
  -e LOCAL_STACK=true \
  -e MODL_CUSTOMER_USERS_PASSWORD=liferaydevsecops \
  -p 127.0.0.1:${LOCALHOST_PORT}:8080 \
  -v liferay_document_library-docker:/opt/liferay/data \
  -v ./scripts:/mnt/liferay/scripts \
  $IMAGE_NAME"

eval "$DOCKER_COMMAND"

echo "Liferay container '${ID_NAME}' added and started successfully."
	
elif [[ $STATUS -eq 2 ]]; then
    echo "⚠ MySQL has not started yet. Wait for 5 sec and restart..."
    exit 99
else
    echo "❌ Unknown error, quit..."
    exit 99
fi