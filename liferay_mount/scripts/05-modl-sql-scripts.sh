#!/usr/bin/env bash

set -o errexit

source /mnt/liferay/scripts/_common.sh

DEFAULT_DATABASE_SCHEMA="${LCP_SECRET_DATABASE_NAME:-lportal}"

main() {
    if [[ "${LCP_PROJECT_ENVIRONMENT}" != *modl && "${LCP_PROJECT_ENVIRONMENT}" != *uat ]]
    then
        echo "[SaaS] It is a production database, skipping DB sanitizer update process."
        return
    fi

    if [[ "$(get_db_server_type)" == "postgresql" ]]
    then
        # The default schema for postgres installation held in "public" schema, so we should use it for the default admin instance
        DEFAULT_DATABASE_SCHEMA="public"
    fi

    update_modl_db
}

function update_modl_db {
    # During the provisioning (first run) we should return
    if [ "$(is_database_valid)" = "true" ]; then
        echo "[SaaS] Database exists and it is not empty."
    else
        echo "[SaaS] Database does not exists or empty."
        echo "[SaaS] Skipping DB sanitizer update process."
        return
    fi

    # Check if the database has been already sanitized after the database restore
    if [ "$(is_database_sanitized)" = "false" ]; then
        echo "[SaaS] This is first the start after the database restore."
        echo "[SaaS] Start sanitizing DB entries..."
    else
        echo "[SaaS] Database has been sanitized already."
        echo "[SaaS] Skipping DB sanitizer update process."
        return
    fi

    # Iterate over all databases starting with the prefix lpartition_ 
    for db_partition in $(get_db_partitions)
    do
        echo "[SaaS] Updating $db_partition..."

        replace_password "$db_partition"

        clear_sso_config "$db_partition"

        fix_users "$db_partition"

	disable_user_validations "$db_partition"

        if [[ "${LCP_PROJECT_ENVIRONMENT}" != *uat ]]; then
            sanitize_smtp_config "$db_partition"

            sanitize_mp_mailing_list "$db_partition"
        fi

        delete_analytics_config "$db_partition"
    done

    echo "[SaaS] Updating default (admin) instance $DEFAULT_DATABASE_SCHEMA..."

    clear_sso_config "$DEFAULT_DATABASE_SCHEMA"
    delete_analytics_config "$DEFAULT_DATABASE_SCHEMA"

    if [[ "${LCP_PROJECT_ENVIRONMENT}" == *uat ]]; then
        return
    fi

    if [[ "${LOCAL_STACK}" != "true" ]]; then
        echo "[SaaS] [$DEFAULT_DATABASE_SCHEMA] Updating virtual hosts on MODL environment"
        if [[ "$(get_db_server_type)" == "postgresql" ]]; then
            execute_sql_query -q "UPDATE VirtualHost AS ModlVH SET hostname = 'admin.${LCP_PROJECT_ENVIRONMENT:0:4}-modl.lxc.liferay.com' FROM VirtualHost AS OriginalVH WHERE ModlVH.virtualHostId = OriginalVH.virtualHostId AND OriginalVH.hostname LIKE 'admin-${LCP_PROJECT_ENVIRONMENT:0:4}%.lxc.liferay.com';"
            execute_sql_query -q "UPDATE VirtualHost SET hostname = REPLACE(REPLACE(VirtualHost.hostname, '-', '--'), '.', '-') || '.${LCP_PROJECT_ENVIRONMENT:0:4}-modl.lxc.liferay.com' WHERE VirtualHost.hostname NOT LIKE 'admin%' AND VirtualHost.hostname NOT LIKE '%-modl.lxc.liferay.com';"
        else
            execute_sql_query -q "UPDATE VirtualHost AS ModlVH INNER JOIN VirtualHost AS OriginalVH ON ModlVH.virtualHostId = OriginalVH.virtualHostId SET ModlVH.hostname = 'admin.${LCP_PROJECT_ENVIRONMENT:0:4}-modl.lxc.liferay.com' WHERE OriginalVH.hostname LIKE 'admin-${LCP_PROJECT_ENVIRONMENT:0:4}%.lxc.liferay.com';"
            execute_sql_query -q "UPDATE VirtualHost SET VirtualHost.hostname = CONCAT(REPLACE(REPLACE(VirtualHost.hostname, '-', '--'), '.', '-'), '.${LCP_PROJECT_ENVIRONMENT:0:4}-modl.lxc.liferay.com') WHERE VirtualHost.hostname NOT LIKE 'admin%' AND VirtualHost.hostname NOT LIKE '%-modl.lxc.liferay.com';"
        fi
    else
        echo "[SaaS] [$DEFAULT_DATABASE_SCHEMA] Updating virtual hosts for Spinner by appending '.local' as a suffix for the original virtualhost name"
        if [[ "$(get_db_server_type)" == "postgresql" ]]; then
            execute_sql_query -q "UPDATE VirtualHost SET hostname = hostname || '.local' WHERE hostname NOT LIKE '%.local';"
        else
            execute_sql_query -q "UPDATE VirtualHost SET hostname=concat(hostname, '.local') WHERE hostname NOT LIKE '%.local';"
        fi

        replace_password ${DEFAULT_DATABASE_SCHEMA}
    fi
}

