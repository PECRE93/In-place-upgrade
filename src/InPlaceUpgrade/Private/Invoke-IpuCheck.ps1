function Invoke-IpuCheck {
    # Runs the checks of one phase. A check that throws, or lacks the data it needs, gets status Error
    # instead of stopping the run, so one broken check never hides the results of the others.
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Pre', 'Post')]
        [string] $Phase,

        [Parameter(Mandatory)]
        [hashtable] $Context
    )

    $validStatus = @('Pass', 'Warning', 'Fail', 'Skipped')

    foreach ($check in @($script:Checks | Where-Object { $_.Phase -eq $Phase })) {
        try {
            # Requires entries look like 'Snapshot.Services' or 'Baseline.Services'. A section that is $null
            # wasn't collected; a section absent from the baseline was added after the baseline's version.
            $missing = @()
            $notInBaseline = @()
            foreach ($requirement in $check.Requires) {
                $source, $section = $requirement -split '\.', 2
                $data = $Context[$source]
                $property = $null
                if ($null -ne $data) {
                    $property = $data.PSObject.Properties[$section]
                }
                if (-not $property -and $source -eq 'Baseline' -and $null -ne $data) {
                    $notInBaseline += $requirement
                }
                elseif (-not $property -or $null -eq $property.Value) {
                    $missing += $requirement
                }
            }

            if ($missing.Count -gt 0) {
                $outcome = @{ Status = 'Error'; Message = "Required data was not collected: $($missing -join ', ')." }
            }
            elseif ($notInBaseline.Count -gt 0) {
                $outcome = @{ Status = 'Skipped'; Message = "The baseline was created by an older version that didn't collect $($notInBaseline -join ', ')." }
            }
            else {
                $outcome = & $check.Test $Context
                if ($outcome -isnot [hashtable] -or $validStatus -notcontains $outcome['Status']) {
                    throw "The check must return one hashtable with Status $($validStatus -join ', ')."
                }
            }
        }
        catch {
            $outcome = @{ Status = 'Error'; Message = "The check failed: $($_.Exception.Message)" }
        }

        [pscustomobject]@{
            Id      = $check.Id
            Title   = $check.Title
            Status  = $outcome['Status']
            Message = $outcome['Message']
            Details = $outcome['Details']
        }
    }
}
