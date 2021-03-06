#!/bin/sh
echo "****** Sset Time zone********"
sudo timedatectl set-timezone Asia/Jerusalem
echo "*********Install neeeded software ***********" 
sudo yum -y update
sudo yum -y install wget
sudo yum -y install vim
sudo yum -y install net-tools
#Configure sshd to allow access from other machine
echo "*********Allow ssh ***********" 
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sudo systemctl restart sshd
#***********Create cron job to sync time after hybernate and vm clock stops ticking
sudo mkdir -p /opt/devops_scripts
echo '
#Sync the time with the NTP server for the first time
sudo ntpdate -u 192.168.100.1 #IP address of the laptop Windows ntp
#Sync harware clock with thesystem clock
sudo hwclock --systohc
' | sudo tee /opt/devops_scripts/sync_time_cron.sh
sudo chmod +x /opt/devops_scripts/sync_time_cron.sh
(crontab -l 2>/dev/null; echo "*/2 * * * * /opt/devops_scripts/sync_time_cron.sh") | crontab -
#=================================
# Cloudera requirements==============
#======================
# NTP - time server
# To configre a local NTP server in Windows: https://www.hellpc.net/how-to-make-your-computer-a-time-server-ntp-server-without-any-software/
#Sync the time with the NTP server for the first time
sudo ntpdate -u 192.168.100.1 #IP address of the laptop Windows ntp
#Sync harware clock with thesystem clock
sudo hwclock --systohc
#Configre OpenNTP service (there are problems with ntpd
# Source https://www.cyberciti.biz/faq/openntpd-on-centos-rhel-fedora-linux/
cd /tmp
wget http://ftp3.usa.openbsd.org/pub/OpenBSD/OpenNTPD/openntpd-6.0p1.tar.gz
tar -zxvf openntpd-6.0p1.tar.gz
cd openntpd-6.0p1
./configure
make
sudo make install
sudo groupadd _ntp
sudo useradd -g _ntp -s /sbin/nologin -d /var/empty/openntpd -c 'OpenNTP daemon' _ntp
sudo mkdir -p /var/empty/openntpd
sudo chown 0 /var/empty/openntpd
sudo chgrp 0 /var/empty/openntpd
sudo chmod 0755 /var/empty/openntpd
echo '
[Unit]
Description=OpenNTP Daemon
After=network.target
Conflicts=systemd-timesyncd.service

[Service]
Type=forking
ExecStart=/usr/local/sbin/ntpd -s

[Install]
WantedBy=multi-user.target
'| sudo tee /usr/lib/systemd/system/openntpd.service
echo '
listen on *
server 192.168.100.1
sensor *
' | sudo tee /usr/local/etc/ntpd.conf
sudo systemctl start openntpd.service
sudo systemctl enable openntpd
#=== Disbale firewall
echo "**********Disable firewall**********"
sudo systemctl stop firewalld
sudo systemctl disable firewalld
#===
echo "**********Diabale SELinux**********"
cd /etc/sysconfig
sudo chmod 777 selinux
sudo sed -i 's/enforcing/disabled/g' /etc/selinux/config
#=== Update HOSTS file
echo "**********Modify HOSTS file**********"
sudo sed -i '1 s/^/#/' /etc/hosts
sudo -- sh -c -e "echo '192.168.100.11    sf-dn1' >> /etc/hosts"
sudo -- sh -c -e "echo '192.168.100.12    sf-dn2' >> /etc/hosts"
sudo -- sh -c -e "echo '192.168.100.13    sf-dn3' >> /etc/hosts"
sudo -- sh -c -e "echo '192.168.100.14    sf-mng1' >> /etc/hosts"
sudo -- sh -c -e "echo '192.168.100.15    sf-mng2' >> /etc/hosts"
sudo -- sh -c -e "echo '192.168.100.16    sf-mng3' >> /etc/hosts"
#====Disable THP https://blacksaildivision.com/how-to-disable-transparent-huge-pages-on-centos
echo 'echo "[Unit]" > /etc/systemd/system/disable-thp.service' | sudo -s
echo 'echo "Description=Disable Transparent Huge Pages (THP)" >> /etc/systemd/system/disable-thp.service' | sudo -s
echo 'echo "" >> /etc/systemd/system/disable-thp.service' | sudo -s
echo 'echo "[Service]" >> /etc/systemd/system/disable-thp.service' | sudo -s
echo 'echo "Type=simple" >> /etc/systemd/system/disable-thp.service' | sudo -s
echo 'echo "ExecStart=/bin/sh -c \"echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled && echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag\"" >> /etc/systemd/system/disable-thp.service' | sudo -s
echo 'echo " " >> /etc/systemd/system/disable-thp.service' | sudo -s
echo 'echo "[Install]" >> /etc/systemd/system/disable-thp.service' | sudo -s
echo 'echo "WantedBy=multi-user.target" >> /etc/systemd/system/disable-thp.service' | sudo -s
sudo systemctl daemon-reload
sudo systemctl start disable-thp
sudo systemctl enable disable-thp
#========== Changes Swap settings
echo 'echo "vm.swappiness = 1" >> /etc/sysctl.conf' | sudo -s
#======== REBOOT ===============
echo "**********Reboot $HOSTNAME **********"
sudo reboot