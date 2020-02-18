#!/bin/bash
# 
# clone-vm.sh vmName SnapName [1804|1604]
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

# called from a project directory
. $(dirname $0)/funcs.sh

if [ -n "$3" ]; then
	OS=$3
else
	OS="1804"
fi

if [ "$#" -lt 2 ]; then
	echo "Manque des paramètres!"
	echo "Usage: $0 zfssnap nouvVmNom [1804|1604] (default 1804)"
        echo -e "\nZFS snapshots disponibles:\n"
	zfs list -t snapshot	
	exit
fi
zfs clone $1 data/vms/$2
sleep 1

if [ "${OS}" == "1804" ]; then
	partprobe /dev/zvol/data/vms/$2
	sleep 1
	# Slash is in partition 3 in the base1804 image
	tmpMountPoint=$(mktemp -d)
	mount /dev/zvol/data/vms/${2}-part3 $tmpMountPoint
	pushd $tmpMountPoint > /dev/null
	echo $2 > etc/hostname
	uuidgen | tr -d '-' > etc/machine-id
	popd > /dev/null
	umount $tmpMountPoint
	rmdir $tmpMountPoint
fi

cp ${LABHOME}/kvm-template.xml ${KVMHOME}/${2}.xml
perl -pi -e "s/ubuntu16.04/${2}/g" ${KVMHOME}/${2}.xml
perl -pi -e "s/0ab0c63e-b33e-4a7b-b170-4778dae67616/$(uuidgen)/g"  ${KVMHOME}/${2}.xml
perl -pi -e "s|/dev/zvol/data/vms/kvm_base1604|/dev/zvol/data/vms/${2}|g" ${KVMHOME}/${2}.xml

# Trouvons une port vnc non-utilise
# ss -antp | grep 'qemu-system' |  grep '127.0.0.1:59'
p=''
for i in $(seq 0 254)
do
        p=$(printf "%02i" $i)
        if ss -antp | grep ":59${p}" > /dev/null; then
                continue;
        else
                break;
        fi
done
perl -pi -e "s/5900/59${p}/g" ${KVMHOME}/${2}.xml

mac=$(cat $LABHOME/mac)
let mac+=1
mac_hex=`printf "%06x" $mac`
mac_hex_form=$(echo "${mac_hex:0:2}:${mac_hex:2:2}:${mac_hex:4:2}")
echo -n $mac > $LABHOME/mac
perl -pi -e "s/${BASEMAC}:00:00:00/${BASEMAC}:$mac_hex_form/g" ${KVMHOME}/${2}.xml
virsh create ${KVMHOME}/${2}.xml

if [ "${OS}" == "1604" ]; then
	for i in $(seq 1 120); do
		IP=$(virsh net-dhcp-leases default | grep "${BASEMAC}:$mac_hex_form" | awk '{ print $5 }')
		if [ "${IP:0:2}" == "10" ]; then
			sleep 2 # to allow sshd to start
			break
		fi
		echo -n '.' 
		sleep 1
	done
	IP=$(virsh net-dhcp-leases default | grep "${BASEMAC}:$mac_hex_form" | awk '{ print $5 }' | cut -d'/' -f1)
	
	echo $2 | su yves -c "ssh root@$IP 'cat - > /etc/hostname;lvextend -L+4G /dev/vg0/lvSlash;resize2fs /dev/vg0/lvSlash;reboot'"
fi

