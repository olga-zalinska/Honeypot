
class TerminalDisplay:

    def __init__(self, sudo_state):
        self.prompt = sudo_state.prompt

    def get_command(self):
        received_command = input(f"{self.prompt}> ")
        return received_command

    def show_output(self, output):
        print(output)
