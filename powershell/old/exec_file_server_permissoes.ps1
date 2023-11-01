

# Paramentro que o script vai receber para a sua execução.
param (
    [string]$dirStart
)
#==============================================================================================================================#
# VARIÁVEIS DE AMBIENTE.
#==============================================================================================================================#
#Instância do banco de dados que será gravado os dados exportados.
$SQLInstance = "s-sebp19"

#Nome da base de dados.
$SQLDatabase = "FileServer"


#==============================================================================================================================#
# INICIO DOS COMANDOS.
#==============================================================================================================================#

#Aviso na tela:
Write-Output "Iniciando exploração de permissões em: " $dirStart


      #Este comando retorna todas a contas de usuários que tem acesso ao diretório que está na variável "$dirStart"
      $listPermission += (Get-Acl -Path $dirStart -ErrorAction SilentlyContinue –ErrorVariable err ).access | 
      Select-Object @{LABEL='Objeto';Expression={$dirStart}},IdentityReference,FileSystemRights,AccessControlType,IsInherited -ErrorAction SilentlyContinue




#Loop: neste ponto do código, o log será iniciado
ForEach( $lp in $listPermission){

    #Calcula o progresso da analise.
    $vt =  “{0:N2}” -f (($pg / $ct) * 100)

    #Grava os arquivos no banco de dados

        # Gravas os valores da lista na variáveis de transição.

        if ($lf.Objeto){      
              $Lipemza = $lf.Objeto
	          $Objeto  = $Lipemza.replace("'","")
        }else{
               $Objeto = $lf.Objeto
             }	

        if ($lf.IdentityReference){      
              $Lipemza            = $lf.IdentityReference
	          $IdentityReference  = $Lipemza.replace("'","")
        }else{
               $IdentityReference = $lf.IdentityReference
             }	

        $FileSystemRights   = $lf.FileSystemRights
        $AccessControlType  = $lf.AccessControlType
        $IsInherited        = $lf.IsInherited


            #Script que fará a inserção na tabela.
            $SQLQuery = "USE $SQLDatabase
            INSERT INTO [dbo].[permissao]
                         ([Objeto],[IdentityReference] ,[FileSystemRights] ,[AccessControlType], [IsInherited])
                  VALUES('$Objeto','$IdentityReference','$FileSystemRights','$AccessControlType','$IsInherited');"


                #Execução do script carregado logo acima.
                try{
                    $SQLQuery1Output = Invoke-Sqlcmd -query $SQLQuery -ServerInstance $SQLInstance -ErrorAction stop
                }catch{
                    Write-Output $SQLQuery
                throw $_
                break
                } 


    #Imprime na tela o progresso da análise.
   "PREMISSÕES - Progresso: "+ $vt+"% concluido, foram analisados " + $pg +" de "+$ct

    #Contado: cada volta do Loop é somado mais um na variável.
    $pg = $pg + 1 
    }
