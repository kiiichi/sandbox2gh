---
name: sandbox2gh
description: Set up and use GitHub CLI inside Codex sandboxes with a project-specific GitHub token. Use when a new project sandbox needs `gh` access, when `gh auth status` shows an invalid default login, when GitHub issues or PRs must be read through `gh`, or when Windows sandbox environment quirks such as duplicate `Path`/`PATH` keys break GitHub CLI commands.
---

# Sandbox2gh

## Goal

Use `gh` inside a Codex sandbox without relying on interactive browser login or the host user's default GitHub CLI credential store.

Prefer a project-specific environment variable such as `GH_TOKEN_ProjectName`, map it to `GH_TOKEN` for the current command, and keep the token out of files and chat.

## Quick Workflow

1. Resolve the repository:

```powershell
git remote -v
```

Use the `owner/name` repo from the remote, for example `kiiichi/wow-KichiRotation`.

2. Locate GitHub CLI:

```powershell
Get-Command gh
```

On this Windows setup, the stable path is usually:

```text
C:\Program Files\GitHub CLI\gh.exe
```

3. Choose a project token environment variable.

Use a project-specific name such as `GH_TOKEN_KichiRotation` or `GH_TOKEN_MyRepo`. `gh` itself reads `GH_TOKEN`, so map the project variable to `GH_TOKEN` only inside the current shell command.

4. Map the project token to `GH_TOKEN` inside each command:

```powershell
$token = [Environment]::GetEnvironmentVariable("GH_TOKEN_KichiRotation", "User")
if (-not $token) { $token = [Environment]::GetEnvironmentVariable("GH_TOKEN_KichiRotation", "Machine") }
if (-not $token) { $token = $env:GH_TOKEN_KichiRotation }
if (-not $token) { throw "GH_TOKEN_KichiRotation not found" }
$env:GH_TOKEN = $token
gh issue list --repo kiiichi/wow-KichiRotation --state open --limit 20
```

Adapt the token variable name and repo for the current project.

## Windows Sandbox Quirk

If PowerShell commands fail with an error like:

```text
An item with the same key has already been added
```

or the localized equivalent mentioning duplicate dictionary keys, the process environment may contain both `Path` and `PATH`. Before calling `gh`, remove the duplicate uppercase key for the current process only:

```powershell
[System.Environment]::SetEnvironmentVariable("PATH", $null, "Process")
```

This does not edit the user's permanent environment. Prefer invoking `gh` normally after that, or call the full path:

```powershell
& "C:\Program Files\GitHub CLI\gh.exe" issue list --repo kiiichi/wow-KichiRotation --state open --limit 20
```

## Auth Checks

`gh auth status` is useful but not authoritative in sandboxes with stale default credentials. It can report `Logged in ... (GH_TOKEN)` and still exit nonzero because an old default token is invalid.

Treat a real API command as the final test:

```powershell
$env:GH_TOKEN = [Environment]::GetEnvironmentVariable("GH_TOKEN_KichiRotation", "User")
gh issue list --repo kiiichi/wow-KichiRotation --state open --limit 20
```

Success means GitHub access works for the sandbox, even if the default credential store is stale.

## Creating the Token

Tell the user not to paste the token into chat. Have them create a fine-grained GitHub personal access token and store it as a user environment variable.

Recommended minimum permissions for issue and PR work:

- Repository access: only the target repository.
- Metadata: read-only.
- Issues: read and write.
- Contents: read.
- Pull requests: read and write.

If the agent must push branches or modify repository contents remotely, `Contents` must be read and write.

Set the token in PowerShell:

```powershell
[Environment]::SetEnvironmentVariable("GH_TOKEN_ProjectName", "<token>", "User")
```

For the current terminal only:

```powershell
$env:GH_TOKEN_ProjectName = "<token>"
```

After setting a user environment variable, restart Codex or start a fresh terminal so the sandbox process can see it.

## Command Pattern

For each `gh` command in Codex, set `GH_TOKEN` in the same shell invocation and avoid printing token values:

```powershell
[System.Environment]::SetEnvironmentVariable("PATH", $null, "Process")
$token = [Environment]::GetEnvironmentVariable("GH_TOKEN_ProjectName", "User")
if (-not $token) { $token = [Environment]::GetEnvironmentVariable("GH_TOKEN_ProjectName", "Machine") }
if (-not $token) { $token = $env:GH_TOKEN_ProjectName }
if (-not $token) { throw "GH_TOKEN_ProjectName not found" }
$env:GH_TOKEN = $token
gh issue view 12 --repo owner/repo --comments
```

Use `--repo owner/repo` explicitly so the command works even when the local checkout remote is unusual.

## Example Result

For `kiiichi/wow-KichiRotation`, this pattern allowed issue reads even while `gh auth status` still reported a stale default credential:

```powershell
[System.Environment]::SetEnvironmentVariable("PATH", $null, "Process")
$token = [Environment]::GetEnvironmentVariable("GH_TOKEN_KichiRotation", "User")
$env:GH_TOKEN = $token
gh issue list --repo kiiichi/wow-KichiRotation --state open --limit 20
```

The successful output listed open issues `#8` through `#13`.

## Avoid

- Do not ask the user to paste the token into chat.
- Do not commit `.gh-config`, `.scratch-gh-auth.*`, or any file containing credentials.
- Do not depend on `gh auth login` in headless sandboxes unless the user explicitly wants interactive device login.
- Do not assume `gh auth status` failure means `GH_TOKEN` cannot work; test a real repo command.
