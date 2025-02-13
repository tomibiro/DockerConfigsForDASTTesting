#!/usr/bin/env bash
if [[ $1 = "-p" ]]
then
    if [[ $2 ]]
    then
        PATH_TO_FILES="${2}"

        shopt -s nullglob

        cd "${PATH_TO_FILES}"
		
        #Delete Saml related Configuration_ entries
        mysql -u $LCP_SECRET_DATABASE_USER -p$LCP_SECRET_DATABASE_PASSWORD -e "DELETE FROM lportal.Configuration_ WHERE configurationId LIKE 'com.liferay.saml.%' OR configurationId LIKE 'com.liferay.portal.security.ldap.%' OR configurationId LIKE 'com.liferay.portal.security.sso.openid.%'" 2> /dev/null
        echo "Importing Configuration_"
        mysql -u $LCP_SECRET_DATABASE_USER -p$LCP_SECRET_DATABASE_PASSWORD --force -Dlportal < Configuration_ 2> /dev/null

        for PARTITION in *
        do
            if [[ $PARTITION =~ .*(lpartition_[0-9]*) ]]
            then 
                declare -a SamlTable=("SamlIdpSpConnection" "SamlIdpSpSession" "SamlIdpSsoSession" "SamlPeerBinding" "SamlSpAuthRequest" "SamlSpIdpConnection" "SamlSpMessage" "SamlSpSession" "OpenIdConnectSession")
                for curTable in "${SamlTable[@]}"
                do
                    #Delete rows from the Saml Table
                    mysql -u $LCP_SECRET_DATABASE_USER -p$LCP_SECRET_DATABASE_PASSWORD -e "DELETE FROM ${PARTITION}.${curTable}" 2> /dev/null
                done
                #Insert rows using the mysqldump output
                echo "Importing ${PARTITION}"
                mysql -u $LCP_SECRET_DATABASE_USER -p$LCP_SECRET_DATABASE_PASSWORD --force -D${PARTITION} < "${PARTITION}" 2> /dev/null
            fi
        done
        shopt -u nullglob
    fi
else
    echo "Import should be run from the command line. Please supply the source folder path as an argument. e.g. 08-import-saml-configs.sh -p /opt/liferay/data/SamlConfig"
fi

