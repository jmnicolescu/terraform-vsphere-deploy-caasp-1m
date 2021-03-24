#!/bin/sh
#--------------------------------------------------------------------------------------
# CaaSP 4.2.5 / SUSE Linux Enterprise Server 15 SP1
#
#  - Configure vSphere Storage
#  - Deploy NFS client provisioner
#
#  - Run the script only as caaspadm user [ EUID=1000 ]
#
# Tue Feb 23 07:26:42 GMT 2021 - juliusn - initial script
# Sun Mar  7 05:28:01 GMT 2021 - juliusn - use helm3, check for caaspadm user
#--------------------------------------------------------------------------------------
# vSphere Storage for Kubernetes
# https://vmware.github.io/vsphere-storage-for-kubernetes/documentation/index.html


. /home/caaspadm/.bash_profile

HOSTNAME=`hostname`
echo -e "\n[ ${HOSTNAME} ] --> Running script $0 \n"

# Run the script only as caaspadm user [ EUID=1000 ]
if [ "$EUID" != 1000 ]; then 
		echo -e "\n[ ${HOSTNAME} ] Run the script only as caaspadm user [ EUID=1000 ]\n"
		exit 1
fi 

#--------------------------------------------------------------------------------------
# Static Provisioning (Not Recommended)
# https://vmware.github.io/vsphere-storage-for-kubernetes/documentation/persistent-vols-claims.html
#--------------------------------------------------------------------------------------
echo -e "\n[ ${HOSTNAME} ] vSphere storage for Kubernetes - Static Provisioning.\n"

# Create 20GB VMDK disk
echo -e "\n[ ${HOSTNAME} ] Creating 20GB disk [ CAASP-C2/caasp-disk-01-20g.vmdk ] on vsanDatastore.\n"

govc datastore.mkdir -dc=EAST-DC -ds=vsanDatastore CAASP-C2
govc datastore.disk.create -dc=EAST-DC -ds=vsanDatastore -size=20G CAASP-C2/caasp-disk-01-20g.vmdk
govc datastore.disk.info -ds=vsanDatastore CAASP-C2/caasp-disk-01-20g.vmdk

# Define vsphere-static StorageClass using a YAML manifest file. 
kubectl apply -f vsphere-storage/create-static-storage-class.yaml 
kubectl get sc vsphere-static

# Supported accessModes: - ReadWriteOnce
kubectl apply -f vsphere-storage/create-static-pv.yaml
kubectl get pv static-pv-01

kubectl apply -f vsphere-storage/create-static-pvc.yaml

echo -e "\n[ ${HOSTNAME} ] Review STATUS for static pvc ...\n"
kubectl get pvc static-pvc-01
sleep 10

#--------------------------------------------------------------------------------------
# Dynamic Provisioning (Recommended)
# https://vmware.github.io/vsphere-storage-for-kubernetes/documentation/policy-based-mgmt.html
#--------------------------------------------------------------------------------------
echo -e "\n[ ${HOSTNAME} ] vSphere storage for Kubernetes - Dynamic Provisioning.\n"
echo -e "\n[ ${HOSTNAME} ] Creating dynamic StorageClass using vSAN Policy [ EAST-STORAGE-PROFILE ]\n"

kubectl apply -f vsphere-storage/create-dynamic-storage-class.yaml
kubectl get sc vsphere-dynamic

kubectl apply -f vsphere-storage/create-dynamic-pvc.yaml

echo -e "\n[ ${HOSTNAME} ] Review STATUS for dynamic pvc ...\n"
kubectl get pvc dynamic-pvc-01
sleep 10

# Mark only one StorageClass as default
kubectl patch storageclass nfs-client -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
kubectl patch storageclass vsphere-dynamic -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

exit 0
