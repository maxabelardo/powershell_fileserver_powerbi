# VARIÁVEIS DE AMBIENTE
$dirStart = 'J:\ARQUIVOS PUBLICOS\'
$letra = "\"

# Função para executar comandos em paralelo
function Execute-CommandInParallel($command) {
    Start-Job -ScriptBlock {
        param($cmd)
        Invoke-Expression $cmd
    } -ArgumentList $command
}

# Função para percorrer os níveis de pastas recursivamente
function Process-Folders($path, $level) {
    $folders = Get-ChildItem -Path $path | Where-Object { $_.PSIsContainer }

    # Recuperar o total de trabalhos em execução
    $jobsEmExecucao = Get-Job | Where-Object { $_.State -eq 'Running' }

    # Obter o número total de trabalhos em execução
    $totalEmExecucao = $jobsEmExecucao.Count

        # Quando o total de jobs em paralelos alcançar 20 jobs o loop é pausado por 30 minutos.
        if ($totalEmExecucao -le 20) {
            Write-Output 'Pausa na extração.'
            Start-Sleep -Seconds 108000
        }

        if ($folders.Count -gt 5) {
            # Se houver mais de 5 subpastas, criar trabalhos em paralelo
            $folders | ForEach-Object {
                $command = "c:\temp\exec_file_server.ps1 -dirStart '$($_.FullName)' -recurse $level"
                Execute-CommandInParallel $command
            }
        } else {
            # Caso contrário, executar em série
            $folders | ForEach-Object {
                $command = "c:\temp\exec_file_server.ps1 -dirStart '$($_.FullName)' -recurse $level"
                Invoke-Expression $command
            }
        }

    # Processar os subníveis
    foreach ($folder in $folders) {
        Process-Folders $folder.FullName ($level + 1)
    }
}

# Executar a função inicialmente no nível 0
Process-Folders $dirStart 0

# Aguardar a conclusão de todos os trabalhos
While (Get-Job -State "Running") {
    Start-Sleep -Milliseconds 500
}

# Limpar todos os trabalhos
Get-Job | Remove-Job
