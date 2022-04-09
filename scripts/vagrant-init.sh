#!/usr/bin/env bash
set -o errtrace
trap 'echo "catched error on line $LINENO ";exit 1' ERR

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

ansible-galaxy install -r "${SCRIPTPATH}/../ansible/requirements.yml" --roles-path "${SCRIPTPATH}/../ansible/roles/"

pathadd() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then PATH="${PATH:+"$PATH:"}$1"; fi
}

# for wsl
if grep -q Microsoft /proc/version; then
  echo "Windows Subsystem for Linux detected"
  echo "Please specify VirtualBox install directory on Windows (e.g.: /mnt/c/Program Files/Oracle/VirtualBox)"
  read -p "[/mnt/c/apps/VirtualBox]: " -r virtualbox_installation_path
  if [ -z "$virtualbox_installation_path" ]; then virtualbox_installation_path='/mnt/c/apps/VirtualBox'; fi
  pathadd "${virtualbox_installation_path}"
  export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
fi

echo "building packer image..."
packer build -force -var-file "${vars_path}" "${SCRIPTPATH}/../packer/vagrant-ubuntu.json"

# create vm with terraform
cd "${SCRIPTPATH}/../terraform/" || exit
echo "validating terraform..."
terraform validate
echo "applying terraform module..."
terraform apply -auto-approve