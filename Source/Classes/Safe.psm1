using Module .\Logging.psm1
using Module .\PASObject.psm1

Class SafeSearchParms {
    [Int32]$Limit = 1000
    [string]$Sort = "PSMStartTime"
    [Int32]$OffSet = 0
    [string]$Search
    [string]$Safe
    [Int32]$FromTime
    [Int32]$ToTime
    [string]$Activities    
}

Class Safe : PASObject {
    Safe() {
    }
    static [PSCustomObject] Find([string]$search, [string]$offset = 0, [string]$limit = 0) {
        $base = "$([Safe]::URL_Base)/API/Safes"
        [string]$add = "?"
        If (![string]::IsNullOrEmpty($search)) {
            $add = "$($add)search=$search&"
        }
        If (![string]::IsNullOrEmpty($offset)) {
            $add = "$($add)offset=$offset&"
        }
        If (![string]::IsNullOrEmpty($limit)) {
            $add = "$($add)limit=$limit&"
        }
        If ("?" -ne $add) {
            $base = "$($Base)$($add)"
        }
        [logging]::WriteDebug("Base = $base")
        return $([Safe]::InvokeGet([string]$base)).value
    }


    static [PSCustomObject] Get([string]$safename) {
        [logging]::WriteDebug('Get($safeName)')
        return [Safe]::get($safename, $false)
    }
    static [PSCustomObject] Get([string]$safename, [bool]$includeAccounts) {
        [logging]::WriteDebug('Get($safeName,$includeAccounts)')
        return [Safe]::get($safename, $includeAccounts, $false)
    }
    static [PSCustomObject] Get([string]$safename, [bool]$includeAccounts, [bool]$useCache) {
        [logging]::WriteDebug('Get($safeName,$includeAccounts,$useCache)')
        $base = "$([Safe]::URL_Base)/API/Safes/$safename/"
        [string]$add = "?"
        If ($includeAccounts) {
            $add = "$($add)includeAccounts=true&"
        }
        If ($useCache) {
            $add = "$($add)useCache=true&"
        }
        If ("?" -ne $add) {
            $base = "$($Base)$($add)"
        }
        [logging]::WriteDebug("Base = $base")
        return $([Safe]::InvokeGet([string]$base))
    }
}