#!/bin/sh
#************************************
#****** Basic Configuration**********
echo "****** Set Time zone********"
sudo timedatectl set-timezone Asia/Jerusalem
echo "*********Install neeeded software ***********"
sudo yum -y update
sudo yum -y install wget
sudo yum -y install vim
sudo yum -y install telnet
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

#*******************************************
#*******Sensu client install and configure *******
#http://roobert.github.io/2015/11/09/Sensu-What/
#https://wecode.wepay.com/posts/sensu-at-wepay
echo '[sensu]
name=sensu
baseurl=https://sensu.global.ssl.fastly.net/yum/$releasever/$basearch/
gpgcheck=0
enabled=1' | sudo tee /etc/yum.repos.d/sensu.repo
sudo yum install sensu -y
#http://roobert.github.io/2015/11/09/Sensu-What/
#https://wecode.wepay.com/posts/sensu-at-wepay
#Install checks
sudo sensu-install -p cpu-checks  
sudo sensu-install -p disk-checks  
sudo sensu-install -p memory-checks  
sudo sensu-install -p process-checks  
sudo sensu-install -p load-checks  
sudo sensu-install -p vmstats  
#sudo sensu-install -p mailer
#======Get host IP address ===========
ip="$(ifconfig | grep -A 1 'eth1' | grep inet | awk '{print($2)}')"
echo "Host IP: $ip"
#Configure Client * :
echo '{
  "transport": {
    "name": "redis",
	"reconnect_on_error": true
  }
}' | sudo tee /etc/sensu/conf.d/transport.json
echo '{
  "client": {
    "name": "'$HOSTNAME'",
    "address": "'$ip'",
    "environment": "development",
    "subscriptions": [
      "default"
    ]
  }
}' |sudo tee /etc/sensu/conf.d/client.json
echo '{
  "redis": {
    "host": "192.168.100.100",
    "port": 6379
  }
}' |sudo tee /etc/sensu/conf.d/redis.json
#Copy checks from /vagrant to the client
sudo cp /vagrant/check-cpu.json /etc/sensu/conf.d/
sudo cp /vagrant/check-disk-usage.json /etc/sensu/conf.d/
sudo cp /vagrant/check-memory-percent.json /etc/sensu/conf.d/
#Start client
sudo chown -R sensu:sensu /etc/sensu
sudo systemctl enable sensu-{api,client}
sudo systemctl start sensu-{api,client}
#=================================
# Cloudera requirements==============
#======================
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
sudo -- sh -c -e "echo '192.168.100.11    sf-mngdn1' >> /etc/hosts"
sudo -- sh -c -e "echo '192.168.100.12    sf-mngdn2' >> /etc/hosts"
sudo -- sh -c -e "echo '192.168.100.13    sf-mngdn3' >> /etc/hosts"
sudo -- sh -c -e "echo '192.168.100.100   sensu' >> /etc/hosts"
#====Disable THP - required by Cloudera  https://blacksaildivision.com/how-to-disable-transparent-huge-pages-on-centos
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
#========== Changes Swap settings - recommented settings for Cloudera
echo 'echo "vm.swappiness = 10" >> /etc/sysctl.conf' | sudo -s
#======== REBOOT ===============
echo "**********Reboot $HOSTNAME **********"
sudo reboot

##==========Cloudera manager installation from Local Artifactory
#cd /etc/yum.repos.d/
#sudo wget https://archive.cloudera.com/cm5/redhat/7/x86_64/cm/cloudera-manager.repo
#sudo wget http://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/cloudera-cdh5.repo
## cdh5
#sudo sed -i 's/https\:\/\/archive.cloudera.com\/cdh5\/redhat\/7\/x86_64\/cdh\/5\//http\:\/\/192.168.100.1\:8081\/artifactory\/cdh5\/redhat\/7\/x86_64\/cdh\/5.14.2\//g' /etc/yum.repos.d/cloudera-cdh5.repo
## cm5
#sudo sed -i 's/https\:\/\/archive.cloudera.com\/cm5\/redhat\/7\/x86_64\/cm\/5\//http\:\/\/192.168.100.1\:8081\/artifactory\/cm5\/redhat\/7\/x86_64\/cm\/5.14.2\//g' /etc/yum.repos.d/cloudera-manager.repo
#cd ~
#wget http://192.168.100.1:8081/artifactory/cm5/redhat/7/x86_64/cm/5.14.2/RPMS/x86_64/oracle-j2sdk1.7-1.7.0+update67-1.x86_64.rpm
#sudo yum -y --disablerepo=* localinstall oracle-j2sdk1.7-1.7.0+update67-1.x86_64.rpm
#sudo yum -y install cloudera-manager-daemons cloudera-manager-server
#sudo yum -y install cloudera-manager-server-db-2
#sudo systemctl start cloudera-scm-server-db
#sleep 30
#sudo systemctl start cloudera-scm-server
## check that you can connect netstat -an | grep 7180
## connect 
