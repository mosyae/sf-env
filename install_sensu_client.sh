#!/bin/sh
#http://roobert.github.io/2015/11/09/Sensu-What/
#https://wecode.wepay.com/posts/sensu-at-wepay
ip="$(ifconfig | grep -A 1 'eth1' | grep inet | awk '{print($2)}')"
echo '[sensu]
name=sensu
baseurl=https://sensu.global.ssl.fastly.net/yum/$releasever/$basearch/
gpgcheck=0
enabled=1' | sudo tee /etc/yum.repos.d/sensu.repo
sudo yum install sensu
#Configure Client * :
echo '{
  "transport": {
    "name": "redis",
	"reconnect_on_error": true
  }
}' | sudo tee /etc/sensu/conf.d/transport.json
echo '{
  "client": {
    "name": "$HOSTNAME",
    "address": "$ip",
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
sudo chown -R sensu:sensu /etc/sensu
sudo systemctl enable sensu-{api,client}
sudo systemctl start sensu-{api,client}
#Install checks
sudo sensu-install -p cpu-checks  
sudo sensu-install -p disk-checks  
sudo sensu-install -p memory-checks  
#sudo sensu-install -p nginx  
sudo sensu-install -p process-checks  
sudo sensu-install -p load-checks  
sudo sensu-install -p vmstats  
#sudo sensu-install -p mailer
cd /etc/sensu/conf.d


