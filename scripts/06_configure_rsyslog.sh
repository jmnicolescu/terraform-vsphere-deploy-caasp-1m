#!/bin/sh
#--------------------------------------------------------------------------------------
# CaaSP 4.2.5 / SUSE Linux Enterprise Server 15 SP1
#
#  - Configure admin server as the rsyslog server
#
#  Kadmin=caasp4-admin          -> rsyslog server
#  Kmaster1=caasp4-master1      -> rsyslog client
#  Kworker1=caasp4-worker1      -> rsyslog client
#  Kworker2=caasp4-worker2      -> rsyslog client
#
#  Syslog file location on caasp4-admin:
#       /var/log/caasp4-admin
#       /var/log/caasp4-master1
#       /var/log/caasp4-worker1
#       /var/log/caasp4-worker2
#
# Tue Feb 23 07:26:42 GMT 2021 - juliusn - initial script
# Sun Mar  7 05:28:01 GMT 2021 - juliusn 
#--------------------------------------------------------------------------------------

zypper -n install rsyslog
alternatives --set helm /usr/bin/helm3

HOSTNAME=`hostname`
if [ ${HOSTNAME} != "c2-admin" ]; then

    echo -e "\n[ ${HOSTNAME} ] --> Configure Rsyslog Client \n"
    cp /etc/rsyslog.conf /etc/rsyslog.conf.save
    echo "*.*  @@192.168.130.110:514" >> /etc/rsyslog.conf
    systemctl enable rsyslog
    systemctl restart rsyslog
    logger -s -p user.info Testing Rsyslog Client log
    exit 0
else
    echo -e "\n[ ${HOSTNAME} ] --> Configure Rsyslog Server \n"
fi

cp /etc/rsyslog.conf /etc/rsyslog.conf.save
cat << EOF > /etc/rsyslog.conf
# ----------------------------------------------------------------
# Configure Rsyslog Server
# ----------------------------------------------------------------
\$ModLoad imtcp
\$InputTCPServerRun 514

\$ModLoad imudp
\$UDPServerRun 514

\$template RemoteLogs,"/var/log/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& ~
EOF
cat /etc/rsyslog.conf.save >> /etc/rsyslog.conf
systemctl enable rsyslog
systemctl restart rsyslog

# allow both UDP/TCP connections to the rsyslog server
firewall-cmd --zone=public --permanent --add-port=514/udp
firewall-cmd --zone=public --permanent --add-port=514/tcp
firewall-cmd --reload

echo -e "\n[ ${HOSTNAME} ] --> Verify the rsyslog network sockets \n"
ss -tulnp | grep "rsyslog"


exit 0