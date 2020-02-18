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

. /home/yves/labs/funcs.sh

LABPREFIX=LabGr

# The group replication lab is made of:
# - 3 LXC VMs running MySQL
# - 1 LXC VMs running MySQL router
# - 1 kvm VMs running PMM

destroyVM LXC ${LABPREFIX}MySQL1 
destroyVM LXC ${LABPREFIX}MySQL2 
destroyVM LXC ${LABPREFIX}MySQL3 
destroyVM LXC ${LABPREFIX}Router 
destroyVM KVM ${LABPREFIX}Pmm 

