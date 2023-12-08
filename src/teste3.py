import os
from datetime import datetime
import dask
from dask import delayed
from dask.distributed import Client

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

@delayed
def processar_arquivo(caminho_completo):
    atributos = obter_atributos_arquivo(caminho_completo)

    # Calculando a idade do arquivo (em dias)
    now = datetime.now()
    atributos['Age'] = (now - atributos['CreationTime']).days

    # Faça algo com os atributos, como imprimir na tela
    print(atributos)
    print('\n')

def percorrer_diretorio_recursivamente(diretorio):
    try:
        tarefas = []
        for pasta_atual, sub_pastas, arquivos in os.walk(diretorio):
            for nome_arquivo in arquivos:
                caminho_completo = os.path.join(pasta_atual, nome_arquivo)
                tarefa = processar_arquivo(caminho_completo)
                tarefas.append(tarefa)

        return tarefas
    except FileNotFoundError:
        print(f'O diretório "{diretorio}" não foi encontrado.')
    except Exception as e:
        print(f'Ocorreu um erro: {e}')

if __name__ == '__main__':
    dh_inicio = datetime.now()

    # Lista de diretórios principais
    diretorios_principais = [
        r'J:\ARQUIVOS PUBLICOS\DS\DS',
        r'J:\ARQUIVOS PUBLICOS\DS\DSAD',
        r'J:\ARQUIVOS PUBLICOS\DS\DSCN',
        r'J:\ARQUIVOS PUBLICOS\DS\DSSA',
        r'J:\ARQUIVOS PUBLICOS\DS\DSTI',
        r'J:\ARQUIVOS PUBLICOS\CA',
        r'J:\ARQUIVOS PUBLICOS\DF',
        r'J:\ARQUIVOS PUBLICOS\DG',
        r'J:\ARQUIVOS PUBLICOS\DN',
    ]

    # Configurar o cliente Dask para utilizar threads
    with Client(processes=False, threads_per_worker=4):
        # Criar um gráfico de tarefas Dask e executar em paralelo
        dask.compute([percorrer_diretorio_recursivamente(diretorio) for diretorio in diretorios_principais])

    dh_fim = datetime.now()

    dhdif = (dh_fim - dh_inicio).total_seconds() / 60.0

    print(f"A extração dos metadados durou: {dhdif} minutos")
