#!/usr/bin/env bash
set -o errtrace
trap 'echo "catched error on line $LINENO ";exit 1' ERR

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

vars_path="${SCRIPTPATH}/../.tfvars.json"

AZ_RESOURCE_GROUP_NAME=$(jq -r '.AZ_RESOURCE_GROUP_NAME' "$vars_path")
AZ_APP_NAME=$(jq -r '.AZ_APP_NAME' "$vars_path")

# delete sensitive info
echo "removing sensitive info ..."
vars_path="$SCRIPTPATH/../.tfvars.json"
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
app_id=$(az ad app list --display-name "${AZ_APP_NAME}" | jq -r '.[].appId')
az ad sp delete --id "${app_id}" || true

# remove resource group
echo "removing resource group ..."
az group delete -n "${AZ_RESOURCE_GROUP_NAME}" --yes || true
