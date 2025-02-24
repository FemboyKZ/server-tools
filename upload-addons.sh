#!/bin/bash

CONFIG_FILE=config.json
if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_FILE=config.example.json
fi

ip=$(jq -r '.upload_addons.ip' "$CONFIG_FILE")
user=$(jq -r '.upload_addons.user' "$CONFIG_FILE")
password=$(jq -r '.upload_addons.password' "$CONFIG_FILE")
ssh_key=$(jq -r '.upload_addons.ssh_key' "$CONFIG_FILE")
use_ssh=$(jq -r '.upload_addons.use_ssh' "$CONFIG_FILE")
local_folder=$(jq -r '.upload_addons.local_folder' "$CONFIG_FILE")

remote_folder="/home/$user/serverfiles/game/csgo/addons/"

if [ "$use_ssh" = true ]; then
    if [ -n "$ssh_key" ]; then
        rsync -avz -e "ssh -i $ssh_key" "$local_folder" "$user@$ip:$remote_folder"
    else
        sshpass -p "$password" rsync -avz -e "ssh" "$local_folder" "$user@$ip:$remote_folder"
    fi
else
    if [ -z "$use_ssh" ] || [ "$use_ssh" = false ]; then
            if [ -n "$ssh_key" ]; then
            echo "Setting up lftp with an SSH key requires manual configuration."
    else
        lftp_cmd="lftp -u $user,$password sftp://$ip"
        lftp -e "mirror -R $local_folder $remote_folder; quit" $lftp_cmd
    fi
fi

$rsync_cmd -avz --delete $local_folder $remote_folder
