#!/bin/bash

user_id=0

main_dir=$(dirname "$0")

if [[ $EUID -ne $user_id ]]; then
   echo "This script must be run as root"
   exit 1
fi

remove_containers(){
  docker kill honeypot || true
  docker rm honeypot || true
  docker kill gateway || true
  docker rm gateway || true
  docker volume remove volume1 || true
  docker network remove net1 || true
}

create_and_run_containers() {
  docker network create --subnet=172.18.0.0/24 net1 && echo "Network already created" || echo "Created network net1"
  docker volume create --name volume1 && echo "Volume already created" || echo "Created volume volume1"

  docker build . -t honeypot_img -f Honeypot_Dockerfile && echo "Honeypot already created" || echo "Created Honeypot"
  docker build . -t gateway_to_honeypot -f Gateway_Dockerfile && echo "Gateway already created" || echo "Created Gateway"

  docker run -itd --net net1 -v volume1:/volume --name gateway gateway_to_honeypot /bin/bash || true
  docker run -itd --net net1 -v volume1:/volume --ip 172.18.0.2 --name honeypot honeypot_img /bin/bash || true
}

parse_args(){
  [ $# -eq 0 ] && usage

  while getopts ":cr" arg; do
    case ${arg} in
      c) # CREATE CONTAINERS
        create_and_run_containers
        ;;
      r) # REMOVE CONTAINERS
        remove_containers
        ;;
      *)
      usage
      exit 1
      ;;
    esac
  done
}

parse_args $*

exit 0

#docker inspect -f "{{ .NetworkSettings.Networks.net1.IPAddress }}" $honeypot_container
#docker exec -it gateway /bin/bash
#docker exec -it honeypot /bin/bash