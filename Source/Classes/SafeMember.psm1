using Module .\Logging.psm1
using Module .\PASObject.psm1
Class SafeMember : PASObject {
    SafeMember() {
    }
    static [PSCustomObject] Find([string]$safename, [string]$filter, [string]$search, [string]$offset=0, [string]$limit=0) {
        $base = "$([SafeMember]::URL_Base)/API/Safes/$safename/members"
        [string]$add = "?"
        If (![string]::IsNullOrEmpty($filter)) {
            $add = "$($add)filter=$filter&"
        }
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
            $base = [SafeMember]::trimLast($("$($Base)$($add)"))
        }
        [logging]::WriteDebug("Base = $base")
        return $([SafeMember]::InvokeGet([string]$base)).value
    }
    static [PSCustomObject] Get([string]$safename) {
        return [SafeMember]::InvokeGet("$([SafeMember]::URL_Base)/API/Safes/$safename/members").value
    }
    static [PSCustomObject] Get([string]$safename, [string]$MemberName) {
        return $([SafeMember]::Get([string]$safename) | Where-Object { $PSItem.MemberName -eq $MemberName })
    }
}