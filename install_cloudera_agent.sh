##==========Cloudera Agent installation from Local Artifactory
cd /etc/yum.repos.d/
sudo wget https://archive.cloudera.com/cm5/redhat/7/x86_64/cm/cloudera-manager.repo
sudo wget http://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/cloudera-cdh5.repo
## cdh5
sudo sed -i 's/https\:\/\/archive.cloudera.com\/cdh5\/redhat\/7\/x86_64\/cdh\/5\//http\:\/\/192.168.100.1\:8081\/artifactory\/cdh5\/redhat\/7\/x86_64\/cdh\/5.14.2\//g' /etc/yum.repos.d/cloudera-cdh5.repo
## cm5
sudo sed -i 's/https\:\/\/archive.cloudera.com\/cm5\/redhat\/7\/x86_64\/cm\/5\//http\:\/\/192.168.100.1\:8081\/artifactory\/cm5\/redhat\/7\/x86_64\/cm\/5.14.2\//g' /etc/yum.repos.d/cloudera-manager.repo
cd ~
wget http://192.168.100.1:8081/artifactory/cm5/redhat/7/x86_64/cm/5.14.2/RPMS/x86_64/oracle-j2sdk1.7-1.7.0+update67-1.x86_64.rpm
sudo yum -y --disablerepo=* localinstall oracle-j2sdk1.7-1.7.0+update67-1.x86_64.rpm
sudo yum -y install cloudera-manager-daemons cloudera-manager-agent
## check that you can connect netstat -an | grep 7180
## connect 