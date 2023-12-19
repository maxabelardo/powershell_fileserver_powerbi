import pymongo
import pyodbc

def list_files():
    # Conectar ao servidor MongoDB
    myclient = pymongo.MongoClient("mongodb://mongoadmin:secret@10.0.19.140:27017/")

    # Selecionar o banco de dados e a coleção
    mydb = myclient["file_server"]

    # Seleciona a collection
    mycol = mydb["files_process"]

    # Especifica as colunas desejadas
    projection = {"idNivel": 1, "idPai": 1, "diretorio": 1, "fullname": 1, "_id": 0}

    # Conectar ao servidor SQL Server
    conn = pyodbc.connect(
        'DRIVER={SQL Server};'
        'SERVER=your_server;'
        'DATABASE=your_database;'
        'UID=your_username;'
        'PWD=your_password;'
    )

    cursor = conn.cursor()

    # Itera sobre os documentos e insere os dados no SQL Server
    for x in mycol.find({}, projection):
        # Substitua 'your_table' pelo nome da sua tabela no SQL Server
        query = f"INSERT INTO your_table (idNivel, idPai, diretorio, fullname) VALUES (?, ?, ?, ?)"
        values = (x['idNivel'], x['idPai'], x['diretorio'], x['fullname'])

        cursor.execute(query, values)
        conn.commit()

    # Fechar as conexões
    cursor.close()
    conn.close()

if __name__ == '__main__':
    list_files()
