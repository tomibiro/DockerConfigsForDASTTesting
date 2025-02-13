#!/usr/bin/env bash
if [[ $1 = "-p" ]]
then
    if [[ $2 ]]
    then
        mkdir -p "${2}"
        
        mysqldump -h$DATABASE_PORT_3306_TCP_ADDR -u $LCP_SECRET_DATABASE_USER -p$LCP_SECRET_DATABASE_PASSWORD --skip-add-locks --no-create-info --column-statistics=0 lportal Configuration_ --where="configurationId LIKE 'com.liferay.saml.%' OR configurationId LIKE 'com.liferay.portal.security.ldap.%' OR configurationId LIKE 'com.liferay.portal.security.sso.openid.%'" > "${2}/Configuration_" 2> /dev/null
		
        mysql -u $LCP_SECRET_DATABASE_USER -p$LCP_SECRET_DATABASE_PASSWORD -e "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME LIKE 'lpartition_%'" > "${2}/lpartitions.txt" 2> /dev/null;
         
        input="${2}/lpartitions.txt"
        
        while IFS= read -r line
        do
            if [[ $line =~ .*(lpartition_[0-9]*) ]]
            then 
                mysqldump -h$DATABASE_PORT_3306_TCP_ADDR -u $LCP_SECRET_DATABASE_USER -p$LCP_SECRET_DATABASE_PASSWORD --skip-add-locks --no-create-info --column-statistics=0 ${BASH_REMATCH[1]} SamlIdpSpConnection SamlIdpSpSession SamlIdpSsoSession SamlPeerBinding SamlSpAuthRequest SamlSpIdpConnection SamlSpMessage SamlSpSession OpenIdConnectSession > "${2}/${BASH_REMATCH[1]}" 2> /dev/null
            fi
        done < "$input"
    fi
else
    echo "Export should be run from the command line. Please supply the destination folder path as an argument. e.g. 07-export-saml-configs.sh -p  /opt/liferay/data/SamlConfig"
fi
