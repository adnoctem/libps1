#Requires -Version 5.0

function Install-AppxPackage {
  <#
    .SYNOPSIS
      Installs an AppX package from a local .appx / .msix file.

    .DESCRIPTION
      Installs or provisions an AppX package from the given file path.
      Without -AllUsers the package is installed only for the current user;
      with -AllUsers it is provisioned system-wide so every profile receives
      it.  The package file must be signed and trusted.

    .PARAMETER Path
      Full path to the .appx or .msix package file.

    .PARAMETER AllUsers
      Provision the package for all existing and future user profiles.
      Requires elevation.

    .PARAMETER DryRun
      Preview the installation without making changes.

    .EXAMPLE
      PS> Install-AppxPackage -Path 'C:\Packages\MyApp.appx'
      Installs the package for the current user only.

    .EXAMPLE
      PS> Install-AppxPackage -Path 'C:\Packages\MyApp.msix' -AllUsers
      Provisions the package for every profile on the machine.  Requires
      running as Administrator.

    .EXAMPLE
      PS> Install-AppxPackage -Path 'C:\Packages\MyApp.appx' -DryRun
      Previews the installation without making changes.

    .LINK
      https://github.com/adnoctem/libps1/lib/packages.ps1

    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
  param (
    [Parameter(
      Mandatory = $true,
      Position = 0,
      HelpMessage = "Full path to the .appx or .msix package file."
    )]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]
    $Path,

    [Parameter(HelpMessage = 'Provision the package for all user profiles — requires elevation.')]
    [switch]
    $AllUsers,

    [Parameter(HelpMessage = 'Preview the installation without making changes.')]
    [switch]
    $DryRun
  )

  if ($DryRun) {
    $WhatIfPreference = $true
    Write-Log -Message "DRY RUN — no package will be installed`n" -Color Yellow
  }

  $fileName = Split-Path -Path $Path -Leaf

  if ($AllUsers) {
    Write-Log -Message "Provisioning AppX package for all users: $fileName …" -Color Yellow

    if ($PSCmdlet.ShouldProcess($Path, 'Provision AppX package for all users')) {
      try {
        $null = Add-AppxProvisionedPackage -Online -PackagePath $Path -ErrorAction Stop
        Write-Log -Message "  -> Provisioned: $fileName" -Color Green
        Write-Log -Message "`nPackage provisioned — it will be available for all current and future users." -Color Green
      }
      catch {
        Write-Log -Message "  -> FAILED: $_" -Color Red
        Write-Log -Message "`nPackage installation failed — review the error above." -Color Red
      }
    }
  }
  else {
    Write-Log -Message "Installing AppX package for current user: $fileName …" -Color Yellow

    if ($PSCmdlet.ShouldProcess($Path, 'Install AppX package')) {
      try {
        $null = Add-AppxPackage -Path $Path -ErrorAction Stop
        Write-Log -Message "  -> Installed: $fileName" -Color Green
        Write-Log -Message "`nPackage installed for current user." -Color Green
      }
      catch {
        Write-Log -Message "  -> FAILED: $_" -Color Red
        Write-Log -Message "`nPackage installation failed — review the error above." -Color Red
      }
    }
  }
}

