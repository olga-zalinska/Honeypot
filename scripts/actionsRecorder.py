import logging
import os

FULL_MODE_LOGS_LOCATION = '/volume'
DEFAULT_LOGS_LOCATION = 'logs'


class CommandsFormatter(logging.Formatter):
    def format(self, record):
        record.output = record.args.get("output")
        return super().format(record)


class ActionsRecorder:

    def __init__(self, is_full_mode, dirname):
        self.is_full_mode = is_full_mode
        self.dirname = dirname
        self.logs_directory = FULL_MODE_LOGS_LOCATION if self.is_full_mode else os.path.join(dirname, DEFAULT_LOGS_LOCATION)
        self.__setLogger()

    def __setLogger(self):
        logger = logging.getLogger('Intruder')
        logger.setLevel(logging.DEBUG)
        logger.propagate = False
        log_format = '%(asctime)s %(filename)s: %(message)s'
        logging.basicConfig(format=log_format,
                            datefmt='%Y-%m-%d %H:%M:%S')
        formatter = logging.Formatter('%(asctime)s | %(name)s  Command: %(message)s')
        command_with_output_formatter \
            = CommandsFormatter('%(asctime)s | %(name)s  root> %(message)s \n output_start \n %(output)s \n output_end')

        commands_log_handler = logging.FileHandler(os.path.join(self.logs_directory, 'commands.log'))
        commands_log_handler.setLevel(logging.DEBUG)
        commands_with_outputs_log_handler = logging.FileHandler(
            os.path.join(self.logs_directory, 'commands_with_outputs.log'))
        commands_with_outputs_log_handler.setLevel(logging.DEBUG)
        logger.addHandler(commands_log_handler)
        logger.addHandler(commands_with_outputs_log_handler)

        commands_with_outputs_log_handler.setFormatter(command_with_output_formatter)
        commands_log_handler.setFormatter(formatter)
        self.logger = logger

    def log_command(self, command='', output=''):
        self.logger.debug(command, {'output': output})
