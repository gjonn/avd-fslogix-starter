# FSLogix + Entra Kerberos settings, run as a VM run command.
# FSLogix is already on the win11 multi-session images so this is just registry.
param(
    [Parameter(Mandatory)]
    [string] $VhdLocation,

    [int] $ProfileSizeMB = 30000
)

$ErrorActionPreference = 'Stop'

function Set-RegValue {
    param([string] $Path, [string] $Name, $Value, [string] $Type = 'DWord')
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

# profile containers
$profiles = 'HKLM:\SOFTWARE\FSLogix\Profiles'
Set-RegValue $profiles 'Enabled'                              1
Set-RegValue $profiles 'VHDLocations'                         @($VhdLocation) 'MultiString'
Set-RegValue $profiles 'VolumeType'                           'VHDX' 'String'
Set-RegValue $profiles 'SizeInMBs'                            $ProfileSizeMB
Set-RegValue $profiles 'IsDynamic'                            1
Set-RegValue $profiles 'DeleteLocalProfileWhenVHDShouldApply' 1
Set-RegValue $profiles 'FlipFlopProfileDirectoryName'         1
Set-RegValue $profiles 'PreventLoginWithFailure'              1
Set-RegValue $profiles 'PreventLoginWithTempProfile'          1
Set-RegValue $profiles 'LockedRetryCount'                     3
Set-RegValue $profiles 'LockedRetryInterval'                  15
Set-RegValue $profiles 'ReAttachRetryCount'                   3
Set-RegValue $profiles 'ReAttachIntervalSeconds'              15

# entra kerberos for azure files
Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters' 'CloudKerberosTicketRetrievalEnabled' 1
Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\AzureADAccount' 'LoadCredKeyFromProfile' 1

# no profile containers for local admins
try {
    Add-LocalGroupMember -Group 'FSLogix Profile Exclude List' -Member 'Administrators' -ErrorAction Stop
}
catch [Microsoft.PowerShell.Commands.MemberExistsException] { }

Write-Output "FSLogix configured with VHDLocations = $VhdLocation"
