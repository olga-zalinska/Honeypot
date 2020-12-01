#!/bin/bash

user_id=0
main_dir=$(dirname "$0")
honeypot_dir=$1
shared_volume=/volume

if [[ $EUID -ne $user_id ]]; then
   echo "This script must be run as root"
   exit 1
fi

echo "ForceCommand cd $honeypot_dir; ./main.py --full_mode" >> /etc/ssh/sshd_config
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

service ssh start
service mysql start &
apachectl -D FOREGROUND &
chmod 777 "$shared_volume"
chmod 777 "$honeypot_dir"
sudo --user=root p0f -i eth0 >> $shared_volume/p0f_scan.log &
