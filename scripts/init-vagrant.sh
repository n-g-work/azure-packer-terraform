#!/usr/bin/env bash
set -o errtrace
trap 'echo "catched error on line $LINENO ";exit 1' ERR

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

ansible-galaxy install -r "${SCRIPTPATH}/../ansible/requirements.yml" --roles-path "${SCRIPTPATH}/../ansible/roles/"

vars_path="${SCRIPTPATH}/../variables.json"

packer validate -var-file "${vars_path}" "${SCRIPTPATH}/../packer/vagrant-ubuntu.json"

echo "building packer image..."
packer build -force -var-file "${vars_path}" "${SCRIPTPATH}/../packer/vagrant-ubuntu.json"

# create vm with terraform
cd "${SCRIPTPATH}/../terraform/" || exit
echo "validating terraform..."
terraform validate
echo "applying terraform module..."
terraform apply -auto-approve