#!/bin/bash

# TODO: * Add logic to remove local-lvm from cli.
#        * Note that the following proxmox helper script does inital proxmox configuration but not resizing and deleting local-lvm
#          https://community-scripts.github.io/ProxmoxVE/scripts?id=post-pve-install        

# Run this script after removing  'local-lvm' in the GUI

lvremove /dev/pve/data

lvresize -l +100%FREE /dev/pve/root

resize2fs /dev/mapper/pve-root

echo "Finished..."
