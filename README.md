# sandbox2gh

`sandbox2gh` is a Codex skill for making GitHub CLI (`gh`) work reliably inside project sandboxes.

It documents the token-based workflow that avoids fragile interactive `gh auth login` flows, stale default credentials, and Windows sandbox environment quirks such as duplicate `Path`/`PATH` keys.

## Install

From a published GitHub repo:

```powershell
npx skills@latest add owner/sandbox2gh -a codex -g
```

From a local checkout:

```powershell
npx skills@latest add ./sandbox2gh -a codex -g
```

## Use

Invoke the skill in Codex:

```text
Use $sandbox2gh to configure GitHub CLI access in this project sandbox.
```

```text
使用 `$sandbox2gh` 在此项目沙箱中配置 GitHub CLI 访问权限。
```

## Token Pattern

Create a fine-grained GitHub personal access token with repository-scoped permissions:

- New fine-grained token page: https://github.com/settings/personal-access-tokens/new
- GitHub instructions: https://docs.github.com/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line
- Prefilled template:

```text
https://github.com/settings/personal-access-tokens/new?name=Codex-owner-repo&description=Codex+sandbox+GitHub+CLI+access&target_name=owner&expires_in=90&contents=read&issues=write&pull_requests=write
```

Store the token as a project-specific environment variable such as `GH_TOKEN_MyRepo`, then map it to `GH_TOKEN` only for the current `gh` command.

Minimum useful permissions:

- Metadata: read-only.
- Issues: read and write.
- Contents: read.
- Pull requests: read and write.

Use `Contents: read and write` only when the agent must push branches or write repository contents.

Quick validation command:

```powershell
[System.Environment]::SetEnvironmentVariable("PATH", $null, "Process")
$token = [Environment]::GetEnvironmentVariable("GH_TOKEN_MyRepo", "User")
if (-not $token) { $token = [Environment]::GetEnvironmentVariable("GH_TOKEN_MyRepo", "Machine") }
if (-not $token) { $token = $env:GH_TOKEN_MyRepo }
if (-not $token) { throw "GH_TOKEN_MyRepo not found" }
$env:GH_TOKEN = $token
gh repo view owner/repo --json nameWithOwner,url,viewerPermission
```

## Files

- `SKILL.md`: the skill consumed by Codex.
- `agents/openai.yaml`: UI metadata for Codex skill lists.
- `scripts/gh-sandbox2gh.ps1`: optional local wrapper that reads `GH_TOKEN_sandbox2gh`, maps it to `GH_TOKEN` for one `gh` command, and works around the duplicate `PATH` sandbox issue.

## Security

Do not commit tokens, `.gh-config`, or scratch auth files. Never paste tokens into chat.
