using Module .\PASObject.psm1
using Module .\Logging.psm1
using Module .\RestCall.psm1

[NoRunspaceAffinity()]
class PSMRecording :PASObject {
    # Class properties
    [string]$SessionID
    [string]$SessionGuid
    [string]$SafeName
    hidden [string]$_Start
    hidden [string]$_End
    [datetime]$Start
    [datetime]$End
    [string]$User
    [string]$RemoteMachine
    [string]$AccountUsername
    [string]$AccountAddress
    [string]$AccountPlatformID
    [string]$ConnectionComponentID
    [string]$FromIP
    [bool] $ProtectionEnabled
    [PSCustomObject]$RecordingFiles
    hidden static [string]$DownloadLocation 
    hidden static [string]$ReportName 


    # Default constructor
    PSMRecording() { $this.Init(@{}) 
    }
    # Convenience constructor from hashtable
    PSMRecording([pscustomobject]$Properties) { 
        [logging]::WriteVerbose("Creating PSMRecording object: SessionID:`"$($Properties.SessionID)`" SessionGuid: `"$($Properties.SessionGuid)`"")
        $this.Init($Properties) 
        [logging]::WriteVerbose("Succesfully created PSMRecording object:: SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
    }
    # Shared initializer method
    [void] Init([pscustomobject]$PSCustom) {
        $this.SetGet()
        foreach ($Property in $PSCustom.psobject.properties.name) {
            if ([bool]($this.PSobject.Properties.name -match $Property)) {
                $this.$Property = $PSCustom.$Property
                
            }
        }
    }
    
    hidden [datetime] GetDateTimeFromEpoch([string]$Epoch) {
        [datetime]$Begin = '1970-01-01 00:00:00'
        Return $Begin.AddSeconds($Epoch)
    }
    hidden [void] SetGet() {
        [datetime]$This._Start = [datetime]$($this | Add-Member -Force ScriptProperty 'Start' `
            {
                # get
                $([datetime]$this._Start)
            }`
            {
                # set
                param ( $arg )
                [datetime]$this._Start = [datetime]$This.GetDateTimeFromEpoch($arg)
            }
        )
        [datetime]$This._End = [datetime]$($this | Add-Member -Force ScriptProperty 'End' `
            {
                # get
                $([datetime]$this._End)
            }`
            {
                # set
                param ( $arg )
                [datetime]$this._End = [datetime]$This.GetDateTimeFromEpoch($arg)
            }
        ) 
    }

    hidden [void] WriteCSV($data) {
        $Written = $false
        $Report = $false
        While (!$Written) {
            Try {
                $data | Export-Csv -Append "$([PSMRecording]::ReportName)"
                $Written = $true
                If ($Report) {
                    [logging]::WriteDebug("After Error, was able to succesfully writing session information to index file.`"$($This.SessionGuid)`" SessionGuid: `"$($This.SessionGuid)`"")
                }
            } catch {
                $report = $true
                [logging]::WriteDebug("Error writing session information to index file. Sleeping and retrying SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
                Start-Sleep -Milliseconds 100
            }
        }
    }
    hidden [void] WriteActivites($data, $filename) {
        $Written = $false
        $Report = $false
        While (!$Written) {
            Try {
                If ([string]::IsNullOrEmpty($($data.Offsets))) {
                    $data | Out-File $filename -Force
                } else {
                    $data | Select-Object -Property ActivityText -ExpandProperty Offsets | Out-File $filename -Force
                }
                $Written = $true
                If ($Report) {
                    [logging]::WriteDebug("After Error, was able to succesfully writing activites to file.`"$($This.SessionGuid)`" SessionGuid: `"$($This.SessionGuid)`"")
                }
            } catch {
                $report = $true
                [logging]::WriteDebug("Error writing activites to file. Sleeping and retrying SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
                Start-Sleep -Milliseconds 100
            }
        }
    }

    [void] Download() {
<#         Try { #>
            [logging]::WriteDebug("Proccessing SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
            $this.RecordingFiles | ForEach-Object {
                If ($PSItem.Format -in @("VID")) {
                    [logging]::WriteDebug("`"$($PSitem.Format)`" file found. SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
                    $filename = "$([PSMRecording]::DownloadLocation)\$($this.SessionGuid).$($PSItem.Format).avi"
                    If (Test-Path $filename) {
                        [logging]::WriteDebug("File with name `"$Filename`" found. Skipping")
                        [logging]::WriteDebug("Download Skipped for SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
                        return
                    }
                    $type = $PSItem.Format
                    [logging]::WriteDebug("`"$($PSitem.Format)`" file download started. SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
                    $this.InvokePostOut("$([pasobject]::URL_Base)/API/Recordings/$($this.SessionID)/Play/", $filename) 
                    [logging]::WriteDebug("`"$($PSitem.Format)`" download Completed. SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
                    [logging]::WriteDebug("`"$($PSitem.Format)`" writing file to index file. SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
                    $This.WriteCsv( $($this | Select-Object -Property "User", "AccountUSername", "AccountAddress", "AccountPlatformID", "ConnectionComponentID", "FromIP", "Start", "End", "SessionID", @{n = "Type"; e = { $type } }, @{n = "Filename"; e = { $filename } }, @{n = "Downloaded"; e = { $(Get-Date -Format 'u') } },"SafeName"))
                    [logging]::WriteDebug("`"$($PSitem.Format)`" writing file to index file. SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
                }
                If ($PSItem.Format -in @("SSH", "WIN", "Keystrokes","Audits")) {
                    [logging]::WriteDebug("`"$($PSitem.Format)`" file found. SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
                    $filename = "$([PSMRecording]::DownloadLocation)\$($this.SessionGuid).$($PSItem.Format).txt"
                    If (Test-Path $filename) {
                        [logging]::WriteDebug("File with name `"$Filename`" found. Skipping")
                        [logging]::WriteDebug("Download Skipped for SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
                        return
                    }
                    $type = $PSItem.Format
                    [logging]::WriteDebug("`"$($PSitem.Format)`" file download started. SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
                    [PSCustomObject]$activities = $this.InvokeGet("$([pasobject]::URL_Base)/API/Recordings/$($this.SessionID)/activities/").Activities
                    [logging]::WriteDebug("`"$($PSitem.Format)`" download Completed. SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
                    [logging]::WriteDebug("`"$($PSitem.Format)`" file review started. SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
                    If ( $activities.count -ne 0 ) {
                        [logging]::WriteDebug("`"$($PSitem.Format)`" file contains acitivies. Saving to file. SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
                        $This.WriteActivites($activities, $filename)
                        [logging]::WriteDebug("`"$($PSitem.Format)`" file saved. SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
                    } else {
                        $message = "Download sucessful but no activites found for SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`""
                        [logging]::WriteDebug($message)
                        $This.WriteActivites($message, $filename)
                    }
                    $This.WriteCsv( $($this | Select-Object -Property "User", "AccountUSername", "AccountAddress", "AccountPlatformID", "ConnectionComponentID", "FromIP", "Start", "End", "SessionID", @{n = "Type"; e = { $type } }, @{n = "Filename"; e = { $filename } }, @{n = "Downloaded"; e = { $(Get-Date -Format 'u') } },"SafeName"))
                }
                If ($PSItem.Format -notin @("SSH", "WIN", "Keystrokes","VID","Audits")){
                    [logging]::WriteError("Missing Format Found: $($PSItem.Format)")
                }
            }
            [logging]::WriteDebug("Proccessing completed succesfully for SessionID:`"$($This.SessionID)`" SessionGuid: `"$($This.SessionGuid)`"")
<#         } catch { 
            [logging]::WriteError("Error proccessing `"$($This.SessionGuid)`" SessionGuid: `"$($This.SessionID)`"")
            [logging]::WriteError("StackTrace: `n$($psitem.ScriptStackTrace)")
            [logging]::WriteVerbose("Error: $($psitem |ConvertTo-Json)")
            Throw $psitem.InvocationInfo
        } #>
    }
}