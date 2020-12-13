#!/usr/bin/python3
from scripts.SudoState import SudoState
from scripts.actionsRecorder import ActionsRecorder
from scripts.exceptions import CommandFailedError, ExitException
from scripts.systemCommandsHandler import SystemCommandsHandler
from scripts.terminaldisplay import TerminalDisplay
import os
import sys
from argparse import ArgumentParser, RawTextHelpFormatter

DIRNAME = os.path.dirname(os.path.realpath(__file__))


def parse_arguments():
    parser = ArgumentParser(formatter_class=RawTextHelpFormatter)
    parser.add_argument("-f", "--full_mode", action="store_true",
                        help="""
Skrypt jest Honeypotem, który udaje terminal i symuluje wywołania komend systemowych                        
Tryb full_mode sluży do uruchomienia skryptu na dockerze. 
W przeciwnym wypadku, jeśli chce sie go uruchomić na innym systemie, to nie należy używać tej opcji.
                             
                             """)
    parser.add_argument("-c", "--help_commands", action="store_true", help="By wyświetlić listę oszukanych komend wywołaj -c lub --help_commands")
    args = parser.parse_args()
    if args.help_commands:
        print("""
Komendy oszukiwane przez honeypota:
 - wget - plik zostanie pobrany, ale do innego katalogu niż wskazany - do wget_downloads. 
 Użytkownikowi natomiast zostanie wyświetlona fałszywa informacja o nieznalezieniu pliku pod danym linkiem
 - apt-get - nie można znaleźć wymienionej paczki
 - curl - nieznalezienie komendy
 - df - fałszywy output
 - free - fałszywy output
 - ifconfig - fałszywy output
 - init - brak outputu
 - killall - brak outputu
 - mc - nie znaleziono
 - pico - nie znaleziono
 - nano - nie znaleziono
 - vi/vim - nie znaleziono
 - mount - fałszywy output
 - reboot - brak outputu
 - shutdown - brak outputu
 - top - fałszywa informacja o braku wolnego miejsca na dysku
 - ping - nie znaleziono
 - bash - pusty output, żeby myślano że komendę udało się wywołać
 - uname - w przypadku korzystania z dockera zostanie zwrócona komenda uname bez nazwy i wersji systemu
 - exit, logout - wylogowanie z systemu
 Inne obsługiwane komendy:
 - cd - skrypt zapamiętuje każde przejście do innego katalogu i wtedy komendy wywołuje z niego
 - sudo su - obsługuje wprowadzanie hasła. Jednak żadne z nich nie zadziała
 - 'su -' - Wprowadzenie jakiegokolwiek hasła zwróci błąd
 
 By dodać obsługę kolejnej komendy należy dodać plik tekstowy do 'backed_up_commands'. Jego treść będzie traktowana jako output.
                             
                             """)
        sys.exit(0)

    return args


if __name__ == '__main__':
    args = parse_arguments()
    sudoState = SudoState()
    actionRecorder = ActionsRecorder(args.full_mode, DIRNAME)
    terminalDisplay = TerminalDisplay(sudoState)
    systemCommandsHandler = SystemCommandsHandler(actionRecorder, terminalDisplay, sudoState, DIRNAME)

    while True:
        try:
            received_command = terminalDisplay.get_command()
            systemCommandsHandler.handle_command(received_command)
        except CommandFailedError:
            continue
        except KeyboardInterrupt:
            print("")
            continue
        except ExitException:
            print("")
            sys.exit(2)
        except EOFError:
            actionRecorder.log_command(command="SessionEnded", output="********************* Session ended *********************\n")
            sys.exit(3)
