#!/bin/bash

ID_NAME=$1
CONTAINER_ID=$(docker ps --filter "name=$ID_NAME" --format "{{.ID}}")

docker stop $CONTAINER_ID
echo "Docker container '${CONTAINER_ID}' is stopped."

docker rm -f $CONTAINER_ID
echo "Docker container '${CONTAINER_ID}' is removed."

# MySQL container name
MYSQL_CONTAINER="mysql"

# MySQL credentials
MYSQL_USER="root"
MYSQL_PASSWORD="password"

# SQL command
SQL_COMMAND="DROP DATABASE $ID_NAME;"

# Run the sql command
docker exec -i $MYSQL_CONTAINER mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e "$SQL_COMMAND"

echo "MySQL database '${ID_NAME}' is removed."

# Stop Mysql container if there is no more container that's image name starts with "liferay"
IS_ANY_LIFERAY_CONTAINER=$(docker ps --format "{{.Image}}" | grep "^liferay")

if [[ -z "$IS_ANY_LIFERAY_CONTAINER" ]]; then
    echo "No more running liferay container, stop Mysql container..."
    docker stop mysql
fi
