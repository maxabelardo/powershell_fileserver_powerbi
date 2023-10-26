


# Paramentro que o script vai receber para a sua execução.
param (
    [string]$dirStart,
    [int]$recurse
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
Write-Output "Iniciando exploração em: " $dirStart

<#
    #Limpa a tabela de Stage no servidor.
    $SQLQueryDelete = "USE $SQLDatabase
    TRUNCATE TABLE [AD].[STGADUser]"

    #Executa o script caregado na linha acima.
    $SQLQuery1Output = Invoke-Sqlcmd -query $SQLQueryDelete -ServerInstance $SQLInstance
#>

    #Extrai o volume total em giga.
    #$TGb = “{0:N2}” -f ((Get-ChildItem -Path $dirStart -Recurse -Force -ErrorAction SilentlyContinue| Measure-Object Length ).sum / 1Gb)

    #Extrai os meta-dados dos objetos.

    if ($recurse -eq 1){
    $listFiles = Get-ChildItem -Path $dirStart -recurse -Force -ErrorAction SilentlyContinue –ErrorVariable err | 
        Select-Object FullName,
        @{LABEL="Diretorio";Expression={if($_.Mode.Substring(0,2) -Like 'd*'){$_.FullName+"\"} elseif ($_.Mode.Substring(0,2) -Like '-a*'){$_.FullName -Replace($_.Name )  } } }  , 
        Name , CreationTime, lastAccessTime, LastWriteTime, 
        @{Name="Age";Expression={ (((Get-Date) - $_.LastWriteTime).Days) }} , 
        @{Name="Length";Expression={ if($_.Mode.Substring(0,2) -Like 'd*'){ (Get-Childitem -Path $_.FullName -Recurse | Measure-Object -Property Length -s).Sum } elseif ($_.Mode.Substring(0,2) -Like '-a*'){$_.Length} } },
        @{Name="Mode";Expression={ if($_.Mode.Substring(0,2) -Like 'd*'){"Diretorio"} elseif ($_.Mode.Substring(0,2) -Like '-a*'){"Arquivo"}   } } -ErrorAction SilentlyContinue
    }

    if ($recurse -eq 0){
    $listFiles = Get-ChildItem -Path $dirStart -Force -ErrorAction SilentlyContinue  | 
        Select-Object FullName,
        @{LABEL="Diretorio";Expression={if($_.Mode.Substring(0,2) -Like 'd*'){$_.FullName+"\"} elseif ($_.Mode.Substring(0,2) -Like '-a*'){$_.FullName -Replace($_.Name )  } } }  , 
        Name , CreationTime, lastAccessTime, LastWriteTime, 
        @{Name="Age";Expression={ (((Get-Date) - $_.LastWriteTime).Days) }} , 
        @{Name="Length";Expression={ if($_.Mode.Substring(0,2) -Like 'd*'){ (Get-Childitem -Path $_.FullName -Recurse | Measure-Object -Property Length -s).Sum } elseif ($_.Mode.Substring(0,2) -Like '-a*'){$_.Length} } },
        @{Name="Mode";Expression={ if($_.Mode.Substring(0,2) -Like 'd*'){"Diretorio"} elseif ($_.Mode.Substring(0,2) -Like '-a*'){"Arquivo"}   } } -ErrorAction SilentlyContinue
    }


#Aviso na tela:
Write-Output "Iniciando a exploração das permissões dos objetos"

#Variáveis de ambiente.
#Retoma o total de linhas. Observação: cada linha é um objeto, seja diretório ou arquivo.
$ct = $listFiles.Count

#Contador que será usado para o cálculo de porcentagem.
$pg = 1
        
#Contador que armazenará o progresso da análise.
$vt = 0

#Loop: neste ponto do código, o log será iniciado
    ForEach( $lf in $listFiles){

    #Calcula o progresso da analise.
    $vt =  “{0:N2}” -f (($pg / $ct) * 100)

    #Grava os arquivos no banco de dados

        # Gravas os valores da lista na variáveis de transição.

        if ($lf.FullName){      
              $Lipemza    = $lf.FullName
	          $FullName   = $Lipemza.replace("'","")
        }else{
               $FullName  = $lf.FullName
             }	

        if ($lf.Diretorio){      
              $Lipemza    = $lf.Diretorio
	          $Diretorio  = $Lipemza.replace("'","")
        }else{
               $Diretorio = $lf.Diretorio
             }	

        if ($lf.Name){      
              $Lipemza = $lf.Name
	          $Nome    = $Lipemza.replace("'","")
        }else{
               $Name   = $lf.Name
             }	

        $CreationTime   = $lf.CreationTime
        $LastAccessTime = $lf.LastAccessTime
        $LastWriteTime  = $lf.LastWriteTime
        $Age            = $lf.Age
        $Length         = [Math]::Round(($lf.Length/1024/1024), 2 ) 
        $Mode           = $lf.Mode

            #Script que fará a inserção na tabela.
            $SQLQuery = "USE $SQLDatabase
            INSERT INTO [dbo].[arquivosI]
                  ( [FullName], [Diretorio], [Name], [CreationTime], [LastAccessTime], [LastWriteTime], [Age], [Length], [Mode])
            VALUES('$FullName','$Diretorio','$Name','$CreationTime','$LastAccessTime','$LastWriteTime','$Age','$Length','$Mode');"


                #Execução do script carregado logo acima.
                try{
                    $SQLQuery1Output = Invoke-Sqlcmd -query $SQLQuery -ServerInstance $SQLInstance -ErrorAction stop
                }catch{
                    Write-Output $SQLQuery
                throw $_
                break
                } 


    #Imprime na tela o progresso da análise.
   "Progresso: "+ $vt+"% concluido, foram analisados " + $pg +" de "+$ct

    #Contado: cada volta do Loop é somado mais um na variável.
    $pg = $pg + 1 
    }

