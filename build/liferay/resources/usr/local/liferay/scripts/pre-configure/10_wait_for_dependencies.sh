#!/bin/bash

function wait_for_database {
	local jdbc_driver_class_name="${LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_DRIVER_UPPERCASEC_LASS_UPPERCASEN_AME}"

	local db_host="${LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_URL}"

	db_host="${db_host##*://}"
	db_host="${db_host%%/*}"
	db_host="${db_host%%:*}"

	local db_password=${LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_PASSWORD}

	if [ -n "${LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_PASSWORD_FILE}" ]
	then
		db_password=$(cat "${LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_PASSWORD_FILE}")
	fi

	local db_username=${LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_USERNAME}

	echo "Connecting to database server ${db_username}@${db_host}."

	if [[ "${jdbc_driver_class_name}" != *mariadb* ]] && [[ "${jdbc_driver_class_name}" != *mysql* ]]
	then
		while ! (PGPASSWORD="${db_password}" psql -h "${db_host}" -U "${db_username}" -d "lportal" -c "select 1" &> /dev/null); do
			echo "Waiting for database server ${db_username}@${db_host}."

			sleep 3
		done
	else
		while ! (echo "select 1" | mysql -h "${db_host}" -p"${db_password}" -u "${db_username}" &> /dev/null); do
			echo "Waiting for database server ${db_username}@${db_host}."

			sleep 3
		done
	fi

	echo "Database server ${db_username}@${db_host} is available."
}

function main {
	wait_for_database
}

main