#!/usr/bin/env bash

source /mnt/liferay/scripts/_common.sh

function get_product_version {
  unzip -q -c tomcat/webapps/ROOT/WEB-INF/shielded-container-lib/portal-kernel.jar META-INF/MANIFEST.MF | grep 'Git-SHA\|Liferay-Portal-Version-Display-Name' > poshi/dxp-version
}

function get_dxp_update_type {
  if [[ "${LIFERAY_RELEASE_VERSION}" == *nightly* ]]
  then
    DXP_UPDATE_TYPE="MODL Nightly"
  else
    DXP_UPDATE_TYPE="MODL Latest Update"
  fi

  echo "DXP_UPDATE_TYPE: ${DXP_UPDATE_TYPE}" >> poshi/dxp-version
}

function main {
  if [[ "${LOCAL_STACK}" == "true" ]]
  then
    return
  fi

  get_product_version
  get_dxp_update_type
 
}

main "$@"