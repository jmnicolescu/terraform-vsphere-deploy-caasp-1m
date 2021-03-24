# -------------------------------------------------------------
# File Name: variables.tf
# Defining simple variables required for VM deployment
#
# Tue Nov 3 12:59:12 BST 2020 - juliusn - initial script
# -------------------------------------------------------------

# -------------------------------------------------------------
# PROVIDER - VMware vSphere vCenter connection 
# -------------------------------------------------------------

variable "provider_vsphere_host" {
    description = "vCenter server FQDN or IP"
    type        = string
}

variable "provider_vsphere_user" {
    description = "vSphere username to use to connect to the environment"
    type        = string
}

variable "provider_vsphere_password" {
    description = "vSphere password"
    type        = string
}

variable "provider_vsphere_unverified_ssl" {
    description = "If there is a self-signed cert"
    default     = true
}

# -------------------------------------------------------------
# INFRASTRUCTURE - VMware vSphere vCenter settings 
# -------------------------------------------------------------

variable "vsphere_datacenter" {
    description = "vSphere datacenter in which the virtual machine will be deployed."
}

variable "vsphere_cluster" {
    description = "vSphere cluster in which the virtual machine will be deployed."
}

variable "vsphere_resource_pool"{
    description = "The resource pool to put this virtual machine in."
}
