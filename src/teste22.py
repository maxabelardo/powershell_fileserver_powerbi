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
            'Length': os.path.getsize(caminho_completo),
            'Mode': os.stat(caminho_completo).st_mode
        }

        if os.path.isdir(caminho_completo):
            atributos['Tipo'] = 'Diretorio'
        else:
            atributos['Tipo'] = 'Arquivo'

        return atributos
    except Exception as e:
        print(f"Erro ao processar arquivo {caminho_completo}: {e}")
        return None  # ou outra estratégia de tratamento de erro


def percorrer_diretorio_recursivamente(diretorio):
    try:
        for pasta_atual, sub_itens, _ in os.walk(diretorio):
            for sub_item in sub_itens:
                caminho_completo = os.path.join(pasta_atual, sub_item)
                atributos = obter_atributos_arquivo(caminho_completo)

                # Calculando a idade do arquivo (em dias)
                now = datetime.now()
                atributos['Age'] = (now - atributos['CreationTime']).days

                # Inserir os atributos no MongoDB
                inserir_no_mongodb(atributos)

                # Faça algo com os atributos, como imprimir na tela
                print(atributos)
                print('\n')

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

    diretorio_principal = r'J:\ARQUIVOS PUBLICOS\DF'        
    percorrer_diretorio_recursivamente(diretorio_principal)

    dh_fim = datetime.now()

    dhdif = (dh_fim - dh_inicio).total_seconds() / 60.0

    print(f"A extração dos metadados dureou: {dhdif} minutos")
