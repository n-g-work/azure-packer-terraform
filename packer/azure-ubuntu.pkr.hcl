# This file was autogenerated by the 'packer hcl2_upgrade' command. We
# recommend double checking that everything is correct before going forward. We
# also recommend treating this file as disposable. The HCL2 blocks in this
# file can be moved to other files. For example, the variable blocks could be
# moved to their own 'variables.pkr.hcl' file, etc. Those files need to be
# suffixed with '.pkr.hcl' to be visible to Packer. To use multiple files at
# once they also need to be in the same folder. 'packer inspect folder/'
# will describe to you what is in that folder.

# Avoid mixing go templating calls ( for example ```{{ upper(`string`) }}``` )
# and HCL2 calls (for example '${ var.string_value_example }' ). They won't be
# executed together and the outcome will be unknown.

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source. Read the documentation for source blocks here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
source "azure-arm" "autogenerated_1" {
  azure_tags = {
    dept = "Devops"
    task = "Image deployment"
  }
  client_id                         = "<azure client id>"
  client_secret                     = "<azure client secret>"
  image_offer                       = "UbuntuServer"
  image_publisher                   = "Canonical"
  image_sku                         = "18.04-LTS"
  location                          = "East US"
  managed_image_name                = "packerimage"
  managed_image_resource_group_name = "packergroup"
  os_type                           = "Linux"
  subscription_id                   = "<azure subscription>"
  tenant_id                         = "<azure tenant>"
  vm_size                           = "Standard_A2_v2"
}

# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  sources = ["source.azure-arm.autogenerated_1"]

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    inline          = [
      "apt-get update", 
      "apt-get install -y ca-certificates curl gnupg lsb-release", 
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg", 
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null", 
      "apt-get update", 
      "apt-get install -y docker-ce docker-ce-cli containerd.io", 
      "docker pull ng01000/petclinic:latest", 
      "docker run -dt -p 80:8080 --restart always ng01000/petclinic:latest", 
      "/usr/sbin/waagent -force -deprovision+user && export HISTSIZE=0 && sync"
      ]
    inline_shebang  = "/bin/sh -x"
  }

}