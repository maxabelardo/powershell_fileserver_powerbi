import os
from datetime import datetime

diretorio = r'J:\ARQUIVOS PUBLICOS'

try:
    for nome_arquivo in os.listdir(diretorio):
        caminho_completo = os.path.join(diretorio, nome_arquivo)

        # Obtendo os atributos do arquivo
        atributos = {
            'FullName': os.path.abspath(caminho_completo),
            'Diretorio': os.path.dirname(caminho_completo),
            'Name': nome_arquivo,
            'CreationTime': datetime.fromtimestamp(os.path.getctime(caminho_completo)),
            'LastAccessTime': datetime.fromtimestamp(os.path.getatime(caminho_completo)),
            'LastWriteTime': datetime.fromtimestamp(os.path.getmtime(caminho_completo)),
            'Length': os.path.getsize(caminho_completo),
            'Mode': os.stat(caminho_completo).st_mode
        }

        # Calculando a idade do arquivo (em dias)
        now = datetime.now()
        atributos['Age'] = (now - atributos['CreationTime']).days

        # Faça algo com os atributos, como imprimir na tela
        print(atributos)
        print('\n')
except FileNotFoundError:
    print(f' O diretório "{diretorio}" não foi encontrado.')
except Exception as e:
    print(f'Ocorreu um erro: {e}')
