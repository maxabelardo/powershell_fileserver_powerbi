# Defina a quantidade mínima de pastas para acionar o paralelismo
$limitePastas = 5

# Defina o caminho do diretório raiz
$dirStart = 'J:\ARQUIVOS PUBLICOS\DF\'

# A letra que será utilizada para definir o nível da pasta
$letra = "\"  # Substitua "e" pela letra que deseja contar

# Obtenha a lista de diretórios de primeiro nível
$listaDiretorios = Get-ChildItem -Path $dirStart | Where-Object { $_.PSIsContainer } | Select-Object -ExpandProperty FullName

# Array para armazenar os jobs
$jobs = @()

foreach ($diretorio in $listaDiretorios) {
    $dirRegex = [regex]::Escape($dirStart)
    $caracteres = ($diretorio -replace $dirRegex, '') -split '\\'  # Obtenha os níveis do diretório
    
    $nivel = 1
    foreach ($caracter in $caracteres) {
        if ($caracter -eq $letra) {
            $nivel++
        }
    }
    Write-Output $diretorio

    # Execute o comando se o número de subpastas for maior que o limite definido
    if ($nivel -gt $limitePastas) {
        $cmd = "c:\temp\exec_file_server.ps1 -dirStart '$diretorio'"

        $job = Start-Job -ScriptBlock {
            param($cmd)
            Invoke-Expression $cmd
        } -ArgumentList $cmd
        $jobs += $job
    }
}

# Aguarde a conclusão de todos os trabalhos
$jobs | Wait-Job

# Obtenha os resultados de cada trabalho
$jobs | ForEach-Object {
    Receive-Job -Job $_
}

# Limpa todos os trabalhos
$jobs | Remove-Job
