#!/bin/sh
echo "****** Sset Time zone********"
sudo timedatectl set-timezone Asia/Jerusalem
echo "****** Start SENSU install********"
sudo yum update
sudo yum -y vim
sudo yum -y install net-tools
sudo yum -y install telnet
sudo yum -y install epel-release -y
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
#COnfigure Client * :
echo '{
  "transport": {
    "name": "redis",
	"reconnect_on_error": true
  }
}' | sudo tee /etc/sensu/conf.d/transport.json
echo '{
  "client": {
    "name": "sensu",
    "address": "192.168.100.100",
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
#Copy checks from /vagrant to the client
sudo cp /vagrant/check-cpu.json /etc/sensu/conf.d/
sudo cp /vagrant/check-disk-usage.json /etc/sensu/conf.d/
sudo cp /vagrant/check-memory-percent.json /etc/sensu/conf.d/
#Start sensu
sudo systemctl enable sensu-{server,api,client}
sudo systemctl start sensu-{server,api,client}
sudo systemctl enable uchiwa
sudo systemctl start uchiwa
#Check the install
sudo yum install jq curl -y
curl -s http://127.0.0.1:4567/clients | jq .
