#!/bin/sh
#--------------------------------------------------------------------------------------
# CaaSP 4.2.5 / SUSE Linux Enterprise Server 15 SP1
#
#  - Run example apps in the Kubernetes Cluster that can be reached through a ingress route
#
#  - Example #1: Create namespace ns-mongodb. Deploy MongoDB and Mongo Express
#  - Example #2: Create namespace ns-nginx. Deploy NGINX
#  - Example #3: Create namespace ns-nginx-hello-app. Deploy NGINX hello-app
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


HOSTNAME=`hostname`
echo -e "\n[ ${HOSTNAME} ] --> Running script $0 \n"

# Run the script only as caaspadm user [ EUID=1000 ]
if [ "$EUID" != 1000 ]; then 
		echo -e "\n[ ${HOSTNAME} ] Run the script only as caaspadm user [ EUID=1000 ]\n"
		exit 1
fi 

export EXTERNAL_IP=`kubectl get services -n nginx-ingress | grep nginx-ingress-controller | grep LoadBalancer |awk '{print $4}'`
echo -e "\n[ ${HOSTNAME} ] Ingress External IP: [ ${EXTERNAL_IP} ]"

echo ${EXTERNAL_IP} > /tmp/EXTERNAL_IP
sudo bash -c 'cat << EOF >> /etc/hosts
###
### Example Apps
###
`cat /tmp/EXTERNAL_IP` c2-mongo-express.flexlab.local c2-mongo-express
`cat /tmp/EXTERNAL_IP` c2-nginx-app.flexlab.local c2-nginx-app
`cat /tmp/EXTERNAL_IP` c2-nginx-hello-app.flexlab.local c2-nginx-hello-app
EOF'

#--------------------------------------------------------------------------------------
# Example #1: Deploy MongoDB and Mongo Express - c2-mongo-express.flexlab.local
#--------------------------------------------------------------------------------------

echo -e "\n[ ${HOSTNAME} ] --> Example #1: Deploy MongoDB and Mongo Express\n"
kubectl apply -f deploy-mongodb/01-mongodb-namespace.yaml

# Create TLS secret for c2-mongo-express.flexlab.local
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout deploy-mongodb/mongodb-tls.key -out deploy-mongodb/mongodb-tls.crt -subj "/CN=c2-mongo-express.flexlab.local/O=c2-mongo-express"
kubectl create secret tls mongodb-tls --key deploy-mongodb/mongodb-tls.key --cert deploy-mongodb/mongodb-tls.crt -n ns-mongodb

kubectl apply -f deploy-mongodb/02-mongodb-pvc.yaml
kubectl apply -f deploy-mongodb/03-mongodb-secret.yaml
kubectl apply -f deploy-mongodb/04-mongodb-deployment.yaml

echo -e "\n[ ${HOSTNAME} ] ... sleeping 120 secs ... waiting for mongodb containers deployment ... \n"
sleep 120

kubectl apply -f deploy-mongodb/05-mongo-express-deployment.yaml
kubectl get ingress -n ns-mongodb

echo -e "\n[ ${HOSTNAME} ] ->> MONGO EXPRESS URL [ https://c2-mongo-express.flexlab.local ]"

echo -e "\n[ ${HOSTNAME} ] ... sleeping 15 secs ... \n"
sleep 15

#--------------------------------------------------------------------------------------
# Example #2: Deploy NGINX App - c2-nginx-app.flexlab.local 
#--------------------------------------------------------------------------------------

echo -e "\n[ ${HOSTNAME} ] --> Example #2: Deploy NGINX App\n"
kubectl apply -f deploy-nginx/01-nginx-namespace.yaml

# Create TLS secret for c2-nginx-app.flexlab.local
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout deploy-nginx/nginx-app-tls.key -out deploy-nginx/nginx-app-tls.crt -subj "/CN=c2-nginx-app.flexlab.local/O=c2-nginx-app"
kubectl create secret tls nginx-app-tls --key deploy-nginx/nginx-app-tls.key --cert deploy-nginx/nginx-app-tls.crt -n ns-nginx

kubectl apply -f deploy-nginx/02-nginx-deployment.yaml
kubectl get ingress -n ns-nginx

echo -e "\n[ ${HOSTNAME} ] ->> NGINX URL [ https://c2-nginx-app.flexlab.local ]"

echo -e "\n[ ${HOSTNAME} ] ... sleeping 15 secs ... \n"
sleep 15

#--------------------------------------------------------------------------------------
# Example #3: Deploy NGINX hello-app - c2-nginx-hello-app.flexlab.local 
#--------------------------------------------------------------------------------------

echo -e "\n[ ${HOSTNAME} ] --> Example #3: Deploy NGINX hello-app\n"

kubectl apply -f deploy-nginx-hello-app/01-nginx-namespace.yaml

# Create TLS secret for c2-nginx-hello-app.flexlab.local
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout deploy-nginx-hello-app/nginx-hello-app-tls.key -out deploy-nginx-hello-app/nginx-hello-app-tls.crt -subj "/CN=c2-nginx-hello-app.flexlab.local/O=c2-nginx-hello-app"
kubectl create secret tls nginx-hello-app-tls --key deploy-nginx-hello-app/nginx-hello-app-tls.key --cert deploy-nginx-hello-app/nginx-hello-app-tls.crt -n ns-nginx-hello-app

kubectl apply -f deploy-nginx-hello-app/02-nginx-deployment.yaml
kubectl get ingress -n ns-nginx-hello-app

echo -e "\n[ ${HOSTNAME} ] ->> NGINX HELLO APP URL [ https://c2-nginx-hello-app.flexlab.local ]"

echo -e "\n[ ${HOSTNAME} ] ... sleeping 15 secs ... \n"
sleep 15

# to remove example apps
# kubectl delete namespace ns-mongodb
# kubectl delete namespace ns-nginx
# kubectl delete namespace ns-nginx-hello-app

exit 0

