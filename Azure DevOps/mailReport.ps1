param (
    $veracodeAppName,
    $veracodeID,
    $veracodeAPIkey,
    $contaAlerta,
    $contaEmail,
    $SenhaEmail
)

# Bibliotecas funções
function Send-VeracodeReport {
    param (
        $caminhoRelatorio,
        $To = "mail@dominio.com.br",
        $contaEmail = "mail@dominio.com.br",
        $SenhaEmail = "suasenhaApp"
    )

    try {
        # Credencial
        $Password = ConvertTo-SecureString "$SenhaEmail" -AsPlainText -Force
        $credencialMail = New-Object System.Management.Automation.PSCredential ($contaEmail, $Password)

        # Com base no nome do arquivo recebe os dados do App e o Build
        $stringInfo = $caminhoRelatorio.Split("\App-")[1]
        $veracodeAppName = $stringInfo.Split("-")[0]
        $BuildVersion = $stringInfo.Split("-")[1] -replace (".pdf", "")

        # Envia o e-mail
        Send-MailMessage `
            -To $To `
            -Subject "Veracode Report - App $veracodeAppName - Build: $BuildVersion" `
            -Body "Segue em anexo o relatorio detalhado no ultimo scan do perfil $veracodeAppName" `
            -BodyAsHtml `
            -Priority high `
            -UseSsl `
            -Port 587 `
            -SmtpServer 'smtp.gmail.com' `
            -From $contaEmail `
            -Credential $credencialMail `
            -Attachments $caminhoRelatorio
        Write-Host "Enviado o relatorio: App $veracodeAppName - Build: $BuildVersion"
    }
    catch {
        $ErrorMessage = $_.Exception.Message # Recebe o erro
        Write-Host "Erro ao enviar o relatorio:"
        Write-Host "$ErrorMessage"
    }
    
}

function Get-VeracodeReport {
    param (
        $veracodeAppName
    )
    
    # Recebe o App ID com base no nome da aplicacao dentro do Veracode
    [xml]$INFO = $(VeracodeAPI.exe -vid $veracodeID -vkey $veracodeAPIkey -action GetAppList | Select-String -Pattern $veracodeAppName)
    # Filtra o App ID
    $appID = $INFO.app.app_id

    try {
        # Pega o ID da build
        [xml]$buildINFO = $(VeracodeAPI.exe -vid $veracodeID -vkey $veracodeAPIkey -action getbuildinfo -appid $appID)
        $buildID = $buildINFO.buildinfo.build_id
        $BuildVersion = $buildINFO.buildinfo.build.version
        $caminhoRelatorio = "$env:LOCALAPPDATA\App-$veracodeAppName-$BuildVersion.pdf"
        # Gera o relatorio
        $out = VeracodeAPI.exe -vid $veracodeID -vkey $veracodeAPIkey -action DetailedReport -buildid "$buildID" -format pdf -outputfilepath "$caminhoRelatorio"
        return $caminhoRelatorio
    }
    catch {
        $ErrorMessage = $_.Exception.Message # Recebe o erro
        Write-Host "Erro ao gerar o relatorio:"
        Write-Host "$ErrorMessage"
    }
}

# Faz o processo de envio
$caminhoRelatorio = Get-VeracodeReport $veracodeAppName
Send-VeracodeReport $caminhoRelatorio $contaAlerta $contaEmail $SenhaEmail