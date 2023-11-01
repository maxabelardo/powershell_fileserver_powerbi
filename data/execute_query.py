class QueryExecutor:
    def __init__(self, connection):
        self.connection = connection

    def execute_query(self, query):
        try:
            cursor = self.connection.cursor()
            cursor.execute(query)
            result = cursor.fetchall()
            cursor.close()
            return result, 1  # 1 for "executado com sucesso"
        except Exception as e:
            print(f"Error: {e}")
            return None, 0  # 0 for "executado com falha"
