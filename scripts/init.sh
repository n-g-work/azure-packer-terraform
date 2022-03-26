#!/usr/bin/env bash
set -o errtrace
trap 'echo "catched error on line $LINENO ";exit 1' ERR

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

ansible-galaxy install -r "${SCRIPTPATH}/../ansible/requirements.yml" --roles-path "${SCRIPTPATH}/../ansible/roles/"

vars_path="${SCRIPTPATH}/../variables.json"

packer_images_resource_group=$(jq -r '.packer_images_resource_group' "$vars_path")
location=$(jq -r '.location' "$vars_path")
service_principal_role=$(jq -r '.service_principal_role' "$vars_path")
packer_app_name=$(jq -r '.packer_app_name' "$vars_path")

# create packer resource group in azure
az_resource_group=$(az group create -n "${packer_images_resource_group}" -l "${location}")

echo "azure resource group:"
echo "${az_resource_group}"

# get azure subscription
az_subscription=$(az account show --query "{ subscription_id: id }")

subscription_id=$(jq -r '.subscription_id' <<< "${az_subscription}")
echo "azure subscription id: ${subscription_id}"

# create azure service principal (app registration) and grant permissions to resource group
az_app_registration=$(az ad sp create-for-rbac --role "${service_principal_role}" --name "api://${packer_app_name}" \
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
        subscription_id: "'"$subscription_id"'"
    }' \
    "$vars_path" > "$tmp" && mv "$tmp" "$vars_path"

echo "waiting for azure..."
sleep 10s

# run packer
echo "validating packer..."
packer validate -var-file "${vars_path}" "${SCRIPTPATH}/../packer/azure-ubuntu.json"

echo "building packer image..."
packer build -var-file "${vars_path}" "${SCRIPTPATH}/../packer/azure-ubuntu.json"

# create vm with terraform
cd "${SCRIPTPATH}/../terraform/" || exit
echo "validating terraform..."
terraform validate
echo "applying terraform module..."
# TODO:
# terraform apply -auto-approve