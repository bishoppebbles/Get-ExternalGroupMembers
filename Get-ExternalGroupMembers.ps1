<#
.SYNOPSIS
    Identify external accounts with group membership access for a given OU.
.DESCRIPTION
    This script pulls all group memberships for a given OU and highlights accounts with access that reside outside of the given OU.  By default accounts with administrative privileges are excluded. These are identified by having "adm" in the SamAccountName.
.PARAMETER PostName
    The OU name of the post of interest.
.PARAMETER SearchBase
    Specify the domain component (DC) of the distinguised name (DN) for the domain of interest (e.g., 'dc=branch1,dc=business,dc=net').
.PARAMETER IncludeAdminAccounts
    Include administrative accounts in the results as identified with the "adm" string within the SamAccountName.  If a non-administrative has this as well it will be filtered.  If other administrative accounts exist that use a different naming convention these will also be included.
.PARAMETER CsvFile
    Specify the CSV output file name (default: Output.csv).
.EXAMPLE
    Get-ExternalGroupMembers.ps1 -PostName Atlanta -SearchBase 'dc=mycompany,dc=local'
    This command returns any AD account that is not based in Atlanta but has a group membership within the Atlanta OU. The results are output to the 'Output.csv' file.
.NOTES
    Version 1.0 - Last Modified 05 MAY 2021
    Main author: Sam Pursglove
#>

param 
(
    [Parameter(Position=0,
               Mandatory=$true,
               ValueFromPipeline=$false,
               HelpMessage='Enter the Post OU name as listed in Active Directory.')]
    [string]$PostName,
    
    [Parameter(Position=1,
               Mandatory=$true,
               ValueFromPipeline=$false,
               HelpMessage="Enter the full distinguished name where the servers of interest reside (e.g., 'dc=hq,dc=company,dc=com')")]
    [string]$SearchBase,
    
    [Parameter(Mandatory=$false,
               HelpMessage='Include admin accounts in the results. By default any SamAccounName with "adm" in it is excluded.')]
    [switch]$IncludeAdminAccounts,
    
    [Parameter(Mandatory=$false,
               ValueFromPipeline=$false,
               HelpMessage='Set the output CSV filename.')]
    [string]$CsvFile = "Output.csv"
)

function Get-Memberships {
    param (
        [Parameter(Mandatory)]
        $groups
    )

    foreach ($group in $groups) {
        $members = Get-ADGroupMember $group -Recursive | 
            Where-Object {$_.distinguishedName -notlike "*$($PostName)*" -and $_.objectClass -eq 'user'}

        if(-not $IncludeAdminAccounts) {
            $members = $members | Where-Object {$_.SamAccountName -notlike "*adm*"}
        }

        foreach ($member in $members) {
            $output.Add([PSCustomObject]@{
                AccountName = $member.SamAccountName
                AccountOU   = $member.distinguishedName.Split(',')[-4].Split('=')[1]
                Domain      = $member.distinguishedName.Split(',')[-3].Split('=')[1].ToUpper()
                Group       = $group.SamAccountName
            }) > $null
        }
    }
}

$output = New-Object System.Collections.ArrayList
$groups = Get-ADGroup -Filter * -SearchBase "ou=$($PostName),$($SearchBase)"
Get-Memberships $groups
$output | Export-Csv -NoTypeInformation -Path $CsvFile