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
#=================================
# Cloudera requirements==============
#======================
# NTP - time server
# To configre a local NTP server in Windows: https://www.hellpc.net/how-to-make-your-computer-a-time-server-ntp-server-without-any-software/
echo "**********Configure NTP server**********"
sudo yum -y install ntp
sudo sed -i 's/0\.centos\.pool\.ntp\.org iburst/192.168.100.1/g' /etc/ntp.conf 
sudo sed -i 's/1\.centos\.pool\.ntp\.org iburst/192.168.100.1/g' /etc/ntp.conf 
sudo sed -i 's/2\.centos\.pool\.ntp\.org iburst/192.168.100.1/g' /etc/ntp.conf 
sudo sed -i 's/3\.centos\.pool\.ntp\.org iburst/192.168.100.1/g' /etc/ntp.conf 
sudo systemctl enable ntpd
sudo systemctl restart ntpd
sudo ntpdate -u 192.168.100.1 #for home laptop
sudo hwclock --systohc
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