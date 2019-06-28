#!/bin/bash

echo "debug: Executing ZXAGT provision"

#yum install -y -q mc vim htop net-tools

## installing zabbix-agent
if ! rpm -q zabbix-agent 
then
    echo "debug: Install Zabbix Agent"
    yum install -y http://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-1.el7.noarch.rpm
    yum install -y zabbix-agent

    sed -i 's/# ListenPort/ListenPort/' /etc/zabbix/zabbix_agentd.conf
    sed -i 's/# ListenIP/ListenIP/' /etc/zabbix/zabbix_agentd.conf
    sed -i 's/# StartAgents/StartAgents/' /etc/zabbix/zabbix_agentd.conf
    sed -i 's/# HostnameItem/HostnameItem/' /etc/zabbix/zabbix_agentd.conf

    if [ -d "/opt/tomcat" ]; then
        sed -i 's/Server=127.0.0.1/Server=192.168.99.10/' /etc/zabbix/zabbix_agentd.conf
        sed -i 's/ServerActive=127.0.0.1/ServerActive=192.168.99.10/' /etc/zabbix/zabbix_agentd.conf
        sed -i 's/Hostname=Zabbix server/Hostname=Tomcat/' /etc/zabbix/zabbix_agentd.conf
        sed -i 's/# HostMetadata=/HostMetadata=system.uname/' /etc/zabbix/zabbix_agentd.conf
    fi 

    systemctl start zabbix-agent && systemctl enable zabbix-agent    
fi


echo "debug: Zabbix agent ready"
