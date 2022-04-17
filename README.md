# QueryUser

Get local or remote user sessions as PSCustomObjects which can be used in the pipeline. Can optionally logoff the returned sessions, or just get computers with no user sessions. This Cmdlet is a wrapper for the Windows "query user" command to improve usability with PowerShell.

## Example output

    PS C:\Windows\system32> Get-QueryUser | Format-Table
    
    ComputerName UserName SessionName ID State        IdleTime LogonTime
    ------------ -------- ----------- -- -----        -------- ---------
    excomputer   exuser1  rdp-tcp#11   2 Active                03/27/2022 08:06
    excomputer   exuser2               3 Disconnected 4+19:03  04/01/2022 14:20
    excomputer   exuser3               3 Disconnected 2:10     04/11/2022 09:37
