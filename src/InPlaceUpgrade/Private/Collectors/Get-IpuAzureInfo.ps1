function Get-IpuAzureInfo {
    # Asks the Azure Instance Metadata Service (IMDS) whether this is an Azure VM.
    [CmdletBinding()]
    param()

    $request = [System.Net.WebRequest]::Create('http://169.254.169.254/metadata/instance/compute?api-version=2021-02-01')
    $request.Headers.Add('Metadata', 'true')
    # IMDS doesn't support proxies, so always connect directly.
    $request.Proxy = New-Object -TypeName System.Net.WebProxy
    $request.Timeout = 3000

    try {
        $response = $request.GetResponse()
    }
    catch {
        Write-Verbose -Message "Azure Instance Metadata Service not reachable, so not an Azure VM: $($_.Exception.Message)"
        return [pscustomobject]@{
            IsAzureVm  = $false
            ResourceId = $null
            VmSize     = $null
            Location   = $null
            Zone       = $null
        }
    }

    try {
        $reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $response.GetResponseStream()
        $compute = $reader.ReadToEnd() | ConvertFrom-Json
    }
    finally {
        $response.Close()
    }

    [pscustomobject]@{
        IsAzureVm  = $true
        ResourceId = Get-IpuProperty -InputObject $compute -Name 'resourceId'
        VmSize     = Get-IpuProperty -InputObject $compute -Name 'vmSize'
        Location   = Get-IpuProperty -InputObject $compute -Name 'location'
        Zone       = Get-IpuProperty -InputObject $compute -Name 'zone'
    }
}
