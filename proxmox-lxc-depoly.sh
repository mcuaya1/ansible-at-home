#!/bin/bash

#TODO: * Add logic to detect if any container exist
#       * Add flag to specify start range

# Before running this script, ensure the specificed template has been downloaded
# And have at least ONE container created


# Display help function
Help()
{
   echo "Create LXC containers in bulk."
   echo
   echo "Syntax: proxmox-lxc-depoly.sh [-n|h|a]"
   echo "options:"
   echo "n     Number of LXC containers to create."
   echo "h     Print help."
   echo
}


# Get the options
while getopts ":hn:a" option; do
   case $option in
      h) # display Help
         Help
	 exit
         ;;
     n) # store number of containers
	 NUM=$OPTARG
	 ;;
     \?) # invalid option
         echo "Error: Invalid option"
         exit
	 ;;
   esac
done

if [[ -z "$NUM" ]]; then
  echo "Number LXC containers not specified."
  exit
fi

START=$( expr $(pct list | cut -d " " -f 1 | tail -n 1) + 1)

END=$(expr ${START} - 1 + ${NUM})

for (( i=$START; i<=$END; i++ ))
do
	echo "Creating LXC${i}."
	echo
	pct create ${i} local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
	    --hostname lxc${i} \
	    --password temp12345 \
	    --cores 2 \
	    --cpulimit 2 \
	    --memory 512 \
	    --swap 0 \
	    --storage local \
	    --rootfs local:8 \
	    --net0 name=eth0,bridge=vmbr0,ip=dhcp,tag=${i} \
	    --features nesting=1 &
done

wait

echo "Setting up tailscale."
AUTH_KEY=$(cat .authkey)
for (( i=$START; i<=$END; i++ ))
do

cat << EOF >> /etc/pve/lxc/${i}.conf
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
EOF

	pct start ${i}
	sleep 1
	pct exec ${i} -- bash -c "apt update -y && \ 
	    apt upgrade -y && \
	    apt install -y curl && \
	    mkdir -p /etc/pve/lxc/ && \
	    curl -fsSL https://tailscale.com/install.sh | sh
	    tailscale up --auth-key=${AUTH_KEY}" &
done

wait

reset
echo "Finished."
