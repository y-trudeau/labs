This set of scripts creates lab environments in LXC and/or KVM. The scripts are alpha at best, you'll need to get your hands dirty.  It assumes a few things:

- Both LXC and KVM share the same network, with dnsmasq acting as a DHCP server
- ZFS is used, reference images for Ubuntu 16.04 or 18.04 exists and have snapshots
- The ubuntu images have a ubuntu user for which a public key has been pushed.  The ubuntu user is sudoer without password.
- Ansible is installed.

For KVM, it is important the 3rd partition is /, no LVM.  The image needs not be mounted before kvm starts to set the hostname and machine-id

Configure the variables at the top of the funcs.sh file to reflect your setup:

  LABHOME=/home/yves/labs
  declare -A LXCsnap
  LXCsnap[1804]="data/lxc/base1804@20200110"
  declare -A KVMsnap
  KVMsnap[1804]="data/vms/kvm_base1804@20181125"
  KVMsnap[1604]="data/vms/kvm_base1604@20190206"
  LXCHOME=${LABHOME}/VMs/lxc
  KVMHOME=${LABHOME}/VMs
  BASEMAC="00:16:3e"

To create a lab, create a directory in LABHOME (ex: PXC3n), then copy an ansible.cfg from another project and create a lab.sh file with:

  LABPREFIX=LabPXC3n
  VMs="LXC/1 LXC/2 LXC/3"
  Groups="mysql/1,2,3 bootstrap/1"

This will creates 3 LXC VMS called LabPXC3n1, LabPXC3n2 and LabPXC3n3. The ansible hosts files will have 2 groups: mysql and bootstrap.  The hosts file will be created and populated by the script.  Once you are ready, do:

  ../mkLab.sh 

This creates the VMs, populate the hosts file and then launch ansible to configure it. 
