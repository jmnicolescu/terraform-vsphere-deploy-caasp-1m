# -------------------------------------------------------------
# File Name: create_tags.tf
# Create a VMware category and VM tag. Assign the tag to a VM.
#
# Tue Nov 3 12:59:12 BST 2020 - juliusn - initial script
# -------------------------------------------------------------

# Note: he vsphere_tag and vsphere_tag_category resources are designed 
# to manage new tags and categories only - this is in line with the 
# general principles of Terraform

# --- Provider
provider "vsphere" {
    user                    = var.provider_vsphere_user
    password                = var.provider_vsphere_password
    vsphere_server          = var.provider_vsphere_host
    allow_unverified_ssl    = var.provider_vsphere_unverified_ssl
}


data "vsphere_tag_category" "vsan" {    
    name = "vSANDirectStorage"
} 

# -------------------------------------------------------------
# Tag Categories
# -------------------------------------------------------------
resource "vsphere_tag_category" "category01" {    
    name = var.guest_category_name
    description = var.guest_category_name
    cardinality = "SINGLE"
    associable_types = [        
        "VirtualMachine"    
    ]
} 

# -------------------------------------------------------------
# VM Tag - Category: User Defines
# -------------------------------------------------------------
resource "vsphere_tag" "tag01_category01" {    
    name = var.guest_tag_name
    description = var.guest_tag_name    
    category_id = vsphere_tag_category.category01.id
    depends_on    = [vsphere_tag_category.category01]
} 

# -------------------------------------------------------------
# VM Tag - Category: vSANDirectStorage
# -------------------------------------------------------------
resource "vsphere_tag" "tag02_vsan" {    
    name = var.guest_tag_name
    description = var.guest_tag_name    
    category_id = data.vsphere_tag_category.vsan.id
} 