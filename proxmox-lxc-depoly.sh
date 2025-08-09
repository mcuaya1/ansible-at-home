#!/bin/bash

#TODO: * Add logic to detect if any container exist

lxc_gen()
{
 
 pct create ${1} local:vztmpl/${2} \
	 --hostname lxc${1} \
	 --cores 2 \
	 --cpulimit 2 \
	 --memory 512 \
	 --swap 512 \
	 --storage local \
	 --rootfs local:8 \
	 --net0 name=eth0,bridge=vmbr0,ip=dhcp \
	 --features nesting=1

}

lxc_init()
{
 case ${1} in
   "arch")
	echo "Initializing Arch Linux startup script."
	pct set ${2} --description "User:cyber | Password: ${4}"
	pct exec ${2} -- bash -c "pacman --disable-sandbox --noconfirm -Syu && \ 
	    pacman --disable-sandbox --noconfirm -Sy curl ${5} && \
	    mkdir -p /etc/pve/lxc/ && \
	    curl -fsSL https://tailscale.com/install.sh | sh && \
	    tailscale up --auth-key=${3} && \
	    tailscale set --ssh && \
	    useradd -m cyber && \
	    echo ${4} | passwd cyber --stdin \
	    passwd -dl root"
     ;;
 esac
}

# Display help function
Help()
{
   echo "Create LXC containers in bulk."
   echo
   echo "Syntax: proxmox-lxc-depoly.sh [-n|h|a]"
   echo "options:"
   echo "n     Number of LXC containers to create."
   echo "t     Template to use when creating container."
   echo "d     Distro template is based off of. Currently available options are the following:
   	       arch=Arch Linux 2025"
   echo "e     Extra packages to install. See example below:
               curl wget etc"
   echo "s     Starting range for containers."
   echo "h     Print help."
   echo
}


# Defaults
EXTRA=""

# Get the options
while getopts ":hn:t:d:e:s:" option; do
   case $option in
      h) # display Help
         Help
	 exit
         ;;
     n) # store number of containers
	 NUM=$OPTARG
	 ;;
     t) # container template
	 TEMPLATE=$OPTARG
	 ;;
     d) # distro being used
 	 DISTRO=$OPTARG
	 ;;
     e) # extra packages to install
	 EXTRA=$OPTARG
	 ;;
     s) # starting range
	 START=$OPTARG
	 ;;
     \?) # invalid option
         echo "Error: Invalid option"
         exit
	 ;;
   esac
done

if [[ -z "${NUM}" ]]; then
  echo "Number LXC containers not specified."
  exit 1
fi

if [[ -z "${DISTRO}"  ]]; then
  echo "Distro not specified."
  exit 1
fi

if [[ -z "${TEMPLATE}"  ]]; then
  echo "Container template not specified."
  exit 1
fi

if pveam list local | grep -qw ${TEMPLATE}; then
  echo "Template found."
else
  echo "Template not found."
  exit 1
fi

if [[ -z "${START}" ]]; then
  echo "Starting range not specified"
  exit 1
fi

END=$(expr ${START} - 1 + ${NUM})

for (( i=$START; i<=$END; i++ ))
do
	echo "Creating LXC${i}."
	lxc_gen ${i} ${TEMPLATE} &
done

wait

echo "Initalizing containers and installing tailscale."
AUTH_KEY=$(cat .authkey)

for (( i=$START; i<=$END; i++ ))
do

cat << EOF >> /etc/pve/lxc/${i}.conf
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
EOF

	pct start ${i}
	sleep 5
	lxc_init ${DISTRO} ${i} ${AUTH_KEY} $(openssl rand -base64 6) ${EXTRA} &
done

wait

reset
echo "Finished."
