# not added into module - just wanted to get this down whilst it was still in my head 
# needs proper help and proper parameters
# needs try catch
# needs shouldprocess added
# Ready for more comments and suggestions
# Need to validate for monthyear or year but not have both?

function Get-DBABackupThroughPut
{
param (
[object]$Server,
[object]$database,
[ValidatePattern(“(?# SHOULD BE 2 digits hyphen 4 digits)\d{2}-\d{4}”)]
[string]$MonthYear,
[ValidatePattern(“(?# SHOULD BE 4)\d{4}”)]
[string]$Year)
# Load SMO extension
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | Out-Null;
$all = $true
## Probably should take an array of servers?
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $Server
$Results = @()
foreach($db in $srv.Databases)
{
# filters for Fulland Diff Backups
$Results +=  $db.EnumBackupSets()|Where-Object{$_.BackupSetType -ne 3 -and (($_.BackupFinishDate - $_.BackupStartDate).totalseconds -gt 1)} |Select DatabaseName,Name,BackupStartDate,BackupFinishDate,BackupSize,BackupSetType 
}
# Backp Throughput calc from Brent Ozar blog 
$TPexp = @{Name='ThroughPut';Expression = {($_.BackupSize/($_.BackupFinishDate - $_.BackupStartDate).totalseconds)/1048576 }}
if($database)
{
$All = $false
$a = $Results|Where-Object {$_.DatabaseName -eq $database} | Select $TPexp, DatabaseName,Name,BackupStartDate,BackupFinishDate,BackupSize,BackupSetType 
$database =$a[0].DatabaseName
}
if($all)
{
$a = $Results | Select $TPexp, DatabaseName,Name,BackupStartDate,BackupFinishDate,BackupSize,BackupSetType 
$database = 'All'
}
if($MonthYear)
{
[int]$Month,[int]$Year = $MonthYear.Split('-')
$a = $a | Where-Object {($_.BackupFinishDate).Month -eq $Month -and ($_.BackupFinishDate).Year -eq $Year}
}
If($Year)
{
$a = $a | Where-Object {($_.BackupFinishDate).Year -eq $Year}
}
$Throughput =  $a|Measure-Object -Property 'ThroughPut' -Sum -Average -Maximum -Minimum
$BackupDate = $a|Measure-Object -Property 'BackupFinishDate' -Maximum -Minimum

$Return = [pscustomobject]@{Instance = $Server;
Database = $database
MinDate = $BackupDate.Minimum;
MaxDate = $BackupDate.Maximum; 
MaxThroughPut = $Throughput.Maximum;
MinThroughPut = $Throughput.Minimum;
AvgThroughPut = $Throughput.Average }

$MaxDate = $BackupDate.Maximum
$MinDate = $BackupDate.Minimum
Write-Output "$Server has managed a backup throughput in Mb/sec between $MinDate and $MaxDate of :- "

Return $Return
}
 