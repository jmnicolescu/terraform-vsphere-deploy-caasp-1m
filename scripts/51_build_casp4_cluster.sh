#!/bin/sh
#--------------------------------------------------------------------------------------
# CaaSP 4.2.5 / SUSE Linux Enterprise Server 15 SP1
#
#  - Build CaaSP Cluster
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

ClusterName=caasp4-cluster2
Kadmin=c2-admin.flexlab.local
Kmaster1=c2-master1.flexlab.local
Kworker1=c2-worker1.flexlab.local
Kworker2=c2-worker2.flexlab.local

HOSTNAME=`hostname`
echo -e "\n[ ${HOSTNAME} ] --> Running script $0 \n"

# Run the script only as caaspadm user [ EUID=1000 ]
if [ "$EUID" != 1000 ]; then 
		echo -e "\n[ ${HOSTNAME} ] Run the script only as caaspadm user [ EUID=1000 ]\n"
		exit 1
fi 

echo -e "\n[ ${HOSTNAME} ] Start ssh-agent and add private key to ssh-agent.\n"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
ssh-add -L

echo -e "\n[ ${HOSTNAME} ] Initalize the cluster. \n"
if [ -d $ClusterName ]
then
    rm -f $ClusterName
fi

echo -e "\n[ ${HOSTNAME} ] testing vCenter connectivity.\n"
/usr/local/bin/govc ls
sleep 10

# Define the cluster

# Enable vSphere Cloud Provider Integration
skuba cluster init --control-plane ${Kmaster1} --cloud-provider vsphere ${ClusterName}

# Bootstrap a master node
# cd <CLUSTER_NAME>
# skuba node bootstrap --user sles --sudo --target <IP/FQDN> <NODE_NAME>

# Add additional master nodes to the cluster.
# skuba node join --role master --user sles --sudo --target <IP/FQDN> <NODE_NAME>| tee <NODE_NAME>-skuba-node-join.log

# Add a worker to the cluster
# skuba node join --role worker --user sles --sudo --target <IP/FQDN> <NODE_NAME>| tee <NODE_NAME>-skuba-node-join.log

# Verify that the nodes have been added:
# skuba cluster status

echo -e "\n[ ${HOSTNAME} ] Creating vSphere CPI configuration file [ ${ClusterName}/cloud/vsphere/vsphere.conf ]\n"

. /home/caaspadm/.bash_profile
cat << EOF > ${ClusterName}/cloud/vsphere/vsphere.conf
[Global]
user = "${GOVC_USERNAME}"
password = "${GOVC_PASSWORD}"
port = "443"
insecure-flag = "1"
[VirtualCenter "${GOVC_HOST}"]
datacenters = "EAST-DC"
[Workspace]
server = "${GOVC_HOST}"
datacenter = "EAST-DC"
default-datastore = "vsanDatastore"
resourcepool-path = "CAASP-C2"
folder = "CAASP-C2"
[Disk]
scsicontrollertype = pvscsi
[Network]
public-network = "lab-mgmt"
EOF

if [ ! -f ${ClusterName}/cloud/vsphere/vsphere.conf ]
then
    echo -e "\n[ ${HOSTNAME} ] vSphere CPI configuration file [ ${ClusterName}/cloud/vsphere/vsphere.conf ] doesn't exit\n"
    exit 1
fi

echo -e "\n[ ${HOSTNAME} ] Bootstrap the cluster with $Kmaster1 as the master node. \n"
cd ${ClusterName}

echo -e "\n[ ${HOSTNAME} ] Working on node -------------> [ $Kmaster1 ]\n"
skuba node bootstrap --user caaspadm --sudo --target ${Kmaster1} c2-master1

echo -e "\n[ ${HOSTNAME} ] Working on node -------------> [ $Kworker1 ]\n"
skuba node join --role worker --user caaspadm --sudo --target ${Kworker1} c2-worker1

echo -e "\n[ ${HOSTNAME} ] Working on node -------------> [ $Kworker2 ]\n"
skuba node join --role worker --user caaspadm --sudo --target ${Kworker2} c2-worker2

echo -e "\n[ ${HOSTNAME} ] Show Skuba Cluster Status \n"
skuba cluster status

if [ -d ~/.kube ]
then
    rm -rf ~/.kube 
fi
mkdir ~/.kube
cp admin.conf ~/.kube/config

echo -e "\n[ ${HOSTNAME} ] Waiting for nodes to become available .... \n"
kubectl get nodes --watch

exit 0