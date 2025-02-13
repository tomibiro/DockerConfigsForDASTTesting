#!/usr/bin/env bash

set -o errexit

if [[ "${LOCAL_STACK}" == "true" ]]
then
  return
fi

if [ -z "${LDAP_CERTIFICATE}" ]
then
  echo "[SaaS] LDAP certificate is not present."
else
  mkdir $LIFERAY_HOME/certificates

  SOURCE_PATH=$LIFERAY_HOME/certificates
  CACERTS_ORIGIN_PATH=$JAVA_HOME/lib/security/cacerts
  CACERTS_LIFERAY_PATH=$SOURCE_PATH/cacerts

  echo "[SaaS] Copying the default keystore to a new path"

  cp -f $CACERTS_ORIGIN_PATH $CACERTS_LIFERAY_PATH

  echo "[SaaS] Importing certificate"
  echo "${LDAP_CERTIFICATE}" | base64 -d | keytool -import -alias ldapcert -keystore $CACERTS_LIFERAY_PATH -storepass changeit -noprompt
  
  keytool -list -keystore $CACERTS_LIFERAY_PATH -storepass changeit -noprompt | grep ldapcert
fi
