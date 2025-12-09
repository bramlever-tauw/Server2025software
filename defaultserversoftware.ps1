msiexec /i "ElementsAgentOfflineInstaller.msi" VOUCHER= /q
        Execute-MSI -Action Install -Path 'agentInstaller-x86_64.msi' -Parameters "CUSTOMTOKEN=`"eu:62ec816e-0e6c-47fd-8561-b4251879a2cf`" /QN"


param (
    [Parameter(Mandatory = $true)]
    [string]$VOUCHER,

    [Parameter(Mandatory = $true)]
    [string]$CUSTOMTOKEN
)

# === Logging setup ===
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$tempPath = "C:\Temp"
$logPath = "$tempPath\setup_$timestamp.log"
New-Item -ItemType Directory -Path $avdPath -Force | Out-Null
Start-Transcript -Path $logPath

function Write-Log {
    param([string]$message)
    try {
        $message | Add-Content -Path $logPath
    } catch {
        Write-Host "Logfout: $message"
    }
}

Write-Log "[$(Get-Date)] Script gestart"

# === Software installaties ===
$withSecureUrl = "https://raw.githubusercontent.com/bramlever/avd-bicep/main/Microsoft.RDInfra.RDAgent.Installer-x64-1.0.12183.900.msi"
$Rapid7Url = "https://raw.githubusercontent.com/bramlever/avd-bicep/main/Microsoft.RDInfra.RDAgentBootLoader.Installer-x64-1.0.11388.1600.msi"

$WithSecureDest = "$tempPath\ElementsAgentOfflineInstaller.msi"
$Rapid7Dest = "$tempPath\agentInstaller-x86_64.msi"

Invoke-WebRequest -Uri $withSecureUrl -OutFile $agentDest -UseBasicParsing
Invoke-WebRequest -Uri $Rapid7Url -OutFile $bootloaderDest -UseBasicParsing

Start-Process msiexec.exe -ArgumentList "/i `"$WithSecureDest`" VOUCHER=`"$VOUCHER`" /quiet /norestart" -Wait
Start-Process msiexec.exe -ArgumentList "/i `"$Rapid7Dest`" CUSTOMTOKEN=`"$CUSTOMTOKEN`" /quiet /norestart" -Wait

powershell.exe -windowstyle hidden -executionpolicy bypass -file Deploy-Application.ps1 -DeploymentType Install

Write-Log "[$(Get-Date)] Default software geïnstalleerd."
Write-Log "[$(Get-Date)] Script voltooid. VM wordt herstart..."
Stop-Transcript

Restart-Computer -Force
