#!/usr/bin/env bash
set -o errtrace
trap 'echo "catched error on line $LINENO ";exit 1' ERR

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

VAGRANT_VAGRANTFILE="${SCRIPTPATH}/../vagrant/Vagrantfile" vagrant destroy -f

rm -rf "${SCRIPTPATH}/../ansible/roles" "${SCRIPTPATH}/../.vagrant" "${SCRIPTPATH}/../vagrant/.vagrant"
find "${SCRIPTPATH}/../balancer" -name "*.log" -type f -delete