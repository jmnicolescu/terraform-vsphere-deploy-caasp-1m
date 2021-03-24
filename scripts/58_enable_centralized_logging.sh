#!/bin/sh
#--------------------------------------------------------------------------------------
# CaaSP 4.2.5 / SUSE Linux Enterprise Server 15 SP1
#
#  - Centralized Logging using rsyslog:8.39.0 and log-agent-rsyslog
#  - Use Helm3 to install log agents on each node
#
# Limitation - The Kubernetes audit log only collects and stores actions performed on the 
# level of the cluster. This does not include any resulting actions of application services.
#
#  - Run the script only as caaspadm user [ EUID=1000 ]
#
# Tue Feb 23 07:26:42 GMT 2021 - juliusn - initial script
# Sun Mar  7 05:28:01 GMT 2021 - juliusn - added check for caaspadm user
#--------------------------------------------------------------------------------------
# Deployment Instructions - SUSE CaaS Platform 4.5.2
# https://documentation.suse.com/suse-caasp/4.5/html/caasp-deployment/index.html

# Administration Guide - SUSE CaaS Platform 4.5.2
# https://documentation.suse.com/suse-caasp/4.5/html/caasp-admin/index.html

SERVER_HOST=c2-admin.flexlab.local 
SERVER_PORT=54

HOSTNAME=`hostname`
if [ ${HOSTNAME} != "c2-admin" ]; then
    echo -e "\n[ ${HOSTNAME} ] --> Will NOT run script $0 \n"
    exit 0
else
    echo -e "\n[ ${HOSTNAME} ] --> Running script $0 \n"
fi

# Run the script only as caaspadm user [ EUID=1000 ]
if [ "$EUID" != 1000 ]; then 
		echo -e "\n[ ${HOSTNAME} ] Run the script only as caaspadm user [ EUID=1000 ]\n"
		exit 1
fi 

echo -e "\n[ ${HOSTNAME} ] Installing log-agent-rsyslog. \n"
helm3 repo add suse https://kubernetes-charts.suse.com
helm3 install rsyslog suse/log-agent-rsyslog --namespace kube-system \
            --set server.host=${SERVER_HOST} --set server.port=${SERVER_PORT} \
            --set logs.osSystem.enabled=false --set logs.kubernetesSystem.enabled=true \
            --set logs.kubernetesControlPlane.enabled=true --set logs.kubernetesUserNamespaces.enabled=true  

helm3 ls --all --namespace kube-system
kubectl get pods -n kube-system -o wide | grep rsyslog

# To remove rsyslog agents
# helm3 ls --all --short --namespace kube-system
# helm3 delete rsyslog --namespace kube-system

exit 0