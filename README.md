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

## Token Pattern

Create a fine-grained GitHub personal access token with repository-scoped permissions, store it as a project-specific environment variable such as `GH_TOKEN_MyRepo`, then map it to `GH_TOKEN` only for the current `gh` command.

Minimum useful permissions:

- Metadata: read-only.
- Issues: read and write.
- Contents: read.
- Pull requests: read and write.

Use `Contents: read and write` only when the agent must push branches or write repository contents.

## Files

- `SKILL.md`: the skill consumed by Codex.
- `agents/openai.yaml`: UI metadata for Codex skill lists.

## Security

Do not commit tokens, `.gh-config`, or scratch auth files. Never paste tokens into chat.
