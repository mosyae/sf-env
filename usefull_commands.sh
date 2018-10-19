#Repository links
#http://192.168.100.1:8081/artifactory/cdh5/parcels/5.14.2/
#http://192.168.100.1:8081/artifactory/cdh4/parcels/latest/
#http://192.168.100.1:8081/artifactory/impala/parcels/latest/
#http://192.168.100.1:8081/artifactory/search/parcels/latest/
#http://192.168.100.1:8081/artifactory/accumulo/1.4/
#http://192.168.100.1:8081/artifactory/accumulo-c5/parcels/latest/
#http://192.168.100.1:8081/artifactory/kafka/parcels/latest/
#http://192.168.100.1:8081/artifactory/kudu/parcels/latest/
#http://192.168.100.1:8081/artifactory/spark/parcels/latest/
#http://192.168.100.1:8081/artifactory/sqoop-connectors/parcels/latest/

wget -r -np --no-check-certificate https://archive.cloudera.com/cdh5/parcels/5.14.2/
wget -r -np --no-check-certificate https://archive.cloudera.com/cdh4/parcels/latest/
wget -r -np --no-check-certificate https://archive.cloudera.com/impala/parcels/latest/
wget -r -np --no-check-certificate https://archive.cloudera.com/search/parcels/latest/
wget -r -np --no-check-certificate https://archive.cloudera.com/accumulo/1.4/
wget -r -np --no-check-certificate https://archive.cloudera.com/accumulo-c5/parcels/latest/
wget -r -np --no-check-certificate https://archive.cloudera.com/kafka/parcels/latest/
wget -r -np --no-check-certificate https://archive.cloudera.com/kudu/parcels/latest/
wget -r -np --no-check-certificate https://archive.cloudera.com/spark/parcels/latest/
wget -r -np --no-check-certificate https://archive.cloudera.com/sqoop-connectors/parcels/latest/




wget -np -r --no-check-certificate https://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/5.14.2/

wget -np -r --no-check-certificate https://archive.cloudera.com/cm5/redhat/7/x86_64/cm/5.14.2/

wget -np -r https://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/5.14.2/


wget -np -r https://archive.cloudera.com/cm5/redhat/7/x86_64/cm/5.14.2/

http://localhost:8081/artifactory/cdh5/

http://192.168.100.1:8081/artifactory/cdh5/redhat/7/x86_64/cdh/5.14.2/

http://192.168.100.1:8081/artifactory/cm5/redhat/7/x86_64/cm/5.14.2/


##==========Cloudera manager installation from Local Artifactory
cd /etc/yum.repos.d/
sudo wget https://archive.cloudera.com/cm5/redhat/7/x86_64/cm/cloudera-manager.repo
sudo wget http://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/cloudera-cdh5.repo
# cdh5
sudo sed -i 's/https\:\/\/archive.cloudera.com\/cdh5\/redhat\/7\/x86_64\/cdh\/5\//http\:\/\/192.168.100.1\:8081\/artifactory\/cdh5\/redhat\/7\/x86_64\/cdh\/5.14.2\//g' /etc/yum.repos.d/cloudera-cdh5.repo
# cm5
sudo sed -i 's/https\:\/\/archive.cloudera.com\/cm5\/redhat\/7\/x86_64\/cm\/5\//http\:\/\/192.168.100.1\:8081\/artifactory\/cm5\/redhat\/7\/x86_64\/cm\/5.14.2\//g' /etc/yum.repos.d/cloudera-manager.repo
cd ~
wget http://192.168.100.1:8081/artifactory/cm5/redhat/7/x86_64/cm/5.14.2/RPMS/x86_64/oracle-j2sdk1.7-1.7.0+update67-1.x86_64.rpm
sudo yum -y --disablerepo=* localinstall oracle-j2sdk1.7-1.7.0+update67-1.x86_64.rpm
sudo yum -y install cloudera-manager-daemons cloudera-manager-server
sudo yum -y install cloudera-manager-server-db-2
sudo systemctl start cloudera-scm-server-db
sleep 30
sudo systemctl start cloudera-scm-server

#check/validate Json file
python -m json.tool graphite.json

cd ~
wget http://192.168.100.1/cloudera/cm5/redhat/7/x86_64/cm/5.14.2/RPMS/x86_64/oracle-j2sdk1.7-1.7.0%2Bupdate67-1.x86_64.rpm

wget http://192.168.100.1/cloudera/cm5/redhat/7/x86_64/cm/5.14.2/RPMS/x86_64/oracle-j2sdk1.7-1.7.0%2Bupdate67-1.x86_64.rpm


wget http://192.168.100.1/cloudera/cm5/redhat/7/x86_64/cm/5.14.2/RPMS/x86_64/oracle-j2sdk1.7-1.7.0+update67-1.x86_64.rpm
sudo yum --disablerepo=* localinstall oracle-j2sdk1.7-1.7.0+update67-1.x86_64.rpm

#Change IIS to allow + in the URL - reference: https://blogs.iis.net/thomad/iis7-rejecting-urls-containing
#%windir%\system32\inetsrv\appcmd set config "Default Web Site" -section:system.webServer/security/requestfiltering -allowDoubleEscaping:true



https://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/cloudera-cdh5.repo


http://192.168.100.14:7180/cmf/express-wizard/welcome

http://192.168.100.14:7180/cmf/login

http://archive.cloudera.com/cdh5/redhat/7/x86_64/cdh/5.14.2/

http://172.16.101.6:8081/artifactory/shopFloor_static_content




Timed out while waiting for the machine to boot. This means that
Vagrant was unable to communicate with the guest machine within
the configured ("config.vm.boot_timeout" value) time period.

If you look above, you should be able to see the error(s) that
Vagrant had when attempting to connect to the machine. These errors
are usually good hints as to what may be wrong.

If you're using a custom box, make sure that networking is properly
working and you're able to connect to the machine. It is a common
problem that networking isn't setup properly in these boxes.
Verify that authentication configurations are also setup properly,
as well.

If the box appears to be booting properly, you may want to increase
the timeout ("config.vm.boot_timeout") value.
