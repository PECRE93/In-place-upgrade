@{
    Id       = 'POST-001'
    Phase    = 'Post'
    Title    = 'Upgraded to the target version'
    Requires = @('Snapshot.OperatingSystem')
    Test     = {
        param($Context)

        $os = $Context.Snapshot.OperatingSystem
        $current = Get-IpuServerVersion -BuildNumber $os.BuildNumber -Releases $Context.WindowsServer.Releases
        if ($current -ne $Context.TargetVersion) {
            return @{ Status = 'Fail'; Message = "Expected Windows Server $($Context.TargetVersion), but the server runs $($os.Caption) (build $($os.BuildNumber))." }
        }
        @{ Status = 'Pass'; Message = "The server runs $($os.Caption) (build $($os.BuildNumber))." }
    }
}
