# Windows Server LTSC releases and their supported in-place upgrade paths (installation media and
# Azure upgrade media). Source: https://learn.microsoft.com/windows-server/get-started/install-upgrade-migrate
@{
    Releases     = @(
        @{ Version = '2012'; Build = 9200 }
        @{ Version = '2012 R2'; Build = 9600 }
        @{ Version = '2016'; Build = 14393 }
        @{ Version = '2019'; Build = 17763 }
        @{ Version = '2022'; Build = 20348 }
        @{ Version = '2025'; Build = 26100 }
    )

    # Source version -> versions it can be upgraded to in place.
    UpgradePaths = @{
        '2012'    = @('2012 R2', '2016')
        '2012 R2' = @('2016', '2019', '2025')
        '2016'    = @('2019', '2022', '2025')
        '2019'    = @('2022', '2025')
        '2022'    = @('2025')
    }
}
