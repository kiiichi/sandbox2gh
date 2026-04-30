[CmdletBinding()]
param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]] $GhArgs
)

$ErrorActionPreference = "Stop"

$Repo = "kiiichi/sandbox2gh"
$TokenVariable = "GH_TOKEN_sandbox2gh"
$GhPath = "C:\Program Files\GitHub CLI\gh.exe"

# Work around Windows sandboxes that expose both Path and PATH.
[System.Environment]::SetEnvironmentVariable("PATH", $null, "Process")

function Get-TokenFromEnvironment {
  param([Parameter(Mandatory = $true)][string] $Name)

  $token = [Environment]::GetEnvironmentVariable($Name, "User")
  if (-not $token) { $token = [Environment]::GetEnvironmentVariable($Name, "Machine") }
  if (-not $token) { $token = [Environment]::GetEnvironmentVariable($Name, "Process") }

  return $token
}

$token = Get-TokenFromEnvironment -Name $TokenVariable
if (-not $token) {
  throw "$TokenVariable not found. Create a fine-grained GitHub token, store it in that environment variable, and restart this sandbox."
}

$env:GH_TOKEN = $token

if (-not $GhArgs -or $GhArgs.Count -eq 0) {
  $GhArgs = @("repo", "view", $Repo)
}

& $GhPath @GhArgs
