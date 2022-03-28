# Hosting dockerized Java application with Terraform and Packer in Azure

## Overview

This is an example project that uses [packer](https://www.packer.io/) and [terraform](https://www.terraform.io/) to manage virtual machines and docker containers in [Azure](https://portal.azure.com/) cloud.

## Requirements

To get through with all the operations these requirements should be met:

* Azure account obtained
* terraform installed locally
* packer installed locally
* azure cli installed locally
* jq installed
* ansible and docker for debug

Install on Linux (Ubuntu):

```bash
sudo apt-get install -y azure-cli terraform packer jq ansible
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

Expected output:

```bash
{
  "id": "/subscriptions/{YOUR SUBSCRIPTION ID}/resourceGroups/packergroup",
  "location": "eastus",
  "managedBy": null,
  "name": "packergroup",
  "properties": {
    "provisioningState": "Succeeded"
  },
  "tags": null,
  "type": "Microsoft.Resources/resourceGroups"
}
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
az ad sp create-for-rbac --role Owner --name api://packer001 \
    --query "{ client_id: appId, client_secret: password, tenant_id: tenant }" \
    --scopes /subscriptions/{YOUR SUBSCRIPTION ID}
```

Expected output:
Creating a role assignment under the scope of "/subscriptions/{YOUR SUBSCRIPTION ID}"
  Retrying role assignment creation: 1/36
  Retrying role assignment creation: 2/36

```json
{
  "client_id": "{YOUR CLIENT ID}",    
  "client_secret": "{YOUR CLIENT SECRECT}",
  "tenant_id": "{YOUR TENANT ID}"     
}
```

Update the client and tenant info in packer variables files - [packer/variables.json]

Build packer image:

```packer
cd packer/
packer build -var-file variables.json azure-ubuntu.json
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

## Automation

Useful scripts:

* scripts/init.sh - installs ansible galaxy roles, then creates azure resource group for packer images, app registration (packer app) and packer image, and then launches terraform
* scripts/remove.sh - removes ansible roles, sensitive info, app registration and resource groups

The scripts use variables from variables.json.

## References

* [How to use Packer to create Linux virtual machine images in Azure](https://docs.microsoft.com/en-us/azure/virtual-machines/linux/build-image-with-packer)
* [Create an Azure virtual machine scale set from a Packer custom image by using Terraform](https://docs.microsoft.com/en-us/azure/developer/terraform/create-vm-scaleset-network-disks-using-packer-hcl)
