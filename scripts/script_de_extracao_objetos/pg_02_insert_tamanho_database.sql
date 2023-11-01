/**************************************************************************************************************
Autor: José Abelardo Vicente Filho
Data de criação: 31/01/2022
Data de alteração: 

Descrição:
	Script utilizado para extrair o tamanho atual da base de dados

	Tabelas:
		- pg_catalog.pg_database: Tabela principal com as informações gerais da base de dados.

Observação: para se obter o valor da base é preciso utilizar uma função "pg_size_pretty"

**************************************************************************************************************/

SELECT d.datname AS DBName
    , CASE 
       WHEN pg_catalog.has_database_privilege(d.datname, 'CONNECT') THEN pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname))
       ELSE 'No Access'
      END AS SIZE
FROM pg_catalog.pg_database d
ORDER BY
CASE WHEN pg_catalog.has_database_privilege(d.datname, 'CONNECT')
THEN pg_catalog.pg_database_size(d.datname)
ELSE NULL
END DESC;