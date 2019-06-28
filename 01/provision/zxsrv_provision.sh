#!/bin/bash

echo "debug: Executing ZXSRV provision"

#yum install -y -q mc vim htop net-tools

if ! rpm -q mariadb ; then
    echo "Install mariadb..."
    yum install -y mariadb mariadb-server && \
    /usr/bin/mysql_install_db --user=mysql && \
    systemctl start mariadb && systemctl enable mariadb

    mysql -uroot -e "create database zabbix character set utf8 collate utf8_bin"
    mysql -uroot -e "grant all privileges on zabbix.* to zabbix@localhost identified by 'mdbpasswd'"
fi

## installing zabbix-server
if ! rpm -q zabbix-server-mysql ; then
    echo "debug: Install Zabbix Server"
    yum install -y http://repo.zabbix.com/zabbix/4.2/rhel/7/x86_64/zabbix-release-4.2-1.el7.noarch.rpm
    yum install -y zabbix-server-mysql zabbix-web-mysql 
    
    zcat /usr/share/doc/zabbix-server-mysql-*/create.sql.gz | mysql -uzabbix -pmdbpasswd zabbix

    sed -i 's/# DBHost/DBHost/' /etc/zabbix/zabbix_server.conf
    sed -i 's/# DBPassword/DBPassword=mdbpasswd/' /etc/zabbix/zabbix_server.conf

    sed -i 's-# php_value date.timezone Europe/Riga-php_value date.timezone Europe/Minsk-' /etc/httpd/conf.d/zabbix.conf

    systemctl start zabbix-server && systemctl enable zabbix-server

    [ "$(grep -c "# Alias" /etc/httpd/conf.d/zabbix.conf)" -eq "0" ]
        sed -i 's/^Alias/# Alias/' /etc/httpd/conf.d/zabbix.conf
        sed -i '/^# Alias.*/a </VirtualHost>' /etc/httpd/conf.d/zabbix.conf
        sed -i '/^# Alias.*/a ServerName zabbix-server' /etc/httpd/conf.d/zabbix.conf
        sed -i '/^# Alias.*/a DocumentRoot /usr/share/zabbix' /etc/httpd/conf.d/zabbix.conf
        sed -i '/^# Alias.*/a <VirtualHost *\:\80>' /etc/httpd/conf.d/zabbix.conf

    sudo systemctl start httpd && sudo systemctl enable httpd
fi 

echo "debug: Zabbix server ready"
