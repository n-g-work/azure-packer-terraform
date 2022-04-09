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

# build base VM from bionic ubuntu cloud image with addition of docker
VAGRANT_VAGRANTFILE="${SCRIPTPATH}/../vagrant/Vagrantfile_base" vagrant up

# stop built VM
VAGRANT_VAGRANTFILE="${SCRIPTPATH}/../vagrant/Vagrantfile_base" vagrant halt

# export it as a new box
vagrant package --base bionic_docker_local --output bionic_docker_local.box

# remove the no longer needed VM
VAGRANT_VAGRANTFILE="${SCRIPTPATH}/../vagrant/Vagrantfile_base" vagrant destroy -f

# add the box to vagrant inventory
vagrant box add "bionic_docker_local.box" "${SCRIPTPATH}/../bionic_docker_local.box"

# start and provision all the VMs
VAGRANT_VAGRANTFILE="${SCRIPTPATH}/../vagrant/Vagrantfile" vagrant up
