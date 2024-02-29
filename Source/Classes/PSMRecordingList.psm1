using Module .\Logging.psm1
using Module .\RestCall.psm1
using Module .\PASObject.psm1
using Module .\PSMRecording.psm1

Class PSMRecordingListSearchParms {
    [Int32]$Limit = 1000
    [string]$Sort = "PSMStartTime"
    [Int32]$OffSet = 0
    [string]$Search
    [string]$Safe
    [Int32]$FromTime
    [Int32]$ToTime
    [string]$Activities    
}

[NoRunspaceAffinity()]
Class PSMRecordingList :PASObject {

    [Int32]$AmountOfJobs = 50
#    [string]$DownloadLocation = "C:\\DownloadTest\\"
#    [string]$ReportName = "C:\GIT\EPV-API\Test.csv"
    [string]$DownloadLocation = ".\"
    [string]$ReportName = ".\Report.csv"

    # property to hold the list of PSMRecording
    [System.Collections.Generic.List[PSMRecording]]$PSMRecordings
    # method to initialize the list of PSMRecording. Called in the other
    # methods to avoid needing to explicit initialize the value.
    [void] Initialize() {
        $this.Initialize($false) 
    }
    [bool] Initialize([bool]$force) {
        if ($this.PSMRecordings.Count -gt 0 -and -not $force) {
            return $false
        }
    
        $this.PSMRecordings = [System.Collections.Generic.List[PSMRecording]]::new()
    
        return $true
    }
    # Ensure a PSMRecording is valid for the list.
    [void] Validate([PSMRecording]$PSMRecording) {
        $Prefix = @(
            'PSMRecording validation failed: PSMRecording must be defined with SessionGuid'
            ' properties, but'
        ) -join ' '
        if ($null -eq $PSMRecording) {
            throw "$Prefix was null" 
        }
        if ([string]::IsNullOrEmpty($PSMRecording.SessionGuid)) {
            throw "$Prefix SessionGuid wasn't defined"
        }
    }
    # methods to manage the list of PSMRecording.
    # Add a PSMRecording if it's not already in the list.
    [void] Add([PSMRecording]$PSMRecording) {
        $this.Initialize()
        $this.Validate($PSMRecording)
        if ($this.PSMRecordings.Contains($PSMRecording)) {
            [logging]::WriteDebug("PSMRecording '$($PSMRecording.SessionGuid)' already in list")
            return
        }
    
        $FindPredicate = {
            param([PSMRecording]$b)
            $b.SessionGuid -eq $PSMRecording.SessionGuid 
        }.GetNewClosure()
        if ($this.PSMRecordings.Find($FindPredicate)) {
            [logging]::WriteDebug("PSMRecording '$($PSMRecording.SessionGuid)'already in list")
            return
        }
        [logging]::WriteVerbose("Adding PSMRecording to PSMRecordingList: SessionID:`"$($PSMRecording.SessionID)`" SessionGuid: `"$($PSMRecording.SessionGuid)`"")
        $this.PSMRecordings.Add($PSMRecording)
        [logging]::WriteVerbose("Succesfully Added PSMRecording to PSMRecordingList: SessionID:`"$($PSMRecording.SessionID)`" SessionGuid: `"$($PSMRecording.SessionGuid)`"")
    }
    # Clear the list of PSMRecording.
    [void] Clear() {
        $this.Initialize()
        $this.PSMRecordings.Clear()
    }
    # Find a specific PSMRecording using a filtering scriptblock.
    [PSMRecording] Find([scriptblock]$Predicate) {
        $this.Initialize()
        return $this.PSMRecordings.Find($Predicate)
    }
    # Find every PSMRecording matching the filtering scriptblock.
    [PSMRecording[]] FindAll([scriptblock]$Predicate) {
        $this.Initialize()
        return $this.PSMRecordings.FindAll($Predicate)
    }
    [PSMRecording[]] IndexOf([scriptblock]$Predicate) {
        $this.Initialize()
        return $this.PSMRecordings.IndexOf($Predicate)
    }
    [PSMRecording[]] IndexOf([PSMRecording]$PSMRecording) {
        $FindPredicate = {
            param([PSMRecording]$b)
        }.GetNewClosure()
        return $this.PSMRecordings.IndexOf($FindPredicate)
    }
    [string] FindBy([string]$Property, [string]$Value) {
        $this.Initialize()
        $Index = $this.PSMRecordings.FindIndex({
                param($b)
                $b.$Property -eq $Value
            }.GetNewClosure())
        if ($Index -ge 0) {
            return $Index
        }
        return $null
    }
    # Remove a specific PSMRecording.
    [void] Remove([PSMRecording]$PSMRecording) {
        $this.Initialize()
        $this.PSMRecordings.Remove($PSMRecording)
    }
    # Remove a PSMRecording by property value.
    [void] RemoveBy([string]$Property, [string]$Value) {
        $this.Initialize()
        $Index = $this.PSMRecordings.FindIndex({
                param($b)
                $b.$Property -eq $Value
            }.GetNewClosure())
        if ($Index -ge 0) {
            $this.PSMRecordings.RemoveAt($Index)
        }
    }

    [void] DownloadAll() {
        $startTime = $(Get-Date)
        [logging]::WriteInfo("Started download of PSM Sessions at $startTime")
        [logging]::WriteInfo("Found $($this.PSMRecordings.count) PSM Sessions")
        [logging]::WriteInfo("Found $($($this.PSMRecordings.RecordingFiles).count) recording files")

        $load = $null
        $(Get-ChildItem -Path $PSScriptRoot -Filter *.psm1).FullName | ForEach-Object {
            $load += "Using Module $PSItem`n"
        }
        $this.PSMRecordings |  ForEach-Object -Parallel {
            . ([scriptblock]::Create($using:Load))
            
            $PSItem.Download()
        } -ThrottleLimit $($this.AmountOfJobs) -AsJob  | Receive-Job -Wait

    
        <#         $this.PSMRecordings |  ForEach-Object {
            $PSItem.Download()
        }  #>
        $endtime = $(Get-Date)
        $diff = $endtime - $startTime
        [logging]::WriteInfo("Completed download of PSM Sessions at $endtime")
        [logging]::WriteInfo("Elapsed time $diff")
    }

    [void] GatherAllRecordings () {
        [PSMRecordingListSearchParms]$URLParms = @{
            Limit = "500"
            Sort  = "PSMStartTime"
        } 
        $this.GatherRecordings($URLParms)
    }

    [void] Download() {
        $this.DownloadAll()
    }

    [void] Download([string]$Recording) {
        $($this.PSMRecordings[$Recording]).Download()
    }

    [void] Download([string[]]$Recording) {
        $Recording | ForEach-Object {
            $($this.PSMRecordings[$PSitem]).Download()
        }
    }

    [void] GatherRecordings([PSMRecordingListSearchParms]$URLSearchParms) {
        $startTime = $(Get-Date)
        [logging]::WriteInfo("Started gathering Sessions at $startTime")
        $restResult = ($this.InvokeGet($this.GenURLSearchString("/API/Recordings", $URLSearchParms)))
        [logging]::WriteLogOnly("Toatl PSM Sessions gathered so far: $($restResult.Recordings.count)")
        While ($restResult.Recordings.Count -lt $restResult.total) {
            $URLSearchParms.Offset = $($restResult.Recordings.count)
            $addRecordings = ($this.InvokeGet($this.GenURLSearchString("/API/Recordings", $URLSearchParms))).Recordings
            If ($addRecordings.count -gt 0) {
                $restResult.Recordings += $addRecordings
                [logging]::WriteLogOnly("Toatl PSM Sessions gathered so far: $($restResult.Recordings.count)")
            }
            else {
                
                Break
            }
        }
        [logging]::WriteLogOnly("Completed gathering PSM Sessions. Total gathered: $($restResult.Recordings.count)")
        [PSMRecording]::DownloadLocation = $this.DownloadLocation
        [PSMRecording]::ReportName = $this.ReportName

        $restResult.Recordings | ForEach-Object { 
            $this.add($([PSMRecording]::New([PSCustomObject]$PSItem))) }
    
        [logging]::WriteLogOnly("Found $($this.PSMRecordings.count) PSM Sessions")
        $endtime = $(Get-Date)
        $diff = $endtime - $startTime
        [logging]::WriteInfo("Completed gathering of PSM Sessions at $endtime")
        [logging]::WriteLogOnly("Elapsed time $diff")
    }


}