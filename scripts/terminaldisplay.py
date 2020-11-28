
class TerminalDisplay:

    def __init__(self, prompt):
        self.prompt = prompt

    def get_command(self):
        received_command = input(self.prompt)
        return received_command

    def show_output(self, output):
        print(output)
