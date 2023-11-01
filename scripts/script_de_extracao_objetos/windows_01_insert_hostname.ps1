#Instância do banco de dados que será gravado os dados exportados.
$SQLInstance = "S-SEBP19\SQL2016"

#Nome da base de dados.
$SQLDatabase = "dcdados"

# Usuário para conectar no site.
$UserName = "svc-sede-dcdados@infraero.gov.br"

# Arquivo encritado com a senha do usuário de conexão.
$pwdTxt = Get-Content "D:\ETL\TesteEtlPassword.txt"

# Converte texto simples ou strings criptografadas em strings seguras.
$Password = $pwdTxt | ConvertTo-SecureString 

$credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $UserName,$Password

#Parametro necessário para execução do script dentro do job no SQL Server.
Set-Location C:
        
#Extrai a lista de servidores que serão verificado.    
$SQLQuery = "USE $SQLDatabase;
                SELECT [idSHServidor],[IPaddress],[HostName]
                FROM [ServerHost].[Servidor] WHERE [Ativo] = 1"

# Executar o script de extração.
$SQLQueryOutput = Invoke-Sqlcmd -query $SQLQuery -ServerInstance $SQLInstance 


#Loop da lista do servidores.
$SQLQueryOutput |  foreach {
    write-host $_["HostName"]
    #IP do servidor que será verificado.
    $servidor = $_["IPaddress"]

    #Comando que vai extrair os dados do disco do servidor remoto.
    $disk = Get-WMIObject -ComputerName $servidor -Credential $credential Win32_LogicalDisk |
                Sort-Object -Property Name | 
                Select-Object Name, VolumeName, FileSystem, Description, VolumeDirty, DriveType, `
                    @{"Label"="DiskSizeGB";"Expression"={"{0:N}" -f ($_.Size/1GB) -as [float]}}, `
                    @{"Label"="FreeSpaceGB";"Expression"={"{0:N}" -f ($_.FreeSpace/1GB) -as [float]}}, `
                    @{"Label"="Free";"Expression"={"{0:N}" -f (($_.FreeSpace/$_.Size)*100) -as [float]}} 
        
        #Loop do dados extraido do servidor.
        ForEach( $dk in $disk){
         
        #Verificar se os dados já foram cadastrado no servidor.
            # Id do SERvidor
            $IdSrv   = $_["idSHServidor"]
            # Nome da unidade do disco.
            $Unidade = $dk.Name

            #Carrega o script com os dados.
            $SQLQuery = "USE $SQLDatabase    
                            SELECT COUNT(*) AS TC
                              FROM [ServerHost].[Disk]
	                            WHERE [idSHServidor] = '$IdSrv'
	                              AND [Unidade] = '$Unidade' "

            #Executar o script de extração.
            $SQLQueryTop = Invoke-Sqlcmd -query $SQLQuery -ServerInstance $SQLInstance

                #Se o total NÃO for maior que 0 cadastra os dados.
                IF (-not $SQLQueryTop.TC -gt 0 ){

                    $Unidade     = $dk.Name 
                    $VolumeName  = $dk.VolumeName
                    $FileSystem  = $dk.FileSystem
                    $Description = $dk.Description
                    $VolumeDirty = $dk.VolumeDirty
                    $DriveType   = $dk.DriveType

                    #Carrega na variável o script de insert com os dados da lista.
                        $SQLQuery = "USE $SQLDatabase
                        INSERT INTO [ServerHost].[Disk]
                        ([idSHServidor],[Unidade],[VolumeName],[FileSystem],[Description],[VolumeDirty],[DriveType])
                        VALUES 
                          ('$IdSrv','$Unidade','$VolumeName','$FileSystem','$Description','$VolumeDirty','$DriveType');"
            
                        #Executa o script de insert no banco 
                        $SQLQueryOutputInsert = Invoke-Sqlcmd -query $SQLQuery -ServerInstance $SQLInstance    

                }#Se o valor for MAIOR que 0.
                ELSE{#Atualiza os dados caso seja diferênte.
                   $SQLQuery = "USE $SQLDatabase                
                    UPDATE [ServerHost].[Disk]
                       SET [VolumeName]  = '$VolumeName'
                          ,[FileSystem]  = '$FileSystem'
                          ,[Description] = '$Description'
                          ,[VolumeDirty] = '$VolumeDirty'
                          ,[DriveType]   = '$DriveType'
                     WHERE [idSHServidor] = '$IdSrv'
                       AND [Unidade]      = '$Unidade'
                       AND ([VolumeName]   <> '$VolumeName'
                          OR [FileSystem]  <> '$FileSystem'
                          OR [Description] <> '$Description'
                          OR [VolumeDirty] <> '$VolumeDirty'
                          OR [DriveType]   <> '$DriveType' ) "
                        
                    #Executa o script de insert no banco 
                    $SQLQueryOutputUpdate = Invoke-Sqlcmd -query $SQLQuery -ServerInstance $SQLInstance  
                }

          #------------------------------------------------------------------------------------------------------
          #Verifica as dimessões das unidades.

            #Extrai o id do disco no servidor.
                #Carrega o script com os dados.
                $SQLQuery = "USE $SQLDatabase    
                                SELECT [idDisk]
                                  FROM [ServerHost].[Disk]
	                                WHERE [idSHServidor] = '$IdSrv'
	                                  AND [Unidade]      = '$Unidade' "

                #Executar o script de extração.
                $SQLQueryIdDisk = Invoke-Sqlcmd -query $SQLQuery -ServerInstance $SQLInstance

            #Se o valor for diferênte inserir o valor.
                 
                 $idDisk    = $SQLQueryIdDisk.idDisk 
                 $FreeSpace = $dk.FreeSpaceGB
                 $TotalSize = $dk.DiskSizeGB        

                #Carrega o script com os dados.
                $SQLQuery = "USE $SQLDatabase  
                                SELECT COUNT(*) AS TC
                                FROM [ServerHost].[vw_disk]
                                WHERE ([idSHServidor] = '$IdSrv' AND [Unidade] = '$Unidade')
                                  AND (FreeSpace <> '$FreeSpace' OR TotalSize <> '$TotalSize') "

                #Executar o script de extração.
                $SQLQueryTM = Invoke-Sqlcmd -query $SQLQuery -ServerInstance $SQLInstance
                #Write-Output $SQLQueryTM.TC

                #Se o total for maior que 0 cadastra um o novo valor da unidade.
                IF ($SQLQueryTM.TC -gt 0 ){

                    #Carrega na variável o script de insert com os dados da lista.
                        $SQLQuery = "USE $SQLDatabase
                        INSERT INTO [ServerHost].[DiskTamanho]
                          ([idDisk],[FreeSpace],[TotalSize])
                        VALUES 
                          ('$idDisk','$FreeSpace','$TotalSize');"
            
                        #Executa o script de insert no banco 
                        $SQLQueryOutputInsert = Invoke-Sqlcmd -query $SQLQuery -ServerInstance $SQLInstance
                }    
        }
}