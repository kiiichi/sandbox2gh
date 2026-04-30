---
name: sandbox2gh
description: Set up and use GitHub CLI inside Codex sandboxes with a project-specific GitHub token. Use when a new project sandbox needs `gh` access, when `gh auth status` shows an invalid default login, when GitHub issues or PRs must be read through `gh`, or when Windows sandbox environment quirks such as duplicate `Path`/`PATH` keys break GitHub CLI commands.
---

# Sandbox2gh

## Goal

Use `gh` inside a Codex sandbox without relying on interactive browser login or the host user's default GitHub CLI credential store.

Prefer a project-specific environment variable such as `GH_TOKEN_ProjectName`, map it to `GH_TOKEN` for the current command, and keep the token out of files and chat.

## Fast Path

1. Get the repo slug and CLI path:

```powershell
git remote -v
Get-Command gh
```

2. Give the user a fine-grained personal access token link and a page checklist.

Start with the prefilled token link, then immediately tell the user what must be checked or changed on the GitHub page. GitHub URL parameters can prefill name, description, owner, expiration, and permissions, but they do not currently preselect `Only select repositories` or the repository itself.

Use this response shape:

- Open this link: `https://github.com/settings/personal-access-tokens/new?name=Codex-owner-repo&description=Codex+sandbox+GitHub+CLI+access+for+owner%2Frepo&target_name=owner&expires_in=90&contents=read&issues=write&pull_requests=write`
- Before clicking `Generate token`, check or change:
  - `Repository access`: select `Only select repositories`.
  - `Selected repositories`: select `repo`.
  - `Expiration`: use the shortest practical value, such as 90 days.
  - `Contents`: use `Read-only`, or `Read and write` only if Codex must push branches.
  - `Issues`: use `Read and write`.
  - `Pull requests`: use `Read and write`.
- Do not paste the token into chat.
- Store it in a project-specific variable:

```powershell
[Environment]::SetEnvironmentVariable("GH_TOKEN_ProjectName", "<token>", "User")
```

Useful links:

- New fine-grained token page: https://github.com/settings/personal-access-tokens/new
- GitHub instructions: https://docs.github.com/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line
- Prefilled template:

```text
https://github.com/settings/personal-access-tokens/new?name=Codex-owner-repo&description=Codex+sandbox+GitHub+CLI+access&target_name=owner&expires_in=90&contents=read&issues=write&pull_requests=write
```

For the current repository, restrict repository access to only that repo. Use the shortest expiration that is practical.

Minimum useful repository permissions:

- Metadata: read-only.
- Issues: read and write.
- Contents: read.
- Pull requests: read and write.

Use `Contents: read and write` only when the agent must push branches or write repository contents.

3. Store the token in a project-specific variable. Do not paste it into chat.

```powershell
[Environment]::SetEnvironmentVariable("GH_TOKEN_ProjectName", "<token>", "User")
```

If user-level environment writes are blocked in the sandbox, set it in the current terminal before starting Codex, or set it in a fresh terminal and restart Codex:

```powershell
$env:GH_TOKEN_ProjectName = "<token>"
```

4. Validate with a real API call, not only `gh auth status`:

```powershell
[System.Environment]::SetEnvironmentVariable("PATH", $null, "Process")
$token = [Environment]::GetEnvironmentVariable("GH_TOKEN_ProjectName", "User")
if (-not $token) { $token = [Environment]::GetEnvironmentVariable("GH_TOKEN_ProjectName", "Machine") }
if (-not $token) { $token = $env:GH_TOKEN_ProjectName }
if (-not $token) { throw "GH_TOKEN_ProjectName not found" }
$env:GH_TOKEN = $token
gh repo view owner/repo --json nameWithOwner,url,viewerPermission
```

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

Make the response procedural and easy to test:

1. State what was detected:
   - repository slug, such as `owner/repo`
   - GitHub CLI path
   - project token variable name, such as `GH_TOKEN_RepoName`

2. Give one direct link:

```text
https://github.com/settings/personal-access-tokens/new?name=Codex-owner-repo&description=Codex+sandbox+GitHub+CLI+access+for+owner%2Frepo&target_name=owner&expires_in=90&contents=read&issues=write&pull_requests=write
```

3. Immediately list exactly what the user must check on the GitHub page:

- `Repository access`: select `Only select repositories`.
- `Selected repositories`: select `repo`.
- `Contents`: select `Read-only`, unless the agent must push branches; then select `Read and write`.
- `Issues`: select `Read and write`.
- `Pull requests`: select `Read and write`.
- `Expiration`: use the shortest practical value.

4. Tell the user how to store it without exposing the secret:

```powershell
[Environment]::SetEnvironmentVariable("GH_TOKEN_RepoName", "<token>", "User")
```

5. Tell the user to restart Codex or open a fresh terminal after setting a user environment variable.

6. Finish with the exact validation command the agent will run next:

```powershell
[System.Environment]::SetEnvironmentVariable("PATH", $null, "Process")
$token = [Environment]::GetEnvironmentVariable("GH_TOKEN_RepoName", "User")
if (-not $token) { $token = [Environment]::GetEnvironmentVariable("GH_TOKEN_RepoName", "Machine") }
if (-not $token) { $token = $env:GH_TOKEN_RepoName }
if (-not $token) { throw "GH_TOKEN_RepoName not found" }
$env:GH_TOKEN = $token
gh repo view owner/repo --json nameWithOwner,url,viewerPermission
```

If the user says the token page still shows `All repositories`, explain that this is expected. GitHub's supported URL parameters do not include repository access mode or selected repositories. The user must change `Repository access` manually on the page.

Token creation pages:

- Direct token form: https://github.com/settings/personal-access-tokens/new
- GitHub docs: https://docs.github.com/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line
- Prefilled template. This cannot preselect `Only select repositories`; the user must change that manually on the GitHub page:

```text
https://github.com/settings/personal-access-tokens/new?name=Codex-owner-repo&description=Codex+sandbox+GitHub+CLI+access&target_name=owner&expires_in=90&contents=read&issues=write&pull_requests=write
```

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

## Fast Failure Order

When setup fails, check in this order:

1. `git remote -v` resolves the expected `owner/repo`.
2. `Get-Command gh` finds GitHub CLI.
3. The duplicate `PATH` sandbox quirk is cleared for the current process.
4. The project token variable exists without printing its value.
5. A real command such as `gh repo view owner/repo --json nameWithOwner,url,viewerPermission` succeeds.

Skip `gh auth login` unless the user explicitly wants an interactive device flow.

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
