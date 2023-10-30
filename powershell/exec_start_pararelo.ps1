

#==============================================================================================================================#
# VARIÁVEIS DE AMBIENTE.
#==============================================================================================================================#

# Variável que vai armazenar o local que será analisado.
$dirStart = 'J:\ARQUIVOS PUBLICOS\'

# A letra que será utilizada para definir o nivel da pasta.
$letra = "\"  # Substitua "e" pela letra que deseja contar

#==============================================================================================================================#
# INICIO DOS COMANDOS.
#==============================================================================================================================#

# Comando que vai extrair as pasta do primeiro nivel, será o numero de pasta do primeiro nível que vai definir quantos processos vão ser executado em paralelo.
$listFiles =  Get-ChildItem -Path $dirStart   | Where-Object {$_.Mode.Substring(0,2) -Like "d*"} | select FullName, @{LABEL="Diretorio";Expression={ ($_.FullName -Replace($_.Name )).replace($dirStart,'')   } }

$NivelDiretorio += @("c:\temp\exec_file_server.ps1 -dirStart " +"'"+ $dirStart + "' -recurse 0"   ) 


#Loop que vai encontra as pasta do primeiro nivel e montar os comandos que serão executado em pararelo.
    ForEach( $lf in $listFiles){

        $SubListFiles =  Get-ChildItem -Path $lf.FullName | Where-Object {$_.Mode.Substring(0,2) -Like "d*"} | select FullName, @{LABEL="Diretorio";Expression={ ($_.FullName -Replace($_.Name )).replace($dirStart,'')   } }
        
        # Zera o contador 
        $nivel = 0
        
            #Loop que vai encontra as pasta do primeiro nivel e montar os comandos que serão executado em pararelo.
                ForEach( $sublf in $SubListFiles){
                  $nivel++ 
                }

                if ($nivel -gt 5) {

                $NivelDiretorio += @("c:\temp\exec_file_server.ps1 -dirStart " +"'"+ $lf.FullName + '\'+"' -recurse 0"   ) 
                                   
                    ForEach( $sublf in $SubListFiles){

                    # A variável que vai aramazenar os comandos.
                    $NivelDiretorio += @("c:\temp\exec_file_server.ps1 -dirStart " +"'"+ $sublf.FullName + '\'+"' -recurse 1"   )                    

                    }
                }


                if ($nivel -le 5) {
                    # A variável que vai aramazenar os comandos.
                    $NivelDiretorio += @("c:\temp\exec_file_server.ps1 -dirStart " +"'"+ $lf.FullName + '\'+"' -recurse 1" )                    
                }
    }

    # Loop que vai ler a variável executar os comandos em pararelo.
        ForEach($nd in $NivelDiretorio){
        
            Start-Job -ScriptBlock {
                param($cmd)
                Invoke-Expression $cmd
            } -ArgumentList $nd
            
            #Write-Host $nd    
            #.\exec_file_server.ps1 -dirStart $nd
        }
                # Aguarda a conclusão de todos os trabalhos
                While (Get-Job -State "Running") {
                    Start-Sleep -Milliseconds 500
                }

                    # Obtém os resultados de cada trabalho
                    Get-Job | Receive-Job

                        # Limpa todos os trabalhos
                        Get-Job | Remove-Job

 
#Comando para limpar a variável.
$NivelDiretorio = $null