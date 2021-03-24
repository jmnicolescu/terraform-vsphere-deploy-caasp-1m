#!/bin/sh
#--------------------------------------------------------------------------------------
# CaaSP 4.2.5 / SUSE Linux Enterprise Server 15 SP1
#
#  - Copy the public key to remote-host using ssh-copy-id.
#  - Run the script only as caaspadm user [ EUID=1000 ]
#
# Tue Feb 23 07:26:42 GMT 2021 - juliusn - initial script
# Sun Mar  7 05:28:01 GMT 2021 - juliusn 
#--------------------------------------------------------------------------------------

HOSTNAME=`hostname`
echo -e "\n[ ${HOSTNAME} ] --> Running script $0 \n"

# Run the script only as caaspadm user [ EUID=1000 ]
if [ "$EUID" != 1000 ]; then 
		echo -e "\n[ ${HOSTNAME} ] Run the script only as caaspadm user [ EUID=1000 ]\n"
		exit 1
fi 

ClusterName=caasp4-cluster2
Kadmin=c2-admin.flexlab.local
Kmaster1=c2-master1.flexlab.local
Kworker1=c2-worker1.flexlab.local
Kworker2=c2-worker2.flexlab.local

echo -e "\n[ ${HOSTNAME} ] Copy the public key to remote-host using ssh-copy-id. \n"
for host in $Kadmin $Kmaster1 $Kworker1 $Kworker2
do
    echo -e "\n ----------> Updating $host <------------"
    ssh-copy-id -i ~/.ssh/id_rsa.pub $host
done

echo -e "\n[ ${HOSTNAME} ] VerVerifying remote login. \n"
for host in $Kadmin $Kmaster1 $Kworker1 $Kworker2
do
    ssh $host "hostname;date"
done
sleep 10

exit 0

