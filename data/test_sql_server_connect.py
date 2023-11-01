# Importe a classe QueryExecutor do arquivo execute_query.py
from execute_query import QueryExecutor

# Importe a classe DatabaseConnection do arquivo database_connection.py
from database_connection import DatabaseConnection

# Crie uma instância de DatabaseConnection para estabelecer a conexão com o SQL Server
# Forneça os parâmetros db_type, server e database
# db = DatabaseConnection("SQLServer", "s-sebp19", "master")

# Crie uma instância de DatabaseConnection para estabelecer a conexão com o MySQL
db = DatabaseConnection("MySQL", "s-sebu121", "mysql")


# Crie uma instância do QueryExecutor e passe a conexão como argumento
query_executor = QueryExecutor(db.connection)

# Defina a consulta que você deseja executar
query = "select * from user;"

# Execute a consulta e obtenha o resultado e o status de sucesso
result, success = query_executor.execute_query(query)

# Verifique o status de sucesso e imprima o resultado, se for bem-sucedido
if success:
    print("Consulta executada com sucesso:")
    for row in result:
        print(row)
else:
    print("Falha na consulta")

# Feche a conexão quando não for mais necessária
db.close()
