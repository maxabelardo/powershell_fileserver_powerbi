/**************************************************************************************************************
Autor: José Abelardo Vicente Filho
Data de criação: 30/01/2022
Data de alteração: 

Descrição:
	Script utilizado para extrair os dados da base de dados de servidores "MySQL".
    Para extrair os dados será preciso utilzar variás tabelas.

	Tabelas:
		- information_schema.SCHEMATA: Tabela principal com as informações gerais da base de dados.


**************************************************************************************************************/

SELECT SCHEMA_NAME               -- Nome do schema
   , DEFAULT_CHARACTER_SET_NAME  -- O conjunto de caracteres padrão do esquema.
   , DEFAULT_COLLATION_NAME      -- O agrupamento padrão do esquema.
   , SQL_PATH                    -- Este valor é sempre NULL.
FROM information_schema.SCHEMATA