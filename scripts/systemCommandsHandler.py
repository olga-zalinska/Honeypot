from subprocess import check_output, CalledProcessError, call, DEVNULL
from time import sleep

from scripts.exceptions import CommandFailedError, ExitException
import os
from pathlib import Path

blacklist_commands = ['shutdown', 'init', 'kill', 'rm -rf', ':(){:|:&};:']


class Command:

    def __init__(self, command):
        self.command = command

    def execute(self):
        return check_output(self.command, shell=True, cwd=SystemCommandsHandler.cwd).decode()


class FakedCommand(Command):

    def __init__(self, command, backuped_commands_dir):
        super().__init__(command)
        self.backuped_commands_dir = backuped_commands_dir

    def execute(self):
        with open(os.path.join(self.backuped_commands_dir, self.command), 'r') as f:
            return f.read()


class CdCommand(Command):  # todo chdir
    def execute(self):
        if '..' in self.command:
            SystemCommandsHandler.cwd = '/' + '/'.join(SystemCommandsHandler.cwd.split('/')[:-1])
        else:
            cd_destination = self.command.split(' ')[1]
            SystemCommandsHandler.cwd = cd_destination
        return ''


class BlacklistCommand(Command):
    def execute(self):
        ip_address = ''  # todo get ip from i0f
        call(f"iptables -A INPUT -s ${ip_address} -j DROP", shell=True)
        exit(100)


class WgetCommand(Command):
    faked_chmod_files = []

    def __init__(self, command, wget_storage_location):
        Path(wget_storage_location).mkdir(exist_ok=True)
        self.wget_storage_location = wget_storage_location
        self.command = command + ' -P ' + wget_storage_location

    def execute(self):
        try:
            call(self.command, shell=True, stdout=DEVNULL, stderr=DEVNULL)
        except Exception:
            pass
        download_address = self.command.replace('wget ', '')
        faked_output = f'''
--2020-11-30 20:54:01--  ${download_address}
Resolving {download_address}... failed: 443... connected.
HTTP request sent, awaiting response... 404 Not Found
2020-11-30 20:58:38 ERROR 404: Not Found.
        '''# todo date
        return faked_output


class UnameCommand(Command):
    def execute(self):
        output = super(UnameCommand, self).execute()
        return output.replace("GNU/Linux", "").replace("4.15.0-96-generic #97-Ubuntu", "").replace("Linux", "System")


class ExitCommand(Command):
    def execute(self):
        raise ExitException()


class SudoCommand(Command):

    def __init__(self, sudo_state, action_recorder):
        self.sudo_state = sudo_state
        self.actionRecorder = action_recorder

    def execute(self):
        i = 0
        for _ in range(3):
            possible_password = input(f"[sudo] password for {self.sudo_state.prompt}:")
            self.actionRecorder.log_command(command='sudo su', output=f'Provided password: {possible_password}')
            sleep(3)
            i += 1
        return f"sudo: {i} incorrect password attempts"


class SuCommand(Command):

    def __init__(self, command, action_recorder):
        self.command = command
        self.actionRecorder = action_recorder

    def execute(self):
        possible_password = input("Password: ")
        self.actionRecorder.log_command(command=self.command, output=f'Provided password: {possible_password}')
        return "su: Authentication failure"

class CustomCommand(Command):
    pass


class SystemCommandsHandler:
    cwd = "/"
    commands = {
        'uname': UnameCommand,
        'wget': WgetCommand,
        'cd': CdCommand
    }


    def __deduce_command_type(self, provided_command):
        for command in [file for file in os.listdir(self.backuped_commands_dir) if not os.path.isfile(file)]:
            if command in provided_command:
                return FakedCommand(command, self.backuped_commands_dir)

        if 'uname' in provided_command: return UnameCommand(provided_command)
        if 'wget' in provided_command: return WgetCommand(provided_command, self.wget_storage_location)
        if 'cd' in provided_command: return CdCommand(provided_command)
        if 'exit' in provided_command: return ExitCommand(provided_command)
        if 'sudo su' in provided_command: return SudoCommand(self.sudo_state, self.actionRecorder)
        if 'su -' in provided_command: return SuCommand(provided_command, self.actionRecorder)
        return CustomCommand(provided_command)

    def __init__(self, action_recorder, terminal_display, sudo_state, dirname):
        self.dirname = dirname
        self.actionRecorder = action_recorder
        self.terminalDisplay = terminal_display
        self.sudo_state = sudo_state
        self.backuped_commands_dir = os.path.join(self.dirname, 'backed_up_commands')
        self.wget_storage_location = os.path.join(self.dirname, 'wget_downloads')

    def handle_command(self, command):
        try:
            command_instance = self.__deduce_command_type(command)
            out = command_instance.execute()
            self.terminalDisplay.show_output(out)
            self.actionRecorder.log_command(command=command, output=out)
        except CalledProcessError as e:
            self.actionRecorder.log_command(output='command failed')
            raise CommandFailedError()
