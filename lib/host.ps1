#Requires -Version 5.0

function Show-HostName {
  <#
  .SYNOPSIS
    Generate hostnames according to the OFC hostname schema.

  .EXAMPLE
    # Single firewall in home building
    Show-HostName -BuildingId H00 -MachineType NI -InfrastructureType FW

  .EXAMPLE
    # 5 Windows PCs in H00 starting at 0001
    Show-HostName -BuildingId H00 -MachineType PC -OS W -StartIndex 1 -Count 5

  .EXAMPLE
    # 3 domain controller VMs in H00, starting at 010
    Show-HostName -BuildingId H00 -MachineType VM -WorkloadPurpose DC -StartIndex 10 -Count 3
  #>

  [CmdletBinding()]
  param (
    # Company code (fixed to OFC for you, but overridable)
    [string]
    $CompanyCode = "OFC",

    # Building identifier (e.g. H00, B01, W03)
    [Parameter(Mandatory = $true)]
    [ValidatePattern("^[HBWS]\d{2}$")]
    [string]
    $BuildingId,

    # Machine type
    [Parameter(Mandatory = $true)]
    [ValidateSet("NI", "VM", "CT", "PC", "NB", "MP")]
    [string]
    $MachineType,

    # Only for Network Infrastructure (NI)
    [ValidateSet("FW", "SW", "AP", "MC", "BX", "MD", "VS", "SS")]
    [string]
    $InfrastructureType,

    # Only for VM / CT
    [ValidateSet("DC", "MX", "CJ", "AS", "NS", "DH", "CA")]
    [string]
    $WorkloadPurpose,

    # Only for PC / NB / MP
    [ValidateSet("W", "L", "I", "A", "B", "U")]
    [string]
    $OS,

    # Starting index (numeric part)
    [int]
    $StartIndex = 1,

    # Number of hostnames to generate
    [int]
    $Count = 1
  )


  # Validate subtype based on machine type
  switch ($MachineType) {
    "NI" {
      if (-not $InfrastructureType) {
        throw "MachineType 'NI' requires -InfrastructureType (FW, SW, AP, MC, BX, MD, VS, SS)."
      }
    }
    "VM" {
      if (-not $WorkloadPurpose) {
        throw "MachineType 'VM' requires -WorkloadPurpose (DC, MX, CJ, AS, NS, DH, CA)."
      }
    }
    "CT" {
      if (-not $WorkloadPurpose) {
        throw "MachineType 'CT' requires -WorkloadPurpose (DC, MX, CJ, AS, NS, DH, CA)."
      }
    }
    { $_ -in @("PC", "NB", "MP") } {
      if (-not $OS) {
        throw "MachineType '$MachineType' requires -OS (W, L, I, A, B, U)."
      }
    }
  }

  # Determine serial number padding
  # 3-digit for Network Infrastructure, Servers, Virtual Machines (=> NI, VM, CT)
  # 4-digit for PCs, Notebooks, Mobile phones
  $padWidth = if ($MachineType -in @("NI", "VM", "CT")) { 3 } else { 4 }

  for ($i = 0; $i -lt $Count; $i++) {
    $currentIndex = $StartIndex + $i
    $serial = $currentIndex.ToString("D$padWidth")

    $segments = @($CompanyCode, $BuildingId, $MachineType)

    switch ($MachineType) {
      "NI" { $segments += $InfrastructureType }
      "VM" { $segments += $WorkloadPurpose }
      "CT" { $segments += $WorkloadPurpose }
      "PC" { $segments += $OS }
      "NB" { $segments += $OS }
      "MP" { $segments += $OS }
    }

    $segments += $serial

    $hostname = ($segments -join "-")
    Write-Output $hostname
  }
}