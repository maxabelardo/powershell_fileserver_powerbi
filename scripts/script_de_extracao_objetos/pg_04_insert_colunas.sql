/**************************************************************************************************************
Autor: José Abelardo Vicente Filho
Data de criação: 31/01/2022
Data de alteração: 

Descrição:
	Script utilizado para extrair todos schemas e tabelas de uma base.

	Tabelas:
		- information_schema.columns: Tabela principal da consulta utilizada para obter os valores.


Observação: Este script só traz os valores das tabelas que a conexão está ativa, ou seja se a conexão foi feita para base "Postgres" o script só retornar 
os valores da base "Postgres".

**************************************************************************************************************/


SELECT table_catalog    -- Nome da Base
	, table_schema      -- Nome do schema
	, table_name        -- Nome da tabela
	, column_name       -- Nome da Coluna
	, ordinal_position  -- Possição da coluna dentro da tabela.
	, data_type         -- Tipo da coluna, o tivpo do valor que é armazenado na coluna.
FROM information_schema.columns