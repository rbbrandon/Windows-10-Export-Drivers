Write-Output "Checking if script has been run as admin..."
$UserIsAdmin = ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent() `
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($UserIsAdmin) {
    Write-Output "User has admin rights. Continuing...`n"
} else {
    Write-Output "User does not have admin rights. Re-launching as admin..`n"

    try {
        Start-Process "powershell.exe" -Argument "-ExecutionPolicy Bypass -File ""$($MyInvocation.MyCommand.Definition)""" -Verb RunAs -WorkingDirectory $PSScriptRoot -ErrorAction Stop
    } catch {
        Write-Error $_.Exception.Message
        cmd /c pause
    }
    Exit
}

function Convertto-SanitisedFolderName {
    [CmdletBinding()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$FolderName=$(Throw "Folder name required.")
    ) # End param

    ($FolderName -replace '[<>:"/\\|?*]', '_').TrimStart(" ").TrimEnd(". ")
}

Write-Output "Getting Computer Information..."
$Computer   = Get-WmiObject -Class:Win32_ComputerSystem
$OSVersion  = [System.Environment]::OSVersion.Version
$OSName     = "Windows NFI"
if ($OSVersion -gt [System.Version]"10.0.0.0") {
    $OSName = "Windows 10"
} elseif ($OSVersion -gt [System.Version]"6.2.0.0") {
    $OSName = "Windows 8"
} elseif ($OSVersion -gt [System.Version]"6.1.0.0") {
    $OSName = "Windows 7"
}
$OSArch     = if ([System.Environment]::Is64BitOperatingSystem) { "x64" } else { "x86" }

