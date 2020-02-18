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

. ../funcs.sh

LABPREFIX=LabGr

sudo ./mkHosts.sh

# give some time to start 
sleep 30

# let's create the hosts file


echo "[mysql]" > hosts
echo "${LABPREFIX}MySQL1 ansible_host=$(getIpVM ${LABPREFIX}MySQL1)" >> hosts
echo "${LABPREFIX}MySQL2 ansible_host=$(getIpVM ${LABPREFIX}MySQL2)" >> hosts
echo "${LABPREFIX}MySQL3 ansible_host=$(getIpVM ${LABPREFIX}MySQL3)" >> hosts
echo "[router]" >> hosts
echo "${LABPREFIX}Router ansible_host=$(getIpVM ${LABPREFIX}Router)" >> hosts
echo "[pmm]" >> hosts
echo "${LABPREFIX}Pmm ansible_host=$(getIpVM ${LABPREFIX}Pmm)" >> hosts

rm -rf cache/*
