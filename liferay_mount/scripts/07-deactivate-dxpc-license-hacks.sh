#!/bin/bash

function install_license {
	echo "[SaaS] Removing DXP Cloud license."

	rm -fv /opt/liferay/data/license/DXPCloudInternal*

	echo "[SaaS] Removing the DXP Cloud license from deploy."

	rm -fv /opt/liferay/deploy/dxpActivationLicense.xml

	echo "[SaaS] Writing the LXC license."

	mkdir -p /opt/liferay/data/license

	echo -n "${LXC_DXP_LICENSE}" > /opt/liferay/data/license/LiferayExperienceCloudPatches_DXPUnlimitedEnterpriseWide_enterprise.li
}

function remove_scripts {
	echo "[SaaS] Deleting obsolete DXP Cloud licensing scripts."

	rm -fv /usr/local/liferay/scripts/pre-startup/010_get_dxp_activation_license.sh
	rm -fv /usr/local/liferay/scripts/pre-startup/105_liferay_cloud_mounted_config.sh
}

function main {
	if [ -z "${LXC_DXP_LICENSE}" ]
	then
		echo "[SaaS] WARNING: The LXC license is not loaded as LXC_DXP_LICENSE is not set."

		return
	fi

	if [ "${LXC_DXP_LICENSE}" == "@lxc-dxp-license" ]
	then
		echo "[SaaS] WARNING: The LXC license is not loaded as LXC_DXP_LICENSE is @lxc-dxp-license, the secret was not loaded properly."

		return
	fi

	if [ $(date +%Y) -gt 2122 ]
	then
		echo "[SaaS] WARNING: The LXC license is not loaded as it's 2123 or later."

		return
	fi

	install_license

	remove_scripts
}

main