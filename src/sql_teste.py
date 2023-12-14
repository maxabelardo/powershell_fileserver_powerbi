import pymongo

def list_files():
    # Conectar ao servidor MongoDB
    myclient = pymongo.MongoClient("mongodb://mongoadmin:secret@10.0.19.140:27017/")

    # Selecionar o banco de dados e a coleção
    mydb = myclient["file_server"]

    # Seleciona a collection
    mycol = mydb["files_process"]

    # Especifica as colunas desejadas
    projection = {"idNivel": 1, "idPai": 1, "diretorio": 1, "fullname": 1, "_id": 0}

    # Itera sobre os documentos e imprime as colunas desejadas
    for x in mycol.find({}, projection):
        print(x)



if __name__ == '__main__':

    list_files()


