@{
    Id       = 'PRE-001'
    Phase    = 'Pre'
    Title    = 'Supported upgrade path'
    Requires = @('Snapshot.OperatingSystem')
    Test     = {
        param($Context)

        $build = $Context.Snapshot.OperatingSystem.BuildNumber
        $source = Get-IpuServerVersion -BuildNumber $build -Releases $Context.WindowsServer.Releases
        $target = $Context.TargetVersion

        if (-not $source) {
            return @{ Status = 'Fail'; Message = "OS build $build is not a Windows Server LTSC release with a supported upgrade path." }
        }

        $supported = @()
        if ($Context.WindowsServer.UpgradePaths.ContainsKey($source)) {
            $supported = @($Context.WindowsServer.UpgradePaths[$source])
        }
        if ($supported -contains $target) {
            return @{ Status = 'Pass'; Message = "Windows Server $source can be upgraded in place to $target." }
        }

        $alternatives = 'none'
        if ($supported.Count -gt 0) {
            $alternatives = $supported -join ', '
        }
        @{ Status = 'Fail'; Message = "Windows Server $source can't be upgraded in place to $target. Supported targets: $alternatives." }
    }
}
