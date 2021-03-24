#!/bin/sh
#--------------------------------------------------------------------------------------
# CaaSP 4.2.5 / SUSE Linux Enterprise Server 15 SP1
#
#  - Configure CaaSP4 cluster
#  - Setup and Configure Metal Load Balancer
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


HOSTNAME=`hostname`
echo -e "\n[ ${HOSTNAME} ] --> Running script $0 \n"

# Run the script only as caaspadm user [ EUID=1000 ]
if [ "$EUID" != 1000 ]; then 
		echo -e "\n[ ${HOSTNAME} ] Run the script only as caaspadm user [ EUID=1000 ]\n"
		exit 1
fi 

echo -e "\n[ ${HOSTNAME} ] Show basic Kubernetes status. \n"
kubectl cluster-info
kubectl get nodes
kubectl get pods --all-namespaces

echo -e "\n[ ${HOSTNAME} ] ... sleeping 60 ... \n"
echo -e "\n[ ${HOSTNAME} ] Review the output - make sure all pods are running ... \n"
sleep 60

#--------------------------------------------------------------------------------------
# Deploy Metal Load Balancer
#--------------------------------------------------------------------------------------

echo -e "\n[ ${HOSTNAME} ] Set up Kubernetes Networking via Metal Load Balancer. \n"
kubectl create -f deploy-metallb/53_metallb_init.yaml

echo -e "\n[ ${HOSTNAME} ] Metal Load Balancer add layer2 network configuration. \n"
echo -e "\n[ ${HOSTNAME} ] Using IP range: 192.168.130.230 - 192.168.130.250. \n"
kubectl create -f deploy-metallb/54_metallb_layer2_config.yaml

echo -e "\n[ ${HOSTNAME} ] ... sleeping 120 secs ... waiting for metallb containers deployment ... \n"
sleep 120

echo -e "\n[ ${HOSTNAME} ] Show Metallb pods [ kubectl get pods -n metallb-system ]. \n"
kubectl get pods -n metallb-system

exit 0
