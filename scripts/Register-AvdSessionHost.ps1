# Installs the AVD agent + bootloader and joins the host pool.
# Token is a protected param so it stays out of run command output.
param(
    [Parameter(Mandatory)]
    [string] $RegistrationToken
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if (Get-Service -Name 'RDAgentBootLoader' -ErrorAction SilentlyContinue) {
    Write-Output 'AVD agent already installed; skipping registration.'
    return
}

$work = Join-Path $env:TEMP 'avd-agent'
New-Item -Path $work -ItemType Directory -Force | Out-Null

$installers = [ordered]@{
    'RDAgent.msi'           = 'https://go.microsoft.com/fwlink/?linkid=2310011'
    'RDAgentBootLoader.msi' = 'https://go.microsoft.com/fwlink/?linkid=2311028'
}

foreach ($file in $installers.Keys) {
    $path = Join-Path $work $file
    Invoke-WebRequest -Uri $installers[$file] -OutFile $path -UseBasicParsing
}

function Install-Msi {
    param([string] $Path, [string[]] $ExtraArgs = @())
    $log = "$Path.log"
    $msiArgs = @('/i', "`"$Path`"", '/quiet', '/norestart', '/l*v', "`"$log`"") + $ExtraArgs
    $proc = Start-Process -FilePath 'msiexec.exe' -ArgumentList $msiArgs -Wait -PassThru
    if ($proc.ExitCode -notin 0, 3010) {
        throw "Install of $Path failed with exit code $($proc.ExitCode). See $log."
    }
}

Install-Msi -Path (Join-Path $work 'RDAgent.msi') -ExtraArgs @("REGISTRATIONTOKEN=$RegistrationToken")
Install-Msi -Path (Join-Path $work 'RDAgentBootLoader.msi')

Start-Service -Name 'RDAgentBootLoader'
Write-Output 'AVD agent installed and session host registered.'
