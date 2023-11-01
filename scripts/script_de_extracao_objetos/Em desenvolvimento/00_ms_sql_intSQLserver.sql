/************************************************************************************************
Este script vai extrair os dados do servidor de SQL Server.

Fluxo de execução:
	1 - Lista todos os servidores.
	2 - Verifica se existe linked server configurado. 
			a - Se não existir criar o linked server.
			b - Se existir continua o fluxo.

    3 - Testa o Linked Server.
			a - Testa o Liked Server, se o teste for bem sucedido condinua o script se não passa para o proximo servidor.
			b - Caso o teste do Liked server apresentar erro, o erro será gravado na tabela de logerro.

	4 - Monta os script para extrair os dados da versão do servidor.
			a - Extrair a versão do banco.
			b - Extrair CPU.
			c - Extrair Memória.
			d - Extrair max de memória configurado para banco.
			e - Extrai a versão do S.O. e sua versão

	5 - Apaga o linked Server criado para o servidor.

************************************************************************************************/


-- Variaveis do Loop de Instância.
DECLARE @idInstancia     INT
DECLARE @Servidor        NVarchar(60)
DECLARE @HostName        NVarchar(255)
DECLARE @IP              NVarchar(255)
DECLARE @Porta           Real
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

		SELECT --TOP 1 
		       [idInstancia]   
              ,[conectstring] AS Servidor
			  ,[conectstring] AS HostName
			  ,[IP]
			  ,[Porta]
		  FROM [SGBD].[instancia]
		WHERE [SGBD] = 'SQL Server AWS'
		  --AND [idInstancia] = 10

	OPEN intancia_for 
		FETCH NEXT FROM intancia_for INTO @idInstancia, @Servidor, @HostName, @IP, @Porta

			WHILE @@FETCH_STATUS = 0
			BEGIN
			
	
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
					--PRINT @Servidor+' - '+ @HostName+' - '+@Servidor
					EXEC @RC = [dbo].[SP_CreateLinkServer_SQL] @Servidor, @HostName,@Servidor

				END 
			
	-- b - Se existir continua o fluxo.

	--3 - Testa o Linked Server.
	  -- a - Testa o Liked Server, se o teste for bem sucedido condinua o script se não passa para o proximo servidor.
		SELECT @srvr = a.name
			FROM sys.Servers a
			LEFT OUTER JOIN sys.linked_logins b ON b.server_id = a.server_id
			LEFT OUTER JOIN sys.server_principals c ON c.principal_id = b.local_principal_id
			WHERE a.name like 'LNK_SQL_%' and a.data_source = @Servidor

		begin try
			exec @retval = sys.sp_testlinkedserver @srvr;
		end try
		begin catch
		        set @retval = sign(@@error)
				SET @TEXTO = 'Carga de ETL - Instância'
				SELECT @ERROR_NUMBER   = ERROR_NUMBER()
				 	 , @ERROR_SEVERITY = ERROR_SEVERITY()
                     , @ERROR_MESSAGE  = ERROR_MESSAGE()

				EXECUTE @RC = [dbo].[SP_Insert_erro_log] @SRVR,@ERROR_NUMBER,@ERROR_SEVERITY,@ERROR_MESSAGE,@TEXTO

		end catch;
	  --Se o retorno da varipavel de erro for 0 zero o script continua com o servidor atual.
		IF @retval = 0
		BEGIN 
		PRINT @Servidor
		-- 4 - Monta os script para extrair.

					-- a - Extrair as configurações da intância de banco

						IF NOT EXISTS(SELECT [idInstancia] FROM [sgbd].[InsSQLServer] WHERE [ativo] = 1	AND idInstancia = @idInstancia)
						BEGIN
							SET @ScriptCMD = '
							INSERT INTO [sgbd].[InsSQLServer]
									   ([idInstancia]
									   ,[memoria_fisica]
									   ,[memoria_sql_server]
									   ,[cpu_count]
									   ,[cpu_hyperthead]
									   ,[sqlserver_start_time])
							SELECT B.[idInstancia]
								 , physical_memory_kb
								 , committed_target_kb
								 , cpu_count
								 , hyperthread_ratio
								 , sqlserver_start_time
							FROM OPENQUERY([LNK_SQL_'+@Servidor+'], ''
												SELECT cpu_count
													 , hyperthread_ratio
													 , physical_memory_kb
													 , committed_target_kb
													 , sqlserver_start_time
												FROM sys.dm_os_sys_info OPTION (RECOMPILE); '') AS A
							INNER JOIN [SGBD].[instancia] AS B ON B.idInstancia = '+ CONVERT(NVARCHAR(10),@idInstancia)  + '  '
							--Executa o script.  
							BEGIN TRY
								exec sp_executesql @scriptcmd
								--PRINT @scriptcmd
							END TRY	
							BEGIN CATCH-- Caso o alguns das etapas apresente erro na execução do script o erro será inserido na tabela de "logerror"
							    SET @SRVR = 'Servidor: '+ @Servidor 
								SET @TEXTO = 'Erro ao Extrair a versão do banco.'
								SELECT @ERROR_NUMBER   = ERROR_NUMBER()
				 					 , @ERROR_SEVERITY = ERROR_SEVERITY()
									 , @ERROR_MESSAGE  = ERROR_MESSAGE()

								EXECUTE @RC = [dbo].[SP_Insert_erro_log] @SRVR,@ERROR_NUMBER,@ERROR_SEVERITY,@ERROR_MESSAGE,@TEXTO
							END CATCH

						END 
						ELSE 
						BEGIN
							SET @ScriptCMD ='UPDATE SH
												SET SH.[memoria_fisica]       = V.physical_memory_kb,
													SH.[memoria_sql_server]   = V.committed_target_kb,
													SH.[cpu_count]            = V.cpu_count,
													SH.[cpu_hyperthead]       = V.hyperthread_ratio,
													SH.[sqlserver_start_time] = V.sqlserver_start_time
   											  FROM [SGBD].[InsSQLServer] AS SH
											  LEFT JOIN (SELECT B.[idInstancia]
															  , physical_memory_kb
														      , committed_target_kb
															  , cpu_count
															  , hyperthread_ratio
															  , sqlserver_start_time
															FROM OPENQUERY([LNK_SQL_'+@Servidor+'], ''
																	SELECT cpu_count
																		 , hyperthread_ratio
																		 , physical_memory_kb
																		 , committed_target_kb
																		 , sqlserver_start_time
																	FROM sys.dm_os_sys_info OPTION (RECOMPILE);'' ) AS A
															        INNER JOIN [SGBD].[instancia] AS B ON B.[idInstancia] = ' + CONVERT(Nvarchar(20),@idInstancia) + ' ) AS V ON V.idInstancia = ' + CONVERT(Nvarchar(20),@idInstancia) + ' 
											   WHERE SH.[idInstancia] =  ' + CONVERT(Nvarchar(20),@idInstancia) + ' '	
							--Executa o script.  
							BEGIN TRY
								exec sp_executesql @scriptcmd
								--PRINT @scriptcmd
							END TRY	
							BEGIN CATCH-- Caso o alguns das etapas apresente erro na execução do script o erro será inserido na tabela de "logerror"
							    SET @SRVR = 'Servidor: '+ @Servidor 
								SET @TEXTO = 'Erro ao Extrair a versão do banco.'
								SELECT @ERROR_NUMBER   = ERROR_NUMBER()
				 					 , @ERROR_SEVERITY = ERROR_SEVERITY()
									 , @ERROR_MESSAGE  = ERROR_MESSAGE()

								EXECUTE @RC = [dbo].[SP_Insert_erro_log] @SRVR,@ERROR_NUMBER,@ERROR_SEVERITY,@ERROR_MESSAGE,@TEXTO
							END CATCH
					   END 

							SET @ScriptCMD ='UPDATE SH
												SET SH.[cpu_parelelismo]      = V.value
   											  FROM [SGBD].[InsSQLServer] AS SH
											  LEFT JOIN (SELECT B.[idInstancia]
															  , value
															FROM OPENQUERY([LNK_SQL_'+@Servidor+'], ''
																	SELECT cast(value as int) as ''''value''''
																	FROM sys.configurations
																	WHERE name = ''''cost threshold for parallelism'''' '' ) AS A
															        INNER JOIN [SGBD].[instancia] AS B ON B.[idInstancia] = ' + CONVERT(Nvarchar(20),@idInstancia) + ' ) AS V ON V.idInstancia = ' + CONVERT(Nvarchar(20),@idInstancia) + ' 
											   WHERE SH.[idInstancia] =  ' + CONVERT(Nvarchar(20),@idInstancia) + ' '	
							--Executa o script.  
							BEGIN TRY
								exec sp_executesql @scriptcmd
								--PRINT @scriptcmd
							END TRY	
							BEGIN CATCH-- Caso o alguns das etapas apresente erro na execução do script o erro será inserido na tabela de "logerror"
							    SET @SRVR = 'Servidor: '+ @Servidor 
								SET @TEXTO = 'Erro ao Extrair a versão do banco.'
								SELECT @ERROR_NUMBER   = ERROR_NUMBER()
				 					 , @ERROR_SEVERITY = ERROR_SEVERITY()
									 , @ERROR_MESSAGE  = ERROR_MESSAGE()

								EXECUTE @RC = [dbo].[SP_Insert_erro_log] @SRVR,@ERROR_NUMBER,@ERROR_SEVERITY,@ERROR_MESSAGE,@TEXTO
							END CATCH


		END -- b - Caso o teste do Liked server apresentar erro, o erro será gravado na tabela de logerro.

		-- 5 - Apaga o linked Server criado para o servidor.
				SET @stringConnect = @HostName
				EXECUTE @RC = [dbo].[SP_DropLinkServer] @Servidor
			-- Alimenta a memória com o próximo registro.
			FETCH NEXT FROM intancia_for INTO @idInstancia, @Servidor, @HostName, @IP, @Porta
			END


CLOSE intancia_for
DEALLOCATE intancia_for
