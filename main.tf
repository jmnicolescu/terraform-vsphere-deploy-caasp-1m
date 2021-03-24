# -------------------------------------------------------------
# File Name: main.tf
# Deploy a new VM from a template.
#
# REQUIREMENTS #1: vsphere_tag_category and vsphere_tag must exist
#                  cd helpers/tags && terraform apply
# REQUIREMENTS #2: deploy_vsphere_folder and deploy_vsphere_sub_folder must exist
#                  cd helpers/folders && terraform apply
#
# Tue Oct 6 09:50:12 GMT 2020 - juliusn - initial script
# -------------------------------------------------------------

# -- Provider
provider "vsphere" {
    user                    = var.provider_vsphere_user
    password                = var.provider_vsphere_password
    vsphere_server          = var.provider_vsphere_host
    allow_unverified_ssl    = var.provider_vsphere_unverified_ssl
}

# -------------------------------------------------------------
# VM deployment - VM configuration files
# -------------------------------------------------------------

module "vm-deployment" {
    source = "./vm-deployment"
}

# -------------------------------------------------------------
# Example - output files
# -------------------------------------------------------------

output "c2-admin-VM-ip" {
	value = module.vm-deployment.c2-admin-VM-ip
}

output "c2-master1-VM-ip" {
	value = module.vm-deployment.c2-master1-VM-ip
}

output "c2-worker1-VM-ip" {
	value = module.vm-deployment.c2-worker1-VM-ip
}

output "c2-worker2-VM-ip" {
	value = module.vm-deployment.c2-worker2-VM-ip
}
