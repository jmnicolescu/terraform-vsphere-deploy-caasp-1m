#!/bin/sh
#--------------------------------------------------------------------------------------
# CaaSP 4.2.5 / SUSE Linux Enterprise Server 15 SP1
#
#  - Configure CaaSP4 cluster
#  - Deploy NFS client provisioner
#
#  - Run the script only as caaspadm user [ EUID=1000 ]
#
# Tue Feb 23 07:26:42 GMT 2021 - juliusn - initial script
# Sun Mar  7 05:28:01 GMT 2021 - juliusn - use helm3, check for caaspadm user
#--------------------------------------------------------------------------------------
# Deployment Instructions
# https://documentation.suse.com/suse-caasp/4.5/html/caasp-deployment/_deployment_instructions.html

# Bootstrapping the Cluster
# https://documentation.suse.com/suse-caasp/4.5/html/caasp-deployment/bootstrap.html


NFSserver=c2-admin.flexlab.local
NFSpath="/caasp4-storage"
NFSdeploy="caasp4-storage"

HOSTNAME=`hostname`
echo -e "\n[ ${HOSTNAME} ] --> Running script $0 \n"

# Run the script only as caaspadm user [ EUID=1000 ]
if [ "$EUID" != 1000 ]; then 
		echo -e "\n[ ${HOSTNAME} ] Run the script only as caaspadm user [ EUID=1000 ]\n"
		exit 1
fi 

#--------------------------------------------------------------------------------------
# Deploy NFS-Client-Provisioner
#--------------------------------------------------------------------------------------

# this is a workaround as suse no longer provides nfs-client-provisioner
echo -e "\n[ ${HOSTNAME} ] Add repo [ suse ] https://kubernetes-charts.suse.com"
echo -e "\n[ ${HOSTNAME} ] Add repo [ stable ]	https://charts.helm.sh/stable"

helm3 repo add suse https://kubernetes-charts.suse.com
helm3 repo add stable https://charts.helm.sh/stable
helm3 repo update

# nfs-client-provisioner
# The NFS client provisioner is an automatic provisioner for Kubernetes that uses your already configured NFS server, 
# automatically creating Persistent Volumes.
# https://github.com/helm/charts/tree/master/stable/nfs-client-provisioner

echo -e "\n[ ${HOSTNAME} ] Configure NFS Storage. \n"
helm3 install ${NFSdeploy} stable/nfs-client-provisioner --set storageClass.defaultClass=true --set nfs.server=${NFSserver} --set nfs.path=${NFSpath}
helm3 list --all-namespaces

echo -e "\n[ ${HOSTNAME} ] ... sleeping 120 secs ... waiting for nfs-client deployment ... \n"
sleep 120

# remove workaround
helm3 repo remove stable

echo -e "\n[ ${HOSTNAME} ] Get StorageClass [ kubectl get storageclass ]. \n"
kubectl get storageclass

exit 0
