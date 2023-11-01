/************************************************************************************************
Este script vai extrair os meta dados das bases de dados do servidor de SQL Server.

Dados extraidos:
	- Schema
	- Tabela
	- Coluna
	- Index

Fluxo de execução:
	1 - Lista todos os servidores.
	2 - Verifica se existe linked server configurado. 
			a - Se não existir criar o linked server.
			b - Se existir continua o fluxo.

    3 - Testa o Linked Server.
	        a - Testa o Liked Server, se o teste for bem sucedido condinua o script 
			b - se não passa para o proximo servidor.

	4 - Monta os script para extrair os dados das bases de dados.
			a - Cadastra novos Schemas e tabelas.
			b - Cadadastra as estatísticas da Tabelas.
			c - Cadastra as colunas.
			d - Cadastra os Index.

	4 - Apaga o linked Server criado para o servidor.

************************************************************************************************/


-- Variaveis do Loop de Instância.
DECLARE @idInstancia     INT
DECLARE @idSHServidor    INT
DECLARE @Servidor        NVarchar(60)
DECLARE @HostName        NVarchar(255)
DECLARE @IP              NVarchar(255)
DECLARE @Porta           Real
DECLARE @idBaseDeDados   INT
DECLARE @BasedeDados     NVarchar(255)
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

		SELECT TOP 15
		       [idInstancia]   			  
			  ,[Servidor]
			  ,[conectstring] AS HostName
		  FROM [SGBD].[vw_instancia]
		WHERE [SGBD] = 'SQL Server AWS'
		  --AND [Servidor] NOT LIKE'S-SEBN8187'
		  --AND [idInstancia] >= 58 AND [idInstancia] <= 58
		  --AND [idInstancia] < 23
		--ORDER BY [idInstancia] DESC
		  
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
				SET @TEXTO = 'Carga de ETL - Cadastra novos Schemas e tabelas.'
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
				  FROM [SGBD].[vw_instancia] AS I 
				  INNER JOIN [SGBD].[vw_basededados] AS B ON B.[idInstancia] = I.[idInstancia]
				  INNER JOIN [SGBD].[BDSQLServer] AS S ON S.[idBaseDeDados] = B.[idBaseDeDados]
				WHERE I.[idInstancia] = @idInstancia
				  AND S.[RestrictAccess] = 'MULTI_USER'
				  AND S.OnlineOffline = 'ONLINE'
				 -- AND I.[idInstancia] = 10

			OPEN basededados_for 
				FETCH NEXT FROM basededados_for INTO @idBaseDeDados, @BasedeDados

					WHILE @@FETCH_STATUS = 0
					BEGIN
		
		    -- 4 - Monta os script para extrair.
		
							-- a - Cadastra novos Schemas e tabelas.
							SET @ScriptCMD = '
					INSERT INTO [SGBD].[BDTabela]
							   ([idBaseDeDados]
							   ,[schema_name]
							   ,[table_name])
							SELECT B.[idBaseDeDados]
								 , A.[schema_name]
								 , A.table_Name
							FROM OPENQUERY([LNK_SQL_'+@Servidor+'], ''
											SELECT B.[schema_name]
												 , B.table_Name
												 , sum(reserved_in_kb) [Reservado_kb]
												 , sum(case 
														when Type_Desc in (''''CLUSTERED'''',''''HEAP'''') then reserved_in_kb 
													   else 0 end) [Dados_kb]
												 , sum(case 
														when Type_Desc in (''''NONCLUSTERED'''') then reserved_in_kb 
													   else 0 end) [Indices_kb]
												 , Qtd_Linhas
											FROM (
											select s.name as ''''schema_name''''
												 , o.name as ''''table_Name''''
												 , coalesce(i.name,''''heap'''') as ''''index_Name''''
												 , p.used_page_Count*8 as ''''used_in_kb''''
												 , p.reserved_page_count*8 as ''''reserved_in_kb''''
												 , p.row_count as ''''Qtd_Linhas''''
												 , case when i.index_id in (0,1) then p.row_count else 0 end as ''''tbl_rows''''
												 , i.type_Desc
											from ['+@BasedeDados+'].sys.dm_db_partition_stats p
											join ['+@BasedeDados+'].sys.objects o on o.object_id = p.object_id
											join ['+@BasedeDados+'].sys.schemas s on s.schema_id = o.schema_id
											left join ['+@BasedeDados+'].sys.indexes i on i.object_id = p.object_id and i.index_id = p.index_id
											where o.type_desc = ''''user_Table'''' and o.is_Ms_shipped = 0 ) AS B
											where index_Name is not null								  	  
											group by Schema_Name, Table_Name , Qtd_Linhas
										'') AS A
								INNER JOIN [SGBD].[vw_basededados] AS B ON B.idInstancia = '+ CONVERT(NVARCHAR(10),@idInstancia)  + ' AND B.[idBaseDeDados] = '+ CONVERT(NVARCHAR(10),@idBaseDeDados)  + ' 
								WHERE NOT EXISTS( SELECT * FROM [SGBD].[BDTabela] AS T
												   WHERE T.[idBaseDeDados] = B.[idBaseDeDados]
													 AND T.[schema_name] COLLATE DATABASE_DEFAULT = A.schema_name
													 AND T.[table_name]  COLLATE DATABASE_DEFAULT = A.table_name)  '
							
							--Executa o script.  
							BEGIN TRY
							   exec sp_executesql @scriptcmd						
								--PRINT @scriptcmd
							END TRY	
							BEGIN CATCH-- Caso o alguns das etapas apresente erro na execução do script o erro será inserido na tabela de "logerror"
							    SET @SRVR = 'Servidor: '+ @Servidor +' Base de dados: ' + @BasedeDados
								SET @TEXTO = 'Erro ao cadastra novos Schemas e tabelas.'
								SELECT @ERROR_NUMBER   = ERROR_NUMBER()
				 					 , @ERROR_SEVERITY = ERROR_SEVERITY()
									 , @ERROR_MESSAGE  = ERROR_MESSAGE()

								EXECUTE @RC = [dbo].[SP_Insert_erro_log] @SRVR,@ERROR_NUMBER,@ERROR_SEVERITY,@ERROR_MESSAGE,@TEXTO
							END CATCH


							-- b - Cadadastra as estatísticas da Tabelas.
							SET @ScriptCMD = '
						INSERT INTO [SGBD].[TBStarts]
								   ([idBDTabela]
								   ,[reservedkb]
								   ,[datakb]
								   ,[Indiceskb]
								   ,[sumline])
							SELECT T.[idBDTabela]
								 , A.Reservado_kb
								 , A.Dados_kb
								 , A.Indices_kb
								 , A.Qtd_Linhas
							FROM OPENQUERY([LNK_SQL_'+@Servidor+'], ''
											SELECT B.[schema_name]
												 , B.table_Name
												 , sum(reserved_in_kb) [Reservado_kb]
												 , sum(case 
														when Type_Desc in (''''CLUSTERED'''',''''HEAP'''') then reserved_in_kb 
													   else 0 end) [Dados_kb]
												 , sum(case 
														when Type_Desc in (''''NONCLUSTERED'''') then reserved_in_kb 
													   else 0 end) [Indices_kb]
												 , Qtd_Linhas
											FROM (
											select s.name as ''''schema_name''''
												 , o.name as ''''table_Name''''
												 , coalesce(i.name,''''heap'''') as ''''index_Name''''
												 , p.used_page_Count*8 as ''''used_in_kb''''
												 , p.reserved_page_count*8 as ''''reserved_in_kb''''
												 , p.row_count as ''''Qtd_Linhas''''
												 , case when i.index_id in (0,1) then p.row_count else 0 end as ''''tbl_rows''''
												 , i.type_Desc
											from ['+@BasedeDados+'].sys.dm_db_partition_stats p
											join ['+@BasedeDados+'].sys.objects o on o.object_id = p.object_id
											join ['+@BasedeDados+'].sys.schemas s on s.schema_id = o.schema_id
											left join ['+@BasedeDados+'].sys.indexes i on i.object_id = p.object_id and i.index_id = p.index_id
											where o.type_desc = ''''user_Table'''' and o.is_Ms_shipped = 0 ) AS B
											where index_Name is not null							  	  
											group by Schema_Name, Table_Name , Qtd_Linhas
										'') AS A
								INNER JOIN [SGBD].[vw_basededados] AS B ON B.idInstancia = '+ CONVERT(NVARCHAR(10),@idInstancia)  + ' AND B.[idBaseDeDados] = '+ CONVERT(NVARCHAR(10),@idBaseDeDados)  + ' 
								INNER JOIN [SGBD].[vw_tabelas_Starts] AS T ON T.[idBaseDeDados] = B.[idBaseDeDados] 
																   AND T.[schema_name] COLLATE DATABASE_DEFAULT = A.schema_name
																   AND T.[table_name]  COLLATE DATABASE_DEFAULT = A.table_name
																   AND (T.[reservedkb] <> A.Reservado_kb
																	OR T.[datakb] <> A.Dados_kb
																	OR T.[Indiceskb] <> A.Indices_kb
																	OR T.[sumline] <> A.Qtd_Linhas)	'

							--PRINT @scriptcmd
							--Executa o script.  
							BEGIN TRY
								exec sp_executesql @scriptcmd						
							END TRY	
							BEGIN CATCH-- Caso o alguns das etapas apresente erro na execução do script o erro será inserido na tabela de "logerror"
							    SET @SRVR = 'Servidor: '+ @Servidor +' Base de dados: ' + @BasedeDados
								SET @TEXTO = 'Erro ao Cadadastra as estatísticas da Tabelas.'
								SELECT @ERROR_NUMBER   = ERROR_NUMBER()
				 					 , @ERROR_SEVERITY = ERROR_SEVERITY()
									 , @ERROR_MESSAGE  = ERROR_MESSAGE()

								EXECUTE @RC = [dbo].[SP_Insert_erro_log] @SRVR,@ERROR_NUMBER,@ERROR_SEVERITY,@ERROR_MESSAGE,@TEXTO
							END CATCH
							
							-- c - Cadastra as colunas.
							SET @ScriptCMD = '
									INSERT INTO [SGBD].[TBColuna]
											   ([idBDTabela]
											   ,[colunn_name]
											   ,[ordenal_positon]
											   ,[data_type])
	 										SELECT B.[idBDTabela]
												 , A.column_name
												 , A.ordinal_position
												 , A.data_type
												FROM OPENQUERY([LNK_SQL_'+@Servidor+'], ''
															SELECT C.table_schema
																 , C.table_name
																 , C.column_name
																 , C.ordinal_position
																 , C.data_type 
															FROM ['+@BasedeDados+'].INFORMATION_SCHEMA.COLUMNS AS C
															 '') AS A 
												INNER JOIN [SGBD].[vw_tabelas] AS B ON B.idInstancia = '+ CONVERT(NVARCHAR(10),@idInstancia)  + ' 
																				   AND B.[idBaseDeDados] = '+ CONVERT(NVARCHAR(10),@idBaseDeDados)  + ' 
																				   AND B.[schema_name] COLLATE DATABASE_DEFAULT = A.table_schema
																				   AND B.[table_name]  COLLATE DATABASE_DEFAULT = A.table_name
												WHERE NOT EXISTS (SELECT * FROM [SGBD].[TBColuna] AS C
																   WHERE C.idBDTabela = B.idBDTabela
																	 AND C.[colunn_name] COLLATE DATABASE_DEFAULT = A.column_name ) '
			
							--Executa o script.  
							--PRINT @scriptcmd
							BEGIN TRY
								exec sp_executesql @scriptcmd						
							END TRY	
							BEGIN CATCH-- Caso o alguns das etapas apresente erro na execução do script o erro será inserido na tabela de "logerror"
							    SET @SRVR = 'Servidor: '+ @Servidor +' Base de dados: ' + @BasedeDados
								SET @TEXTO = 'Erro ao Cadastra as colunas.'
								SELECT @ERROR_NUMBER   = ERROR_NUMBER()
				 					 , @ERROR_SEVERITY = ERROR_SEVERITY()
									 , @ERROR_MESSAGE  = ERROR_MESSAGE()

								EXECUTE @RC = [dbo].[SP_Insert_erro_log] @SRVR,@ERROR_NUMBER,@ERROR_SEVERITY,@ERROR_MESSAGE,@TEXTO
							END CATCH


							-- d - Cadastra os Index.
							SET @ScriptCMD = '
									INSERT INTO [SGBD].[TBIndex]
											   ([idBDTabela]
											   ,[Index_name]
											   ,[FileGroup]
											   ,[type_desc])
											   SELECT B.idBDTabela
													, A.Index_name
													, A.FileGroup
													, A.Type_index
												FROM OPENQUERY([LNK_SQL_'+@Servidor+'], ''
															SELECT S.name AS ''''table_schema''''
														  			, A.name AS ''''table_name''''
																	, coalesce(I.name,''''heap'''') AS ''''Index_name''''
																	, E.[name]  AS [FileGroup]
																	, I.type_desc ''''Type_index''''
															FROM  ['+@BasedeDados+'].sys.objects A
															INNER JOIN ['+@BasedeDados+'].sys.schemas S on S.schema_id = A.schema_id
															INNER JOIN ['+@BasedeDados+'].sys.indexes I on I.object_id = A.object_id
															INNER JOIN ['+@BasedeDados+'].sys.data_spaces E on E.data_space_id = I.data_space_id
																'') AS A 
													INNER JOIN [SGBD].[vw_tabelas] AS B ON B.idInstancia = '+ CONVERT(NVARCHAR(10),@idInstancia)  + ' 
																				AND B.[idBaseDeDados] = '+ CONVERT(NVARCHAR(10),@idBaseDeDados)  + ' 
																				AND B.[schema_name] COLLATE DATABASE_DEFAULT = A.table_schema
																				AND B.[table_name]  COLLATE DATABASE_DEFAULT = A.table_name		
												WHERE NOT EXISTS (SELECT * FROM [SGBD].[VM_TBIndex] AS I
																	WHERE I.idBDTabela = B.idBDTabela
																	AND I.Index_name COLLATE DATABASE_DEFAULT = A.Index_name )												  '					
					 
			
							--Executa o script.  
							--PRINT @scriptcmd
							BEGIN TRY
								exec sp_executesql @scriptcmd						
							END TRY	
							BEGIN CATCH-- Caso o alguns das etapas apresente erro na execução do script o erro será inserido na tabela de "logerror"
							    SET @SRVR = 'Servidor: '+ @Servidor +' Base de dados: ' + @BasedeDados
								SET @TEXTO = 'Erro ao Cadastra os Index.'
								SELECT @ERROR_NUMBER   = ERROR_NUMBER()
				 					 , @ERROR_SEVERITY = ERROR_SEVERITY()
									 , @ERROR_MESSAGE  = ERROR_MESSAGE()

								EXECUTE @RC = [dbo].[SP_Insert_erro_log] @SRVR,@ERROR_NUMBER,@ERROR_SEVERITY,@ERROR_MESSAGE,@TEXTO
							END CATCH

					-- Alimenta a memória com o próximo registro.
					FETCH NEXT FROM basededados_for INTO @idBaseDeDados, @BasedeDados
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