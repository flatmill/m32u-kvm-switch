# SPDX-License-Identifier: MIT
# See LICENSE.txt for more information.

# Register m32u-kvm-switch.ps1 script for startup
#
# SYNTAX
#   setup.ps1 [ -Install -IPAddr <string> -MacAddr <string> | -Uninstall ]
#
# e.g.)
#   Install:
#       setup.ps1 -Install -IPAddr 192.168.0.255 -MacAddr 12-34-56-AB-CD-EF
#
#   Uninstall:
#       setup.ps1 -Uninstall
#
#   Invoke startup directory
#       setup.ps1

param (
    [switch]$Install,
    [switch]$Uninstall,
    [string]$IPAddr,
    [string]$MacAddr

)

$scriptPath = $(Resolve-Path "./m32u-kvm-switch.ps1")
$shortcutFilename = "startup-m32u-kvm-switch.lnk"
$workingDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$userProperty = $(Get-ItemProperty 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders')
$startupDirectory = $UserProperty.Startup
$shortcutFilePath = $(Join-Path -Path $startupDirectory -ChildPath $shortcutFilename)
$isExistShortcutFile = $(Test-Path $shortcutFilePath)

if ($Install) {
    if ($isExistShortcutFile) {
        Write-Host "ERROR: Startup shortcut file already exists."
    } else {
        # Check target IP Address
        if ([string]::IsNullOrEmpty($IPAddr)) {
            Write-Output "ERROR: -IPAddr option is required."
            exit 1
        } else {
            try {
                $ipTest = [ipaddress]$IPAddr
            } catch {
                Write-Output "ERROR: $IPAddr is not an IP address."
                exit 1
            }
        }
        # Check target MAC Address
        if ([string]::IsNullOrEmpty($MacAddr)) {
            Write-Output "ERROR: -MacAddr option is required."
            exit 1
        } else {
            if ($MacAddr -match '^([0-9a-fA-F]{2})[-: ]?([0-9a-fA-F]{2})[-: ]?([0-9a-fA-F]{2})[-: ]?([0-9a-fA-F]{2})[-: ]?([0-9a-fA-F]{2})[-: ]?([0-9a-fA-F]{2})$') {
                $macAddress = $Matches[1].ToUpper() + "-" + $Matches[2].ToUpper() + "-" + $Matches[3].ToUpper() + "-" + $Matches[4].ToUpper() + "-" + $Matches[5].ToUpper() + "-" + $Matches[6].ToUpper()
            } else {
                Write-Output "ERROR: $MacAddr is not a MAC address."
                exit 1
            }
        }
        # Create shortcut
        $ws = New-Object -ComObject WScript.Shell
        $shortcut = $ws.CreateShortcut($shortcutFilePath)
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.WorkingDirectory = $workingDirectory
        $shortcut.Arguments = "-WindowStyle Hidden -NoProfile -NoLogo -ExecutionPolicy Unrestricted -File $scriptPath -Notify -IPAddr $IPAddr -MacAddr $macAddress"
        $shortcut.WindowStyle = 7 # Minimize
        $shortcut.Save()
        Write-Host "Installed startup shortcut file: $shortcutFilePath"
    }
} elseif ($Uninstall) {
    if ($isExistShortcutFile) {
        Remove-Item $shortcutFilePath
        Write-Host "Uninstalled startup shortcut file: $shortcutFilePath"
    } else {
        Write-Host "ERROR: Startup shortcut file not found."
    }
} else {
    Invoke-Item $startupDirectory
}
