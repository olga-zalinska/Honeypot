from stat import S_ENFMT
from subprocess import check_output, CalledProcessError, call
from scripts.exceptions import CommandFailedError
import os

BACKUPED_COMMANDS_DIR = 'backed_up_commands'
WGET_STORAGE_LOCATION = 'wget_downloads'
blacklist_commands = ['shutdown', 'init', 'kill', 'rm -rf', ':(){:|:&};:']


class Command:

    def __init__(self, command):
        self.command = command

    def execute(self):
        return check_output(self.command, shell=True, cwd=SystemCommandsHandler.cwd).decode()


class FakedCommand(Command):
    def execute(self):
        with open(os.path.join(BACKUPED_COMMANDS_DIR, self.command), 'r') as f:
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

    def __init__(self, command):
        self.command = command + ' -P ' + WGET_STORAGE_LOCATION

    def fake_file(self):
        downloaded_file = os.listdir(WGET_STORAGE_LOCATION)[0]
        print(downloaded_file)
        file_location = os.path.join(WGET_STORAGE_LOCATION, downloaded_file)
        if os.path.isfile(file_location):
            os.symlink(file_location, os.path.join(SystemCommandsHandler.cwd, downloaded_file))
        else:
            os.symlink(file_location, os.path.join(SystemCommandsHandler.cwd, downloaded_file),
                       target_is_directory=True)
        os.chmod(file_location, S_ENFMT)

    def execute(self):
        output = super().execute()
        self.fake_file()
        return output


class UnameCommand(Command):
    def execute(self):
        output = super(UnameCommand, self).execute()
        return output.replace("GNU/Linux", "").replace("4.15.0-96-generic #97-Ubuntu", "").replace("Linux", "System")


class CustomCommand(Command):
    pass


# todo CurlCommand, CatCommand

class SystemCommandsHandler:
    cwd = "/"
    commands = {
        'uname': UnameCommand,
        'wget': WgetCommand,
        'cd': CdCommand
    }

    def __deduce_command_type(self, provided_command):
        for command in [file for file in os.listdir(BACKUPED_COMMANDS_DIR) if not os.path.isfile(file)]:
            if command in provided_command:
                return FakedCommand(command)

        if 'uname' in provided_command: return UnameCommand(provided_command)
        if 'wget' in provided_command: return WgetCommand(provided_command)
        if 'cd' in provided_command: return CdCommand(provided_command)
        return CustomCommand(provided_command)

    def __init__(self, action_recorder, terminal_display):
        self.actionRecorder = action_recorder
        self.terminalDisplay = terminal_display

    def handle_command(self, command):
        try:
            command_instance = self.__deduce_command_type(command)
            out = command_instance.execute()
            self.terminalDisplay.show_output(out)
            self.actionRecorder.log_command(command=command, output=out)
        except CalledProcessError as e:
            self.actionRecorder.log_command(output='command failed')
            raise CommandFailedError()
