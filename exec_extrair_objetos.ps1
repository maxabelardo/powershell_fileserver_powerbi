# Tabela temporária que vai receber a hierarquia do endereço fornecido.
$Nivel = @()

# Variáveis com os valores iniciais
$TotalLetra = 'J:\ARQUIVOS PUBLICOS\DF\DFGE\DFGE\Apresentações Aeroportos - Encontro de Executivos 2018\Desempenho do Aeroporto SBBV - Encontro de Executivos INFRAERO 2018 45 anos - Copia.pptx'
$Diretorio = $TotalLetra
$fullname = $TotalLetra
$Dir = ''
$Divisa = 0
$Name = $null
$idNivel = 1
$idPai = $null


while ($TotalLetra.Length -gt 0) {

    # Localiza a posição da divisa no diretório
    $Divisa = $Diretorio.IndexOf('\')    
    # Extrair a parte do endereço localizada pela divisa
    if ($TotalLetra.Length -gt 1) {
        $Name = $Diretorio.Substring(0, $Divisa + 1 )
    } else {
        $Name = $Diretorio
        $TotalLetra = 0
    }

    $Dir += $Name

    # Inserir os dados no array $Nivel
    $NivelEntry = [PSCustomObject]@{
        idNivel = $idNivel
        idPai = $idPai
        diretorio = $Dir
        fullname = $fullname
        Dname = $Name
    }    



    Write-Output $idNivel

}    