function Uninstall-AppxPackage {
  <#
    .SYNOPSIS
      Removes one or more AppX provisioned packages by name or wildcard pattern.

    .DESCRIPTION
      Uninstalls AppX packages from the current user (or all users with
      -AllUsers).  When -RemoveProvisioning is specified the package is also
      stripped from the system image so it does not reappear for new profiles
      or after feature updates.  This is useful for debloating modern Windows
      installations.

    .PARAMETER Name
      Display name or package name to remove.  Wildcards (*) are supported.

    .PARAMETER Pattern
      Wildcard pattern for bulk removal, e.g. '*Xbox*' or '*Bing*'.

    .PARAMETER AllUsers
      Remove the package for all existing user profiles, not just the current
      user.  Requires elevation.

    .PARAMETER RemoveProvisioning
      Also remove the package from the system provisioning store so it does
      not reinstall for new users or after Windows updates.

    .PARAMETER DryRun
      Preview which packages would be removed without making changes.

    .EXAMPLE
      PS> Uninstall-AppxPackage -Name '*Xbox*'
      Removes all AppX packages whose name contains "Xbox" for the current user.

    .EXAMPLE
      PS> Uninstall-AppxPackage -Pattern '*Bing*' -AllUsers -RemoveProvisioning
      Removes all Bing-related AppX packages for every user and prevents them
      from reinstalling.

    .EXAMPLE
      PS> Uninstall-AppxPackage -Name '*Zune*' -DryRun
      Shows which Zune-related packages would be removed without touching them.

    .LINK
      https://github.com/adnoctem/libps1/lib/packages.ps1

    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
  param (
    [Parameter(
      Mandatory = $true,
      ParameterSetName = 'Name',
      HelpMessage = "Display name or package name to remove — wildcards (*) are supported."
    )]
    [string]
    $Name,

    [Parameter(
      Mandatory = $true,
      ParameterSetName = 'Pattern',
      HelpMessage = "Wildcard pattern for bulk removal, e.g. '*Xbox*'."
    )]
    [string]
    $Pattern,

    [Parameter(HelpMessage = 'Remove for all user profiles — requires elevation.')]
    [switch]
    $AllUsers,

    [Parameter(HelpMessage = 'Also strip from the system provisioning store.')]
    [switch]
    $RemoveProvisioning,

    [Parameter(HelpMessage = 'Preview which packages would be removed.')]
    [switch]
    $DryRun
  )

  # Enable WhatIf across downstream calls when -DryRun is active
  if ($DryRun) {
    $WhatIfPreference = $true
    Write-Log -Message "DRY RUN — no packages will be removed`n" -Color Yellow
  }

  $filter = if ($PSCmdlet.ParameterSetName -eq 'Name') { $Name } else { $Pattern }

  # Installed packages
  Write-Log -Message "Searching for AppX packages matching: '$filter' …" -Color Yellow

  $packages = if ($AllUsers) {
    @(Get-AppxPackage -AllUsers -Name $filter -ErrorAction SilentlyContinue)
  }
  else {
    @(Get-AppxPackage -Name $filter -ErrorAction SilentlyContinue)
  }

  if ($packages.Count -eq 0) {
    Write-Log -Message '  -> No matching AppX packages found.' -Color Gray
  }
  else {
    Write-Log -Message "  -> Found $($packages.Count) installed package(s)." -Color Gray
  }

  $removed = 0
  $removeFailed = 0

  foreach ($pkg in $packages) {
    if ($PSCmdlet.ShouldProcess($pkg.PackageFullName, 'Remove AppX package')) {
      try {
        if ($AllUsers) {
          $null = Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
        }
        else {
          $null = Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop
        }
        Write-Log -Message "  Removed: $($pkg.PackageFullName)" -Color Green
        $removed++
      }
      catch {
        Write-Log -Message "  FAILED: $($pkg.PackageFullName) — $_" -Color Red
        $removeFailed++
      }
    }
  }

  # Provisioning removal
  $provRemoved = 0
  $provRemoveFailed = 0

  if ($RemoveProvisioning) {
    Write-Log -Message "`nSearching for provisioned packages matching: '$filter' …" -Color Yellow

    $provisioned = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
      Where-Object { $_.DisplayName -like $filter -or $_.PackageName -like $filter })

    if ($provisioned.Count -eq 0) {
      Write-Log -Message '  -> No matching provisioned packages found.' -Color Gray
    }
    else {
      Write-Log -Message "  -> Found $($provisioned.Count) provisioned package(s)." -Color Gray
    }

    foreach ($prov in $provisioned) {
      if ($PSCmdlet.ShouldProcess($prov.PackageName, 'Remove AppX provisioning')) {
        try {
          $null = Remove-AppxProvisionedPackage -Online -PackageName $prov.PackageName -ErrorAction Stop
          Write-Log -Message "  Removed provisioning: $($prov.PackageName)" -Color Green
          $provRemoved++
        }
        catch {
          Write-Log -Message "  FAILED provisioning: $($prov.PackageName) — $_" -Color Red
          $provRemoveFailed++
        }
      }
    }
  }

  # Summary
  if ($DryRun) {
    Write-Log -Message "`nDRY RUN COMPLETE — $($packages.Count) installed + $($provisioned.Count) provisioned package(s) would have been removed" -Color Yellow
  }
  else {
    $totalOk = $removed + $provRemoved
    $totalBad = $removeFailed + $provRemoveFailed
    $color = if ($totalBad -gt 0) { 'Yellow' } else { 'Green' }
    Write-Log -Message "`nRemoved: $totalOk  |  Failed: $totalBad  |  Installed: $($packages.Count)  |  Provisioned: $($provisioned.Count)" -Color $color
  }
}

