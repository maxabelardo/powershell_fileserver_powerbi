/**************************************************************************************************************
Autor: José Abelardo Vicente Filho
Data de criação: 30/01/2022
Data de alteração: 

Descrição:
	Script utilizado para extrair o tamanho atual da base de dados

	Tabelas:
		- information_schema.TABLES: Tabela principal, é feito um somatorios de todos os objetos da base para ter o valor total da base.

**************************************************************************************************************/

SELECT table_schema  -- Nome da base de dados
     , CAST( (SUM( data_length + index_length ) / 1024 /1024) AS DECIMAL(10,2) ) AS 'Size' -- tamanho da base de dados em Megabytes.
FROM information_schema.TABLES
GROUP BY table_schema;