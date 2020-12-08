#!/usr/bin/python3

from scripts.actionsRecorder import ActionsRecorder
from scripts.exceptions import CommandFailedError, ExitException
from scripts.systemCommandsHandler import SystemCommandsHandler
from scripts.terminaldisplay import TerminalDisplay
import os
import sys
import argparse

DIRNAME = os.path.dirname(os.path.realpath(__file__))
PROMPTS = ['root> ', 'user> ']


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("-f", "--full_mode", action="store_true",
                        help="Tryb full_mode sluży do uruchomienia skryptu na dockerze. "
                             "W przeciwnym wypadku, jeśli chce sie go uruchomić na innym systemie, to należy uruchamiać skrypt bez tej opcji." 
                             "Komendy oszukiwane przez honeypota:"
                             "- wget - plik zostanie pobrany, ale do innego katalogu niż wskazany - do wget_downloads. "
                             "Użytkownikowi natomiast zostanie wyświetlona fałszywa informacja o nieznalezieniu pliku pod danym linkiem"
                             "- apt-get - nie można znaleźć wymienionej paczki"
                             "- curl - nieznalezienie komendy"
                             "- df - fałszywy output"
                             "- free - fałszywy output"
                             "- ifconfig - fałszywy output"
                             "- init - brak outputu"
                             "- killall - brak outputu"
                             "- mc - nie znaleziono"
                             "- pico - nie znaleziono"
                             "- nano - nie znaleziono"
                             "- vi/vim - nie znaleziono"
                             "- mount - fałszywy output"
                             "- reboot - brak outputu"
                             "- shutdown - brak outputu"
                             "- top - fałszywa informacja o braku wolnego miejsca na dysku"
                             "- bash - pusty output, żeby myślano że komendę udało się wywołać"
                             "- uname - w przypadku korzystania z dockera zostanie zwrócona komenda uname bez nazwy i wersji systemu"
                             "- exit - wylogowanie z systemu"
                             "Inne obsługiwane komendy:"
                             "- cd - skrypt zapamiętuje każde przejście do innego katalogu i wtedy komendy wywołuje z niego"
                             ""
                             "")
    return parser.parse_args()


if __name__ == '__main__':
    args = parse_arguments()
    actionRecorder = ActionsRecorder(args.full_mode, DIRNAME)
    terminalDisplay = TerminalDisplay(PROMPTS[1])
    systemCommandsHandler = SystemCommandsHandler(actionRecorder, terminalDisplay, DIRNAME)

    while True:
        try:
            received_command = terminalDisplay.get_command()
            systemCommandsHandler.handle_command(received_command)
        except CommandFailedError:
            continue
        except ExitException:
            sys.exit(-20)
        except KeyboardInterrupt:
            sys.exit(-10)
