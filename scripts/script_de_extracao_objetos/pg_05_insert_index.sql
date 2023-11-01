/**************************************************************************************************************
Autor: José Abelardo Vicente Filho
Data de criação: 31/01/2022
Data de alteração: 

Descrição:
	Script utilizado para extrair todos schemas e tabelas de uma base.
    O script esta excluindo os schemas: pg_catalog e information_schema.

	Tabelas:
		- information_schema.pg_indexes: Tabela principal da consulta utilizada para obter os valores.


Observação: Este script só traz os valores das tabelas que a conexão está ativa, ou seja se a conexão foi feita para base "Postgres" o script só retornar 
os valores da base "Postgres".

**************************************************************************************************************/


SELECT schemaname  -- Nome do schema
     , tablename   -- Nome da tabelas.
     , indexname   -- Nome do index.
FROM pg_catalog.pg_indexes
WHERE schemaname <> 'pg_catalog'
  AND schemaname <> 'information_schema'