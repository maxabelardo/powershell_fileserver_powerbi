/**************************************************************************************************************
Autor: José Abelardo Vicente Filho
Data de criação: 31/01/2022
Data de alteração: 

Descrição:
	Script utilizado para extrair todos schemas e tabelas de uma base.

	Tabelas:
		- information_schema.columns: Tabela principal da consulta utilizada para obter os valores.

**************************************************************************************************************/

SELECT C.table_schema
     , C.table_name
     , C.column_name
	 , C.ordinal_position
	 , C.data_type 
FROM INFORMATION_SCHEMA.COLUMNS AS C