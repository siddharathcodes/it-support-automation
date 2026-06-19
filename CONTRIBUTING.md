# Contributing

## How to contribute

1. Fork the repo
2. Create a branch: `git checkout -b feat/your-feature`
3. Make your changes
4. Test every script before committing
5. Commit: `git commit -m "feat: describe what you added"`
6. Push: `git push origin feat/your-feature`
7. Open a Pull Request

## Script standards

- No emojis or special characters in scripts (causes encoding issues on Windows)
- Every script must have a header comment with usage example
- Always include an admin check for scripts that need elevated privileges
- Test on both PowerShell 5.1 and PowerShell 7
- Use plain ASCII only in all .ps1 and .sh files

## Commit message format

```
feat: add new feature
fix: fix a bug
docs: update documentation
refactor: restructure without changing behavior
```
