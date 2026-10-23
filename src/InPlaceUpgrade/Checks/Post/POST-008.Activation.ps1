@{
    Id       = 'POST-008'
    Phase    = 'Post'
    Title    = 'Windows is activated'
    Requires = @('Snapshot.Licensing')
    Test     = {
        param($Context)

        # SoftwareLicensingProduct.LicenseStatus 1 = licensed; other values are grace or notification states.
        $status = $Context.Snapshot.Licensing.LicenseStatus
        if ($status -ne 1) {
            return @{ Status = 'Warning'; Message = "Windows isn't activated (license status $status). Check that the server can reach its KMS host (Azure KMS on Azure VMs)." }
        }
        @{ Status = 'Pass'; Message = 'Windows is activated.' }
    }
}
