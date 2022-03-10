# Hosting dockerized Java application with Terraform and Packer in Azure

## Overview

This is an example project that uses [packer](https://www.packer.io/) and [terraform](https://www.terraform.io/) to manage virtual machines and docker containers in [Azure](https://portal.azure.com/) cloud.

## Requirements

To get through with all the operations these requirements should be met:

* Azure account obtained
* terraform installed locally
* packer installed locally
* azure cli installed locally

## Cost

With the use of Azure free account the actions could be performed without an additional cost. However free Azure account registration requires use of a banking card.

## Azure + packer

Create azure resource group:

```bash
az group create -n packergroup -l eastus
```

Create service principal (app registration):

```bash
az ad sp create-for-rbac --role Contributor --name packer001 --query "{ client_id: appId, client_secret: password, tenant_id: tenant }"
```

Expected output:

```json
{
    "": ""
}
```

Get Azure subscription id:

```bash
az account show --query "{ subscription_id: id }"
```

Build packer image:

```packer
packer build azure-ubuntu.json
```

Create VM in Azure using built packer image:

```bash
az vm create --resource-group packergroup --name packedVm --image packerimage --public-ip-sku Standard --admin-username packerazuser --generate-ssh-keys
```

Allow access through port 80:

```bash
az vm open-port --resource-group packergroup --name packedVm --port 80
```

Convert pakcer json file to hcl:

```bash
packer hcl2_upgrade -with-annotations azure-ubuntu.json
```
