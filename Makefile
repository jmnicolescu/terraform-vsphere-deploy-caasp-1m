# -------------------------------------------------------------
# File Name: Makefile
#
# Tue Oct 6 09:50:12 GMT 2020 - juliusn - initial script
# -------------------------------------------------------------

build:
	@echo " "
	@echo "Execute \> make clean  - to remove Terraform's state files"
	@echo "Execute \> make backup - to backup .tf files to .backup"
	@echo " "

clean:
	echo "Executing make clean ...."
	rm -rf .terraform terraform.tfstate terraform.tfstate.backup
	cd helpers/folders && rm -rf .terraform terraform.tfstate terraform.tfstate.backup
	cd helpers/tags && rm -rf .terraform terraform.tfstate terraform.tfstate.backup
	cd helpers/resource_pools && rm -rf .terraform terraform.tfstate terraform.tfstate.backup

backup:
	rm -rf .backup
	mkdir .backup
	cp *.tf .backup
	cp *.md .backup
	cp -r scripts .backup
	cd helpers/folders && rm -rf .backup
	cd helpers/folders && mkdir .backup
	cd helpers/folders && cp *.tf .backup
	cd helpers/tags && rm -rf .backup
	cd helpers/tags && mkdir .backup
	cd helpers/tags && cp *.tf .backup
	cd helpers/resource_pools && rm -rf .backup
	cd helpers/resource_pools && mkdir .backup
	cd helpers/resource_pools && cp *.tf .backup
	cd modules/vsphere-deploy-linux-vm && rm -rf .backup
	cd modules/vsphere-deploy-linux-vm && mkdir .backup
	cd modules/vsphere-deploy-linux-vm && cp *.tf .backup