#!/usr/bin/env bash
set -o errtrace
trap 'echo "catched error on line $LINENO ";exit 1' ERR

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

# shellcheck source=/dev/null
source "${SCRIPTPATH}/vars.sh"

# create azure resource group
az_resource_group=$(az group create -n "${AZ_RESOURCE_GROUP_NAME}" -l "${AZ_LOCATION}")

echo "azure resource group:"
echo "${az_resource_group}"

# get azure subscription
az_subscription=$(az account show --query "{ subscription_id: id }")

subscription_id=$(jq -r '.subscription_id' <<< "${az_subscription}")
echo "azure subscription id: ${subscription_id}"

# create azure service principal (app registration) and grant permissions to resource group
az_app_registration=$(az ad sp create-for-rbac --role "${AZ_SP_ROLE}" --name "api://${AZ_APP_NAME}" \
    --query "{ client_id: appId, client_secret: password, tenant_id: tenant }" \
    --scopes "/subscriptions/${subscription_id}")

client_id=$(jq -r '.client_id' <<< "${az_app_registration}")
client_secret=$(jq -r '.client_secret' <<< "${az_app_registration}")
tenant_id=$(jq -r '.tenant_id' <<< "${az_app_registration}")
echo "azure app registration:"
echo "client_id: ${client_id}"
echo "client_secret: ${client_secret}"
echo "tenant_id: ${tenant_id}"

# save variables for packer
cat <<EOF >"${SCRIPTPATH}/../packer/variables.json"
{
    "client_id": "${client_id}",
    "client_secret": "${client_secret}",
    "tenant_id": "${tenant_id}",
    "subscription_id": "${subscription_id}",
    "resource_group_name": "${AZ_RESOURCE_GROUP_NAME}",
    "image_name": "${AZ_PACKER_IMAGE_NAME}"
}
EOF

# run packer build
packer build -var-file "${SCRIPTPATH}/../packer/variables.json" "${SCRIPTPATH}/../packer/azure-ubuntu.json"