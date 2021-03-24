#!/bin/sh
#--------------------------------------------------------------------------------------
# CaaSP 4.2.5 / SUSE Linux Enterprise Server 15 SP1
#
#  - First set of OS customization 
#  - Configure NFS on c4admin only
#
#  /CaaspStorage - for the Kubernetes cluster storage
#  /caasp4-storage - for admin purpose
#
# Tue Feb 23 07:26:42 GMT 2021 - juliusn - initial script
#--------------------------------------------------------------------------------------

HOSTNAME=`hostname`
NFSpath="/caasp4-storage"

if [ ${HOSTNAME} != "c2-admin" ]; then
    echo -e "\n[ ${HOSTNAME} ] --> Will NOT run script $0 \n"
    exit 0
else
    echo -e "\n[ ${HOSTNAME} ] --> Running script $0 \n"
fi

zypper -n install nfs-kernel-server nfs-client
systemctl enable rpcbind.service
systemctl start rpcbind.service
systemctl enable nfsserver.service
systemctl start nfsserver.service

mkdir -p $NFSpath
chmod -R 755 $NFSpath

# Create /etc/exports

cat << EOF > /etc/exports
$NFSpath    192.168.130.0/24(rw,sync,no_root_squash,no_all_squash,no_subtree_check)
EOF

firewall-cmd --permanent --zone=public --add-service=nfs
firewall-cmd --permanent --zone=public --add-service=mountd
firewall-cmd --permanent --zone=public --add-service=rpc-bind
firewall-cmd --reload

# update /etc/sysconfig/nfs
cp /etc/sysconfig/nfs /etc/sysconfig/nfs.org
sed -i 's/^#RPCNFSDARGS.*/RPCNFSDARGS="-N2 -N3 -V4"/' /etc/sysconfig/nfs
sed -i 's/^RPCNFSDARGS.*/RPCNFSDARGS="-N2 -N3 -V4"/' /etc/sysconfig/nfs
sed -i 's/^#RPCNFSDCOUNT.*/RPCNFSDCOUNT=16"/' /etc/sysconfig/nfs
sed -i 's/^RPCNFSDCOUNT.*/RPCNFSDCOUNT=16"/' /etc/sysconfig/nfs

exportfs -a
systemctl restart rpcbind.service
systemctl restart nfsserver.service

# Test NFS access
# showmount -e localhost
# showmount -e `hostname`
# mount -t nfs -o vers=4 `hostname`:/caasp4-storage /mnt
# umount /mnt
# mount -t nfs -o vers=3 `hostname`:/caasp4-storage /mnt
# umount /mnt

exit 0
