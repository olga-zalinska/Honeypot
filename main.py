#!/usr/bin/python3

from scripts.actionsRecorder import ActionsRecorder
from scripts.exceptions import CommandFailedError
from scripts.systemCommandsHandler import SystemCommandsHandler
from scripts.terminaldisplay import TerminalDisplay
import os
import sys

DIRNAME = os.path.dirname(__file__)
PROMPTS = ['root> ', 'user> ']
LOGS_DIRECTORY = '/volume'

if __name__ == '__main__':
    actionRecorder = ActionsRecorder(LOGS_DIRECTORY)
    terminalDisplay = TerminalDisplay(PROMPTS[1])
    systemCommandsHandler = SystemCommandsHandler(actionRecorder, terminalDisplay)

    while True:
        try:
            received_command = terminalDisplay.get_command()
            systemCommandsHandler.handle_command(received_command)
        except CommandFailedError:
            continue
        except KeyboardInterrupt:
            sys.exit(-10)
