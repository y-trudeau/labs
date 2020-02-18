# Prefix of all VMs
LABPREFIX=K8s

# List of VMs Type/suffix  Type is [LXC|KVM]
VMs="KVM/master KVM/worker1 KVM/worker2"

# Ansible roles, space separated
# for each role:  RoleName/member1,member2
Groups="master/master worker/worker1,worker2"

# OS currently supports only 1804 and 1604
OS="1604"  
