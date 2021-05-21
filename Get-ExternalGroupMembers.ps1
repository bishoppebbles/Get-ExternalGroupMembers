<#
.SYNOPSIS
    Identify external accounts with group membership access for a given OU.
.DESCRIPTION
    This script pulls all group memberships for a given OU and highlights accounts with access that reside outside of the given OU.  By default accounts with administrative privileges are excluded. These are identified by having "adm" in the SamAccountName.
.PARAMETER OUName
    The OU name of interest.
.PARAMETER SearchBase
    Specify the domain component (DC) of the distinguised name (DN) for the domain of interest (e.g., 'dc=branch1,dc=business,dc=com').
.PARAMETER IncludeAdminAccounts
    Include administrative accounts in the results as identified with the "adm" string within the SamAccountName.  If a non-administrative account has this as well it will be filtered.  If other administrative accounts exist that use a different naming convention these will also be included.
.PARAMETER CsvFile
    Specify the CSV output file name (default: Output.csv).
.EXAMPLE
    Get-ExternalGroupMembers.ps1 -OUName Atlanta -SearchBase 'dc=mycompany,dc=local'
    This command returns any AD account that is not based in the Atlanta OU but has a group membership within the Atlanta OU. The results are output to the 'Output.csv' file.
.NOTES
    Version 1.02 - Last Modified 05 MAY 2021
    Author: Sam Pursglove
    Inspiration: Michael Latham
#>

param 
(
    [Parameter(Position=0,
               Mandatory=$true,
               ValueFromPipeline=$false,
               HelpMessage='Enter the OU name as listed in Active Directory.')]
    [string]$OUName,
    
    [Parameter(Position=1,
               Mandatory=$true,
               ValueFromPipeline=$false,
               HelpMessage="Enter the domain component (DC) of the distinguished name (DN) for the domain of interest (e.g., 'dc=hq,dc=company,dc=com')")]
    [string]$SearchBase,
    
    [Parameter(Mandatory=$false,
               HelpMessage='Include admin accounts in the results. By default any SamAccounName with the string "adm" in it is excluded.')]
    [switch]$IncludeAdminAccounts,
    
    [Parameter(Mandatory=$false,
               ValueFromPipeline=$false,
               HelpMessage='Set the output CSV filename.')]
    [string]$CsvFile = "Output.csv"
)


function Get-Memberships {
    $groups = Get-ADGroup -Filter * -SearchBase "ou=$($OUName),$($SearchBase)" -Server "$($globalCatalogServer):$GCPort"

    foreach ($group in $groups) {
        $members = Get-ADGroupMember $group -Recursive -Server "$($globalCatalogServer):$GCPort" | 
            Where-Object {$_.distinguishedName -notlike "*$($OUName)*" -and $_.objectClass -eq 'user'}

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

$GCPort = 3268 
$globalCatalogServer = Get-ADDomainController -discover -service GlobalCatalog
# $dcServer = Get-ADDomainController  -Discover -DomainName 'eur.state.sbu'
$output = New-Object System.Collections.ArrayList

Get-Memberships

$output | Export-Csv -NoTypeInformation -Path $CsvFile