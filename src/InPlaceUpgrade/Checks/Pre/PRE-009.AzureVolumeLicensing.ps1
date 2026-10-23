@{
    Id       = 'PRE-009'
    Phase    = 'Pre'
    Title    = 'Volume licensing for the Azure upgrade media'
    Requires = @('Snapshot.Azure', 'Snapshot.Licensing')
    Test     = {
        param($Context)

        if (-not $Context.Snapshot.Azure.IsAzureVm) {
            return @{ Status = 'Skipped'; Message = 'Not an Azure VM.' }
        }

        $description = $Context.Snapshot.Licensing.Description
        if ($description -notlike '*VOLUME_KMSCLIENT*') {
            return @{ Status = 'Fail'; Message = "Windows isn't set up for KMS client activation ($description). The Azure upgrade media requires volume licensing: install the KMS client setup key first." }
        }
        @{ Status = 'Pass'; Message = 'Windows uses KMS client (volume) activation.' }
    }
}
