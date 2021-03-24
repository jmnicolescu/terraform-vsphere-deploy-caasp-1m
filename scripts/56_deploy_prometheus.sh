#!/bin/sh
#--------------------------------------------------------------------------------------
# CaaSP 4.2.5 / SUSE Linux Enterprise Server 15 SP1
#
#  - Deploy and configure Prometheus - Installation For Subdomains
#  - Deploy and configure Grafana - Installation For Subdomains
#  - Add pre-built Grafana dashboards to monitor the SUSE CaaS Platform system
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
# Deploy and configure Prometheus - c2-prometheus.flexlab.local 
#--------------------------------------------------------------------------------------

echo -e "\n[ ${HOSTNAME} ] Create Monitoring namespace."
kubectl create namespace monitoring

# create a basic-auth secret file [admin/tux]
htpasswd -b -c deploy-prometheus/auth admin tux

# Create secret in Kubernetes cluster
echo -e "\n[ ${HOSTNAME} ] Create secret for [admin/tux] in Kubernetes cluster."
kubectl create secret generic -n monitoring prometheus-basic-auth --from-file=deploy-prometheus/auth

# Prometheus - Installation For Subdomains
export EXTERNAL_IP=`kubectl get services -n nginx-ingress | grep nginx-ingress-controller | grep LoadBalancer |awk '{print $4}'`
echo -e "\n[ ${HOSTNAME} ] Ingress External IP: [ ${EXTERNAL_IP} ]"

echo -e "\n[ ${HOSTNAME} ] Creating /etc/host entry for c2-prometheus.flexlab.local [ ${EXTERNAL_IP}"
echo ${EXTERNAL_IP} > /tmp/EXTERNAL_IP

sudo bash -c 'cat << EOF >> /etc/hosts
###
### Prometheus - Installation For Subdomains
###
`cat /tmp/EXTERNAL_IP` c2-prometheus.flexlab.local c2-prometheus
`cat /tmp/EXTERNAL_IP` c2-prometheus-alertmanager.flexlab.local c2-prometheus-alertmanager
`cat /tmp/EXTERNAL_IP` c2-grafana.flexlab.local c2-grafana
EOF'

# Configure certificates as secrets in the Kubernetes cluster.
echo -e "\n[ ${HOSTNAME} ] Configure certificates as secrets in the Kubernetes cluster."

# Create TLS secret for c2-prometheus.flexlab.local
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout deploy-prometheus/prometheus-tls.key -out deploy-prometheus/prometheus-tls.crt -subj "/CN=c2-prometheus.flexlab.local/O=c2-prometheus"
kubectl create secret tls prometheus-tls --key deploy-prometheus/prometheus-tls.key --cert deploy-prometheus/prometheus-tls.crt -n monitoring

# Create TLS secret for c2-prometheus-alertmanager.flexlab.local.flexlab.local
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout deploy-prometheus/prometheus-alertmanager-tls.key -out deploy-prometheus/prometheus-alertmanager-tls.crt -subj "/CN=c2-prometheus-alertmanager.flexlab.local/O=c2-prometheus-alertmanager"
kubectl create secret tls prometheus-alertmanager-tls --key deploy-prometheus/prometheus-alertmanager-tls.key --cert deploy-prometheus/prometheus-alertmanager-tls.crt -n monitoring

# Deploy SUSE prometheus helm chart
echo -e "\n[ ${HOSTNAME} ] Deploy SUSE prometheus helm chart. \n"

helm3 repo add suse https://kubernetes-charts.suse.com
helm3 install prometheus suse/prometheus --namespace monitoring --values deploy-prometheus/prometheus-config-values.yaml

kubectl -n monitoring get pod | grep prometheus
kubectl get ingress -n monitoring

echo -e "\n[ ${HOSTNAME} ] Prometheus server [ http://c2-prometheus.flexlab.local ] -- login as [admin/tux]"
echo -e "\n[ ${HOSTNAME} ] Prometheus alertmanager server [ http://c2-prometheus-alertmanager.flexlab.local ] -- login as [admin/tux]"

echo -e "\n[ ${HOSTNAME} ] ... sleeping 180 ... waiting for prometheus containers deployment ..."
sleep 180

# -- to remove prometheus --
# helm3 ls --all  --namespace monitoring
# helm3 delete prometheus --namespace monitoring
# kubectl delete namespace monitoring

#--------------------------------------------------------------------------------------
# Deploy and configure Grafana - c2-grafana.flexlab.local
#--------------------------------------------------------------------------------------

echo -e "\n[ ${HOSTNAME} ] Deploy and configure Grafana"

kubectl create -f deploy-prometheus/grafana-datasources.yaml

# Create TLS secret for grafana.flexlab.local
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout deploy-prometheus/grafana-tls.key -out deploy-prometheus/grafana-tls.crt -subj "/CN=c2-grafana.flexlab.local/O=c2-grafana"
kubectl create secret tls grafana-tls --key deploy-prometheus/grafana-tls.key --cert deploy-prometheus/grafana-tls.crt -n monitoring

# Deploy Grafana helm chart
echo -e "\n[ ${HOSTNAME} ] Deploy Grafana helm chart."

helm3 install grafana suse/grafana --namespace monitoring --values deploy-prometheus/grafana-config-values.yaml

kubectl -n monitoring get pod | grep grafana
kubectl get ingress -n monitoring

echo -e "\n[ ${HOSTNAME} ] Grafana server [ http://c2-grafana.flexlab.local ] -- login as [admin/tux]"

echo -e "\n[ ${HOSTNAME} ] ... sleeping 180 ... waiting for grafana containers deployment ... "
sleep 180

# Adding pre-built dashboards to monitor the SUSE CaaS Platform system
echo -e "\n[ ${HOSTNAME} ] Adding pre-built dashboards to monitor the SUSE CaaS Platform system."

# monitor SUSE CaaS Platform cluster
kubectl apply -f https://raw.githubusercontent.com/SUSE/caasp-monitoring/master/grafana-dashboards-caasp-cluster.yaml
# monitor SUSE CaaS Platform etcd cluster
kubectl apply -f https://raw.githubusercontent.com/SUSE/caasp-monitoring/master/grafana-dashboards-caasp-etcd-cluster.yaml
# monitor SUSE CaaS Platform nodes
kubectl apply -f https://raw.githubusercontent.com/SUSE/caasp-monitoring/master/grafana-dashboards-caasp-nodes.yaml
# monitor SUSE CaaS Platform namespaces
kubectl apply -f https://raw.githubusercontent.com/SUSE/caasp-monitoring/master/grafana-dashboards-caasp-namespaces.yaml
# monitor SUSE CaaS Platform pods
kubectl apply -f https://raw.githubusercontent.com/SUSE/caasp-monitoring/master/grafana-dashboards-caasp-pods.yaml
# monitor SUSE CaaS Platform certificates
kubectl apply -f https://raw.githubusercontent.com/SUSE/caasp-monitoring/master/grafana-dashboards-caasp-certificates.yaml

exit 0

