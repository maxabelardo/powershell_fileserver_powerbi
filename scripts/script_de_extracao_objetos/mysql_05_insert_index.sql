/**************************************************************************************************************
Autor: José Abelardo Vicente Filho
Data de criação: 31/01/2022
Data de alteração: 

Descrição:
	Script utilizado para extrair todos schemas e tabelas de uma base.

	Tabelas:
		- INFORMATION_SCHEMA.STATISTICS : Tabela principal da consulta utilizada para obter os valores.


**************************************************************************************************************/


 SELECT TABLE_SCHEMA  -- Nome do schema      
	  , TABLE_NAME    -- Nome da tabela
      , INDEX_NAME    -- Nome do index
	  , NON_UNIQUE	  -- Se o index é UNique ou NÃO.
FROM INFORMATION_SCHEMA.STATISTICS 