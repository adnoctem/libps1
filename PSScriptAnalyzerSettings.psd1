@{
  Severity = @('Error', 'Warning')
  IncludeDefaultRules = $true
  ExcludeRules = @(
    # Project convention: Merge-ObjectArrays describes a two-array merge helper.
    'PSUseSingularNouns'
  )

  Rules = @{
    PSPlaceOpenBrace = @{
      Enable = $true
      OnSameLine = $true
      NewLineAfter = $true
      IgnoreOneLineBlock = $true
    }

    PSPlaceCloseBrace = @{
      Enable = $true
      NewLineAfter = $true
      IgnoreOneLineBlock = $true
      NoEmptyLineBefore = $false
    }

    PSUseConsistentIndentation = @{
      Enable = $true
      Kind = 'space'
      IndentationSize = 2
      PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
    }

    PSUseConsistentWhitespace = @{
      Enable = $true
      CheckInnerBrace = $true
      CheckOpenBrace = $true
      CheckOpenParen = $true
      CheckOperator = $true
      CheckPipe = $true
      CheckPipeForRedundantWhitespace = $false
      CheckSeparator = $true
      CheckParameter = $false
      IgnoreAssignmentOperatorInsideHashTable = $false
    }

    PSUseCorrectCasing = @{
      Enable = $true
    }
  }
}
