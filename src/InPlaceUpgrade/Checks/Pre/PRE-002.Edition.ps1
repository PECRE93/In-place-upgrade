@{
    Id       = 'PRE-002'
    Phase    = 'Pre'
    Title    = 'Edition can be upgraded'
    Requires = @('Snapshot.OperatingSystem')
    Test     = {
        param($Context)

        $os = $Context.Snapshot.OperatingSystem
        $edition = $os.EditionId

        if ($edition -like 'ServerStorage*') {
            return @{ Status = 'Fail'; Message = "Windows Storage Server editions ($edition) can't be upgraded in place." }
        }
        if ($edition -like '*Eval') {
            return @{ Status = 'Warning'; Message = "$edition is an evaluation edition. Convert it to a licensed edition before upgrading." }
        }

        # Setup can't switch between Server Core and Desktop Experience, so the operator must pick the matching image.
        $image = 'Desktop Experience'
        if ($os.InstallationType -eq 'Server Core') {
            $image = 'Server Core'
        }
        @{ Status = 'Pass'; Message = "$edition ($image). In Setup, select a $image image of the same or a higher edition." }
    }
}
