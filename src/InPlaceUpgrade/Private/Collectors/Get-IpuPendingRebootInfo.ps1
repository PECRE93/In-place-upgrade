function Get-IpuPendingRebootInfo {
    [CmdletBinding()]
    param()

    $reasons = @()
    if (Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
        $reasons += 'Component Based Servicing'
    }
    if (Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired') {
        $reasons += 'Windows Update'
    }

    $sessionManager = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager' -ErrorAction Stop
    if (Get-IpuProperty -InputObject $sessionManager -Name 'PendingFileRenameOperations') {
        $reasons += 'Pending file rename operations'
    }

    $activeName = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ActiveComputerName' -ErrorAction Stop).ComputerName
    $pendingName = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName' -ErrorAction Stop).ComputerName
    if ($activeName -ne $pendingName) {
        $reasons += 'Computer rename'
    }

    [pscustomobject]@{
        IsPending = $reasons.Count -gt 0
        Reasons   = $reasons
    }
}