function Install-WinGetPackage {
  <#
    .SYNOPSIS
      Installs an application via WinGet by package name or ID.

    .DESCRIPTION
      Uses the Microsoft.WinGet.Client PowerShell module to search for and
      install an application.  Requires the module to be installed (run
      'Install-Module Microsoft.WinGet.Client' if missing).

    .PARAMETER Name
      Application name to search for and install, e.g. 'Microsoft.VisualStudioCode'.
      Wildcards are not recommended — the first match is installed.

    .PARAMETER Id
      Exact package identifier, e.g. 'Microsoft.VisualStudioCode'.
      Use this when -Name is ambiguous.

    .PARAMETER Version
      A specific version to install.  Omitting this installs the latest.

    .PARAMETER Source
      The WinGet source to query, e.g. 'winget' or 'msstore'.
      Defaults to whatever WinGet considers the default source.

    .PARAMETER DryRun
      Preview which package would be installed without making changes.

    .EXAMPLE
      PS> Install-WinGetPackage -Name 'Microsoft.VisualStudioCode'
      Installs the latest version of VS Code via WinGet.

    .EXAMPLE
      PS> Install-WinGetPackage -Id 'Microsoft.VisualStudioCode' -Version '1.85'
      Installs a specific version of VS Code.

    .EXAMPLE
      PS> Install-WinGetPackage -Name 'Firefox' -Source 'winget' -DryRun
      Previews the installation without making changes.

    .LINK
      https://github.com/adnoctem/libps1/lib/packages.ps1

    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
  param (
    [Parameter(
      Mandatory = $true,
      ParameterSetName = 'Name',
      HelpMessage = "Application name to install, e.g. 'Microsoft.VisualStudioCode'."
    )]
    [string]
    $Name,

    [Parameter(
      Mandatory = $true,
      ParameterSetName = 'Id',
      HelpMessage = "Exact package identifier, e.g. 'Microsoft.VisualStudioCode'."
    )]
    [string]
    $Id,

    [Parameter(HelpMessage = 'Specific version to install — defaults to latest.')]
    [string]
    $Version,

    [Parameter(HelpMessage = "WinGet source, e.g. 'winget' or 'msstore'.")]
    [string]
    $Source,

    [Parameter(HelpMessage = 'Preview the installation without making changes.')]
    [switch]
    $DryRun
  )

  if ($DryRun) {
    $WhatIfPreference = $true
    Write-Log -Message "DRY RUN — no application will be installed`n" -Color Yellow
  }

  # Verify the WinGet client module is available
  if (-not (Get-Module -ListAvailable -Name Microsoft.WinGet.Client -ErrorAction SilentlyContinue)) {
    Write-Log -Message 'Microsoft.WinGet.Client module is not installed. Run: Install-Module Microsoft.WinGet.Client -Force' -Color Red
    return
  }

  Import-Module Microsoft.WinGet.Client -Force -ErrorAction Stop

  $targetLabel = if ($PSCmdlet.ParameterSetName -eq 'Id') { $Id } else { $Name }

  Write-Log -Message "Installing via WinGet: $targetLabel …" -Color Yellow

  # Resolve the exact package (search by name, or trust the ID)
  if ($PSCmdlet.ParameterSetName -eq 'Name') {
    $matches = @(Get-WinGetPackage -ErrorAction SilentlyContinue |
      Where-Object { $_.Name -like $Name })

    if ($matches.Count -eq 0) {
      Write-Log -Message "  -> No package found matching: '$Name'" -Color Red
      return
    }

    if ($matches.Count -gt 1) {
      Write-Log -Message "  -> Multiple packages match '$Name' — using first result: $($matches[0].Name) ($($matches[0].Id))" -Color Yellow
    }

    $Id = $matches[0].Id
    Write-Log -Message "  -> Resolved to ID: $Id" -Color Gray
  }

  if ($PSCmdlet.ShouldProcess($targetLabel, 'Install via WinGet')) {
    try {
      $params = @{ Id = $Id; ErrorAction = 'Stop' }
      if ($Version) { $params.Version = $Version }
      if ($Source)  { $params.Source  = $Source }

      $null = Install-WinGetPackage @params
      Write-Log -Message "  -> Installed: $targetLabel" -Color Green
      Write-Log -Message "`nPackage installed successfully." -Color Green
    }
    catch {
      Write-Log -Message "  -> FAILED: $_" -Color Red
      Write-Log -Message "`nPackage installation failed — review the error above." -Color Red
    }
  }
}

