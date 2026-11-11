# GitHub Copilot review instructions

Follow `AGENTS.md` for project conventions. Review comments, commit messages, code comments and docstrings are written in English; runtime log and error messages are English.

## Review checklist

- Issue body updates must not be destructive: rows without the `<!-- calculate-storage#computer_name#drive -->` marker must be preserved, and changes to `row_regex` or `size_regex` must keep parsing and regeneration consistent (marker rows that fail parsing are dropped on rewrite).
- The token is read from `data/github_token.txt`; flag any exposure of the token or Issue body in logs, exceptions or commits, and any commit of `data/` or `results/`.
- GitHub API failures (non-200), `psutil.disk_usage` `OSError` and directory creation failures must be handled and logged, not swallowed.
- OS-specific code (`os.name`) must work on both Windows and Unix.
- Logic changes need unittest coverage with GitHub and psutil mocked (no real network). CI covers Python 3.10 and later, so new syntax or APIs must work there.

## Not worth flagging

- 2-space Python indentation is intended (`.editorconfig`).
- Reading the token from `data/github_token.txt` instead of an environment variable is intended.
- Double-underscore methods on `GitHubIssue` are intentionally private.
- The `.txt` extension of the JSON Lines results file is existing behavior.
