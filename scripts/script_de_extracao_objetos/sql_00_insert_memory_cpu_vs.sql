

select total_physical_memory_kb / 1024   AS 'TotalMemoriaServidor'
	 , (SELECT c.value
         FROM [LNK_SQL_S-SEBN95].[master].sys.configurations c WHERE c.[name] = 'max server memory (MB)') AS 'MaxMemoriaInstancia'
     , (SELECT physical_memory_in_use_kb / 1024 FROM [LNK_SQL_S-SEBN95].[master].sys.dm_os_process_memory) AS 'TotalMemoriaUsadaInstancia'
     , (SELECT available_physical_memory_kb/1024 FROM [LNK_SQL_S-SEBN95].[master].sys.dm_os_sys_memory) AS 'Memória Disponível (MB)'
	 , (SELECT system_memory_state_desc FROM [LNK_SQL_S-SEBN95].[master].sys.dm_os_sys_memory) AS 'Estado da Memória do Sistema'
from [LNK_SQL_S-SEBN95].[master].sys.dm_os_sys_memory  OPTION (RECOMPILE);

SELECT cpu_count AS 'TotalCPULogicos', 
       hyperthread_ratio AS 'CPULogicosPPCU',
       cpu_count/hyperthread_ratio AS 'CPUFisicos', 	   
       sqlserver_start_time 
FROM [LNK_SQL_S-SEBN95].[master].sys.dm_os_sys_info OPTION (RECOMPILE);


SELECT *
FROM OPENQUERY([LNK_SQL_S-SEBN95], 'SELECT  
  SERVERPROPERTY(''MachineName'') AS ComputerName,
  SERVERPROPERTY(''ServerName'') AS InstanceName,  
  SERVERPROPERTY(''Edition'') AS Edition,
  SERVERPROPERTY(''ProductVersion'') AS ProductVersion,  
  SERVERPROPERTY(''ProductLevel'') AS ProductLevel;  ')


select LEFT(REPLACE(@@VERSION,LEFT(@@VERSION,(CHARINDEX('Windows',@@VERSION)-1)),''),(CHARINDEX('Build',REPLACE(@@VERSION,LEFT(@@VERSION,(CHARINDEX('Windows',@@VERSION)-1)),''))-2)) AS 'SistemaOperaciona'
			 , LEFT(REPLACE(REPLACE(@@VERSION,LEFT(@@VERSION,(CHARINDEX('Windows',@@VERSION)-1)),''),LEFT(REPLACE(@@VERSION,LEFT(@@VERSION,(CHARINDEX('Windows',@@VERSION)-1)),''),(CHARINDEX('Build',REPLACE(@@VERSION,LEFT(@@VERSION,(CHARINDEX('Windows',@@VERSION)-1)),''))-1)),''),CHARINDEX(')',REPLACE(REPLACE(@@VERSION,LEFT(@@VERSION,(CHARINDEX('Windows',@@VERSION)-1)),''),LEFT(REPLACE(@@VERSION,LEFT(@@VERSION,(CHARINDEX('Windows',@@VERSION)-1)),''),(CHARINDEX('Build',REPLACE(@@VERSION,LEFT(@@VERSION,(CHARINDEX('Windows',@@VERSION)-1)),''))-1)),''))-3) AS 'Versao' 

/*

https://docs.microsoft.com/pt-br/troubleshoot/sql/analysis-services/perform-distributed-query-olap

*/