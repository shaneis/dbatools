function Get-DbaSqlInstanceProperty {
    <#
.SYNOPSIS
Gets SQL Instance properties of one or more instance(s) of SQL Server.

.DESCRIPTION
 The Get-DbaSqlInstanceProperty command gets SQL Instance properties from the SMO object sqlserver.

.PARAMETER SqlInstance
SQL Server name or SMO object representing the SQL Server to connect to. This can be a collection and recieve pipeline input to allow the function
to be executed against multiple SQL Server instances.

.PARAMETER SqlCredential
PSCredential object to connect as. If not specified, current Windows login will be used.

.PARAMETER Silent
Use this switch to disable any kind of verbose messages

.NOTES
Author: Klaas Vandenberghe (@powerdbaklaas)
Website: https://dbatools.io
Copyright: (C) Chrissy LeMaire, clemaire@gmail.com
License: GNU GPL v3 https://opensource.org/licenses/GPL-3.0

.LINK
https://dbatools.io/Get-DbaSqlInstanceProperty

.EXAMPLE
Get-DbaSqlInstanceProperty -SqlInstance localhost
Returns SQL Instance properties on the local default SQL Server instance

.EXAMPLE
Get-DbaSqlInstanceProperty -SqlInstance sql2, sql4\sqlexpress
Returns SQL Instance properties on default instance on sql2 and sqlexpress instance on sql4

.EXAMPLE
'sql2','sql4' | Get-DbaSqlInstanceProperty
Returns SQL Instance properties on sql2 and sql4

#>
	[CmdletBinding(DefaultParameterSetName = "Default")]
	Param (
		[parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $True)]
		[Alias("ServerInstance", "SqlServer")]
		[DbaInstanceParameter[]]$SqlInstance,
		[System.Management.Automation.PSCredential]$SqlCredential,
		[switch]$Silent
	)

	PROCESS {		
		foreach ($instance in $SqlInstance) {
			try {
				$server = Connect-SqlInstance -SqlInstance $instance -SqlCredential $sqlcredential
			}
			catch {
				Stop-Function -Message "Failed to connect to: $instance" -ErrorRecord $_ -Target $instance -Continue -Silent $Silent
			}
            $props = $server.properties
            foreach ( $prop in $props )
            {
            	Add-Member -InputObject $prop -MemberType NoteProperty -Name ComputerName -value $server.NetName
				Add-Member -InputObject $prop -MemberType NoteProperty -Name InstanceName -value $server.ServiceName
				Add-Member -InputObject $prop -MemberType NoteProperty -Name SqlInstance -value $server.DomainInstanceName
                Select-DefaultView -InputObject $prop -Property ComputerName, InstanceName, Name, Value
            } #foreach property
		} #foreach instance
	} #process
} #function