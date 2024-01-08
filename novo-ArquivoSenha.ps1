param (
    [parameter(position = 0, Mandatory = $True)]
    $senha,
    [parameter(position = 1, Mandatory = $True)]
    $caminho
)
    
try {
    # Cria a chave
    $hash = Get-Date -Format SECddMMyyyyssmm # Cria um identificador com base no dia e hora
    $KeyFile = "$caminho\$hash.key" # Define o caminho do arquivo
    $Key = New-Object Byte[] 32   # Voce pode usar 16 (128-bit), 24 (192-bit), ou 32 (256-bit) para AES
    [Security.Cryptography.RNGCryptoServiceProvider]::Create().GetBytes($Key) # Cria a chave de criptografia
    $Key | Out-File $KeyFile # Salva em um arquivo

    # Cria a senha
    $senha = ConvertTo-SecureString $senha -AsPlainText -Force
    ConvertTo-SecureString $senha -key $Key | Out-File "$caminho\$hash.pass"
    $retorno = $hash
}
catch {
    $ErrorMessage = $_.Exception.Message # Recebe a mensagem de erro
    $retorno = "Erro: $ErrorMessage"
}
return $retorno