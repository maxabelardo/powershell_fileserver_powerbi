/**************************************************************************************************************
Autor: José Abelardo Vicente Filho
Data de criação: 31/01/2022
Data de alteração: 

Descrição:
	Script utilizado para extrair todos schemas e tabelas de uma base.

	Tabelas:
		- information_schema.TABLES: Tabela principal da consulta utilizada para obter os valores.

**************************************************************************************************************/


SELECT TABLE_SCHEMA  -- Nome do schema
 , TABLE_NAME        --  Nome da tabela
 , ROUND((DATA_LENGTH + INDEX_LENGTH) / 1024) AS 'reservedkb' -- Tamanho reservado
 , ROUND(DATA_LENGTH  / 1024 ) AS 'datakb'                    -- Tamanho da tabela
 , ROUND(INDEX_LENGTH  / 1024) AS 'Indiceskb'                 -- Tamanho do index
 , TABLE_ROWS AS 'sumline'                                    -- Total de linhas
FROM information_schema.TABLES 
WHERE TABLE_SCHEMA <> 'information_schema'
AND TABLE_SCHEMA <> 'mysql'
AND TABLE_SCHEMA <> 'performance_schema'
AND TABLE_SCHEMA <> 'sys'''