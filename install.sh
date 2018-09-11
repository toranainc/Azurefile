#!/bin/bash
#$1 for Ftp User Name
#$2 for Ftp Password
#$3 for Vm user Pwd
#$4 for Vm user dnsName
#$5 for Vm name
sudo -S <<< "$3" sudo -i
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
ICE_MEM=1024
JAVA_HOME=/data/deploy/jdk1.8.0_181
ICE_PROP=$ICEDQ_CONFIG/client/configs/ice_server.properties
CONFIG_JS=$ICEDQ_CONFIG/app/tomcat/webapps/icehtml/assets/config/config.js
CONFIG_ICE=$ICEDQ_CONFIG/app/tomcat/webapps/icehtml
CATALINA_HOME=$ICEDQ_CONFIG/app/tomcat
CATALINA_BASE=$ICEDQ_CONFIG/app/tomcat
CATALINA=$CATALINA_HOME/bin/catalina.sh
CONFIGER_XML=$CATALINA_HOME/webapps/ice/WEB-INF/web.xml
SERVER_XML=$CATALINA_HOME/conf/server.xml
CATALINA=$CATALINA_HOME/bin/catalina.sh
ICE_ENV=$CATALINA_HOME/bin/setenv.sh
BASHRC=$HOME/.bashrc
ICE_SYSTEMD=/usr/lib/systemd/system/icedq.service
  	sed -i -e "s|/opt/app/icedq/icestore|$ICE_STORE|g" $ICE_PROP
	sed -i -e 's/192.168.100.90/'"$4"'/g' $ICE_PROP
	sed -i -e 's/8300/'"$ICE_PORT"'/g' $ICE_PROP
	sed -i -e 's/icehtml/'"ice"'/g' $ICE_PROP
	sed -i -e 's/192.168.1.48/'"$4"'/g' $CONFIG_JS
	sed -i -e 's/8300/'"$ICE_PORT"'/g' $CONFIG_JS
	sed -i -e 's/8300/'"$ICE_PORT"'/g' $SERVER_XML
	sed -i -e 's/3072/'"$ICE_MEM"'/g' $CATALINA
	sed -i -e 's/Home.jsp/'"index.html"'/g' $CONFIGER_XML
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

mv $CONFIG_ICE/* $CATALINA_HOME/webapps/ice
source $CATALINA_HOME/bin/setenv.sh
rm -rf /data/icedq/app/vedit
# Service install Logic 
for i in 1;
do
    touch $ICE_SYSTEMD
    echo "#Systemd unit file for ICEDQ
[Unit]
Description=ICEDQ Service
After=syslog.target network.target
[Service]
User="$5"
Group=="$5"
Type=forking
WorkingDirectory=$CATALINA_HOME
Environment=CATALINA_PID=$ICEDQ_CONFIG/app/tomcat/temp/icedq.pid
Environment='JAVA_OPTS= -Djava.security.egd=file:/dev/./urandom'
ExecStart= $CATALINA_HOME/bin/startup.sh
ExecStop=/bin/kill -15 $MAINPID
[Install]
WantedBy=multi-user.target" > $ICE_SYSTEMD
sudo systemctl enable icedq.service
sudo systemctl daemon-reload
done

chmod -R 755 $ICE_SYSTEMD
chown -R "$5":"$5" $ICE_SYSTEMD

sudo systemctl enable icedq.service
sudo systemctl daemon-reload

chmod -R 755 $ICEDQ_CONFIG
chown -R $5:$5 /data
echo '$3' | sudo -S su - $5

#cd /home/icedqadmin 
#echo "$3" |su --login $5
#echo "$3" | sudo -S sudo systemctl start icedq.service

#chown -R icedq:icedq $ICEDQ_CONFIG
#sh $CATALINA_HOME/bin/startup.sh
sudo systemctl start icedq.service
