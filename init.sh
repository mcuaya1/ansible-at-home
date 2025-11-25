#!/bin/bash
 
# Remove local-lvm and resive local
pvesm remove local-lvm

lvremove -y /dev/pve/data

lvresize -l +100%FREE /dev/pve/root

resize2fs /dev/mapper/pve-root

pvesm set local --content images,iso,vztmpl,backup,rootdir,import

# Remove pop up message
sed -n "0,/.data.status.toLowerCase() !== 'active'/s/.data.status.toLowerCase() !== 'active'/.data.status.toLowerCase() == 'active'/" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

systemctl restart pveproxy.service 

echo "Finished."
