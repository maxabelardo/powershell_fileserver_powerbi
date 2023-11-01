/************************************************************************************************
Este script vai extrair os meta dados das bases de dados do servidor de SQL Server.

Dados extraidos:
	- Fragmentação 
	- total de leitura
	- Total de escrita 
	- Tamanho do index
	- total de linhas

Fluxo de execução:
	1 - Lista todos os servidores.
	2 - Verifica se existe linked server configurado. 
			a - Se não existir criar o linked server.
			b - Se existir continua o fluxo.
	3 - Monta os script para extrair os dados das bases de dados.
			a - Cadastra as estatísticas do index, caso o valor tenha mudado apartir da último valor.
	4 - Apaga o linked Server criado para o servidor.

************************************************************************************************/


-- Variaveis do Loop de Instância.
DECLARE @idInstancia   INT
DECLARE @idSHServidor  INT
DECLARE @Servidor      NVarchar(60)
DECLARE @HostName      NVarchar(255)
DECLARE @IP            NVarchar(255)
DECLARE @Porta         Real
DECLARE @idBaseDeDados INT
DECLARE @BasedeDados   NVarchar(255)
DECLARE @idInternodb   INT
DECLARE @schema_name   NVarchar(255)
DECLARE @table_name    NVarchar(255)
DECLARE @error           NVarchar(128)
DECLARE @srvr            NVarchar(128)
DECLARE @retval          INT
DECLARE @ERROR_NUMBER    INT
DECLARE @ERROR_SEVERITY  INT
DECLARE @ERROR_MESSAGE   NVarchar(MAX)
DECLARE @TEXTO           NVarchar(MAX)
--Variável que executará os script criado em tempo de execução.
DECLARE @ScriptCMD nchar(3000)

--Variável usada para executar o drop do linked server.
DECLARE @stringConnect NVarchar(50)
-----------------------------------------------------------------------Início do fluxo -------------------------------------------------------------------------------

-- 1 - Lista todos os servidores.

-- Variaveis de criação do linked server.
DECLARE @RC int

	-- Curso que lista todos os servidores de SQL Server.
	-- Este curso deverá criar todos os linked Server que seram usados para conectar nos servidores remotos.
	DECLARE intancia_for CURSOR FOR

		SELECT [idInstancia]   			  
			  ,[Servidor]
			  ,[conectstring] AS HostName
		  FROM [SGBD].[vw_instancia]
		WHERE [SGBD] = 'SQL Server AWS'
		  --AND [Servidor] NOT LIKE'S-SEBN8187'
		  --AND [idInstancia] >= 58 AND [idInstancia] <= 58
		  --AND [idInstancia] < 23
		ORDER BY [idInstancia] DESC
		  
		  --AND [idInstancia] = 10

	OPEN intancia_for 
		FETCH NEXT FROM intancia_for INTO @idInstancia, @Servidor, @HostName
			WHILE @@FETCH_STATUS = 0
			BEGIN
			--PRINT @Servidor
					--print @Servidor
		--2 - Verifica se existe linked server configurado. 

			-- a - Se não existir criar o linked server.
						-- Verifica se existe o linked server

						IF NOT EXISTS ( SELECT a.name, a.product, a.data_source
							FROM sys.Servers a
								LEFT OUTER JOIN sys.linked_logins b ON b.server_id = a.server_id
									LEFT OUTER JOIN sys.server_principals c ON c.principal_id = b.local_principal_id
										WHERE a.name like 'LNK_SQL_%' and a.data_source = @Servidor )
						BEGIN -- Se não existir criar o linked Server
							-- Criação do linked server 
							--PRINT'Criar linked server ' + @Servidor
							EXEC @RC = [dbo].[SP_CreateLinkServer_SQL] @Servidor, @HostName,@Servidor
					
						END 
			
			-- b - Se existir continua o fluxo.

	--3 - Testa o Linked Server.
	  -- a - Testa o Liked Server, se o teste for bem sucedido condinua o script
		SELECT @SRVR = a.name
			FROM sys.Servers a
			LEFT OUTER JOIN sys.linked_logins b ON b.server_id = a.server_id
			LEFT OUTER JOIN sys.server_principals c ON c.principal_id = b.local_principal_id
			WHERE a.name like 'LNK_SQL_%' and a.data_source = @Servidor

		begin try
			--PRINT 'teste do linked server'
			exec @retval = sys.sp_testlinkedserver @srvr;
		end try
		begin catch -- Caso o teste apresente erro os erros serão gravado no log.
		        set @retval = sign(@@error)
				SET @TEXTO = 'Carga de ETL - Index estatísticas.'
				SELECT @ERROR_NUMBER   = ERROR_NUMBER()
				 	 , @ERROR_SEVERITY = ERROR_SEVERITY()
                     , @ERROR_MESSAGE  = ERROR_MESSAGE()

				EXECUTE @RC = [dbo].[SP_Insert_erro_log] @SRVR,@ERROR_NUMBER,@ERROR_SEVERITY,@ERROR_MESSAGE,@TEXTO

		end catch;

      -- b se não passa para o proximo servidor.

	  --Se o retorno da varipavel de erro for 0 zero o script continua com o servidor atual.
		IF @retval = 0
		BEGIN 

			-- Curso que lista todas as bases de dados do servidor			
			DECLARE basededados_for CURSOR FOR

				SELECT B.idbasededados
					  ,B.[BasedeDados]
					  ,B.[idInternodb]
					  ,T.schema_name
			          ,T.table_name
				  FROM [SGBD].[vw_instancia] AS I 
				  INNER JOIN [SGBD].[vw_basededados] AS B ON B.[idInstancia] = I.[idInstancia]
				  INNER JOIN [SGBD].[BDSQLServer] AS S ON S.[idBaseDeDados] = B.[idBaseDeDados]
				  INNER JOIN [SGBD].[BDTabela] AS T ON T.idBaseDeDados = B.idbasededados
				WHERE I.[idInstancia] = @idInstancia
				  AND [idInternodb] > 4 
				  AND S.[RestrictAccess] = 'MULTI_USER'
				  AND S.OnlineOffline = 'ONLINE'

			OPEN basededados_for 
				FETCH NEXT FROM basededados_for INTO @idBaseDeDados, @BasedeDados, @idInternodb, @schema_name, @table_name
				WHILE @@FETCH_STATUS = 0
				BEGIN


