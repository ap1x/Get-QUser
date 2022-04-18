function Get-QueryUser {

<#
.SYNOPSIS
Get local or remote user sessions

.DESCRIPTION
Get local or remote user sessions as PSCustomObjects which can be used in the pipeline. Can optionally logoff the returned sessions, or just get computers with no user sessions. This Cmdlet is a wrapper for the Windows "query user" command to improve usability with PowerShell.

.PARAMETER ComputerName

.PARAMETER UserNameContains
Get sessions with a UserName that contains this string

.PARAMETER Active
Get sessions with a State of Active

.PARAMETER Disconnected
Get sessions with a State of Disconnected

.PARAMETER Idle
Get sessions with an IdleTime value

.PARAMETER Logoff
Display the returned sessions as a table and prompt to logoff sessions (no objects are sent to the pipeline)

.PARAMETER Vacant
Get computers that have no sessions

.OUTPUTS
PSCustomObject
#>

[CmdletBinding()]
Param(
	[Parameter(Position=0, Mandatory, ParameterSetName="Vacant")]
	[Parameter(Position=0, ParameterSetName="Idle")]
	[Parameter(Position=0, ParameterSetName="Disconnected")]
	[Parameter(Position=0, ParameterSetName="Active")]
	[Parameter(Position=0, ParameterSetName="Any")]
	[string[]]$ComputerName,

	[Parameter(Position=1, ParameterSetName="Active")]
	[Parameter(Position=1, ParameterSetName="Disconnected")]
	[Parameter(Position=1, ParameterSetName="Idle")]
	[Parameter(Position=1, ParameterSetName="Any")]
	[string]$UserNameContains,

	[Parameter(Mandatory, ParameterSetName="Active")]
	[switch]$Active,

	[Parameter(Mandatory, ParameterSetName="Disconnected")]
	[switch]$Disconnected,

	[Parameter(Mandatory, ParameterSetName="Idle")]
	[switch]$Idle,

	[Parameter(ParameterSetName="Active")]
	[Parameter(ParameterSetName="Disconnected")]
	[Parameter(ParameterSetName="Idle")]
	[Parameter(ParameterSetName="Any")]
	[switch]$Logoff,

	[Parameter(Mandatory, ParameterSetName="Vacant")]
	[switch]$Vacant
)

$RemoteScript = {
	$CompName = hostname
	$UserLogonLines = quser 2>&1
	
	if($UserLogonLines -like 'No user exists for*') { return }

	$UserLogonLines | foreach {
		$_ -replace '^ +' `
		-replace '>' `
		-replace '^([^ ]+) +([0-9]+)', '$1  .  $2' `
		-replace '  +', ','
	} | ConvertFrom-Csv | foreach {
		[PSCustomObject]@{
			ComputerName = $CompName
			UserName = $_.USERNAME
			SessionName = $_.SESSIONNAME -replace '\.'
			ID = [int]$_.ID
			State = $_.STATE -replace 'Disc', 'Disconnected'
			IdleTime = $_.'IDLE TIME' -replace '\.' -replace 'none'
			LogonTime = $_.'LOGON TIME' | Get-Date -Format 'MM/dd/yyyy HH:mm'
		}
	}
}

$InvokeCommandArgs = @{ ScriptBlock = $RemoteScript }
if($ComputerName) { $InvokeCommandArgs += @{ ComputerName = $ComputerName } }

$UserLogons = Invoke-Command @InvokeCommandArgs | Select-Object -Property * -ExcludeProperty PSComputerName,RunspaceId

if($UserNameContains) {
	$UserLogons = $UserLogons | Where-Object { $_.UserName -like "*$UserNameContains*" }
}
if($Active) {
	$UserLogons = $UserLogons | Where-Object { $_.State -eq 'Active' }
}
if($Disconnected) {
	$UserLogons = $UserLogons | Where-Object { $_.State -eq 'Disconnected' }
}
if($Idle) {
	$UserLogons = $UserLogons | Where-Object { $_.IdleTime }
}
if($Vacant) {
	$VacantComputers = @()
	$ComputerName | foreach {
		if(!($UserLogons | Where-Object ComputerName -eq $_)) {
			$VacantComputers += $_
		}
	}
	$VacantComputers
	return
}
if($Logoff) {
	$UserLogons | Format-Table
	$reply = Read-Host -Prompt 'Logoff the sessions listed above? [y/n]'
	if($reply -eq 'y') {
		$UserLogons | foreach {
			$SessionID = $_.ID
			Invoke-Command -ComputerName $_.ComputerName -ScriptBlock { logoff $using:SessionID }
		}
	}
	return
}

$UserLogons
}

New-Alias -Name Get-QUser -Value Get-QueryUser

Export-ModuleMember -Function * -Alias *
