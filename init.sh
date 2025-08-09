#!/bin/bash

# Run proxmox post install script
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pve-install.sh)"
 
# Remove local-lvm and resive local
pvesm remove local-lvm

lvremove -y /dev/pve/data

lvresize -l +100%FREE /dev/pve/root

resize2fs /dev/mapper/pve-root

pvesm set local --content images,iso,vztmpl,backup,rootdir,import

echo "Finished..."
