<# Using Module C:\GIT\EPV-API\Source\Classes\Logging.psm1
Using module C:\GIT\EPV-API\Source\Classes\RestCall.psm1
Using module C:\GIT\EPV-API\Source\Classes\PASObject.psm1
Using Module C:\GIT\EPV-API\Source\Classes\Safe.psm1
Using Module C:\GIT\EPV-API\Source\Classes\Safemember.psm1
Using Module C:\GIT\EPV-API\Source\Classes\PSMRecording.psm1
Using Module C:\GIT\EPV-API\Source\Classes\PSMRecordingList.psm1 #>

#$import-module 'C:\GIT\epv-api\Output\EPV-API-Module\EPV-API-Module.psd1' -verbose -Force

(Get-Module restcall).path

[logging]::OutputVerbose = $false
[logging]::OutputDebug = $false

(New-Object -TypeName PASObject).ConfigurePAS("https://pvwa.lab.local/passwordvault")
(New-Object -TypeName PASObject).Logon([pscredential]::new('administrator', ('Cyberark1!' | ConvertTo-SecureString -AsPlainText -Force)), "CyberARk")
"CyberArk Auth Header: $((New-Object -TypeName PASObject).AuthHeader|ConvertTo-Json)"


(New-Object -TypeName PASObject).ConfigureOAuth2( "https://aal4797.my.idaptive.app","https://servicesum.privilegecloud.cyberark.cloud/passwordvault")
(New-Object -TypeName PASObject).Logon([pscredential]::new('bborsoauth@cyberark.cloud.1024', ('Cyberark1!Cyberark1!' | ConvertTo-SecureString -AsPlainText -Force)), "OAuth2")
"CyberArk OAuth2 Header: $((New-Object -TypeName PASObject).AuthHeader|ConvertTo-Json)"
<# Write-Host -ForegroundColor Cyan "Safe-Get" 
[safe]::Get("babtest")
Write-Host -ForegroundColor Cyan "Safe-Find" 
[safe]::Find("babtest","","")

Write-Host -ForegroundColor Cyan "Safemember-get"
[SafeMember]::get("babtest")
Write-Host -ForegroundColor Cyan "Safemember-get With Member"
[SafeMember]::get("babtest", "PasswordManager")
Write-Host -ForegroundColor Cyan "Safemember-find"
[SafeMember]::find("babtest","memberType eq user","PasswordManager","0","")
 #>
#$Testinfo = ([PASObject]::InvokeGet("$([pasobject]::URL_Base)/API/Recordings?limit=1000&sort=PSMStartTime")).Recordings
#$recordingsClear()

<# $Testinfo | ForEach-Object { 
        $recordingsadd($([PSMRecording]::New([PSCustomObject]$PSItem))) }
 #>
$Recordings = New-Object -TypeName PSMRecordingList

$Recordings.DownloadLocation = "C:\\DownloadTest\\"
$Recordings.ReportName = "C:\\DownloadTest\\Report.csv"

Get-ChildItem $($Recordings.DownloadLocation)| Remove-Item -Force
if (Test-Path $($Recordings.ReportName)) {
    Remove-Item $($Recordings.ReportName) -Force
}



#SSH
#$recordingsPSMRecordings[69].Download()
#Keystrokes
#$recordingsPSMRecordings[48].Download()
#$Recordings.AmountOfJobs = 1
#$Recordings.AmountOfJobs = 10
$Recordings.AmountOfJobs = 25
#$Recordings.AmountOfJobs = 50
#$Recordings.AmountOfJobs = 100
[PSMRecordingListSearchParms]$TestList = @{
    Limit = "100"
    Sort  = "AccountUserName"
    Safe = "PSMRecordings"
} 
$Recordings.GatherRecordings($TestList)
$recordings.DownloadAll()
$Recordings.GatherAllRecordings()
#(New-Object -TypeName PSMRecordingList).downloadall()
$recordings.Download("1")
$recordings.DownloadAll()

Write-Host "Done" -BackgroundColor Red
exit 0

build-Module "C:\GIT\Migrate Usages\Source\" -OutputDirectory "C:\GIT\Migrate Usages\Output\Migrate Usages\" -Verbose

"Loaded"

. ([scriptblock]::Create('Using Module C:\GIT\EPV-API\Source\Classes\Logging.psm1
Using module C:\GIT\EPV-API\Source\Classes\RestCall.psm1
Using module C:\GIT\EPV-API\Source\Classes\PASObject.psm1
Using Module C:\GIT\EPV-API\Source\Classes\Safe.psm1
Using Module C:\GIT\EPV-API\Source\Classes\Safemember.psm1
Using Module C:\GIT\EPV-API\Source\Classes\PSMRecording.psm1
Using Module C:\GIT\EPV-API\Source\Classes\PSMRecordingList.psm1
Write-Host "Loaded"'))