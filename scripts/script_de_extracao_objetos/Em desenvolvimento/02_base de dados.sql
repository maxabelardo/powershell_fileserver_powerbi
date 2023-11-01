/************************************************************************************************
Este script vai extrair os meta dados das bases de dados do servidor de SQL Server.

Fluxo de execução:
	1 - Lista todos os servidores.
	2 - Verifica se existe linked server configurado. 
			a - Se não existir criar o linked server.
			b - Se existir continua o fluxo.
    3 - Testa o Linked Server.
			a - Testa o Liked Server, se o teste for bem sucedido condinua o script se não passa para o proximo servidor.
			b - Caso o teste do Liked server apresentar erro, o erro será gravado na tabela de logerro.

	4 - Monta os script para extrair os dados das bases de dados.
			a - Cadastra novas bases de dados.
			b - Cadastra o detalhamento da base de dados já cadastrada.
			c - Desativa as bases que foram apagadas na origem.
			d - Inserir o tamanho da base caso ele esteja diferente do último registro no banco

	5 - Apaga o linked Server criado para o servidor.

************************************************************************************************/


-- Variaveis do Loop de Instância.
DECLARE @idInstancia     INT
DECLARE @idSHServidor    INT
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

	OPEN intancia_for 
		FETCH NEXT FROM intancia_for INTO @idInstancia, @Servidor, @HostName, @IP, @Porta

			WHILE @@FETCH_STATUS = 0
			BEGIN
			
	        print @Servidor
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
				SET @TEXTO = 'Carga de ETL - Base de dados'
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

					-- a - Cadastra novas bases de dados.
					SET @ScriptCMD = '
										INSERT INTO [SGBD].[basededados]
													([idInstancia]
													,[BasedeDados]
													,[created])
										SELECT B.idInstancia
												, A.name
												, A.create_date
										FROM OPENQUERY([LNK_SQL_'+@Servidor+'], ''
													select DB.[name]
														, L.[name] AS ''''owner''''
														, [database_id] AS ''''dbid''''
														, [create_date]      
														, [state_desc]       
														, [user_access_desc] AS ''''RestrictAccess''''
														, [recovery_model_desc] AS ''''recovery_model''''
														, [collation_name] AS ''''collation''''          
														, [compatibility_level]                      
														from [master].[sys].[databases] AS DB
														left join [master].[sys].syslogins  AS L ON L.sid = DB.owner_sid '') AS A
										INNER JOIN [SGBD].[vw_instancia] AS B ON B.idInstancia = '+ CONVERT(NVARCHAR(10),@idInstancia)  + '
										WHERE NOT EXISTS(SELECT *
															FROM [SGBD].[vw_basededados] AS C
															WHERE C.idInstancia   = B.idInstancia 
															AND C.BasedeDados  COLLATE DATABASE_DEFAULT  = A.name
															AND C.[idInternodb] = A.dbid )	'
				--PRINT @scriptcmd
					--Executa o script.  
					BEGIN TRY
						exec sp_executesql @scriptcmd						
					END TRY	
					BEGIN CATCH-- Caso o alguns das etapas apresente erro na execução do script o erro será inserido na tabela de "logerror"
							    SET @SRVR = 'Servidor: '+ @Servidor 
								SET @TEXTO = 'Erro ao Cadastra novas bases de dados.'
								SELECT @ERROR_NUMBER   = ERROR_NUMBER()
				 					 , @ERROR_SEVERITY = ERROR_SEVERITY()
									 , @ERROR_MESSAGE  = ERROR_MESSAGE()

								EXECUTE @RC = [dbo].[SP_Insert_erro_log] @SRVR,@ERROR_NUMBER,@ERROR_SEVERITY,@ERROR_MESSAGE,@TEXTO
					END CATCH

					-- b - Cadastra o detalhamento da base de dados já cadastrada.
					SET @ScriptCMD = '
										INSERT INTO [SGBD].[BDSQLServer]
												   ([idBaseDeDados]
												   ,[owner]
												   ,[dbid]
												   ,[OnlineOffline]
												   ,[RestrictAccess]
												   ,[recovery_model]
												   ,[collation]
												   ,[compatibility_level])
										SELECT B.[idBaseDeDados]
											 , A.owner
											 , A.dbid
											 , A.state_desc
											 , A.RestrictAccess
											 , A.recovery_model
											 , A.collation
											 , A.compatibility_level
										FROM OPENQUERY([LNK_SQL_'+@Servidor+'], ''
													select DB.[name]
														, L.[name] AS ''''owner''''
														, [database_id] AS ''''dbid''''
														, [create_date]      
														, [state_desc]       
														, [user_access_desc] AS ''''RestrictAccess''''
														, [recovery_model_desc] AS ''''recovery_model''''
														, [collation_name] AS ''''collation''''          
														, [compatibility_level]                      
														from [master].[sys].[databases] AS DB
														left join [master].[sys].syslogins  AS L ON L.sid = DB.owner_sid '') AS A
										INNER JOIN [SGBD].[basededados] AS B ON B.idInstancia = '+ CONVERT(NVARCHAR(10),@idInstancia)  + ' AND B.BasedeDados COLLATE DATABASE_DEFAULT  = A.name
										WHERE NOT EXISTS(SELECT *
															FROM [SGBD].[BDSQLServer] AS C
															WHERE C.[idBaseDeDados]   = B.[idBaseDeDados] )  '
			
					--Executa o script.  
					BEGIN TRY
						exec sp_executesql @scriptcmd						
					END TRY	
					BEGIN CATCH-- Caso o alguns das etapas apresente erro na execução do script o erro será inserido na tabela de "logerror"
						SET @SRVR = 'Servidor: '+ @Servidor 
						SET @TEXTO = 'Erro ao Cadastra o detalhamento da base de dados já cadastrada.'
						SELECT @ERROR_NUMBER   = ERROR_NUMBER()
				 			 , @ERROR_SEVERITY = ERROR_SEVERITY()
							 , @ERROR_MESSAGE  = ERROR_MESSAGE()
						EXECUTE @RC = [dbo].[SP_Insert_erro_log] @SRVR,@ERROR_NUMBER,@ERROR_SEVERITY,@ERROR_MESSAGE,@TEXTO
					END CATCH


					-- C - Desativa as bases que foram apagadas na origem.
					SET @ScriptCMD = '
										UPDATE B
										   SET [ativo] = 0
										  FROM [SGBD].[vw_basededados] AS B
										  WHERE B.[idInstancia] = '+ CONVERT(NVARCHAR(10),@idInstancia)  + '
											AND NOT EXISTS(SELECT *
															FROM OPENQUERY([LNK_SQL_'+@Servidor+'], ''
																			select DB.[name]
																				, L.[name] AS ''''owner''''
																				, [database_id] AS ''''dbid''''
																				, [create_date]      
																				, [state_desc]       
																				, [user_access_desc] AS ''''RestrictAccess''''
																				, [recovery_model_desc] AS ''''recovery_model''''
																				, [collation_name] AS ''''collation''''          
																				, [compatibility_level]                      
																				from [master].[sys].[databases] AS DB
																				left join [master].[sys].syslogins  AS L ON L.sid = DB.owner_sid '') AS A
													  WHERE A.name COLLATE DATABASE_DEFAULT = B.[BasedeDados]
														AND A.dbid = B.[idInternodb] ) '
			
					--Executa o script.  
					BEGIN TRY
						exec sp_executesql @scriptcmd						
					END TRY	
					BEGIN CATCH-- Caso o alguns das etapas apresente erro na execução do script o erro será inserido na tabela de "logerror"
						SET @SRVR = 'Servidor: '+ @Servidor 
						SET @TEXTO = 'Erro ao Desativa as bases que foram apagadas na origem.'
						SELECT @ERROR_NUMBER   = ERROR_NUMBER()
				 			 , @ERROR_SEVERITY = ERROR_SEVERITY()
							 , @ERROR_MESSAGE  = ERROR_MESSAGE()
						EXECUTE @RC = [dbo].[SP_Insert_erro_log] @SRVR,@ERROR_NUMBER,@ERROR_SEVERITY,@ERROR_MESSAGE,@TEXTO
					END CATCH

					-- D - Inserir o tamanho da base caso ele esteja diferente do último registro no banco
					SET @ScriptCMD = '
										INSERT INTO [SGBD].[BDTamanho]
												   ([idBaseDeDados]
												   ,[Tamanho])
										SELECT B.[idBaseDeDados]
											 , A.total_size_mb
										FROM OPENQUERY([LNK_SQL_'+@Servidor+'], ''
										SELECT DB_NAME(database_id) AS name
											, database_id
											, CAST(SUM(size) * 8. / 1024 AS DECIMAL(10,2))  as total_size_mb 
										FROM sys.master_files WITH(NOWAIT)
										GROUP BY database_id '') AS A
										INNER JOIN [SGBD].[vw_basededados] AS B ON B.idInstancia = '+ CONVERT(NVARCHAR(10),@idInstancia)  + '
																			   AND B.BasedeDados COLLATE DATABASE_DEFAULT = A.name 
																			   AND B.idInternodb = database_id
																			   AND (CASE WHEN B.[Tamanho] IS NULL THEN 0 ELSE B.[Tamanho] END) <> A.total_size_mb  '
			
					--Executa o script.  
					BEGIN TRY
						exec sp_executesql @scriptcmd						
					END TRY	
					BEGIN CATCH-- Caso o alguns das etapas apresente erro na execução do script o erro será inserido na tabela de "logerror"
						SET @SRVR = 'Servidor: '+ @Servidor 
						SET @TEXTO = 'Erro ao Inserir o tamanho da base caso ele esteja diferente do último registro no banco.'
						SELECT @ERROR_NUMBER   = ERROR_NUMBER()
				 			 , @ERROR_SEVERITY = ERROR_SEVERITY()
							 , @ERROR_MESSAGE  = ERROR_MESSAGE()
						EXECUTE @RC = [dbo].[SP_Insert_erro_log] @SRVR,@ERROR_NUMBER,@ERROR_SEVERITY,@ERROR_MESSAGE,@TEXTO
					END CATCH


-- 5 - Apaga o linked Server criado para o servidor.
						SET @stringConnect = @HostName
						EXECUTE @RC = [dbo].[SP_DropLinkServer] @Servidor

		END -- b - Caso o teste do Liked server apresentar erro, o erro será gravado na tabela de logerro.

			-- Alimenta a memória com o próximo registro.
			FETCH NEXT FROM intancia_for INTO @idInstancia, @Servidor, @HostName, @IP, @Porta
			END


CLOSE intancia_for
DEALLOCATE intancia_for