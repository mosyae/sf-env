#!/bin/sh
#************************************
#****** Basic Configuration**********
echo "****** Sset Time zone********"
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
#***************Sensu installation ***********************
echo "============Install sensu =============="
sudo yum update
sudo yum -y vim
sudo yum -y install net-tools
sudo yum -y install telnet
sudo yum -y install epel-release -y
sudo yum install gcc-c++ -y #needed for Sensu plugins-graphite install
echo '[sensu]
name=sensu
baseurl=https://sensu.global.ssl.fastly.net/yum/$releasever/$basearch/
gpgcheck=0
enabled=1' | sudo tee /etc/yum.repos.d/sensu.repo
sudo yum install redis -y
# Now edit /etc/redis.conf file and change "protected-mode yes" to "protected-mode no"
sudo sed -i.bak -e '0,/protected-mode yes/ s/protected-mode yes/protected-mode no/' /etc/redis.conf
sudo sed -i.bak -e 's/bind 127.0.0.1/bind 192.168.100.100/' /etc/redis.conf
sudo systemctl enable redis
sudo systemctl start redis
sudo yum install sensu uchiwa -y
#Configure Server * 
echo '{
  "transport": {
    "name": "redis"
  },
  "api": {
    "host": "192.168.100.100",
    "port": 4567
  }
}' | sudo tee /etc/sensu/config.json
#Configure Client * :
echo "============Configure Client =============="
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
echo "Host name: $HOSTNAME"
#Configure Client:
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
#Install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo systemctl enable docker
sudo systemctl start docker
#Start Grafite with docker
sudo mkdir /data
sudo docker run -d\
 --name graphite\
 --restart=always\
 -v /data/graphite:/data \
 -p 80:80\
 -p 2003-2004:2003-2004\
 -p 2023-2024:2023-2024\
 -p 8125:8125/udp\
 -p 8126:8126\
 graphiteapp/graphite-statsd
#Configure handler for Grafite
sudo mkdir /etc/sensu/conf.d/handlers
echo '
{
  "handlers": {
    "graphite": {
      "type": "tcp",
      "mutator": "only_check_output",
      "timeout": 30,
      "socket": {
        "host": "192.168.100.100",
        "port": 2003
      }
    }
  }
}' | sudo tee /etc/sensu/conf.d/handlers/graphite.json
sensu-install -p sensu-plugins-graphite
sudo mkdir /etc/sensu/conf.d/mutators
echo '
{
  "mutators": {
    "graphite_mutator": {
      "command": "/opt/sensu/embedded/bin/mutator-graphite.rb",
      "timeout": 10
    }
  }
}' | sudo tee /etc/sensu/conf.d/mutators/graphite_mutator.json
echo '
{
  "checks": {
    "system_cpu_metrics": {
      "type": "metric",
      "command": "/opt/sensu/embedded/bin/metrics-cpu.rb --scheme sensu.:::service|undefined:::.:::environment|undefined:::.:::zone|undefined:::.:::name:::.cpu",
      "subscribers": [
        "default"
      ],
      "handlers": [
        "graphite"
      ],
      "interval": 60,
      "ttl": 180
    }
  }
}' | sudo tee /etc/sensu/conf.d/cpu_metrics.json
#Configure Dashboard
echo '{
   "sensu": [
     {
       "name": "sensu",
       "host": "192.168.100.100",
       "port": 4567
     }
   ],
   "uchiwa": {
     "host": "0.0.0.0",
     "port": 3000
   }
 }' |sudo tee /etc/sensu/uchiwa.json
sudo chown -R sensu:sensu /etc/sensu
#Start sensu
sudo systemctl enable sensu-{server,api,client}
sudo systemctl start sensu-{server,api,client}
sudo systemctl enable uchiwa
sudo systemctl start uchiwa
#Check the install
sudo yum install jq curl -y
curl -s http://127.0.0.1:4567/clients | jq .
