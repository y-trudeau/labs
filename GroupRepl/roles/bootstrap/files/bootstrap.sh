#!/bin/bash

cnt=$(mysql -proot -e "select * from performance_schema.replication_group_members;" 2> /dev/null | grep -c $(uname -n))
if [ "$cnt" -eq 0 ]; then
	mysql -proot -e "SET GLOBAL group_replication_bootstrap_group=ON;START GROUP_REPLICATION;SET GLOBAL group_replication_bootstrap_group=OFF;" 2> /dev/null
fi
