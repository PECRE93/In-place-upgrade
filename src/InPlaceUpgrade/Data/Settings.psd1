# Policy for the checks. Change it through a pull request so every result can be traced to a version.
@{
    # PRE-003: free space (GB) required on the system drive before upgrading.
    MinimumSystemDriveFreeGB = 32

    # POST-002: automatic services (wildcards allowed) that stop by themselves or are removed by newer versions.
    IgnoredServices          = @(
        'BITS'
        'clr_optimization_*'
        'edgeupdate'
        'gupdate'
        'MapsBroker'
        'RemoteRegistry'
        'sppsvc'
        'tiledatamodelsvc'
        'wuauserv'
    )

    # POST-003: roles and features (wildcards allowed) that newer versions removed or merged, such as the 2012 R2
    # GUI features (an installation option since 2016) and PowerShell-V2 (removed in Windows Server 2025).
    IgnoredFeatures          = @(
        'Desktop-Experience'
        'InkAndHandwritingServices'
        'PowerShell-V2'
        'Server-Gui-Mgmt-Infra'
        'Server-Gui-Shell'
        'User-Interfaces-Infra'
        'Windows-Defender-Features'
        'Windows-Defender-Gui'
        'XPS-Viewer'
    )

    # POST-004: TCP ports that don't have to listen after the upgrade.
    IgnoredPorts             = @()

    # POST-007: applications (wildcards allowed) that the upgrade may rename or remove.
    IgnoredApplications      = @()
}
