# Importe a classe QueryExecutor do arquivo execute_query.py
from execute_query import QueryExecutor

# Importe a classe DatabaseConnection do arquivo database_connection.py
from database_connection import DatabaseConnection

import pandas as pd

import matplotlib.pyplot as plt

class QueryExecutor:
    def __init__(self, connection):
        self.connection = connection

    def execute_query(self, query):
        # Lógica para executar a consulta no SQL Server
        try:
            df = pd.read_sql(query, self.connection)
            return df, True
        except Exception as e:
            print(f"Erro na execução da consulta: {e}")
            return None, False


# Crie uma instância de DatabaseConnection para estabelecer a conexão com o SQL Server
# Forneça os parâmetros db_type, server e database
# db = DatabaseConnection("SQLServer", "s-sebp19", "master")

# Crie uma instância de DatabaseConnection para estabelecer a conexão com o MySQL
db = DatabaseConnection("SQLServer", "S-SEBP19", "Sharepoint")


# Crie uma instância do QueryExecutor e passe a conexão como argumento
query_executor = QueryExecutor(db.connection)

# Defina a consulta que você deseja executar
query = """
    SELECT [idSites], [Title], CONVERT(CHAR(10), [dhcriacao], 111) AS dhcriacao, 
           SUM(StorageUsageCurrent) OVER (PARTITION BY [Title] ORDER BY CONVERT(CHAR(10), [dhcriacao], 111)) AS CrescimentoTotal
    FROM VW_site_evolucao 
"""
# Execute a consulta e obtenha o resultado e o status de sucesso
result, success = query_executor.execute_query(query)


# Se a consulta foi bem-sucedida, continue com a análise e a plotagem do gráfico
if success:
    # Converta a lista de tuplas para um DataFrame
    df = pd.DataFrame(result, columns=['idSites', 'Title', 'dhcriacao', 'CrescimentoTotal'])

    # Remova duplicatas mantendo apenas a última entrada
    df = df.drop_duplicates(subset=['Title', 'dhcriacao'], keep='last')

    # Agrupe e calcule a soma cumulativa
    df['CrescimentoTotal'] = df.groupby(['Title', 'dhcriacao'])['CrescimentoTotal'].cumsum()

    # Pivote os dados para ter os sites como índice
    df_pivot = df.pivot(index='Title', columns='dhcriacao', values='CrescimentoTotal')

    # Plotar o gráfico de linha
    df_pivot.T.plot(kind='line', marker='o')
    plt.title('Histórico de Crescimento dos Sites')
    plt.xlabel('Data de Criação')
    plt.ylabel('Crescimento Total')
    plt.legend(title='Site', loc='upper left', bbox_to_anchor=(1, 1))
    plt.show()

# Feche a conexão ao final do processo
db.close_connection()