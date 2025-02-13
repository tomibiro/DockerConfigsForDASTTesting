#!/bin/bash

ID_NAME=$1
CONTAINER_ID=$(docker ps --filter "name=$ID_NAME" --format "{{.ID}}")

echo $CONTAINER_ID

# docker rm -f $CONTAINER_ID

docker stop $CONTAINER_ID

# MySQL container name
MYSQL_CONTAINER="mysql"

# MySQL credentials
MYSQL_USER="root"
MYSQL_PASSWORD="password"

# SQL command
SQL_COMMAND="DROP DATABASE $ID_NAME;"

# Run the sql command
docker exec -i $MYSQL_CONTAINER mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e "$SQL_COMMAND"
