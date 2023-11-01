/**************************************************************************************************************
Autor: José Abelardo Vicente Filho
Data de criação: 30/01/2022
Data de alteração: 

Descrição:
	Script utilizado para extrair o tamanho atual da base de dados

	Tabelas:
		- sys.master_files: Tabela principal, é feito um somatorios de todos os objetos da base para ter o valor total da base.

**************************************************************************************************************/


SELECT 
      database_name = DB_NAME(database_id)  -- Nome da database
    , log_size_mb = CAST(SUM(CASE WHEN type_desc = 'LOG' THEN size END) * 8. / 1024 AS DECIMAL(10,2))  -- Tamanho dos arquivos de log
    , row_size_mb = CAST(SUM(CASE WHEN type_desc = 'ROWS' THEN size END) * 8. / 1024 AS DECIMAL(10,2)) -- Tamanho dos arquivos de dados.
    , total_size_mb = CAST(SUM(size) * 8. / 1024 AS DECIMAL(10,2))  -- Tamanho total
FROM sys.master_files WITH(NOWAIT)
GROUP BY database_id
