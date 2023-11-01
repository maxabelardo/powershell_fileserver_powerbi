/**************************************************************************************************************
Autor: José Abelardo Vicente Filho
Data de criação: 30/01/2022
Data de alteração: 

Descrição:
	Script utilizado para extrair os dados da base de dados de servidores "SQL Server".
    Para extrair os dados será preciso utilzar variás tabelas.

	Tabelas:
		- [master].[sys].[databases]: Tabela principal com as informações gerais da base de dados.
        - [master].[sys].syslogins: Tabela dos usuários do servidor.

	Permissão mínima para execução do script:
		- [master].[sys].[databases]: VIEW ANY DATABASE
        - [master].[sys].[syslogins]: VIEW ANY DATABASE


Refência:
https://docs.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-databases-transact-sql?view=sql-server-ver16
https://docs.microsoft.com/en-us/sql/relational-databases/system-compatibility-views/sys-syslogins-transact-sql?view=sql-server-ver16
**************************************************************************************************************/

select DB.[name]                                     -- Nome da database
		,L.[name] AS 'owner'                         -- Nome do owner 
		,[database_id] AS 'dbid'                     -- O id da base   
		,[create_date]                               -- Data de criação da tabela
		,[state_desc]                                -- Estatus da database
		,[user_access_desc] AS 'RestrictAccess'      -- Configuração de acesso
		,[recovery_model_desc] AS 'recovery_model'   -- Mode de configuração do log
		,[collation_name] AS 'collation'             -- Coleção de caracteres
		,[compatibility_level]                       -- Modo de compatibilhade da versão da database
from [master].[sys].[databases] AS DB
left join [master].[sys].syslogins  AS L ON L.sid = DB.owner_sid