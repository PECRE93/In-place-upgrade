function Get-IpuListeningPortInfo {
    # Listening TCP ports with the name of the owning process.
    [CmdletBinding()]
    param()

    $processNames = @{}
    foreach ($process in (Get-Process -ErrorAction SilentlyContinue)) {
        $processNames[$process.Id] = $process.ProcessName
    }

    $ports = foreach ($connection in (Get-NetTCPConnection -State Listen -ErrorAction Stop)) {
        [pscustomobject]@{
            Port    = [int]$connection.LocalPort
            Process = $processNames[[int]$connection.OwningProcess]
        }
    }
    , @($ports | Sort-Object -Property Port -Unique)
}