function replace_password {
    local db_schema=$1

    echo "[SaaS] [$db_schema] Updating user password with the MODL_CUSTOMER_USERS_PASSWORD secret value"
    execute_sql_query -s "$db_schema" -q "UPDATE User_ SET password_='${MODL_CUSTOMER_USERS_PASSWORD}', passwordEncrypted = FALSE;" || true
}

function clear_sso_config {
    local db_schema=$1
    
    echo "[SaaS] [$db_schema] Clearing SSO settings"
    for table in $(
        execute_sql_query -s "$db_schema" -q "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = '$db_schema' AND (TABLE_NAME LIKE 'Saml%' OR TABLE_NAME LIKE 'saml%' OR TABLE_NAME = 'OpenIdConnectSession' OR TABLE_NAME = 'openidconnectsession');"
    )
    do
        echo "[SaaS] Truncate table: $db_schema.$table"
        execute_sql_query -s "$db_schema" -q "TRUNCATE TABLE $db_schema.$table;"
    done

    echo "[SaaS] [$db_schema] Clearing SSO settings"
    execute_sql_query -s "$db_schema" -q "DELETE FROM Configuration_ WHERE configurationId LIKE 'com.liferay.portal.security.ldap.%';"
    execute_sql_query -s "$db_schema" -q "DELETE FROM Configuration_ WHERE configurationId LIKE 'com.liferay.saml.%';"
    execute_sql_query -s "$db_schema" -q "DELETE FROM Configuration_ WHERE configurationId LIKE 'com.liferay.portal.security.sso.openid.%';"
    execute_sql_query -s "$db_schema" -q "DELETE FROM Configuration_ WHERE configurationId LIKE '%com.liferay.multi.factor.authentication%';"
}

function disable_user_validations {
    local db_schema=$1

    # Disabling all ObjectValidationRules for the User Object
    echo "[SaaS] [$db_schema] Disabling validations for the User object"
    execute_sql_query -s "$db_schema" -q "UPDATE ObjectValidationRule AS ovr JOIN ObjectDefinition AS od ON ovr.objectDefinitionId = od.objectDefinitionId SET ovr.active_ = 0 WHERE od.externalReferenceCode = 'L_USER';" || true
}

function fix_users {
    local db_schema=$1

    # Enabling all users and fixing the default user
    echo "[SaaS] [$db_schema] Enabling all users and fixing the default user"

    # Set status to 0 for all users in the User_ table
    # Where 0 means STATUS_APPROVED, which defines the user as active
    # These values are defined in the WorkflowConstants class, for reference, please see the following link:
    # https://github.com/liferay/liferay-portal/blob/master/portal-kernel/src/com/liferay/portal/kernel/workflow/WorkflowConstants.java#L90-L108
    echo "[SaaS] Enable active status for the users"
    execute_sql_query -s "$db_schema" -q "UPDATE User_ SET status = 0;" || true

    echo "[SaaS] Update the emailAddress for the default user"
    execute_sql_query -s "$db_schema" -q "UPDATE User_ SET emailAddress = 'liferaydevsecops@liferay.com', screenName='liferaydevsecops', firstName='Liferay', lastName='DevSecOps' WHERE emailAddress = 'test@lxc.app' AND screenName = 'test';" || true
}

