## Histórico de execução do projeto.

### Configuração do VENV.
Foi criado o ambiente virtual VENV npa pasta .\venv e instalado os componentes de banco de dados.


#### <p> SQLAlchemy e os drivers para Oracle, SQL Server, PostgreSQL e MySQL:</p>
  
Instale o SQLAlchemy:
````
pip install sqlalchemy
````

Para Oracle, você pode usar o driver cx_Oracle:
````
pip install cx_Oracle
````

Para SQL Server, você pode usar o driver pyodbc:
````
pip install pyodbc
````

Para PostgreSQL, você pode usar o driver psycopg2:
````
pip install psycopg2
````


Para MySQL, você pode usar o driver mysql-connector-python:
````
pip install mysql-connector-python
````

#### Criação do REQUIREMENTS.TXT
````
pip freeze > requirements.txt
````


### Corrigir erro de proxy quando for instalar os componentes.

$env:HTTP_PROXY = "http://username:password@proxyserver:port"
$env:HTTPS_PROXY = "http://username:password@proxyserver:port"

pip install --proxy http://username:password@proxyserver:port package_name



import pymongo

myclient = pymongo.MongoClient("mongodb://localhost:27017/")
mydb = myclient["mydatabase"]
mycol = mydb["customers"]

mydict = { "name": "John", "address": "Highway 37" }

x = mycol.insert_one(mydict)