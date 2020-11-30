#!/usr/bin/python3

from scripts.actionsRecorder import ActionsRecorder
from scripts.exceptions import CommandFailedError
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
                        help="Use full mode if you use script on target host, which should be protected. " 
                             "Without that, the script will be working correctly, but some system commands would not be blocked")
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
        except KeyboardInterrupt:
            sys.exit(-10)
