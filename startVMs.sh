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

if [ "$(id -u)" -ne "0" ]; then
	echo "$0 must be called by root or through sudo"
	exit 1
fi

. ../funcs.sh
. lab.sh


for v in $VMs; do 
	t=$(echo $v | cut -d'/' -f1) 
	n=$(echo $v | cut -d'/' -f2)
	startVM $t ${LABPREFIX}$n 
done

