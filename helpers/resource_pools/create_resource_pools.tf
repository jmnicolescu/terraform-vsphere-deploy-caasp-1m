# -------------------------------------------------------------
# File Name: create_resource_pools.tf
# Create a VM folder and sub folder on given datacenter.
#
# Tue Nov 3 12:59:12 BST 2020 - juliusn - initial script
# -------------------------------------------------------------

# --- Provider
provider "vsphere" {
    user                    = var.provider_vsphere_user
    password                = var.provider_vsphere_password
    vsphere_server          = var.provider_vsphere_host
    allow_unverified_ssl    = var.provider_vsphere_unverified_ssl
}

# --- Data sources
data "vsphere_datacenter" "target_dc" {
    name = var.vsphere_datacenter
}

data "vsphere_compute_cluster" "target_cluster" {
    name          = var.vsphere_cluster
    datacenter_id = data.vsphere_datacenter.target_dc.id
}

# --- Resources
resource "vsphere_resource_pool" "resource_pool" {
  name                      = var.vsphere_resource_pool
  parent_resource_pool_id   = "${data.vsphere_compute_cluster.target_cluster.resource_pool_id}"
}
