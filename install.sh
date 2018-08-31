#!/bin/bash
#$1 for Ftp User Name
#$2 for Ftp Password
#$3 for Vm user Name
#$4 for Vm user Pwd
#$5 for vm dnsName
sudo -S <<< "$4" sudo -i
(echo n; echo p; echo 1; echo ; echo ; echo w) | sudo fdisk /dev/sdc
sudo mkfs -t ext4 /dev/sdc1
sudo mkdir /data && sudo mount /dev/sdc1 /data
#cd /home/$3
if [ -d "/data/deploy" ] 
then
    echo "Directory /path/to/dir exists." 
else
    echo "Error: Directory /path/to/dir does not exists."
	mkdir -p /data/deploy
	chmod 755 -R /data/deploy
	#chown -R $1:$1 /home/$3/deploy
fi
cd /data/deploy
#wget --user icedemo --password ice123demo http://download.icedq.com/ice_client_V20.zip
wget --user  $1 --password $2 http://download.icedq.com/ICEDQ_12_2_0_x64_linux.tar
tar -xvf ICEDQ_12_2_0_x64_linux.tar 
#>> /home/icedq
#install Java
wget --user  $1 --password $2 http://download.icedq.com/jdk-8u181-linux-x64.tar.gz
tar -xzf jdk-8u181-linux-x64.tar.gz 
#>> /home/
mv -f /data/deploy/ICEDQ_12_2_0_x64_linux/icedq /data/icedq
HOSTNAME="`hostname`"
ICEDQ_CONFIG=/data/icedq
ICE_STORE=/data/icedq/icestore
ICE_PORT=80
JAVA_HOME=/data/deploy/jdk1.8.0_181
ICE_PROP=$ICEDQ_CONFIG/client/configs/ice_server.properties
CONFIG_JS=$ICEDQ_CONFIG/app/tomcat/webapps/icehtml/assets/config/config.js
CATALINA_HOME=$ICEDQ_CONFIG/app/tomcat
CATALINA_BASE=$ICEDQ_CONFIG/app/tomcat
SERVER_XML=$CATALINA_HOME/conf/server.xml
CATALINA=$CATALINA_HOME/bin/catalina.sh
ICE_ENV=$CATALINA_HOME/bin/setenv.sh
BASHRC=$HOME/.bashrc
ICE_SYSTEMD=/etc/systemd/system/icedq.service
  	sed -i -e "s|/opt/app/icedq/icestore|$ICE_STORE|g" $ICE_PROP
	sed -i -e 's/192.168.100.90/'"$5"'/g' $ICE_PROP
	sed -i -e 's/8300/'"$ICE_PORT"'/g' $ICE_PROP
	sed -i -e 's/192.168.1.48/'"$5"'/g' $CONFIG_JS
	sed -i -e 's/8300/'"$ICE_PORT"'/g' $SERVER_XML
  touch $ICE_ENV
        echo "#!/bin/bash" > $ICE_ENV
        echo >> $ICE_ENV
        echo "export JAVA_HOME=$JAVA_HOME" >> $ICE_ENV
        echo "export ICEDQ_CONFIG=$ICEDQ_CONFIG" >> $ICE_ENV
        echo "export CATALINA_HOME=$ICEDQ_CONFIG/app/tomcat" >> $ICE_ENV
        echo "export CATALINA_BASE=$ICEDQ_CONFIG/app/tomcat" >> $ICE_ENV
        echo "export PATH=$JAVA_HOME/bin:$PATH" >> $ICE_ENV
        echo "source $ICE_ENV" >> $BASHRC
		#chmod 755 $ICE_ENV
		#chown -R icedq:icedq $ICE_ENV
source $CATALINA_HOME/bin/setenv.sh
# Service install Logic 
for i in 1;
do
    touch $ICE_SYSTEMD
    echo "#Systemd unit file for ICEDQ
[Unit]
Description=ICEDQ Service
After=syslog.target network.target
[Service]
Type=forking
WorkingDirectory=$CATALINA_HOME
Environment=CATALINA_PID=$ICEDQ_CONFIG/app/tomcat/temp/icedq.pid
Environment='JAVA_OPTS= -Djava.security.egd=file:/dev/./urandom'
ExecStart= $CATALINA_HOME/bin/startup.sh
ExecStop=/bin/kill -15 $MAINPID
User=root
[Install]
WantedBy=multi-user.target" > $ICE_SYSTEMD
sudo systemctl enable icedq.service
sudo systemctl daemon-reload
done
sudo chmod -R 755 /etc/systemd/system
sudo systemctl enable icedq.service
sudo systemctl daemon-reload
chmod -R 755 $ICEDQ_CONFIG
#chown -R icedq:icedq $ICEDQ_CONFIG
#sh $CATALINA_HOME/bin/startup.sh
sudo systemctl start icedq.service
