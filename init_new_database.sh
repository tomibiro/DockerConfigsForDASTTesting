#!/bin/bash

# MySQL container name
MYSQL_CONTAINER="mysql"

# New database name
NEW_DATABASE=$1

# MySQL credentials
MYSQL_USER="root"
MYSQL_PASSWORD="password"

# SQL command
SQL_COMMAND="CREATE DATABASE IF NOT EXISTS $NEW_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Run the sql command
docker exec -i $MYSQL_CONTAINER mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e "$SQL_COMMAND"

# Check
if [ $? -eq 0 ]; then
    echo "✅ The new database has created: $NEW_DATABASE"
	exit 0
else
    echo "❌ There is an error during the command!"
	exit 1
fi