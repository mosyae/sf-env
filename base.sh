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
sudo -- sh -c -e "echo '192.168.100.11    sf-mngdn1' >> /etc/hosts"
sudo -- sh -c -e "echo '192.168.100.12    sf-mngdn2' >> /etc/hosts"
sudo -- sh -c -e "echo '192.168.100.13    sf-mngdn3' >> /etc/hosts"
sudo -- sh -c -e "echo '192.168.100.100   sensu' >> /etc/hosts"
