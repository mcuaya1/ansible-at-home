#!/bin/bash
 
# Remove local-lvm and resive local
pvesm remove local-lvm

lvremove -y /dev/pve/data

lvresize -l +100%FREE /dev/pve/root

resize2fs /dev/mapper/pve-root

pvesm set local --content images,iso,vztmpl,backup,rootdir,import

# Remove pop up message
sed -i "0,/res.data.status.toLowerCase() !== 'active'/s/res.data.status.toLowerCase() !== 'active'/res.data.status.toLowerCase() == 'active'/" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

systemctl restart pveproxy.service 

echo "Finished."
