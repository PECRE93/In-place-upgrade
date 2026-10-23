function Get-IpuServiceInfo {
    [CmdletBinding()]
    param()

    $services = foreach ($service in (Get-CimInstance -ClassName Win32_Service -ErrorAction Stop)) {
        [pscustomobject]@{
            Name        = $service.Name
            DisplayName = $service.DisplayName
            State       = $service.State
            StartMode   = $service.StartMode
        }
    }
    , @($services | Sort-Object -Property Name)
}
