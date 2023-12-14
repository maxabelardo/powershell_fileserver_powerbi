import os
from datetime import datetime
import pymongo

def obter_atributos_arquivo(caminho_completo):
    try:
        atributos = {
            'FullName': os.path.abspath(caminho_completo),
            'Diretorio': os.path.dirname(caminho_completo),
            'Name': os.path.basename(caminho_completo),
            'CreationTime': datetime.fromtimestamp(os.path.getctime(caminho_completo)),
            'LastAccessTime': datetime.fromtimestamp(os.path.getatime(caminho_completo)),
            'LastWriteTime': datetime.fromtimestamp(os.path.getmtime(caminho_completo)),
            'Length': os.path.getsize(caminho_completo)
        }

        if os.path.isdir(caminho_completo):
            atributos['Mode'] = 'Diretorio'
        else:
            atributos['Mode'] = 'Arquivo'

        return atributos
    except Exception as e:
        print(f"Erro ao processar arquivo {caminho_completo}: {e}")
        return None  # ou outra estratégia de tratamento de erro

def percorrer_diretorio_recursivamente(diretorio):
    try:
        for sub_item in os.listdir(diretorio):
            caminho_completo = os.path.join(diretorio, sub_item)
            atributos = obter_atributos_arquivo(caminho_completo)

            # Calculando a idade do arquivo (em dias)
            now = datetime.now()
            atributos['Age'] = (now - atributos['CreationTime']).days

            # Inserir os atributos no MongoDB
            inserir_no_mongodb(atributos)

            # Faça algo com os atributos, como imprimir na tela
            print(atributos)
            print('\n')

            # Se for um diretório, chama a função recursivamente
            if os.path.isdir(caminho_completo):
                percorrer_diretorio_recursivamente(caminho_completo)

    except FileNotFoundError:
        print(f'O diretório "{diretorio}" não foi encontrado.')
    except Exception as e:
        print(f'Ocorreu um erro: {e}')

def inserir_no_mongodb(documento):
    # Inserir o documento no MongoDB
    mycol.insert_one(documento)

if __name__ == '__main__':
    # Substitua 'C:\caminho\para\o\diretorio' pelo caminho do seu diretório principal
    dh_inicio = datetime.now()

    # Conectar ao servidor MongoDB
    myclient = pymongo.MongoClient("mongodb://mongoadmin:secret@10.0.19.140:27017/")
    # Selecionar o banco de dados e a coleção
    mydb = myclient["file_server"]
    mycol = mydb["files2"]

    diretorio_principal = r'J:\ARQUIVOS PUBLICOS'        
    percorrer_diretorio_recursivamente(diretorio_principal)

    dh_fim = datetime.now()

    dhdif = (dh_fim - dh_inicio).total_seconds() / 60.0

    print(f"A extração dos metadados dureou: {dhdif} minutos")
