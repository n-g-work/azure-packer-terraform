#!/usr/bin/env bash
set -o errtrace
trap 'echo "catched error on line $LINENO ";exit 1' ERR

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

vars_path="${SCRIPTPATH}/../.tfvars.json"

AZ_RESOURCE_GROUP_NAME=$(jq -r '.AZ_RESOURCE_GROUP_NAME' "$vars_path")
AZ_LOCATION=$(jq -r '.AZ_LOCATION' "$vars_path")
AZ_SP_ROLE=$(jq -r '.AZ_SP_ROLE' "$vars_path")
AZ_APP_NAME=$(jq -r '.AZ_APP_NAME' "$vars_path")
AZ_PACKER_IMAGE_NAME=$(jq -r '.AZ_PACKER_IMAGE_NAME' "$vars_path")

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

# debug:
echo "azure app registration:"
echo "client_id: ${client_id}"
echo "client_secret: ${client_secret}"
echo "tenant_id: ${tenant_id}"
# end debug

# save variables for packer

tmp=$(mktemp)
jq '. + {
        client_id: "'"$client_id"'",
        client_secret: "'"$client_secret"'",
        tenant_id: "'"$tenant_id"'",
        subscription_id: "'"$subscription_id"'",
        resource_group_name: "'"$AZ_RESOURCE_GROUP_NAME"'",
        image_name: "'"$AZ_PACKER_IMAGE_NAME"'"
    }' \
    "$vars_path" > "$tmp" && mv "$tmp" "$vars_path"
# revert variables: git checkout -q .tfvars.json

echo "waiting for azure..."
sleep 10s

# run packer build
packer validate -var-file "${vars_path}" "${SCRIPTPATH}/../packer/azure-ubuntu.json"
packer build -var-file "${vars_path}" "${SCRIPTPATH}/../packer/azure-ubuntu.json"

# TODO: 
# create vm with terraform
# cd ${SCRIPTPATH}/../terraform/
# terraform apply -auto-approve