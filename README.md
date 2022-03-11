# Hosting dockerized Java application with Terraform and Packer in Azure

## Overview

This is an example project that uses [packer](https://www.packer.io/) and [terraform](https://www.terraform.io/) to manage virtual machines and docker containers in [Azure](https://portal.azure.com/) cloud.

## Requirements

To get through with all the operations these requirements should be met:

* Azure account obtained
* terraform installed locally
* packer installed locally
* azure cli installed locally

Install on Linux (Ubuntu):

```bash
sudo apt-get install -y azure-cli terraform packer
```

## Cost

With the use of Azure free account the actions could be performed without an additional cost. However free Azure account registration requires use of a banking card.

## Login to Azure with device code

Run command to obtain device code:

```bash
az login --use-device-code
```

Expected result:
To sign in, use a web browser to open the page [https://microsoft.com/devicelogin] and enter the code `YOUR DEVICE CODE` to authenticate.

Go to the page and input obtained code.

## Azure + packer

Create azure resource group:

```bash
az group create -n packergroup -l eastus
```

Get Azure subscription id:

```bash
az account show --query "{ subscription_id: id }"
```

Expected output:

```json
{
  "subscription_id": "{YOUR SUBSCRIPTION ID}"
}
```

Create service principal (app registration):

```bash
az ad sp create-for-rbac --role Contributor --name api://packer001 \
    --query "{ client_id: appId, client_secret: password, tenant_id: tenant }" \
    --scopes /subscriptions/{YOUR SUBSCRIPTION ID}/resourceGroups/packergroup
```

Expected output:
Creating a role assignment under the scope of "/subscriptions/815662c5-ba1b-4526-aad0-fe1c70e27ed0/resourceGroups/packergroup"
  Retrying role assignment creation: 1/36
  Retrying role assignment creation: 2/36

```json
{
  "client_id": "{YOUR CLIENT ID}",    
  "client_secret": "{YOUR CLIENT SECRECT}",
  "tenant_id": "{YOUR TENANT ID}"     
}
```

Update the client and tenant info in packer image description - [packer/azure-ubuntu.json] or [packer/azure-ubuntu.pkr.hcl]

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
