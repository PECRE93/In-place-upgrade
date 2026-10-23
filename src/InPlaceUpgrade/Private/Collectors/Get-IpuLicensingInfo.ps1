function Get-IpuLicensingInfo {
    [CmdletBinding()]
    param()

    # ApplicationID of Windows in the Software Licensing service. Add-ons such as ESU have product keys of their own.
    $windowsApplicationId = '55c92734-d682-4d71-983e-d6ec3f16059f'
    $product = Get-CimInstance -ClassName SoftwareLicensingProduct -Filter "ApplicationID = '$windowsApplicationId' AND PartialProductKey IS NOT NULL AND LicenseIsAddon = FALSE" -ErrorAction Stop |
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
