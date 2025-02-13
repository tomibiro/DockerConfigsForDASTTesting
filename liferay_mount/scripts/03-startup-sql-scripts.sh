#!/usr/bin/env bash

set -o errexit

source /mnt/liferay/scripts/_common.sh

function fix_db_common {
    echo "[SaaS] Fix virtualhost for the default instance if it is localhost"
    execute_sql_query -q "UPDATE VirtualHost SET hostname = 'admin-${LCP_PROJECT_ENVIRONMENT:0:4}.lxc.liferay.com' WHERE hostname = 'localhost';"
    
    echo "[SaaS] Truncate the OAuthClientEntry table"
    execute_sql_query -q "TRUNCATE TABLE OAuthClientEntry;"

    # SRE-3633 - Remove Quartz jobs related to Antivirus
    # If 'configuration.override.com.liferay.portal.bundle.blacklist.internal.configuration.BundleBlacklistConfiguration_blacklistBundleSymbolicNames'
    # and 'com.liferay.antivirus.async.store' are present in any properties file on path /opt/liferay, then execute the following SQL queries
    echo "[SaaS] Checking if Async Antivirus is disabled..."
    if grep -sq "com.liferay.antivirus.async.store" /opt/liferay/portal-env.properties
    then
        echo "[SaaS] Async Antivirus module is blacklisted. Removing Quartz jobs related to Antivirus..."
        execute_sql_query -q "DELETE FROM QUARTZ_TRIGGERS WHERE JOB_GROUP LIKE '%Antivirus%';"
        execute_sql_query -q "DELETE FROM QUARTZ_CRON_TRIGGERS WHERE TRIGGER_GROUP LIKE '%Antivirus%';"
        execute_sql_query -q "DELETE FROM QUARTZ_JOB_DETAILS WHERE JOB_GROUP LIKE '%Antivirus%';"
    else
        echo "[SaaS] Async Antivirus is not blacklisted. Skipping..."
    fi
}

main() {
    if [[ "${LOCAL_STACK}" == "true" ]]
    then
        return
    fi

    # During the provisioning (first run) we should return
    if [ "$(is_database_valid)" = "true" ]; then
        echo "[SaaS] Database exists and is not empty."
        echo "[SaaS] Verifying entries..."
    else
        echo "[SaaS] Database does not exists and/or empty"
        echo "[SaaS] Skipping verify process"
    	return
    fi

    # Set the default instance companyId
    ADMIN_COMPANY_ID=$(execute_sql_query -q "SELECT companyId FROM VirtualHost WHERE hostname LIKE '%admin%.lxc.liferay.com';")
    export ADMIN_COMPANY_ID
    echo "ADMIN_COMPANY_ID=$ADMIN_COMPANY_ID"

    # Set the default instance webId
    ADMIN_WEB_ID=$(execute_sql_query -q "SELECT webId from Company WHERE companyId = (SELECT companyId FROM VirtualHost WHERE hostname LIKE '%admin%.lxc.liferay.com');")
    export ADMIN_WEB_ID
    echo "ADMIN_WEB_ID=$ADMIN_WEB_ID"

    fix_db_common

    # Substitute the environment variables in in .config files in /opt/liferay/osgi/configs
    find /opt/liferay/osgi/configs -type f -name '*.config' -exec sh -c 'envsubst < $1 > $1.tmp && mv $1.tmp $1' shell {} \;
}

main "$@"
