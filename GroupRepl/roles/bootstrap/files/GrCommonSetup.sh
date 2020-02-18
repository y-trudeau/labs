#!/bin/bash

cnt=$(mysql -proot -e "show plugins;" 2> /dev/null| grep group_replication | grep -c ACTIVE)
if [ "$cnt" -eq 0 ]; then
        mysql -proot -e "INSTALL PLUGIN group_replication SONAME 'group_replication.so';" 2> /dev/null
fi

cnt=$(mysql -BN -proot -e "select count(*) from mysql.user where user='repl';" 2> /dev/null)
if [ "$cnt" -eq 0 ]; then
	mysql -proot -e "set SQL_LOG_BIN=0;CREATE USER repl@'10.0.%' IDENTIFIED BY 'repl';GRANT REPLICATION SLAVE ON *.* TO repl@'10.0.%';" 2> /dev/null
fi
mysql -proot -e "CHANGE MASTER TO MASTER_USER='repl', MASTER_PASSWORD='repl' FOR CHANNEL 'group_replication_recovery';" 2> /dev/null
