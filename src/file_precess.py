from pymongo import MongoClient
from datetime import datetime

def carregar_files():
    # Conectar ao servidor MongoDB
    client = MongoClient("mongodb://mongoadmin:secret@10.0.19.140:27017/")  # Atualize com os detalhes do seu servidor
    db = client["file_server"]
    
    # Criar uma coleção para armazenar os resultados processados
    files_process_collection = db['files_process']
    
    # Consultar a coleção "arquivos" para obter diretorios distintos
    diretorios = db['files2'].distinct('Diretorio', {'Mode': 'Diretorio'})
    
    # Iterar sobre os diretorios
    for diretorio in diretorios:
        print(diretorio)
        converter_arquivos(diretorio, files_process_collection)

def converter_arquivos(diretorio, files_process_collection):
    # Variáveis
    total_letra = len(diretorio)
    dir_atual = ''
    id_nivel = 1
    id_pai = None

    # Loop enquanto o total de letras não for zero
    while total_letra > 0:
        # Encontrar a posição da barra invertida
        divisa = diretorio.find('\\')

        # Extrair parte do diretório até a barra invertida
        if total_letra > 1:
            name = diretorio[:divisa]
        else:
            name = diretorio
            total_letra = 0

        dir_atual += name

        # Inserir dados na coleção "files_process"
        files_process_collection.insert_one({
            'idNivel': id_nivel,
            'idPai': id_pai,
            'diretorio': dir_atual,
            'Dname': name
        })

        # Remover diretório encontrado
        diretorio = diretorio[divisa + 1:]

        # Nível anterior
        id_pai = id_nivel

        # Determinar o nível do diretório
        id_nivel += 1

        # Remover o valor da barra invertida do contador
        if '\\' in diretorio and total_letra > 1:
            total_letra -= divisa
        elif '\\' not in diretorio and total_letra > 1:
            total_letra = 1
        else:
            total_letra = 0

def main():



    # Chamar a função para carregar e converter os arquivos
    carregar_files()

if __name__ == '__main__':
    dh_inicio = datetime.now()

    main()

    dh_fim = datetime.now()

    dhdif = (dh_fim - dh_inicio).total_seconds() / 60.0

    print(f"A extração dos metadados dureou: {dhdif} minutos")