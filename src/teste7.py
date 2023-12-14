import os
from datetime import datetime
import dask
from dask import delayed
from dask.distributed import Client
from math import ceil

def obter_atributos_arquivo(caminho_completo, arquivos_acesso_negado):
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
    except PermissionError:
        arquivos_acesso_negado.append(caminho_completo)
        return None  # ou outra estratégia de tratamento de erro


@delayed
def processar_arquivos_pedaco(pedaco, arquivos_acesso_negado):
    tarefas = []
    for caminho_completo in pedaco:
        atributos = obter_atributos_arquivo(caminho_completo, arquivos_acesso_negado)

        if atributos is not None:
            # Calculando a idade do arquivo (em dias)
            now = datetime.now()
            atributos['Age'] = (now - atributos['CreationTime']).days

            # Faça algo com os atributos, como imprimir na tela
            print(atributos)
            print('\n')

    return tarefas

def dividir_diretorio_em_pedacos(diretorio, tamanho_pedaco):
    arquivos = []
    for pasta_atual, _, arquivos_na_pasta in os.walk(diretorio):
        for arquivo in arquivos_na_pasta:
            arquivos.append(os.path.join(pasta_atual, arquivo))

    num_pedacos = ceil(len(arquivos) / tamanho_pedaco)
    pedacos = [arquivos[i * tamanho_pedaco:(i + 1) * tamanho_pedaco] for i in range(num_pedacos)]
    return pedacos

if __name__ == '__main__':
    dh_inicio = datetime.now()

    diretorio_principal = r'J:\ARQUIVOS PUBLICOS\DF'
    tamanho_pedaco = 100  # ajuste conforme necessário
    arquivos_acesso_negado = []

    pedacos = dividir_diretorio_em_pedacos(diretorio_principal, tamanho_pedaco)

    # Configurar o cliente Dask para utilizar threads
    with Client(processes=False, threads_per_worker=4):
        # Criar um gráfico de tarefas Dask e executar em paralelo
        dask.compute([processar_arquivos_pedaco(pedaco, arquivos_acesso_negado) for pedaco in pedacos])

    dh_fim = datetime.now()

    dhdif = (dh_fim - dh_inicio).total_seconds() / 60.0

    print(f"A extração dos metadados durou: {dhdif} minutos")
    print(f"Arquivos com acesso negado: {arquivos_acesso_negado}")
