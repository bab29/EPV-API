enum LogType {
    Info
    Warning
    Error
    Debug 
    Verbose
    Super
    Success
    LogOnly
}

[NoRunspaceAffinity()]
Class Logging {
    static [string]$LogFile = ".\EPV-API.Log"
    static [bool]$WriteToLog = $true
    hidden static [bool]$OutputDebug = $false
    hidden static [bool]$OutputVerbose = $false
    hidden static [bool]$OutputSuper = $false
    hidden static [bool]$OverRideMasking = $false

    Logging() {
    }

    Logging([string]$LogFile) {
        IF (
            Test-Path -PathType -Path $(Split-Path -Parent $LogFile)) {
            [logging]::LogFile = $LogFile
        } else {
            Write-Host -ForegroundColor Red "The path `"$(Split-Path -Parent $LogFile)`" is invaild. Setting log file path to .\EPV-API.log"
            [logging]::LogFile = = "$(Get-Location)\EPV-API.Log"
        }
    }
    static [void] WriteLog([string]$Message, [LogType]$Type, [bool]$AuthHeader, [bool]$SubHeader, [bool]$footer) {
        $ThreadId = [Threading.Thread]::CurrentThread.ManagedThreadId
        $RunspaceId = [runspace]::DefaultRunspace.Id
        $InVerbose = $MyInvocation.BoundParameters["Verbose"].IsPresent
        $InSuper = [logging]::OutputSuper
        if (!$InVerbose -or ([string]::IsNullOrEmpty($InVerbose))) { $InVerbose = [logging]::OutputVerbose
        }
        $InDebug = $MyInvocation.BoundParameters["Debug"].IsPresent
        if (!$InDebug -or ([string]::IsNullOrEmpty($InDebug))) { $InDebug = [logging]::OutputDebug
        }
        $InSuper = [logging]::OutputSuper

        If ([string]::IsNullOrEmpty([logging]::LogFile) -and $(!([string]::IsNullOrEmpty($global:LOG_FILE_PATH)))) {
            [logging]::LogFile = $script:LOG_FILE_PATH = $Global:LOG_FILE_PATH
            Write-Host "No log file path passed or found in the module, setting log file path to the global value of: `"$([logging]::LogFile)`""
        } elseIf ([string]::IsNullOrEmpty([logging]::LogFile) -and [logging]::WriteLog) {
            # User wanted to write logs, but did not provide a log file - Create a temporary file
            [logging]::LogFile = Join-Path -Path $ENV:Temp -ChildPath "$((Get-Date).ToShortDateString().Replace('/','_')).log"
            $script:LOG_FILE_PATH = [logging]::LogFile
            Write-Host "No log file path inputted and no global value found, setting modoule log file path to: `"$([logging]::LogFile)`""
        }
        If ([logging]::Header -and [logging]::WriteLog) {
            "=======================================" | Out-File -Append -FilePath $([logging]::LogFile)
            Write-Host "=======================================" -ForegroundColor Magenta
        } ElseIf ([logging]::SubHeader -and [logging]::WriteLog) {
            "------------------------------------" | Out-File -Append -FilePath $([logging]::LogFile)
            Write-Host "------------------------------------" -ForegroundColor Magenta
        }
        # Replace empty message with 'N/A'
        if ([string]::IsNullOrEmpty($Message)) {
            $Message = "N/A"
        }
        $MessageToWrite = ""
        # Change SecretType if password to prevent masking issues
        $Message = $Message.Replace('"secretType":"password"', '"secretType":"pass"')
        # Mask Passwords
        if ($Message -match '((?:password|credentials|secret|client_secret)\s{0,}["\:=]{1,}\s{0,}["]{0,})(?=([\w`~!@#$%^&*()-_\=\+\\\/|;:\.,\[\]{}]+))') {
            if ([logging]::OverRideMasking) {
                $Warning = @(
                    'Masking of sensitive data is in a disabled state.'
                    'Logs should be securely deleted when no longer needed.'
                    'All exposed credentials should be changed when completed '
                    'For use when debugging only '
                ) -join ' '
                If ($($(Get-Host).UI.PromptForChoice($Warning, 'Are you sure you want to proceed?', @('&Yes'; '&No'), 1))) {
                    $Message = $Message.Replace($Matches[2], "****")
                }
            } else {
                $Message = $Message.Replace($Matches[2], "****")
            }
        }
        # Check the message type
        switch ($Type) {
            { ($_ -eq "Info") -or ($_ -eq "LogOnly") } {
                If ($_ -eq "Info") {
                    Write-Host $Message.ToString() -ForegroundColor $(If ($AuthHeader -or $SubHeader) {
                            "Magenta"
                        } Else {
                            "Gray"
                        })
                }
                $MessageToWrite = "[INFO]`t`t$Message"
                break
            }
            "Success" {
                Write-Host $Message.ToString() -ForegroundColor Green
                $MessageToWrite = "[SUCCESS]`t$Message"
                break
            }
            "Warning" {
                Write-Host $Message.ToString() -ForegroundColor Yellow
                $MessageToWrite = "[WARNING]`t$Message"
                break
            }
            "Error" {
                Write-Host $Message.ToString() -ForegroundColor Red
                $MessageToWrite = "[ERROR]`t`t$Message"
                break
            }
            "Debug" {
                if ($InDebug -or $InVerbose) {
                    Write-Debug -Msg $Message
                    $MessageToWrite = "[Debug]`t`t$Message"
                }
                break
            }
            "Verbose" {
                if ($InVerbose) {
                    Write-Verbose -Msg $Message
                    $MessageToWrite = "[VERBOSE]`t$Message"
                }
                break
            }
            "Super" {
                if ($InSuper) {
                    Write-Verbose -Msg $Message
                    $MessageToWrite = "[SUPER]`t`t$Message"
                }
                break
            }
        }
        If ([logging]::WriteToLog) {
            If (![string]::IsNullOrEmpty($MessageToWrite)) {
                $written = $false
                While (!$written) {
                    Try {
                        "[$(Get-Date -Format "yyyy-MM-dd hh:mm:ss")]`t[Tr$($($ThreadId).ToString().PadLeft(3,"0")) Rs$($($RunspaceId).ToString().PadLeft(3,"0"))]`t$MessageToWrite" | Out-File -Append -FilePath $([logging]::LogFile)
                        $written = $true        
                    } catch {
                    }
                }
            }
        }
        If ($Footer -and [logging]::WriteToLog) {
            "=======================================" | Out-File -Append -FilePath $([logging]::LogFile)
            Write-Host "=======================================" -ForegroundColor Magenta
        }

    }
    static [void] WriteLog([string]$Message, [LogType]$Type, [bool]$AuthHeader, [bool]$SubHeader) {
        [logging]::WriteLog($Message, $Type, $AuthHeader, $SubHeader, $false)
    }
    static [void] WriteLog([string]$Message, [LogType]$Type, [bool]$AuthHeader) {
        [logging]::WriteLog($Message, $Type, $AuthHeader, $false, $false)
    }
    static [void] WriteLog([string]$Message, [LogType]$Type) {
        [logging]::WriteLog($Message, $Type, $false, $false, $false)
    }
    static [void] WriteLogOnly([string]$Message) {
        [logging]::WriteLog($Message, "LogOnly", $false, $false, $false)
    }
    static [void] WriteLog([string]$Message) {
        [logging]::WriteLog($Message, "Info", $false, $false, $false)
    }
    static [void] WriteInfo([string]$Message) {
        [logging]::WriteLog($Message, "Info", $false, $false, $false)
    }
    static [void] WriteWarning([string]$Message) {
        [logging]::WriteLog($Message, "Warning", $false, $false, $false)
    }
    static [void] WriteError([string]$Message) {
        [logging]::WriteLog($Message, "Error", $false, $false, $false)
    }
    static [void] WriteDebug([string]$Message) {
        [logging]::WriteLog($Message, "Debug", $false, $false, $false)
    }
    static [void] WriteVerbose([string]$Message) {
        [logging]::WriteLog($Message, "Verbose", $false, $false, $false)
    }
    static [void] WriteSuperVerbose([string]$Message) {
        [logging]::WriteLog($Message, "Super", $false, $false, $false)
    }


}