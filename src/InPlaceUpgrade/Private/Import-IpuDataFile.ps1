function Import-IpuDataFile {
    # Loads a .psd1 data file. Import-PowerShellDataFile needs PowerShell 5.0; this also works on 4.0.
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string] $Path
    )

    $scriptBlock = [scriptblock]::Create((Get-Content -Path $Path -Raw -ErrorAction Stop))
    # Rejects anything but literals, so a data file can never run code.
    $scriptBlock.CheckRestrictedLanguage([string[]]@(), [string[]]@(), $false)
    & $scriptBlock
}
