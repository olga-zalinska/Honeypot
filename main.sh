#!/bin/bash

WRONG_ARGS=1

show_help() {
echo ""
echo ""
echo "$0 usage: [-c CREATE CONTAINERS] or [-l LOGIN TO HONEYPOT] or [-r REMOVE CONTAINERS] or [-e EXECUTED COMMANDS ] or [ -p PLAY LOGGED ACTIONS] or [-s SSH STATISTICS]"
echo ""
grep " .)\ #" $0
}


usage() {
show_help
exit $WRONG_ARGS
}

parse_args(){
[ $# -eq 0 ] && usage

while getopts ":hepclrs" arg; do
  case ${arg} in
    e) # EXECUTED COMMANDS
      docker exec -it gateway perl /root/Honeypot/main.pl --executed_commands
      exit 0
      ;;
    p) # PLAY LOGGED ACTIONS
      docker exec -it gateway perl /root/Honeypot/main.pl --play_logged_actions
      exit 0
      ;;
    c) # CREATE CONTAINERS
      bash_scripts/make_containers.sh -c
      exit 0
      ;;
    l) # LOGIN TO HONEYPOT
      docker exec -it gateway ssh user@172.18.0.2
      exit 0
      ;;
    r) # REMOVE CONTAINERS
      bash_scripts/make_containers.sh -r
      exit 0
      ;;
    s) # SSH STATISTICS
      echo "Not implemented"
      exit 0
      ;;
    h) # HELP
      show_help
      exit 0
      ;;
    help) # HELP
      show_help
      exit 0
      ;;
    *)
    usage
    exit 1
    ;;
  esac
done
}

check_required_packages (){
	required_packages=(git docker )
	i=0
	for package in "${required_packages[@]}"
	do
		which ${package} > /dev/null
		if ! [ $? = 0 ]
		then
		 echo "Error: $package should be installed"
		 let i++
		fi
	done

	if ! [ $i = 0 ]
	then
		exit $i
	fi
}

parse_args $*
check_required_packages

exit 0


