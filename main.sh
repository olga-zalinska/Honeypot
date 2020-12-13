#!/bin/bash

WRONG_ARGS=1
main_dir=$(dirname "$0")

show_help() {
echo ""
echo "***Honeypot***"
echo ""
echo "                   ***********         ****************"
echo " main.sh  -exec--> * Gateway * -SSH--> *   Honeypot   *"
echo "                   ***********         ****************"
echo ""
echo "Ten skrypt jest interfejsem umożliwiającym korzystanie ze wszystkich funkcjonalności stworzonego symulatora."
echo "Składa się z dwóch maszyn wirtualnych: hosta na którym działa Honeypot; oraz Gateway, pozwalający się do niego połączyć."
echo "Zadaniem Honeypota  [-l LOGIN TO HONEYPOT] jest oszukanie osoby włamującej się na system. Myśli ona że udało jej sie dostać do systemu, "
echo "bo teoretycznie ma dostęp do terminala, lecz tak naprawdę wszsytko co robi jest kontrolowane, każde działanie jest rejestrowane."
echo "Ponadto wiele ważnych komend jest albo poblokowana, albo zwracają fałszywe rezultaty."
echo "Ma to wprowadzać włamywacza z konsternację."
echo "Drugi host - Gateway, oprócz umożliwienia logowania, służy również jako serwer, "
echo "w którym skrypty perlowe generują statystyki z akcji podejmowanych przez włamywacza na Honeypodzie."
echo "Można wyświetlić wywołane komendy [-e EXECUTED COMMANDS ] i outputy [ -p PLAY LOGGED ACTIONS] wywołane na Honeypodzie, "
echo "uwzględniając przy tym odstępy czasu między wywołaniami - jakby wcisnąć play i oglądać co po kolei robił włamywacz."
echo ""
echo "    Jak korzystać z symulatora:"
echo "Aby uruchomić symulator, należy najpierw stworzyć kontenery na dockerze [-c CREATE CONTAINERS] - trzeba mieć zainstalowanego dockera"
echo "Logujemy się do Honeypota [-l LOGIN TO HONEYPOT], podajemy hasło 'user' i wcielamy się w rolę włamywacza. Można wywoływać dowolne komendy systemowe."
echo "Niektóre komendy będą zwracać dziwne komendy, ale o to właśnie chodzi. Jeśli tylko nie pojawi się wyjątek pythonowy, to znaczy że tak ma być."
echo "Dla przykładu jakakolwiek próba użycia komendy wget zwróci '404 Not Found'."
echo "Wychodzimy z Honeypota"
echo "Oglądamy: wywołane komendy [-e EXECUTED COMMANDS ]"
echo "Oglądamy zarejestrowane akcje: [ -p PLAY LOGGED ACTIONS]"
echo "Sprawdzamy z jakiego adresu i ile razy próbowano się zalogować [ -s SSH STATISTICS]"
echo "Po skończonym testowaniu symultora warto usunąć stworzone kontenery, sieci i volumeny [-r REMOVE CONTAINERS]."
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
	while getopts ":hepclrs" arg; do
	  case ${arg} in
	    e) # EXECUTED COMMANDS
	      docker exec -it gateway /root/Honeypot/main.pl --executed_commands --full_mode
	      exit 0
	      ;;
	    p) # PLAY LOGGED ACTIONS
	      docker exec -it gateway /root/Honeypot/main.pl --play_logged_actions --full_mode
	      exit 0
	      ;;
	    c) # CREATE CONTAINERS
	      $main_dir/bash_scripts/make_containers.sh -c
	      exit 0
	      ;;
	    l) # LOGIN TO HONEYPOT
	      docker exec -it honeypot service ssh restart
	      docker exec -it honeypot chmod 777 /volume
	      docker exec -it honeypot p0f -i eth0 -o /volume/p0f_scan.log -u user -d 
	      docker exec -it gateway ssh user@172.18.0.3
	      exit 0
	      ;;
	    r) # REMOVE CONTAINERS
	      $main_dir/bash_scripts/make_containers.sh -r
	      exit 0
	      ;;
	    s) # SSH STATISTICS
	      docker exec -it gateway /root/Honeypot/main.pl --ssh_statistics --full_mode
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
	required_packages=(git docker)
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

check_if_help (){
	[ $# -eq 0 ] && usage
	if [[ "$1" == *"-h"* || "$1" == *"--help"* ]]
	then
		show_help
		exit 10
	fi
}

check_if_help $1
check_required_packages
parse_args $*

exit 0
