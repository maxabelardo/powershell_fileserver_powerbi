/**************************************************************************************************************
Autor: José Abelardo Vicente Filho
Data de criação: 31/01/2022
Data de alteração: 

Descrição:
	Script utilizado para extrair todos schemas e tabelas de uma base.
    O script esta excluindo os schemas: pg_catalog e information_schema.

	Tabelas:
		- information_schema.tables: Tabela principal da consulta utilizada para obter os valores.
        - pg_class: tabela que armazena os numero de linhas de uma tabela.

Observação: Este script só traz os valores das tabelas que a conexão está ativa, ou seja se a conexão foi feita para base "Postgres" o script só retornar 
os valores da base "Postgres".

**************************************************************************************************************/


select table_catalog
		, table_schema  -- Nome do Schema
		, table_name    -- Nome da Tabelas
		, pg_size_pretty(pg_relation_size('"'||table_schema||'"."'||table_name||'"')) as "table_size" -- Tamanho da tabela.
		, cl.reltuples as "table_row"   -- Total de ilnhas da tabela
from information_schema.tables AS TB
inner join pg_class as cl on relname = TB.table_name
where table_schema <> 'pg_catalog'
	and table_schema <> 'information_schema'
	and table_type = 'BASE TABLE'