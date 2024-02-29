using Module .\RestCall.psm1
using Module .\Logging.psm1
Enum AuthTypes {
    CyberArk
    LDAP
    RADIUS
    Identity
    OAuth2
}
[NoRunspaceAffinity()]
Class PASObject : Restcall {
    #Properties
    static [pscredential]$Credentials
    static [string]$AuthType
    static [string]$URL_Base
    static [string]$URL_Identity = "https://aal4797.my.idaptive.app"
    static [bool]$RestConfigured = $false
    static [datetime]$LogonTime
    static [timespan]$MaxSessionDuration = (New-TimeSpan -Minutes 5)
    static [bool]$NewSessionInProgress = $false
    hidden static [System.Collections.IDictionary]$_AuthHeader
    [System.Collections.IDictionary] $AuthHeader = [PASObject]::_AuthHeader


    static [string] TrimLast($value) {
        return  $value.Substring(0, $value.Length - 1)
    }

    #Region Logon to PAS
    hidden [void] InvokeLogonPAS ([pscredential]$Credentials, [AuthTypes]$AuthType) {
        $URL_Logon = [PASObject]::URL_Base + "/api/auth/$AuthType/Logon"
        $body = [PSCustomObject]@{ 
            username          = $Credentials.username.Replace('\', '')
            password          = $Credentials.GetNetworkCredential().password
            concurrentSession = $true
        }
        $response = $(Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $URL_Logon -Body $($body | ConvertTo-Json -Compress))
        [PASObject]::_AuthHeader = [System.Collections.IDictionary]@{Authorization = "$($response)" }
        [PASObject]::LogonTime = [datetime]::Now
        [PASObject]::AuthType = $AuthType
        [PASObject]::Credentials = $Credentials
    }

    [void] LogonPAS ([pscredential]$Credentials, [AuthTypes]$AuthType) {
        [PASObject]::Credentials = $Credentials
        [PASObject]::AuthType = $AuthType
        if ([string]::IsNullOrEmpty([PASObject]::URL_Base)) {
            Throw "Unable to connect, URL not set"
        }
        [PASObject]::RestConfigured = $true
        $this.InvokeLogonPAS($Credentials, $AuthType)
    }
    [void] LogonPAS ([pscredential]$Credentials, [AuthTypes]$AuthType, [string]$url) {
        [PASObject]::URL_Base = $url
        $this.LogonPAS($Credentials, $AuthType)
    }
    [void] LogonPAS () {
        [logging]::outputVerbose = $true   
        if ([string]::IsNullOrEmpty([PASObject]::URL_Base)) {
            Throw "RestCall URL_Base is not set"
        }
        $this.LogonPAS($(Get-Credential), "CyberArk")
    }
    [void] ConfigurePAS([string]$URL_Base) {
        [PASObject]::URL_Base = $URL_Base
        [PASObject]::RestConfigured = $true
    }
    [void] ConfigurePAS([string]$URL_Base, [string]$logonToken) {
        $this.ConfigurePAS($URL_Base)
        [PASObject]::_AuthHeader = @{Authorization = $logonToken }
    }
    hidden [void] ConfigurePAS([string]$URL_Base, [PSCustomObject]$AuthHeader) {
        $this.ConfigurePAS($URL_Base)
        [PASObject]::_AuthHeader = $AuthHeader
    } 

    #endregion

    #Region Logon to PCloud via OAuth2
    hidden [void] InvokeLogonOAuth2 ([pscredential]$Credentials) {
        If ($([PASObject]::URL_Identity) -notmatch "/oauth2/platformtoken" ) {
            [PASObject]::URL_Identity = "$([PASObject]::URL_Identity)/oauth2/platformtoken"
        }
        
        $URL_Logon = [PASObject]::URL_Identity 
        $body = @{
            grant_type    = "client_credentials"
            client_id     = $Credentials.username.Replace('\', '')
            client_secret = $Credentials.GetNetworkCredential().password
        }
        $response = $(Invoke-RestMethod -Method Post -Uri $URL_Logon -Body $body)
        [PASObject]::_AuthHeader = [System.Collections.IDictionary]@{Authorization = "Bearer $($response.access_token)" }
        [PASObject]::LogonTime = [datetime]::Now
        [PASObject]::AuthType = [AuthTypes]::OAuth2
        [PASObject]::Credentials = $Credentials
    }

    [void] ConfigureOAuth2([string]$URL_Identity, [string]$URL_Base) {
        [PASObject]::URL_Identity = $URL_Identity
        [PASObject]::URL_Base = $URL_Base
        [PASObject]::RestConfigured = $true
    }
    
    #endregion


    hidden [void] InvokeLogonISPSS ([pscredential]$Credentials) {
        [string]$URL_StartAuthentication = "$([PASObject]::URL_Identity)/Security/StartAuthentication"
        [string]$URL_AdvanceAuthentication = "$([PASObject]::URL_Identity)/Security/AdvanceAuthentication"
        [pscustomobject]$Body = @{
            User    = $Credentials.username
            Version = "1.0"
        }
        [pscustomobject]$StartResponse = $(Invoke-RestMethod -Method Post -ContentType "application/json" -Uri $URL_StartAuthentication -Body $body | ConvertTo-Json -Compress) 
        [string]$SesshID = $StartResponse.Result.sessionid  
        [string]$SelectedMechIDUp = ""
        $i = 1
        foreach ($prop in $StartResponse) {
            foreach ($mech in $prop.Result.Challenges.mechanisms) {
                $mechname = $mech.name
                $mechid = $mech.mechanismid
                $i++
                if ($mechname -eq "UP") {
                    $SelectedMechIDUp = $mechid
                }
            }
        } 
        if ([string]::IsNullOrEmpty($SelectedMechIDUp)) {
            Throw "Unable to locate user password authentication"
        }
        $AdvAuthParms = @{
            Action          = "Answer" 
            Answer          = $Credentials.GetNetworkCredential().password 
            MechanismId     = $SelectedMechIDUp
            SessionId       = $SesshID
            PersistentLogin = "true" 
        }
        $AdvResponse = Invoke-RestMethod -Uri $URL_AdvanceAuthentication -Method POST -ContentType "application/json" -Body (ConvertTo-Json($AdvAuthParms)) 
        if ($AdvResponse.success) {
            [PASObject]::_AuthHeader = @{
                Authorization          = "Bearer $($AdvResponse.Result.Token)"
                'X-IDAP-NATIVE-CLIENT' = "true"
            }
            [PASObject]::AuthType = [AuthTypes]::Identity
            [PASObject]::Credentials = $Credentials
        } Else {
            Throw "Authentication failure"
        }
        
    }

    [void] Logon ([pscredential]$Credentials, [AuthTypes]$AuthType) {
        If (![PASObject]::RestConfigured) {
            Throw "Unable to logon due to configuration not being set"
        }
        Switch ($AuthType) {
            "OAuth2" {
                $this.InvokeLogonOAuth2($Credentials)
            }
            "Identity" {
                #TODO
            }
            default {
                $this.LogonPAS($Credentials, $AuthType)
            }
        }
    }

    hidden [void] RefreshLogon() {
        If (![PASObject]::RestConfigured) {
            Throw "Unable to RefreshLogon due to configuration not being set"
        }
        Switch ([PASObject]::AuthType) {
            OAuth2 {
                $this.InvokeLogonOAuth2([PASObject]::Credentials)
            }
            Identity {

            }
            default {
                $this.LogonPAS([PASObject].Credentials, [PASObject].AuthType)
            }
        }
    }

    [PSCustomObject]InvokeRestCall([Microsoft.PowerShell.Commands.WebRequestMethod]$command, [string]$URI, [string]$body, [PSCustomObject]$AuthHeader = [PASObject]::_AuthHeader) {
        if (![PASObject]::RestConfigured) {
            Throw "Rest not configured"
        }
        While ([PASObject]::NewSessionInProgress) {
            Start-Sleep -Seconds 1
        }
        if ([datetime]::Now -gt $([PASObject]::LogonTime) + [PASObject]::MaxSessionDuration) {
            [Logging]::WriteInfo("Max Duration Exceeded")
            [PASObject]::NewSessionInProgress = $true
            Start-Sleep -Seconds .5
            $this.RefreshLogon()
            [PASObject]::NewSessionInProgress = $false
        }
        return [PSCustomObject](New-Object -TypeName RestCall).InvokeRestCall($command, $URI, $body, $AuthHeader)
    }
    
    [PSCustomObject]InvokeRestOutCall([Microsoft.PowerShell.Commands.WebRequestMethod]$command, [string]$URI, [string]$Outfile, [PSCustomObject]$body, [PSCustomObject]$AuthHeader = [PASObject]::_AuthHeader) {
        if (![PASObject]::RestConfigured) {
            Throw "Rest not configured"
        }
        While ([PASObject]::NewSessionInProgress) {
            Start-Sleep -Seconds 1
        }
        if ([datetime]::Now -gt $([PASObject]::LogonTime) + [PASObject]::MaxSessionDuration) {
            [Logging]::WriteInfo("Max Duration Exceeded")
            [PASObject]::NewSessionInProgress = $true
            Start-Sleep -Seconds .5
            $this.RefreshLogonPAS()
            [PASObject]::NewSessionInProgress = $false
        }
        try {
            return [PSCustomObject](New-Object -TypeName RestCall).InvokeRestOutCall($command, $URI, $outfile, $body, $AuthHeader)
        } catch {
            throw $_
        }

    }
    [string]GenURLSearchString([string]$url,[pscustomobject]$URLSearchParms) {
        $base = "$([pasobject]::URL_Base)/$url"
        [string]$add = "?"
        $URLSearchParms.PSObject.Properties | ForEach-Object {
            if (![string]::IsNullOrEmpty($($PSItem.value)) -and 0 -ne $PSItem.value) {
                $add = "$($add)$($PSitem.name)=$($PSItem.value)&"
            }
        }
        If ("?" -ne $add) {
            $base = [pasobject]::trimLast($("$($Base)$($add)"))
        }
        [logging]::WriteDebug("Base = $base")
        return $base
    }
    <# 
    hidden [PSCustomObject]InvokeRestOutCall([string]$command, [string]$URI, [string]$outfile, [string]$body, [PSCustomObject]$AuthHeader = [PASObject]::_AuthHeader) {
        if (![PASObject]::RestConfigured) {
            Throw "Rest not configured"
        }
        While ([PASObject]::NewSessionInProgress) {
            Start-Sleep -Seconds 1
        }
        if ([datetime]::Now -gt $([PASObject]::LogonTime) + [PASObject]::MaxSessionDuration) {
            [Logging]::WriteInfo("Max Duration Exceed")
            [PASObject]::NewSessionInProgress = $true
            Start-Sleep -Seconds .5
            [PASObject]::RefreshLogonPAS()
            [PASObject]::NewSessionInProgress = $false
        }
        [logging]::WriteVerbose("In PASObject:InvokeRestOutCall")
        Try {
            return [PSCustomObject](New-Object -TypeName RestCall).InvokeRestCall($command, $URI, $body, $AuthHeader)
        } catch {
            [logging]::WriteError($PSItem)
            throw $PSItem
        }
    } #>

}