$DriverPath = "$PSScriptRoot\Drivers\$OSName\$OSArch\$(Convertto-SanitisedFolderName $Computer.Manufacturer)\$(Convertto-SanitisedFolderName $Computer.Model)"
$DriverPath = $DriverPath.Replace(":\\", ":\")

if ($OSName -eq "Windows 7") {
    Write-Warning "Windows 7 is currently not supported with this script"
    cmd /c pause
    Exit
}

if (Test-Path $DriverPath) {
    Remove-Item $DriverPath -Recurse -Force | Out-Null
}
New-Item -ItemType Directory -Path $DriverPath -Force | Out-Null
Write-Output "  Done."

Write-Output "Extracting Windows Drivers to $DriverPath.."
$ExportedDrivers = Export-WindowsDriver -Online -Destination $DriverPath
Write-Output "  Done."

Write-Output "Organising drivers into subfolders..."
foreach ($Driver in $ExportedDrivers) {
    $ParentFolder = Split-Path -Path (Split-Path -Path $Driver.OriginalFileName -Parent) -Leaf

    if ($Driver.ClassName -eq "Printer") {
        # Delete Printer Drivers.
        Remove-Item "$DriverPath\$ParentFolder" -Recurse -Force
    } else {
        # Keep and organise non-printer drivers.
        $Destination  = "$DriverPath\$(Convertto-SanitisedFolderName $Driver.ClassName)\$(Convertto-SanitisedFolderName $Driver.ProviderName)"

        New-Item -ItemType Directory -Path $Destination -Force | Out-Null

        try {
            Move-Item "$DriverPath\$ParentFolder" $Destination -ErrorAction Stop
        } catch {
            Write-Output "  Move Failed!!"
            Write-Output "Source     : $DriverPath\$ParentFolder"
            Write-Output "Destination: $Destination"
            Write-Output "Driver Details:"
            $Driver
        }
    }
}
Write-Output "  Done."
Write-Output "Script Complete."
cmd /c pause

# SIG # Begin signature block
# MIIOCgYJKoZIhvcNAQcCoIIN+zCCDfcCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUaSgQU4AmStTi83w802XCDvrB
# Q66gggtAMIIFWDCCBECgAwIBAgIRANbR9t85tWrnJ+iKzqzAWuIwDQYJKoZIhvcN
# AQELBQAwfTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3Rl
# cjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0ZWQx
# IzAhBgNVBAMTGkNPTU9ETyBSU0EgQ29kZSBTaWduaW5nIENBMB4XDTE4MDcxNjAw
# MDAwMFoXDTIxMDcxNTIzNTk1OVowgZcxCzAJBgNVBAYTAkFVMQ0wCwYDVQQRDAQz
# ODQwMREwDwYDVQQIDAhWaWN0b3JpYTEQMA4GA1UEBwwHTW9yd2VsbDEVMBMGA1UE
# CQwMNDIgQnJpZGxlIFJkMRcwFQYDVQQKDA5LdXJuYWkgQ29sbGVnZTELMAkGA1UE
# CwwCSVQxFzAVBgNVBAMMDkt1cm5haSBDb2xsZWdlMIIBIjANBgkqhkiG9w0BAQEF
# AAOCAQ8AMIIBCgKCAQEA0QOsD4Ns5mP1ZhpSV3e1g07wEgnmZxblNYU3swmEMmWn
# d3J3NoWBBZ9JjtUE8bqU0wGbnGX1uL1wZf8lJENg7Mr/svWD54j//hJhi+rwEy7+
# 9VWwlVPSOarlowIKEgqwWuaF/8Zplnrd3mWdjMdryd0YB3XDqKjpduodY+mijoBe
# 2ktfWwY4wypcpi3Q3/Utjnb9rF8P1wOR8SbYZpRNK6WulvE1V2Y53i3m7uh3Xnvf
# SSxwF2gJK1Z39HAMpU3DZ6F7f5pJPxXfj99LcEn0HzxDmWvWqHRWYWn6pHz3EJKw
# sIt4h5JPiO25Too3aP/BuCnZZWfHskIZo9IUpqLkWwIDAQABo4IBtjCCAbIwHwYD
# VR0jBBgwFoAUKZFg/4pN+uv5pmq4z/nmS71JzhIwHQYDVR0OBBYEFOeG/DmQ3gXI
# RMz721h2pvI/eSGKMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMDMBEGCWCGSAGG+EIBAQQEAwIEEDBGBgNVHSAEPzA9MDsG
# DCsGAQQBsjEBAgEDAjArMCkGCCsGAQUFBwIBFh1odHRwczovL3NlY3VyZS5jb21v
# ZG8ubmV0L0NQUzBDBgNVHR8EPDA6MDigNqA0hjJodHRwOi8vY3JsLmNvbW9kb2Nh
# LmNvbS9DT01PRE9SU0FDb2RlU2lnbmluZ0NBLmNybDB0BggrBgEFBQcBAQRoMGYw
# PgYIKwYBBQUHMAKGMmh0dHA6Ly9jcnQuY29tb2RvY2EuY29tL0NPTU9ET1JTQUNv
# ZGVTaWduaW5nQ0EuY3J0MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9j
# YS5jb20wJwYDVR0RBCAwHoEca3VybmFpLmNvQGVkdW1haWwudmljLmdvdi5hdTAN
# BgkqhkiG9w0BAQsFAAOCAQEAM6PkEcqIM/M+FkGzQIG99hXKPQ2qxvKIfd2jyNkt
# 3XnLBwsCl6CwWnILiu/BB9ud49JTf1hBfQ1K/aSBL/c/hIrJ3A5S39udY70pZr6+
# w9JC8UJMTQsGpdrxaT0YPw3wWo2h3ZewX0WCgBL0hEUY88vZ+uRTeXSNS+nS0niP
# GbdHV3j035UUHGFXNUOheTCu2J8mWK9V5iBLZBAjTpeIEZyCae6lbtx2spbEB6Cd
# Bl56Yl3h4MwyzkZjnhYEo2FHUhQlwtAz4MjR9wK3mxq8XDoZ5uOP2TLXzmjL1Ty2
# ZLX+yL5K0Ut7Sc//xD6vJPNbd8qvyQOOTqlgCfHuIvwXPjCCBeAwggPIoAMCAQIC
# EC58h8wOk0pS/pT9HLfNNK8wDQYJKoZIhvcNAQEMBQAwgYUxCzAJBgNVBAYTAkdC
# MRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQx
# GjAYBgNVBAoTEUNPTU9ETyBDQSBMaW1pdGVkMSswKQYDVQQDEyJDT01PRE8gUlNB
# IENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTEzMDUwOTAwMDAwMFoXDTI4MDUw
# ODIzNTk1OVowfTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hl
# c3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09NT0RPIENBIExpbWl0
# ZWQxIzAhBgNVBAMTGkNPTU9ETyBSU0EgQ29kZSBTaWduaW5nIENBMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAppiQY3eRNH+K0d3pZzER68we/TEds7li
# Vz+TvFvjnx4kMhEna7xRkafPnp4ls1+BqBgPHR4gMA77YXuGCbPj/aJonRwsnb9y
# 4+R1oOU1I47Jiu4aDGTH2EKhe7VSA0s6sI4jS0tj4CKUN3vVeZAKFBhRLOb+wRLw
# HD9hYQqMotz2wzCqzSgYdUjBeVoIzbuMVYz31HaQOjNGUHOYXPSFSmsPgN1e1r39
# qS/AJfX5eNeNXxDCRFU8kDwxRstwrgepCuOvwQFvkBoj4l8428YIXUezg0HwLgA3
# FLkSqnmSUs2HD3vYYimkfjC9G7WMcrRI8uPoIfleTGJ5iwIGn3/VCwIDAQABo4IB
# UTCCAU0wHwYDVR0jBBgwFoAUu69+Aj36pvE8hI6t7jiY7NkyMtQwHQYDVR0OBBYE
# FCmRYP+KTfrr+aZquM/55ku9Sc4SMA4GA1UdDwEB/wQEAwIBhjASBgNVHRMBAf8E
# CDAGAQH/AgEAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBEGA1UdIAQKMAgwBgYEVR0g
# ADBMBgNVHR8ERTBDMEGgP6A9hjtodHRwOi8vY3JsLmNvbW9kb2NhLmNvbS9DT01P
# RE9SU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5LmNybDBxBggrBgEFBQcBAQRlMGMw
# OwYIKwYBBQUHMAKGL2h0dHA6Ly9jcnQuY29tb2RvY2EuY29tL0NPTU9ET1JTQUFk
# ZFRydXN0Q0EuY3J0MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5j
# b20wDQYJKoZIhvcNAQEMBQADggIBAAI/AjnD7vjKO4neDG1NsfFOkk+vwjgsBMzF
# YxGrCWOvq6LXAj/MbxnDPdYaCJT/JdipiKcrEBrgm7EHIhpRHDrU4ekJv+YkdK8e
# exYxbiPvVFEtUgLidQgFTPG3UeFRAMaH9mzuEER2V2rx31hrIapJ1Hw3Tr3/tnVU
# QBg2V2cRzU8C5P7z2vx1F9vst/dlCSNJH0NXg+p+IHdhyE3yu2VNqPeFRQevemkn
# ZZApQIvfezpROYyoH3B5rW1CIKLPDGwDjEzNcweU51qOOgS6oqF8H8tjOhWn1BUb
# p1JHMqn0v2RH0aofU04yMHPCb7d4gp1c/0a7ayIdiAv4G6o0pvyM9d1/ZYyMMVcx
# 0DbsR6HPy4uo7xwYWMUGd8pLm1GvTAhKeo/io1Lijo7MJuSy2OU4wqjtxoGcNWup
# WGFKCpe0S0K2VZ2+medwbVn4bSoMfxlgXwyaiGwwrFIJkBYb/yud29AgyonqKH4y
# jhnfe0gzHtdl+K7J+IMUk3Z9ZNCOzr41ff9yMU2fnr0ebC+ojwwGUPuMJ7N2yfTm
# 18M04oyHIYZh/r9VdOEhdwMKaGy75Mmp5s9ZJet87EUOeWZo6CLNuO+YhU2WETwJ
# itB/vCgoE/tqylSNklzNwmWYBp7OSFvUtTeTRkF8B93P+kPvumdh/31J4LswfVyA
# 4+YWOUunMYICNDCCAjACAQEwgZIwfTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdy
# ZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEaMBgGA1UEChMRQ09N
# T0RPIENBIExpbWl0ZWQxIzAhBgNVBAMTGkNPTU9ETyBSU0EgQ29kZSBTaWduaW5n
# IENBAhEA1tH23zm1aucn6IrOrMBa4jAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIB
# DDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEE
# AYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUJOJI+XLzWNuZ
# wtGVDJgBpRSvrYowDQYJKoZIhvcNAQEBBQAEggEAAA3B6++CwaMK/psgwucqCkGp
# nMeSatyaVq7CD+bnFPGgvYD39pmQgalKly9xziIG7Ui8O50ztyC9F4Xa2Krmf2kC
# 8K6OFDfT4rUUxxpixQX3IKDrhZf5VbF6/etd3dtpUdH4BSnoNezPvR8Ekq5ABzWC
# yklsyMxiDPuyieRa44i2MzsLDs8CCDekpQ8U86g+HcLPjgjdv5t1Vz9V7+IDCgMo
# SmcuBWYidGZ/TtVl8SOLtuQR2QvmcSpW5hSm7SIpZAK1uN5UdrH6T422WKRAhbWM
# Ihi1DftcLdc7Yx3d/Ci2a3/6mvzgobfGAR8a+dPhyzxI1y5714LoX6mSku9jwg==
# SIG # End signature block
