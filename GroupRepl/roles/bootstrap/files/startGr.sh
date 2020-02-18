#!/bin/bash

cnt=$(mysql -proot -e "select * from performance_schema.replication_group_members;" 2> /dev/null | grep -c $(uname -n))
if [ "$cnt" -eq 0 ]; then
	mysql -proot -e "START GROUP_REPLICATION;" 2> /dev/null
fi
