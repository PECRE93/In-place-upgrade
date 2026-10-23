function Get-IpuLicensingInfo {
    [CmdletBinding()]
    param()

    # ApplicationID of Windows in the Software Licensing service.
    $windowsApplicationId = '55c92734-d682-4d71-983e-d6ec3f16059f'
    $product = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "ApplicationID = '$windowsApplicationId' AND PartialProductKey IS NOT NULL" -ErrorAction Stop |
        Select-Object -First 1
    if (-not $product) {
        throw 'No Windows product key is installed.'
    }

    [pscustomobject]@{
        Name          = $product.Name
        Description   = $product.Description
        LicenseStatus = [int]$product.LicenseStatus
    }
}