function Uninstall-WinGetPackage {
  <#
    .SYNOPSIS
      Removes one or more applications via WinGet by name or wildcard pattern.

    .DESCRIPTION
      Uses the Microsoft.WinGet.Client PowerShell module to search for and
      uninstall applications.  Requires the module to be installed (run
      'Install-Module Microsoft.WinGet.Client' if missing).

    .PARAMETER Name
      Application name to remove.  Wildcards (*) are supported.

    .PARAMETER Pattern
      Wildcard pattern for bulk removal, e.g. '*Teams*' or '*Office*'.

    .PARAMETER DryRun
      Preview which applications would be removed without making changes.

    .EXAMPLE
      PS> Uninstall-WinGetPackage -Name '*OneDrive*'
      Removes all applications with "OneDrive" in the name via WinGet.

    .EXAMPLE
      PS> Uninstall-WinGetPackage -Pattern '*Teams*' -DryRun
      Shows which Teams-related applications would be removed without touching
      them.

    .EXAMPLE
      PS> Uninstall-WinGetPackage -Name '*Office*'
      Removes all Microsoft Office related applications found via WinGet.

    .LINK
      https://github.com/adnoctem/libps1/lib/packages.ps1

    .NOTES
      Author: Maximilian Gindorfer <info@mvprowess.com>
      License: MIT
  #>

  [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
  param (
    [Parameter(
      Mandatory = $true,
      ParameterSetName = 'Name',
      HelpMessage = "Application name to remove — wildcards (*) are supported."
    )]
    [string]
    $Name,

    [Parameter(
      Mandatory = $true,
      ParameterSetName = 'Pattern',
      HelpMessage = "Wildcard pattern for bulk removal, e.g. '*Teams*'."
    )]
    [string]
    $Pattern,

    [Parameter(HelpMessage = 'Preview which applications would be removed.')]
    [switch]
    $DryRun
  )

  # Enable WhatIf across downstream calls when -DryRun is active
  if ($DryRun) {
    $WhatIfPreference = $true
    Write-Log -Message "DRY RUN — no applications will be removed`n" -Color Yellow
  }

  # Verify the WinGet client module is available
  if (-not (Get-Module -ListAvailable -Name Microsoft.WinGet.Client -ErrorAction SilentlyContinue)) {
    Write-Log -Message 'Microsoft.WinGet.Client module is not installed. Run: Install-Module Microsoft.WinGet.Client -Force' -Color Red
    return
  }

  Import-Module Microsoft.WinGet.Client -Force -ErrorAction Stop

  $filter = if ($PSCmdlet.ParameterSetName -eq 'Name') { $Name } else { $Pattern }

  Write-Log -Message "Searching WinGet for applications matching: '$filter' …" -Color Yellow

  $packages = @(Get-WinGetPackage -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like $filter })

  if ($packages.Count -eq 0) {
    Write-Log -Message '  -> No matching applications found.' -Color Gray
    return
  }

  Write-Log -Message "  -> Found $($packages.Count) application(s)." -Color Gray

  $removed = 0
  $removeFailed = 0

  foreach ($pkg in $packages) {
    if ($PSCmdlet.ShouldProcess($pkg.Name, 'Uninstall via WinGet')) {
      try {
        $null = Uninstall-WinGetPackage -Id $pkg.Id -ErrorAction Stop
        Write-Log -Message "  Removed: $($pkg.Name) ($($pkg.Id))" -Color Green
        $removed++
      }
      catch {
        Write-Log -Message "  FAILED: $($pkg.Name) ($($pkg.Id)) — $_" -Color Red
        $removeFailed++
      }
    }
  }

  # Summary
  if ($DryRun) {
    Write-Log -Message "`nDRY RUN COMPLETE — $($packages.Count) application(s) would have been removed" -Color Yellow
  }
  else {
    $color = if ($removeFailed -gt 0) { 'Yellow' } else { 'Green' }
    Write-Log -Message "`nRemoved: $removed  |  Failed: $removeFailed  |  Total matched: $($packages.Count)" -Color $color
  }
}