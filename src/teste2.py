
import os
from datetime import datetime

def obter_atributos_arquivo(caminho_completo):
    return {
        'FullName': os.path.abspath(caminho_completo),
        'Diretorio': os.path.dirname(caminho_completo),
        'Name': os.path.basename(caminho_completo),
        'CreationTime': datetime.fromtimestamp(os.path.getctime(caminho_completo)),
        'LastAccessTime': datetime.fromtimestamp(os.path.getatime(caminho_completo)),
        'LastWriteTime': datetime.fromtimestamp(os.path.getmtime(caminho_completo)),
        'Length': os.path.getsize(caminho_completo),
        'Mode': os.stat(caminho_completo).st_mode
    }

def percorrer_diretorio_recursivamente(diretorio):
    try:
        for pasta_atual, sub_pastas, arquivos in os.walk(diretorio):
            for nome_arquivo in arquivos:
                caminho_completo = os.path.join(pasta_atual, nome_arquivo)
                atributos = obter_atributos_arquivo(caminho_completo)

                # Calculando a idade do arquivo (em dias)
                now = datetime.now()
                atributos['Age'] = (now - atributos['CreationTime']).days

                # Faça algo com os atributos, como imprimir na tela
                print(atributos)
                print('\n')

    except FileNotFoundError:
        print(f'O diretório "{diretorio}" não foi encontrado.')
    except Exception as e:
        print(f'Ocorreu um erro: {e}')

# Substitua 'C:\caminho\para\o\diretorio' pelo caminho do seu diretório principal
dh_inicio = datetime.now()

diretorio_principal = r'J:\ARQUIVOS PUBLICOS'
percorrer_diretorio_recursivamente(diretorio_principal)

dh_fim = datetime.now()

dhdif = (dh_fim - dh_inicio).total_seconds() / 60.0

print(f"A extração dos metadados dureou: {dhdif} minutos" )