function sanitize_smtp_config {
    local db_schema=$1

    # Sanitizing SMTP mail settings - update the PortalPreferenceValue with Fake values for pop3 and smtp on modl env
    echo "[SaaS] [$db_schema] Sanitizing SMTP mail settings"

    echo "[SaaS] Update the pop3host for the PortalPreferenceValue"
    execute_sql_query -s "$db_schema" -q "UPDATE PortalPreferenceValue SET smallValue = 'fake-pop3-host' WHERE key_ = 'mail.session.mail.pop3.host';"
    
    echo "[SaaS] Update the mailsmtphost for the PortalPreferenceValue"
    execute_sql_query -s "$db_schema" -q "UPDATE PortalPreferenceValue SET smallValue = 'fake-smtp-host' WHERE key_ = 'mail.session.mail.smtp.host';"
    
    echo "[SaaS] Update the pop3user for the PortalPreferenceValue"
    execute_sql_query -s "$db_schema" -q "UPDATE PortalPreferenceValue SET smallValue = 'fake-pop3-user' WHERE key_ = 'mail.session.mail.pop3.user';"
    
    echo "[SaaS] Update the smtpuser for the PortalPreferenceValue"
    execute_sql_query -s "$db_schema" -q "UPDATE PortalPreferenceValue SET smallValue = 'fake-smtp-user' WHERE key_ = 'mail.session.mail.smtp.user';"
    
    echo "[SaaS] Update the pop3password for the PortalPreferenceValue"
    execute_sql_query -s "$db_schema" -q "UPDATE PortalPreferenceValue SET smallValue = 'fake-pop3-password' WHERE key_ = 'mail.session.mail.pop3.password';"
    
    echo "[SaaS] Update the smtppassword for the PortalPreferenceValue"
    execute_sql_query -s "$db_schema" -q "UPDATE PortalPreferenceValue SET smallValue = 'fake-smtp-password' WHERE key_ = 'mail.session.mail.smtp.password';"
    
    echo "[SaaS] Update the mail session for the PortalPreferenceValue"
    execute_sql_query -s "$db_schema" -q "UPDATE PortalPreferenceValue SET smallValue = 'false' WHERE key_ = 'mail.session.mail';"

    echo "[SaaS] Update the popnotification for the PortalPreferenceValue"
    execute_sql_query -s "$db_schema" -q "UPDATE PortalPreferenceValue SET smallValue = 'false' WHERE key_ = 'pop.server.notifications.enabled';"
}

function sanitize_mp_mailing_list {
    local db_schema=$1

    echo "[SaaS] [$db_schema] Sanitizing MB mailing list settings - update the MBMailingList with Fake values for pop3 and smtp on modl env"
    execute_sql_query -s "$db_schema" -q "UPDATE MBMailingList SET inServerName = 'fake-pop3-host', outServerName = 'fake-smtp-host', inPassword = 'fake-pop3-password', outPassword = 'fake-smtp-password', active_ = FALSE;"
}

function delete_analytics_config {
    local db_schema=$1

    echo "[SaaS] [$db_schema] Delete Analytics links from the Configuration_ and ProtalPreferenceValue tables in non-production environments"
    echo "[SaaS] Update Analytics links from the Configuration_ table"
    execute_sql_query -s "$db_schema" -q "UPDATE Configuration_ SET dictionary = REPLACE(dictionary, 'https://osb', 'fake://fake') WHERE configurationId LIKE '%com.liferay.analytics.settings.configuration.AnalyticsConfiguration%';"
    execute_sql_query -s "$db_schema" -q "UPDATE Configuration_ SET dictionary = REPLACE(dictionary, 'https://anal', 'fake://fake') WHERE configurationId LIKE '%com.liferay.analytics.settings.configuration.AnalyticsConfiguration%';"
    execute_sql_query -s "$db_schema" -q "UPDATE Configuration_ SET dictionary = REPLACE(dictionary, 'token=\"', 'token=\"FAKE_TOKEN_') WHERE configurationId LIKE '%com.liferay.analytics.settings.configuration.AnalyticsConfiguration%';"
    execute_sql_query -s "$db_schema" -q "UPDATE Configuration_ SET dictionary = REPLACE(dictionary, 'liferayAnalyticsProjectId=\"', 'liferayAnalyticsProjectId=\"FAKE_PID_') WHERE configurationId LIKE '%com.liferay.analytics.settings.configuration.AnalyticsConfiguration%';"

    echo "[SaaS] Update Analytics links from PortalPreferenceValue table"
    execute_sql_query -s "$db_schema" -q "UPDATE PortalPreferenceValue SET smallValue = 'fake://fakeAEU' WHERE key_ = 'liferayAnalyticsEndpointURL';"
    execute_sql_query -s "$db_schema" -q "UPDATE PortalPreferenceValue SET smallValue = 'fake://fakeFBU' WHERE key_ = 'liferayAnalyticsFaroBackendURL';"
    execute_sql_query -s "$db_schema" -q "UPDATE PortalPreferenceValue SET smallValue = 'fake://fakeAU' WHERE key_ = 'liferayAnalyticsURL';"
}

main "$@"
