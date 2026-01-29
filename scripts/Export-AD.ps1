#Requires -Version 5.0

<#
.SYNOPSIS
  Exports Active Directory users to a specified CSV file.

.DESCRIPTION
  This script connects to the Active Directory and retrieves user information, exporting it to a CSV file. It allows for filtering options to include specific user attributes and can handle large datasets efficiently.

.PARAMETER OutputFile
  The full path to the CSV file where the exported user data will be saved.

.PARAMETER Filter
  Optional parameter to filter users based on specific criteria (e.g., department, status).

.EXAMPLE
  PS> ./Export-AD.ps1 -OutputPath 'C:\Exports'
  This command exports all Active Directory users to the specified CSV file.

.EXAMPLE
  PS> ./Export-AD.ps1 -OutputPath 'C:\Exports' -Resource 'Users'
  This command exports Active Directory users from the Sales department to the specified CSV file.

.LINK
  https://github.com/adnoctem/libps1

.NOTES
  Author: Maximilian Gindorfer <info@mvprowess.com>
  License: MIT
#>

# Parameters
param (
  [Parameter(
    Position = 0,
    Mandatory = $true,
    HelpMessage = "The output file path for the exported CSV."
  )]
  [string]$OutputPath,

  [Parameter(
    Position = 1,
    Mandatory = $false,
    HelpMessage = "The resource to export from Active Directory."
  )]
  [ValidateSet("Users", "Computers", "Groups", "All")]
  [string]$Resource = "Users",


  [Parameter(
    Position = 2,
    Mandatory = $false,
    HelpMessage = "The encoding for the output CSV file."
  )]
  [ValidateSet("UTF8", "ASCII", "Unicode", "UTF7", "UTF32", "BigEndianUnicode")]
  [string]$Encoding = "UTF8"
)

# ---- Module import ------------------------------------
# $root = Split-Path $PSScriptRoot -Parent
# $module = Join-Path -Path $root 'lib/libps1.psm1'

Import-Module ActiveDirectory -Force
# -------------------------------------------------------

$properties = @{
  Users     = @(
    # Windows AD specific
    "sAMAccountName",
    "userPrincipalName",
    "lastLogon",
    "lastLogonTimestamp",
    "whenCreated",
    "whenChanged",
    "accountExpires",

    # Paths
    "homeDirectory",
    "homeDrive",
    "profilePath",

    # General
    "cn",
    "sn",
    "name",
    "givenName",
    "displayName",
    "mail",
    "mailNickname",
    "description",
    "telephoneNumber"
  )

  Computers = @(
    # Windows AD specific
    "cn",
    "name",
    "sAMAccountName",
    "servicePrincipalName",
    "dNSHostName",
    "lastLogon",
    "lastLogonTimestamp",
    "whenCreated",
    "whenChanged",
    "accountExpires",

    # General
    "operatingSystem",
    "operatingSystemVersion"
  )

  Groups    = @(
    # Windows AD specific
    "cn",
    "name",
    "sAMAccountName",
    "description",
    "whenCreated",
    "whenChanged",

    # General
    "groupType"
  )
}


$obj = @{};

switch ($Resource) {
  "Users" {
    $obj.Users = Get-ADUser -Filter * -Properties $properties.Users
  }
  "Computers" {
    $obj.Computers = Get-ADComputer -Filter * -Properties $properties.Computers
  }
  "Groups" {
    $obj.Groups = Get-ADGroup -Filter * -Properties $properties.Groups
  }
  "All" {
    $obj.Users = Get-ADUser -Filter * -Properties $properties.Users
    $obj.Computers = Get-ADComputer -Filter * -Properties $properties.Computers
    $obj.Groups = Get-ADGroup -Filter * -Properties $properties.Groups
  }

  # Default {

  # }
}

# ensure OutputPath is a directory
#
# ref: https://stackoverflow.com/questions/39825440/check-if-a-path-is-a-folder-or-a-file-in-powershell
if (Test-Path -Path $OutputPath -PathType Leaf) {
  # It's a file
  Throw("OutputPath is a file. Please provide a directory path.")
}

# Output each property as a separate CSV file
$obj | Get-Member -MemberType Property | ForEach-Object {
  $name = $_.Name
  $data = $obj.$name

  $output = Join-Path -Path $OutputPath -ChildPath "AD-$name.csv"
  $data | Export-Csv -Path $output -NoTypeInformation -Encoding $Encoding
}
