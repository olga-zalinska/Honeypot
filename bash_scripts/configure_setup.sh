#!/bin/bash

main_dir=$(dirname "$0")
honeypot_dir=$1
user=$2
user_id=0
shared_volume=/volume
p0f_file="p0f_scan.log"

if [[ $EUID -ne $user_id ]]; then
   echo "This script must be run as root"
   exit 1
fi

echo "ForceCommand cd $honeypot_dir; ./main.py --full_mode" >> /etc/ssh/sshd_config
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

service ssh start
chmod 777 "$honeypot_dir"
p0f -i eth0 -o $shared_volume/$p0f_file -u $user -d 
