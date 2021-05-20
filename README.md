# Get-ExternalGroupMembers

This script pulls all group memberships for a given OU and highlights accounts with access that reside outside of the given OU.  By default accounts with administrative privileges are excluded. These are identified by having "adm" in the SamAccountName.

## Basic Usage
```powershell
.\Get-ExternalGroupMembers.ps1 -OUName Atlanta -SearchBase 'dc=mycompany,dc=local'
```
