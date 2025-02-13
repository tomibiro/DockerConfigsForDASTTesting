#!/usr/bin/env bash

##################################################################
# Always use full path when sourcing --> source /mnt/liferay/scripts/_common.sh
##################################################################

execute_sql_query() {
  local schema_param
  local query_param

  # Reset OPTIND
  OPTIND=1

  while getopts ":s:q:" opt; do
    case ${opt} in
      s)
        #echo "Debug - schema_param" "${OPTARG}"
        schema_param="${OPTARG}"
        ;;
      q)
        #echo "Debug - query_param" "${OPTARG}"
        query_param="${OPTARG}"
        ;;
      \?)
        echo "[SaaS] Invalid option: -${OPTARG}" >&2
        return 1
        ;;
      :)
        echo "[SaaS] Option -${OPTARG} requires an argument." >&2
        return 1
        ;;
    esac
  done

  # Shift past the processed options
  shift $((OPTIND - 1))

  # Debugging: Print parsed values
  #echo "Debug - Schema: '${schema_param}'"
  #echo "Debug - Query: '${query_param}'"

  if [ -z "${query_param}" ]; then
    echo "[SaaS] -q (query) option is required for execute_sql_query function" >&2
    return 1
  fi

  # Ensure no extra arguments are provided
  if [ "$#" -ne 0 ]; then
    echo "[SaaS] No extra arguments allowed." >&2
    return 1
  fi

  if [[ "${LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_URL}" == *"postgresql"* ]]; then
    if [ -z "${schema_param}" ]; then
      psql --tuples-only --no-align -c "${query_param}"
    else
      psql --tuples-only --no-align -c "SET search_path TO ${schema_param}; ${query_param}"
    fi
  else
    if [ -z "${schema_param}" ]; then
      mysql --batch --raw --skip-column-names -e "${query_param}"
    else
      mysql -D ${schema_param} --batch --raw --skip-column-names -e "${query_param}"
    fi
  fi
}

get_db_partitions() {
    execute_sql_query -q "SELECT schema_name FROM information_schema.schemata WHERE schema_name like 'lpartition_%';"
}

get_db_server_type() {
    if [[ "${LIFERAY_JDBC_PERIOD_DEFAULT_PERIOD_URL}" == *"postgresql"* ]]; then
        echo "postgresql"
    else
        echo "mysql"
    fi
}

is_database_sanitized() {
    if [[ "${LCP_PROJECT_ENVIRONMENT}" != *modl && "${LCP_PROJECT_ENVIRONMENT}" != *uat ]]; then
        echo "[SaaS] ERROR: This command must only be used for MODL or UAT environments. Exiting..."

        return 1
    fi

    execute_sql_query -q "CREATE TABLE saas_sanitized (id INT);" >/dev/null 2>&1
    local query_exit_code=$?

    if [[ "${query_exit_code}" -eq 0 ]]; then
        echo "false"
    else
        echo "true"
    fi
}

is_database_valid() {
    # Check if Release_ table exists
    QUERY_OUTPUT=$(execute_sql_query -q "SELECT table_schema, table_name FROM information_schema.tables WHERE table_name like '%elease_';")

    if [ -z "$QUERY_OUTPUT" ]; then
      echo "false"
    else
      echo "true"
    fi
}