-- 3 - Monta os script para extrair.

					-- a - Cadastra as estatísticas do index, caso o valor tenha mudado apartir da último valor.
						SET @ScriptCMD = '
									INSERT INTO [SGBD].[TBIndexStats]
												([idTBIndex]
												,[index_id]
												,[ScanWrites]
												,[ScanReads]
												,[IndexSizeKB]
												,[Row_count])
										SELECT DISTINCT 
										       I.[idTBIndex]
											 , A.index_id
											 , A.ScanWrites
											 , A.ScanReads
											 , A.IndexSizeKB
											 , A.row_count
										FROM OPENQUERY([LNK_SQL_'+@Servidor+'], ''
											SELECT DISTINCT
											          s1.name  AS [schema_name] 
													, Tn.name AS [Table_Name]
													, i.name AS [Index_Name]
													, i.index_id
													, user_updates AS [ScanWrites]
													, user_seeks + user_scans + user_lookups AS [ScanReads]
													, IndexSizeKB
													, row_count
											FROM ['+@BasedeDados+'].sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
											INNER JOIN ['+@BasedeDados+'].sys.indexes AS i WITH (NOLOCK) ON s.[object_id] = i.[object_id] AND i.index_id = s.index_id		
											INNER JOIN ['+@BasedeDados+'].sys.tables tn ON tn.OBJECT_ID = i.object_id
											INNER JOIN ['+@BasedeDados+'].sys.schemas s1 on s1.schema_id = tn.schema_id	
											LEFT  JOIN (SELECT A.[object_id]
																, A.[index_id]
																, A.row_count
																, SUM(A.[used_page_count]) IndexSizeKB
														FROM ['+@BasedeDados+'].sys.dm_db_partition_stats A
											GROUP BY A.[object_id], A.[index_id], A.row_count) AS sz ON sz.[object_id] = i.[object_id] AND sz.[index_id] = i.[index_id] '') AS A	
										INNER JOIN  [sgbd].[VM_TBIndex] AS I ON I.idBaseDeDados = '+CONVERT(NVARCHAR(10),@idBaseDeDados)+' 
																			 AND I.schema_name COLLATE DATABASE_DEFAULT = A.Schema_name
																			 AND I.table_name COLLATE DATABASE_DEFAULT  = A.Table_name
																			 AND I.Index_name COLLATE DATABASE_DEFAULT  = A.Index_Name
																			 AND (I.[ScanWrites] <> A.ScanWrites OR I.[ScanReads] <> A.ScanReads OR I.[IndexSizeKB] <> A.IndexSizeKB) '

				    --PRINT @scriptcmd
					--Executa o script.  
					BEGIN TRY
						exec sp_executesql @scriptcmd						
					END TRY	
					BEGIN CATCH-- Caso o alguns das etapas apresente erro na execução do script o erro será inserido na tabela de "logerror"
						SET @SRVR = 'Servidor: '+ @Servidor +' Base de dados: ' + @BasedeDados + ' Tabela: '+ @schema_name +'.'+ @table_name
						SET @TEXTO = 'Erro ao Cadastra as estatísticas do index, caso o valor tenha mudado apartir da último valor.'
						SELECT @ERROR_NUMBER   = ERROR_NUMBER()
				 				, @ERROR_SEVERITY = ERROR_SEVERITY()
								, @ERROR_MESSAGE  = ERROR_MESSAGE()

						EXECUTE @RC = [dbo].[SP_Insert_erro_log] @SRVR,@ERROR_NUMBER,@ERROR_SEVERITY,@ERROR_MESSAGE,@TEXTO
					END CATCH

					-- Alimenta a memória com o próximo registro.
					FETCH NEXT FROM basededados_for INTO @idBaseDeDados, @BasedeDados, @idInternodb, @schema_name, @table_name
					END

		CLOSE basededados_for
		DEALLOCATE basededados_for

	END 
	

    -- 5 - Apaga o linked Server criado para o servidor.

	EXECUTE @RC = [dbo].[SP_DropLinkServer] @Servidor

	FETCH NEXT FROM intancia_for INTO @idInstancia, @Servidor, @HostName
	END

CLOSE intancia_for
DEALLOCATE intancia_for