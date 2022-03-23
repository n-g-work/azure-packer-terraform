#!/usr/bin/env bash
set -o errtrace
trap 'echo "catched error on line $LINENO ";exit 1' ERR

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

echo "removing ansible roles..."
rm -rf "${SCRIPTPATH}/../ansible/roles/"

vars_path="${SCRIPTPATH}/../variables.json"

# delete sensitive info
echo "removing sensitive info ..."
tmp=$(mktemp)
jq '. + {
        client_id: "",
        client_secret: "",
        tenant_id: "",
        subscription_id: "",
    }' \
    "$vars_path" > "$tmp" && mv "$tmp" "$vars_path"

# remove app registration
echo "removing app registration ..."
jq -r '.packer_app_name' "$vars_path"
app_id=$(az ad app list --display-name "$(jq -r '.packer_app_name' "$vars_path")" | jq -r '.[].appId')
az ad sp delete --id "${app_id}" || true

# remove resource group
echo "removing resource groups ..."
jq -r '.packer_images_resource_group' "$vars_path"
az group delete -n "$(jq -r '.packer_images_resource_group' "$vars_path")" --yes || true
jq -r '.vm_resource_group_name' "$vars_path"
az group delete -n "$(jq -r '.vm_resource_group_name' "$vars_path")" --yes || true
