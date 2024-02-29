using Module .\Logging.psm1
[NoRunspaceAffinity()]
Class RestCall {

    [System.Collections.IDictionary]$AuthHeader
    static [string]$ContentType = "application/json"
    static [int]$Timeout = 2700
    static [System.Management.Automation.ActionPreference]$ErrAction = "Continue"
    
    hidden [PSCustomObject]InvokeRestCall([Microsoft.PowerShell.Commands.WebRequestMethod]$Method, [string]$URI, [PSCustomObject]$body, [PSCustomObject]$header = $this.AuthHeader) {
        $running = $true
        $count = 1
        While ($running) {
            Try {
                $StatusCodeResult = $null
                $Command = $PSBoundParameters
                $Command.ContentType = [RestCall]::ContentType
                $command.TimeoutSec = [RestCall]::Timeout
                $command.ErrorAction = [RestCall]::ErrAction
                $command.StatusCodeVariable = "StatusCodeResult"
                [logging]::WriteDebug("REST URI: $($Command.URI)")
                [logging]::WriteDebug("REST Body: $($Command.body | ConvertTo-Json)")
                [logging]::WriteVerbose($($Command | ConvertTo-Json))
                $restResponse = Invoke-RestMethod @Command
                [logging]::WriteDebug("Invoke-REST Response StatusCode: $($StatusCodeResult)")
                [logging]::WriteVerbose("Invoke-REST Response: $($restResponse | ConvertTo-Json -Depth 2 -WarningAction SilentlyContinue)")
                [logging]::WriteSuperVerbose("Invoke-REST Response: $($restResponse | ConvertTo-Json -Depth 99)")
                $running = $false
                return [PSCustomObject]$restResponse
            }
            Catch {
                if (5 -gt $count) {
                    [logging]::WriteDebug("On `"$($PSitem.Exception.Response.RequestMessage.Method.Method)`" request with outfile recieved status code `"$($PSItem.Exception.Response.ReasonPhrase)`". Retrying attempt to contact to: $($PSitem.Exception.Response.RequestMessage.RequestUri)")
                    If ([logging]::OutputVerbose) {
                        [logging]::WriteVerbose($($PSitem.Exception.Response | ConvertTo-Json -Depth 3))
                    }
                    $count += 1
                    Start-Sleep -Seconds 1
                    continue
                }
                else {
                    $running = $false      
                    [logging]::WriteError("Error Attempting to contact: $URI")
                    if (![string]::IsNullOrEmpty($body)) {
                        [logging]::WriteError("Body: $body")
                    } 
                    [logging]::WriteSuperVerbose($($PSItem | ConvertTo-Json))
                    return "Error"
                    #Throw $PSitem
                }
            }
        }
        return "Error"
    }
    [PSCustomObject]InvokeRest([Microsoft.PowerShell.Commands.WebRequestMethod]$command, [string]$URI, [PSCustomObject]$body, [PSCustomObject]$AuthHeader) {
        if ($URI -notmatch 'http.*') {
            $Uri = "$($this.URL_Base)\$URI"
        }
        
        return [PSCustomObject]$this.InvokeRestCall($command, $URI, $body, $AuthHeader)
    }
    [PSCustomObject]InvokeRest([Microsoft.PowerShell.Commands.WebRequestMethod]$command, [string]$URI, [PSCustomObject]$body ) {
        return $this.InvokeRest($command, $URI, $body, $this.AuthHeader)
    }
    [PSCustomObject]InvokeRest([Microsoft.PowerShell.Commands.WebRequestMethod]$command, [string]$URI ) {
        return $this.InvokeRest($command, $URI, "", $this.AuthHeader)
    }
    [PSCustomObject]InvokeGet([String]$uri) {
        return $this.InvokeRest("Get", $uri)
    }
    [PSCustomObject]InvokeGet([String]$uri, [PSCustomObject]$body) {
        return $this.InvokeRest("Get", $uri, $body)
    }
    [PSCustomObject]InvokePost([String]$uri) {
        return $this.InvokeRest("Post", $uri)
    }
    [PSCustomObject]InvokePost([String]$uri, [PSCustomObject]$body) {
        return $this.InvokeRest("Post", $uri, $body)
    }
    [PSCustomObject]InvokePatch([String]$uri) {
        return $this.InvokeRest("Patch", $uri)
    }
    [PSCustomObject]InvokePatch([String]$uri, [PSCustomObject]$body) {
        return $this.InvokeRest("Patch", $uri, $body)
    }
    [PSCustomObject]InvokeDelete([String]$uri) {
        return $this.InvokeRest("Delete", $uri)
    }
    [PSCustomObject]InvokeDelete([String]$uri, [PSCustomObject]$body) {
        return $this.InvokeRest("Delete", $uri, $body)
    }


    hidden [PSCustomObject]InvokeRestOutCall([Microsoft.PowerShell.Commands.WebRequestMethod]$Method, [string]$URI, [string]$Outfile, [PSCustomObject]$body, [PSCustomObject]$header = $this.AuthHeader) {
        $running = $true
        $count = 1
        While ($running) {
            Try {
                $StatusCodeResult = $null
                $Command = $PSBoundParameters
                $Command.ContentType = [RestCall]::ContentType
                $command.TimeoutSec = [RestCall]::Timeout
                $command.ErrorAction = [RestCall]::ErrAction
                $command.StatusCodeVariable = "StatusCodeResult"
                [logging]::WriteDebug("REST URI: $($Command.URI)")
                [logging]::WriteDebug("REST Body: $($Command.body | ConvertTo-Json)")
                [logging]::WriteVerbose($($Command | ConvertTo-Json))
                $restResponse = Invoke-RestMethod @Command
                [logging]::WriteDebug("Invoke-REST Response StatusCode: $($StatusCodeResult)")
                [logging]::WriteVerbose("Invoke-REST Response: $($restResponse | ConvertTo-Json -Depth 2 -WarningAction SilentlyContinue)")
                [logging]::WriteSuperVerbose("Invoke-REST Response: $($restResponse | ConvertTo-Json -Depth 99)")
                $running = $false
                return [PSCustomObject]$restResponse
            }
            Catch {
                if (5 -gt $count) {
                    [logging]::WriteDebug("On `"$($PSitem.Exception.Response.RequestMessage.Method.Method)`" request with outfile recieved status code `"$($PSItem.Exception.Response.ReasonPhrase)`". Retrying attempt to contact to: $($PSitem.Exception.Response.RequestMessage.RequestUri)")
                    If ([logging]::OutputVerbose) {
                        [logging]::WriteVerbose($($PSitem.Exception.Response | ConvertTo-Json -Depth 3))
                    }
                    $count += 1
                    Start-Sleep -Seconds 1
                    continue
                }
                else {
                    $running = $false      
                    [logging]::WriteError("Error Attempting to contact: $URI")
                    if (![string]::IsNullOrEmpty($body)) {
                        [logging]::WriteError("Body: $body")
                    } 
                    [logging]::WriteSuperVerbose($($PSItem | ConvertTo-Json))
                    return "Error"
                    #Throw $PSitem
                }
            }
        }
        return "Error"
    }
    [PSCustomObject]InvokeRestOut([Microsoft.PowerShell.Commands.WebRequestMethod]$command, [string]$URI, [string]$outfile, [PSCustomObject]$body, [PSCustomObject]$AuthHeader) {
        if ($URI -notmatch 'http.*') {
            $Uri = "$($this.URL_Base)\$URI"
        }
        return [PSCustomObject]$this.InvokeRestOutCall($command, $URI, $outfile, $body, $AuthHeader)
    }
    [PSCustomObject]InvokeRestOut([Microsoft.PowerShell.Commands.WebRequestMethod]$command, [string]$URI, [string]$outfil, [PSCustomObject]$body ) {
        return $this.InvokeRestOut($command, $URI, $body, $this.AuthHeader)
    }
    [PSCustomObject]InvokeRestOut([Microsoft.PowerShell.Commands.WebRequestMethod]$command, [string]$URI, [string]$outfile) {
        return $this.InvokeRestOut($command, $URI, $outfile, "", $this.AuthHeader)
    }
    [PSCustomObject]InvokeGetOut([String]$uri, [string]$outfile) {
        return $this.InvokeRestOut("Get", $uri, $outfile)
    }
    [PSCustomObject]InvokeGetOut([String]$uri, [string]$outfile, [PSCustomObject]$body) {
        return $this.InvokeRestOut("Get", $uri, $outfile, $body)
    }
    [PSCustomObject]InvokePostOut([String]$uri, [string]$outfile) {
        return $this.InvokeRestOut("Post", $uri, $outfile)
    }
    [PSCustomObject]InvokePostOut([String]$uri, [string]$outfile, [PSCustomObject]$body) {
        return $this.InvokeRestOut("Post", $uri, $outfile, $body)
    }
    [PSCustomObject]InvokePatchOut([String]$uri, [string]$outfile) {
        return $this.InvokeRestOut("Patch", $uri, $outfile)
    }
    [PSCustomObject]InvokePatchOut([String]$uri, [string]$outfile, [PSCustomObject]$body) {
        return $this.InvokeRestOut("Patch", $uri, $outfile, $body)
    }
    [PSCustomObject]InvokeDeleteOut([String]$uri, [string]$outfile) {
        return $this.InvokeRestOut("Delete", $uri, $outfile)
    }
    [PSCustomObject]InvokeDeleteOut([String]$uri, [string]$outfile, [PSCustomObject]$body) {
        return $this.InvokeRestOut("Delete", $uri, $outfile, $body)
    }

























    <# 

    hidden [PSCustomObject]InvokeRestOutCall([Microsoft.PowerShell.Commands.WebRequestMethod]$Method, [string]$URI, [string]$outfile, [PSCustomObject]$body, [PSCustomObject]$header = $this.AuthHeader) {
        [logging]::WriteDebug("In InvokeRestOutCall $uri")
        $Command = $PSBoundParameters
        $Command.ContentType = [RestCall]::ContentType
        $command.TimeoutSec = [RestCall]::Timeout
        $command.ErrorAction = [RestCall]::ErrAction
        [logging]::WriteVerbose($($Command | ConvertTo-Json))
        $running = $true
        $count = 1
        While ($running) {
            Try {
                Invoke-RestMethod @Command
                $running = $false
            } Catch {
                if (5 -gt $count) {
                    [logging]::WriteError("Retrying attempting to contact: $URI")
                    $count += 1
                    Start-Sleep -Seconds 1
                    continue
                } else {
                    [logging]::WriteError($PSItem)
                    $running = $false
                }
            }
        }
        Return @{}
    }

    [PSCustomObject]InvokeRestOut([string]$command, [string]$URI, [string]$outfile, [string]$body, [PSCustomObject]$AuthHeader ) {
        if ($URI -notmatch 'http.*') { $Uri = "$($this.URL_Base)\$URI"
        }
        return $this.InvokeRestOutCall($command, $URI, $outfile, $body, $AuthHeader)
    } 
    [PSCustomObject]InvokeRestOut([string]$command, [string]$URI, [string]$outfile, [string]$body ) {
        return $this.InvokeRestOut($command, $URI, $outfile, $body, $this.AuthHeader)
    }
    [PSCustomObject]InvokeRestOut([string]$command, [string]$URI, [string]$outfile ) {
        return $this.InvokeRestOut($command, $URI, $outfile, "", $this.AuthHeader)
    }

    [PSCustomObject]InvokeGetOut([String]$uri, [string]$outfile) {
        return $this.InvokeRestOut("Get", $uri, $outfile)
    }
    [PSCustomObject]InvokeGetOut([String]$uri, [string]$outfile, [PSCustomObject]$body) {
        return $this.InvokeRestOut("Get", $uri, $outfile, $body)
    }
    [PSCustomObject]InvokePostOut([String]$uri, [string]$outfile) {
        return $this.InvokeRestOut("Post", $uri, $outfile)
    }
    [PSCustomObject]InvokePostOut([String]$uri, [string]$outfile, [PSCustomObject]$body) {
        return $this.InvokeRestOut("Post", $uri, $outfile, $body)
    }
    [PSCustomObject]InvokePatchOut([String]$uri, [string]$outfile) {
        return $this.InvokeRestOut("Patch", $uri, $outfile)
    }
    [PSCustomObject]InvokePatchOut([String]$uri, [string]$outfile, [PSCustomObject]$body) {
        return $this.InvokeRestOut("Patch", $uri, $outfile, $body)
    }
    [PSCustomObject]InvokeDeleteOut([String]$uri, [string]$outfile) {
        return $this.InvokeRestOut("Delete", $uri, $outfile)
    }
    [PSCustomObject]InvokeDeleteOut([String]$uri, [string]$outfile, [PSCustomObject]$body) {
        return $this.InvokeRestOut("Delete", $uri, $outfile, $body)
    } #>
}
