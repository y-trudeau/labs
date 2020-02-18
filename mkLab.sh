#!/bin/bash

ThisScript=$(echo ${0} | cut -d'/' -f2)
echo '' > /tmp/${ThisScript}.log
DEBUG_LOG="/tmp/${ThisScript}.log"
if [ "${DEBUG_LOG}" -a -w "${DEBUG_LOG}" -a ! -L "${DEBUG_LOG}" ]; then
  exec 9>>"$DEBUG_LOG"
  exec 2>&9
  date >&9
  set -x
fi

if [ ! -f "lab.sh" ]; then
	echo "Does not appear to be a project directory, no lab.sh file"
	exit 1
fi

. ../funcs.sh
. lab.sh

sudo ../mkHosts.sh

# give some time to start 
sleep 30

# let's create the hosts file
echo '' > hosts
for g in $Groups
do
	group=$(echo $g | cut -d'/' -f1)
	members=$(echo $g | cut -d'/' -f2 | tr ',' ' ')
	echo "[${group}]" >> hosts
	for m in $members
	do
		echo "${LABPREFIX}${m} ansible_host=$(getIpVM ${LABPREFIX}${m})" >> hosts
	done
done

rm -rf cache/*

ansible-playbook -i hosts site.yml
