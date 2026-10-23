function Format-IpuList {
    # Joins items for a result message and truncates long lists; the full list goes in Details.
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [AllowNull()]
        [object[]] $Item,

        [int] $First = 5
    )

    $items = @($Item)
    if ($items.Count -le $First) {
        return ($items -join ', ')
    }
    return ('{0} and {1} more' -f (($items | Select-Object -First $First) -join ', '), ($items.Count - $First))
}
