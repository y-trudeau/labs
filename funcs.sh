#!/bin/bash
# Common functions to configure lab env.
#

LABHOME=/home/yves/labs
declare -A LXCsnap
LXCsnap[1804]="data/lxc/base1804@20200110"
declare -A KVMsnap
KVMsnap[1804]="data/vms/kvm_base1804@20181125"
KVMsnap[1604]="data/vms/kvm_base1604@20190206"
LXCHOME=${LABHOME}/VMs/lxc
KVMHOME=${LABHOME}/VMs
BASEMAC="00:16:3e"

# Check if a VM is running, 1=yes, 0=no
# $1 is the VM type: {KVM,LXC}
# $2 is the VM name
isRunningVM() {
	VMType=$1
	VMName=$2

	vmRunning=0
        case "$VMType" in
                "LXC")
			lxc-ls --lxcpath=${LXCHOME} -f | grep RUNNING | grep $VMName > /dev/null
			if [ "$?" -eq 0 ]; then
				vmRunning=1
			fi
                        ;;
                "KVM")
			virsh list | grep -i RUNNING | grep $VMName > /dev/null
			if [ "$?" -eq 0 ]; then
				vmRunning=1
			fi
                        ;;
        esac

	echo $vmRunning

}

#Start the VM
# $1 is the VM type: {KVM,LXC}
# $2 is the VM name
startVM() {
	VMType=$1
	VMName=$2

	if [ "$(isRunningVM $VMType $VMName)" -eq 0 ]; then
        	case "$VMType" in
                	"LXC")
				mkdir -p ${LXCHOME}
				lxc-start --lxcpath=${LXCHOME} -d -n $VMName
                        ;;
                	"KVM")
				mkdir -p ${KVMHOME}
				virsh create ${KVMHOME}/${VMName}.xml
                        ;;
        	esac
	fi
}

#Stop the VM
# $1 is the VM type: {KVM,LXC}
# $2 is the VM name
stopVM() {
	VMType=$1
	VMName=$2

	if [ "$(isRunningVM $VMType $VMName)" -eq 1 ]; then
        	case "$VMType" in
                	"LXC")
				lxc-stop --lxcpath=${LXCHOME} -n $VMName
                        ;;
                	"KVM")
				virsh destroy $VMName 
                        ;;
        	esac
	fi

}


# Check if a VM is defined, 1=yes, 0=no
# $1 is the VM type: {KVM,LXC}
# $2 is the VM name
existsVM() {
	VMType=$1
	VMName=$2

	vmExists=0
        case "$VMType" in
                "LXC")
                        pushd $LXCHOME > /dev/null
			ls -d ${VMName}/ > /dev/null 2> /dev/null
			if [ "$?" -eq 0 ]; then
				vmExists=1
			fi
                        popd > /dev/null
                        ;;
                "KVM")
                        pushd $KVMHOME  > /dev/null
			ls ${VMName}.xml > /dev/null 2> /dev/null
			if [ "$?" -eq 0 ]; then
				vmExists=1
			fi
                        popd > /dev/null
                        ;;
        esac

	echo $vmExists

}

# Create a VM
# $1 is the VM type: {KVM,LXC}
# $2 is the VM name
# $3 is the OS ["1804"|"1604"]
createVM() {
	VMType=$1
	VMName=$2
	OS=$3 

	if [ -z "$OS" ]; then
		OS="1804"
	fi

	if  [ "$(existsVM $VMType $VMName)" -eq 1 ]; then
		return 0
	fi

	case "$VMType" in
		"LXC")
			      pushd $LXCHOME > /dev/null
		        $LABHOME/clone-lxc.sh zfs data $(echo "${LXCsnap[$OS]}" | cut -d'/' -f3) $VMName 
        		popd > /dev/null
			;;
		"KVM")
		        pushd $KVMHOME > /dev/null
        		$LABHOME/clone-kvm.sh ${KVMsnap[$OS]} $VMName $OS > /dev/null
        		popd > /dev/null
			;;
	esac
	echo "VM ${VMType}/${VMName} created"
	return 0

}


# Destroy a VM
# $1 is the VM type: {KVM,LXC}
# $2 is the VM name
destroyVM() {
	VMType=$1
	VMName=$2

	if  [ "$(existsVM $VMType $VMName)" -eq 0 ]; then
		return 0
	fi

	if [ "a$VMName" == "a" ]; then
		echo "VMName is not defined, can't proceed"
		exit 1
	fi

	stopVM $VMType $VMName
	sleep 1

	case "$VMType" in
		"LXC")
			pushd $LXCHOME > /dev/null
			umount ${LXCHOME}/${VMName}/rootfs
			for i in $(seq 1 10); do
				zfs destroy data/lxc/$VMName
				if [ "$?" -eq 0 ]; then
					break;
				fi
				sleep $i
			done
			rm -rf ${LXCHOME}/$VMName
        		popd > /dev/null
		;;
		"KVM")
		        pushd $KVMHOME > /dev/null
			virsh destroy $VMName
			zfs destroy data/vms/$VMName
			rm -f ${VMName}.xml
        		popd > /dev/null
		;;
	esac
	echo "VM ${VMType}/${VMName} destroyed"
	return 0

}

# $1 is the VM name 
getIpVM() {
	virsh net-dhcp-leases default | grep $1 | awk '{ print $1" "$2" "$5 }' | sort | tail -n 1 | cut -d' ' -f3 | cut -d'/' -f1
}

