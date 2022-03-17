#!/usr/bin/env bash
set -o errtrace
trap 'echo "catched error on line $LINENO ";exit 1' ERR

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

# shellcheck source=/dev/null
source "$SCRIPTPATH/vars.sh"

# delete sensitive info
echo "removing sensitive info ..."
cat <<EOF >"${SCRIPTPATH}/../packer/variables.json"
{
    "client_id": "",
    "client_secret": "",
    "tenant_id": "",
    "subscription_id": "",
    "resource_group_name": "",
    "image_name": ""
}
EOF

# remove app registration
echo "removing app registration ..."
app_id=$(az ad app list --display-name "${AZ_APP_NAME}" | jq -r '.[].appId')
az ad sp delete --id "${app_id}" || true

# remove resource group
echo "removing resource group ..."
az group delete -n "${AZ_RESOURCE_GROUP_NAME}" --yes || true
