#!/bin/bash

# Check database container first
./mysql_check.sh

STATUS=$?  # The status of the Mysql check
LIFERAY_VERSION=$1
ID_NAME=$2
LOCALHOST_PORT=$3
IMAGE_NAME=$(echo "$LIFERAY_VERSION" | tr -d ":")

if [[ $STATUS -eq 0 ]]; then
    echo "✅ Mysql connection is established."
	echo "Start a new database: $ID_NAME" 
    ./init_new_database.sh $ID_NAME  
	
	# Define the new docker-compose file
	COMPOSE_FILE="docker-compose-${ID_NAME}.yml"
	
	COMPOSE_OVERRIDE="docker-compose.override.yml"

# Check if override file exists, otherwise create it
if [ ! -f "$COMPOSE_OVERRIDE" ]; then
    echo "Creating new $COMPOSE_OVERRIDE file..."
    echo "volumes:
  liferay_volume:
networks:
  env-tiger_liferay-net:
    external: true
services:" >> "$COMPOSE_OVERRIDE"
fi
	
	cat >> "$COMPOSE_OVERRIDE" <<EOL
  ${ID_NAME}:
    container_name: ${ID_NAME}
    build: 
      context: ./build/liferay
      args:
        LIFERAY_VERSION: ${LIFERAY_VERSION}
    image: ${IMAGE_NAME}
    deploy:
      resources:
        limits:
          memory: 6G
        reservations:
          memory: 6G
    depends_on:
      mysql:
        condition: service_healthy   
    environment:
            - LCP_LIFERAY_UPGRADE_ENABLED=${LCP_LIFERAY_UPGRADE_ENABLED:-}
            - LCP_SECRET_DATABASE_HOST=mysql
            - LCP_SECRET_DATABASE_PASSWORD=password
            - LCP_SECRET_DATABASE_USER=root
            - LCP_PROJECT_ENVIRONMENT=spinner_modl
            - LIFERAY_DISABLE_TRIAL_LICENSE=false
            - LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_DRIVER_UPPERCASEC_LASS_UPPERCASEN_AME=org.mariadb.jdbc.Driver
            -                                                                    LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_URL=jdbc:mysql://mysql/${ID_NAME}?characterEncoding=UTF-8&dontTrackOpenResources=true&holdResultsOpenOverStatementClose=true&passwordCharacterEncoding=UTF-8&permitMysqlScheme&serverTimezone=GMT&useFastDateParsing=false&useUnicode=true
            - LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_USERNAME=root
            - LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_PASSWORD=password
            - LIFERAY_JPDA_ENABLED=true
            - LIFERAY_UPGRADE_ENABLED=false
            - LIFERAY_USERS_PERIOD_REMINDER_PERIOD_QUERIES_PERIOD_ENABLED=false
            - LIFERAY_VIRTUAL_PERIOD_HOSTS_PERIOD_VALID_PERIOD_HOSTS=*
            - LIFERAY_WORKSPACE_ENVIRONMENT=workspace_env
            - LOCAL_STACK=true
            - MODL_CUSTOMER_USERS_PASSWORD=liferaydevsecops
    extra_hosts:
      - host.docker.internal:host-gateway
    hostname: hostname
    ports:
      - 127.0.0.1:${LOCALHOST_PORT}:8080
    volumes:
      - liferay_volume:/opt/liferay/data
    networks:
      - env-tiger_liferay-net
EOL

# Start new Liferay container
	# LIFERAY_VERSION=$LIFERAY_VERSION ID_NAME=$ID_NAME PORT=$LOCALHOST_PORT IMAGE_NAME=$IMAGE_NAME docker compose up -d
	
	# docker run -d --name $ID_NAME -p $LOCALHOST_PORT:8080 $LIFERAY_VERSION
	
# Start all containers with override file
echo "Starting all Liferay containers..."
# docker compose -f $COMPOSE_FILE up -d --builddocker compose -f docker-compose.yml -f $COMPOSE_OVERRIDE up -d --build
docker compose -f docker-compose.yml -f $COMPOSE_OVERRIDE up -d --build

echo "Liferay container '${ID_NAME}' added and started successfully."
	
elif [[ $STATUS -eq 1 ]]; then
    exit 1
elif [[ $STATUS -eq 2 ]]; then
    echo "⚠ MySQL has not started yet. Wait for 5 sec and re-check..."
    sleep 5
    ./retry_database_not_exist.sh  # script does not exist for re-check
else
    echo "❌ Unknown error, quit..."
    exit 99
fi