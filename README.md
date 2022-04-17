# Get-QUser

Get local or remote user sessions as PSCustomObjects which can be used in the pipeline. Can optionally logoff the returned sessions, or just get computers with no user sessions. This Cmdlet is a wrapper for the Windows "query user" command to improve usability with PowerShell.

## Example output

  PS C:\Windows\system32> Get-QUser | Format-Table
  
  ComputerName UserName  SessionName ID State        IdleTime LogonTime
  ------------ --------  ----------- -- -----        -------- ---------
  excomputer   exuser1   rdp-tcp#11   2 Active                4/14/2022 8:01:00 AM
  excomputer   exuser2                3 Disconnected 2+03:33  4/12/2022 9:21:00 PM
