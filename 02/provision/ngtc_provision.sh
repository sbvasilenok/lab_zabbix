#!/bin/bash

echo "debug: Executing provision"

#yum install -y -q mc vim htop net-tools

## installing nginx
if ! rpm -q nginx 
then 
    yum install -y nginx
    sed -i '/\[\:\:\]/d' /etc/nginx/nginx.conf
    sed -i '/^#/d' /etc/nginx/nginx.conf
    [ "$(grep -c "proxy_pass" /etc/nginx/nginx.conf)" -eq "0" ] && \
        sed -i '/.*location\ \/.*/a \ \ \ \ proxy_pass\ \ http\:\/\/127\.0\.0\.1\:8080\;' /etc/nginx/nginx.conf

    systemctl start	nginx && systemctl enable nginx
fi


# if ! rpm -q java 
# then 
#     yum install -y -q java
# fi

# installing java
if [ ! -f /usr/java/jdk1.8.0_212/bin/java ]; then

    echo "debug: Download and Install Oracle JDK_8"
    mkdir /usr/java
    cd /usr/java

    [ ! -f /usr/java/jdk-8*-x64.tar.gz ] && \
      wget https://github.com/frekele/oracle-java/releases/download/8u212-b10/jdk-8u212-linux-x64.tar.gz && \
      tar xzf jdk-8*-x64.tar.gz
fi

export JAVA_HOME=/usr/java/jdk1.8.0_212/
export PATH=$PATH:$JAVA_HOME/bin/


## installing tomcat
# preparing systemd service for tomcat
SDTC=$(cat <<EOF
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/java/jdk1.8.0_212/
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.port=12345 -Dcom.sun.management.jmxremote.rmi.port=12346 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false -Djava.rmi.server.hostname=192.168.99.20'
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF
)

if [ ! -d "/opt/tomcat" ]; then
    echo "debug: Download and Install Tomcat"
    groupadd tomcat
    sudo useradd -g tomcat -d /opt/tomcat tomcat
    mkdir /opt/tomcat
    cd /tmp
    wget http://ftp.byfly.by/pub/apache.org/tomcat/tomcat-8/v8.5.42/bin/apache-tomcat-8.5.42.tar.gz
    tar xzf apache-tomcat-8*tar.gz -C /opt/tomcat --strip-components=1
    chgrp -R tomcat /opt/tomcat
    cd /opt/tomcat
    chmod -R g+r conf
    chmod g+x conf
    sudo chown -R tomcat webapps/ work/ temp/ logs/
    # importing systemd service for tomcat
    echo "${SDTC}" > /etc/systemd/system/tomcat.service

    systemctl start tomcat && systemctl enable tomcat
fi


echo "debug: NG_TC ready"