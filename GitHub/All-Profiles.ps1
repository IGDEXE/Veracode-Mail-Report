function Get-AllVeracodeProfiles {
    $timeBox = Get-Date -format yyyy-MM-dd
    $AppProfilesList = http --auth-type=veracode_hmac GET "https://api.veracode.com/appsec/v1/applications?policy_compliance_checked_after=$timeBox" | ConvertFrom-Json
    $AppProfiles = $AppProfilesList._embedded.applications.guid
    return $AppProfiles
}

function New-VeracodeReport {
    param (
        $AppGuid
    )
    
    try {
        # Get last findings
        $AppReport = http --auth-type=veracode_hmac GET "https://api.veracode.com/appsec/v2/applications/$AppGuid/findings? violates_policy=TRUE" | ConvertFrom-Json
        $AppFindings = $AppReport._embedded.findings

        $FindingsCount = $AppFindings.count
        $findingsLOG = ""
        $findingCurrent = 0
        while($findingCurrent -lt $FindingsCount)
        {
            $nameCWE = $AppFindings.finding_details.cwe.name[$findingCurrent]
            $severity = $AppFindings.finding_details.severity[$findingCurrent]
            $status = $AppFindings.finding_status.status[$findingCurrent]
            $issueID = $AppFindings.issue_id[$findingCurrent]
            $findingsLOG += "Level: $severity - ID: $issueID - CWE: $nameCWE - Status: $status `n"
            $findingCurrent++
        }
        return $findingsLOG
    }
    catch {
        $ErrorMessage = $_.Exception.Message # Recebe o erro
        Write-Host "Erro ao validar o Scan e pegar os dados"
        Write-Host "$ErrorMessage"
    }
}

function Send-VeracodeReport {
    param (
        $veracodeAppName,
        $findingsLOG,
        $To = "$env:MailTo",
        $contaEmail = "$env:MailAccount",
        $SenhaEmail = "$env:MailPass"
    )

    try {
        # Credencial
        $Password = ConvertTo-SecureString "$SenhaEmail" -AsPlainText -Force
        $credencialMail = New-Object System.Management.Automation.PSCredential ($contaEmail, $Password)

        # Envia o e-mail
        Send-MailMessage `
            -To $To `
            -Subject "Veracode Report - $veracodeAppName" `
            -Body "$findingsLOG" `
            -BodyAsHtml `
            -Priority high `
            -UseSsl `
            -Port 587 `
            -SmtpServer 'smtp.gmail.com' `
            -From $contaEmail `
            -Credential $credencialMail `
            -Attachments $caminhoRelatorio
        Write-Host "Enviado o relatorio: App $veracodeAppName"
    }
    catch {
        $ErrorMessage = $_.Exception.Message # Recebe o erro
        Write-Host "Erro ao enviar o relatorio:"
        Write-Host "$ErrorMessage"
    }
    
}

# Get All Veracode Profiles with scan today
$AppList = Get-AllVeracodeProfiles

foreach ($App in $AppList) {
    $findingsLOG = New-VeracodeReport $App
    Send-VeracodeReport "$veracodeAppName" "$findingsLOG"
}