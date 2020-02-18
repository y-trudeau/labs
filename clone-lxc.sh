#!/bin/bash
#
# clone-lxc.sh 
#
ThisScript=$(echo ${0} | cut -d'/' -f2)
echo '' > /tmp/${ThisScript}.log
DEBUG_LOG="/tmp/${ThisScript}.log"
if [ "${DEBUG_LOG}" -a -w "${DEBUG_LOG}" -a ! -L "${DEBUG_LOG}" ]; then
  exec 9>>"$DEBUG_LOG"
  exec 2>&9
  date >&9
  set -x
fi

. $(dirname $0)/funcs.sh

. /etc/default/lxc-net
HOSTMAC=$(printf "%02x" $(echo $LXC_ADDR | cut -d'.' -f3))


if [ "$#" -ne 4 ]; then
  echo "Usage: $0 zfs|rbd Pool BaseSnap NomVM"
  exit
fi

mkdir -p ${LXCHOME}/$4
touch ${LXCHOME}/$4/fstab
cp ${LXCHOME}/../config.base ${LXCHOME}/$4/config
if [ "$1" == "zfs" ]; then
	zfs clone $2/lxc/$3 $2/lxc/$4
	if [ "$?" -ne 0 ]; then 
		echo "Echec de la commande zfs"
		exit 1
	fi
	zfs set mountpoint=${LXCHOME}/$4/rootfs $2/lxc/$4 
	echo $4 > ${LXCHOME}/$4/rootfs/etc/hostname
	uuidgen | tr -d '-' > ${LXCHOME}/$4/rootfs/etc/machine-id
elif [ "$1" == "rbd" ]; then
	rbd clone $2/$3 $2/$4 
	if [ "$?" -ne 0 ]; then 
		echo "Echec de la commande rbd"
		exit 1
	fi
	mkdir ${LXCHOME}/$4/rootfs
	dev=`rbd map $2/$4`
	mount $dev ${LXCHOME}/$4/rootfs -o nouuid
	echo $4 > ${LXCHOME}/$4/rootfs/etc/hostname
	uuidgen | tr -d '-' > ${LXCHOME}/$4/rootfs/etc/machine-id
	umount $dev
	rbd unmap $dev
	echo "rbd.image = $2/$4" >> ${LXCHOME}/$4/config
else
	echo "Option invalide"
	exit 1
fi

perl -pi -e "s/containername/$4/g" ${LXCHOME}/$4/config
mac=$(cat $LABHOME/mac)
let mac+=1
mac_hex=`printf "%06x" $mac`
mac_hex_form=$(echo "${mac_hex:0:2}:${mac_hex:2:2}:${mac_hex:4:2}")
perl -pi -e "s/lxc.net.0.hwaddr = ${BASEMAC}:xx/lxc.net.0.hwaddr = ${BASEMAC}:$mac_hex_form/g" ${LXCHOME}/$4/config
echo -n $mac > $LABHOME/mac

