/**************************************************************************************************************
Autor: José Abelardo Vicente Filho
Data de criação: 30/01/2022
Data de alteração: 

Descrição:
	Script utilizado para extrair os dados da base de dados de servidores "PostgreSQL".
    Para extrair os dados será preciso utilzar variás tabelas.

	Tabelas:
		- pg_catalog.pg_database: Tabela principal com as informações gerais da base de dados.
        - pg_catalog.pg_roles: tabelas com os dados dos usuários


**************************************************************************************************************/


SELECT d.datname        -- Nome da base de dados
     , d.datdba         -- ID do Owner da base.
     , r.rolname        -- Proprietário do banco de dados, geralmente o usuário que o criou
     , d.encoding       -- Codificação de caracteres para este banco de dados ( pg_encoding_to_char()pode traduzir esse número para o nome da codificação)
     , d.dattablespace  -- O espaço de tabela padrão para o banco de dados. Dentro deste banco de dados, todas as tabelas para as quais pg_class . reltablespace é zero será armazenado neste tablespace; em particular, todos os catálogos de sistema não compartilhados estarão lá.
     , d.datcollate     -- LC_COLLATE para este banco de dados
     , d.datctype       -- LC_CTYPE para este banco de dados
     , d.datconnlimit   -- Define o número máximo de conexões simultâneas que podem ser feitas com este banco de dados. -1 significa sem limite.
     , d.datistemplate  -- Se true, esse banco de dados pode ser clonado por qualquer usuário com privilégios CREATEDB ; se false, somente os superusuários ou o proprietário do banco de dados poderão cloná-lo.
     , d.datallowconn   -- Se false, ninguém poderá se conectar a este banco de dados. Isso é usado para proteger o banco de dados template0 de ser alterado.
FROM pg_catalog.pg_database as d
INNER JOIN pg_catalog.pg_roles as r on r.oid = d.datdba
