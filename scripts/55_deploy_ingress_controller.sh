#!/bin/sh
#--------------------------------------------------------------------------------------
# CaaSP 4.2.5 / SUSE Linux Enterprise Server 15 SP1
#
#  - Deploy and configure NGINX ingress controller
#  - Deploy and configure Kubernetes Dashboard
#
#  - Run the script only as caaspadm user [ EUID=1000 ]
#
# Tue Feb 23 07:26:42 GMT 2021 - juliusn - initial script
# Sun Mar  7 05:28:01 GMT 2021 - juliusn - added check for caaspadm user
#--------------------------------------------------------------------------------------
# Deployment Instructions - SUSE CaaS Platform 4.5.2
# https://documentation.suse.com/suse-caasp/4.5/html/caasp-deployment/_deployment_instructions.html

# Administration Guide - SUSE CaaS Platform 4.5.2
# https://documentation.suse.com/suse-caasp/4.5/html/caasp-admin/index.html


HOSTNAME=`hostname`
echo -e "\n[ ${HOSTNAME} ] --> Running script $0 \n"

# Run the script only as caaspadm user [ EUID=1000 ]
if [ "$EUID" != 1000 ]; then 
		echo -e "\n[ ${HOSTNAME} ] Run the script only as caaspadm user [ EUID=1000 ]\n"
		exit 1
fi 

#--------------------------------------------------------------------------------------
# Deploy and configure NGINX ingress controller - NodePort Implementation
# The services will be publicly exposed on each node of the cluster, including master nodes, 
# at ports 32080 for HTTP and 32443 for HTTPS.
#--------------------------------------------------------------------------------------

echo -e "\n[ ${HOSTNAME} ] Deploy and configure NGINX ingress controller."
helm3 repo add suse https://kubernetes-charts.suse.com
kubectl create namespace nginx-ingress

# helm3 show values suse/nginx-ingress
# helm3 get values nginx-ingress --namespace nginx-ingress
# helm3 get all nginx-ingress --namespace nginx-ingress

helm3 install nginx-ingress suse/nginx-ingress --namespace nginx-ingress \
			--values deploy-ingress-controller/nginx-ingress-config-values.yaml \
			--set controller.service.type=LoadBalancer \
			--set controller.metrics.enabled=true \
  			--set-string controller.podAnnotations."prometheus\.io/scrape"="true" \
  			--set-string controller.podAnnotations."prometheus\.io/port"="10254"

helm3 ls --all --namespace nginx-ingress
kubectl get pods -n nginx-ingress -o wide | grep nginx
kubectl get services -n nginx-ingress

export EXTERNAL_IP=`kubectl get services -n nginx-ingress | grep nginx-ingress-controller | grep LoadBalancer |awk '{print $4}'`
echo -e "\n[ ${HOSTNAME} ] Ingress External IP: [ ${EXTERNAL_IP} ] \n"

echo -e "\n[ ${HOSTNAME} ] ... sleeping 180 ... waiting for nginx-ingress containers deployment ..."
sleep 180

# -- to remove nginx-ingress --
# helm3 ls --all  --namespace nginx-ingress
# helm3 delete nginx-ingress --namespace nginx-ingress
# kubectl delete namespace nginx-ingress

#--------------------------------------------------------------------------------------
# Deploy and configure Kubernetes Dashboard - c2-dashboard.flexlab.local
#--------------------------------------------------------------------------------------

echo -e "\n[ ${HOSTNAME} ] Creating /etc/host entry for c2-dashboard.flexlab.local [ ${EXTERNAL_IP} ]"
echo ${EXTERNAL_IP} > /tmp/EXTERNAL_IP

sudo bash -c 'cat << EOF >> /etc/hosts
###
### Kubernetes Dashboard - Installation For Subdomains
###
`cat /tmp/EXTERNAL_IP` c2-dashboard.flexlab.local  c2-dashboard
EOF'

echo -e "\n[ ${HOSTNAME} ] Deploy and configure Kubernetes Dashboard."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml

### Issue solved
### Stopped working -> apiVersion: networking.c1.io/v1beta1
### Replaced with   -> apiVersion: extensions/v1beta1
### kubectl explain --api-version=extensions/v1beta1 ingress.spec.rules.http.paths.backend

# Create the cluster-admin account [ admin-user ] to access the Kubernetes dashboard.
kubectl apply -f deploy-ingress-controller/dashboard-admin.yaml

# Create the TLS secret
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout deploy-ingress-controller/dashboard-tls.key -out deploy-ingress-controller/dashboard-tls.crt -subj "/CN=c2-dashboard.flexlab.local/O=c2-dashboard"
kubectl create secret tls dashboard-tls --key deploy-ingress-controller/dashboard-tls.key --cert deploy-ingress-controller/dashboard-tls.crt -n kubernetes-dashboard

# Create the ingress resource.
kubectl apply -f deploy-ingress-controller/dashboard-ingress.yaml
kubectl get ingress -n kubernetes-dashboard

# Obtain token from [ admin-user ] 
kubectl get secret -n kubernetes-dashboard 
ADMIN_USER=`kubectl get secret -n kubernetes-dashboard | grep admin-user | awk '{print $1}'`
ADMIN_TOKEN=`kubectl -n kubernetes-dashboard describe secret ${ADMIN_USER}| awk '$1=="token:"{print $2}'`
kubectl config set-credentials admin-user --token="${ADMIN_TOKEN}"

echo -e "\n[ ${HOSTNAME} ] Access the Kubernetes Dashboard by going to [ https://c2-dashboard.flexlab.local ]"
echo -e "\n[ ${HOSTNAME} ] You access token is: ---------------------------------------------- \n"
echo "${ADMIN_TOKEN}"
echo -e "\n[ ${HOSTNAME} ] ------------------------------------------------------------------- \n"

exit 0
