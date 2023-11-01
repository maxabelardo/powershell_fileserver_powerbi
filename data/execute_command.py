class CommandExecutor:
    def __init(self, connection):
        self.connection = connection

    def execute_command(self, command):
        try:
            cursor = self.connection.cursor()
            cursor.execute(command)
            self.connection.commit()
            cursor.close()
            return 1  # 1 for "executado com sucesso"
        except Exception as e:
            print(f"Error: {e}")
            return 0  # 0 for "executado com falha"
