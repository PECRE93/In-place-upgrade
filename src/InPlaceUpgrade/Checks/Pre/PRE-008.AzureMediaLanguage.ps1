@{
    Id       = 'PRE-008'
    Phase    = 'Pre'
    Title    = 'OS language matches the Azure upgrade media'
    Requires = @('Snapshot.Azure', 'Snapshot.OperatingSystem')
    Test     = {
        param($Context)

        if (-not $Context.Snapshot.Azure.IsAzureVm) {
            return @{ Status = 'Skipped'; Message = 'Not an Azure VM.' }
        }

        # 1033 = en-US, the only language of the upgrade media that Azure provides.
        $language = $Context.Snapshot.OperatingSystem.OSLanguage
        if ($language -ne 1033) {
            return @{ Status = 'Warning'; Message = "The OS language is LCID $language, but the Azure upgrade media is en-US (1033) only. Set the system language or locale to en-US before upgrading." }
        }
        @{ Status = 'Pass'; Message = 'The OS language is en-US.' }
    }
}
