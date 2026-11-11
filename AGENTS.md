# AGENTS.md

Guidance for AI coding agents and contributors. `CLAUDE.md` imports this file, and `.github/copilot-instructions.md` adds the review checklist.

## Language

- All deliverables are written in **English**: commit messages, PR/Issue titles and bodies, review comments, code comments and docstrings, and documentation (`README.md`, `AGENTS.md`, etc.).
- Exceptions (keep as is): quotations, technical identifiers, generated files, and external text.
- Runtime messages (logs, errors) are English.
- Do not rewrite Git history to change the language of past commits.

## Overview

A single-file Python tool (`calculate_storage.py`) that uses a GitHub Issue as a disk usage dashboard for multiple machines. It measures the drives registered for the current host with psutil and updates the matching rows of the Issue body's Markdown table through the GitHub API. See `README.md` for setup, usage, and the Issue row format.

## Commands

```bash
pip install -r requirements.txt
python calculate_storage.py <ISSUE_NUMBER>                  # updates a real Issue; needs data/github_token.txt
python -m unittest discover -s . -p "test_*.py"             # tests (mocked, no network)
sudo ISSUE_NUMBER=<n> bash calculate-storage.sh             # deploy and run on Linux/Unix
$env:ISSUE_NUMBER = "<n>"; .\calculate-storage.ps1          # deploy and run on Windows
```

Run the tests before committing. CI (`.github/workflows/ci.yml`) runs them on Ubuntu and Windows with Python 3.10 to 3.13 and the latest 3.x. Do not run the tool or the deployment scripts against production data while developing: the scripts also run `docker system prune -a -f`.

## Structure

- `calculate_storage.py`: `setup_logging()`, `GitHubIssue` (fetch/parse/update the Issue body, `get_human_readable_size`), `get_real_hostname()`, `get_github_token()`, `save_results()`, `main()`.
- `test_calculate_storage.py`: unittest tests.
- `calculate-storage.sh` / `calculate-storage.ps1`: deployment scripts.
- `requirements.txt`: pinned dependencies (`psutil`, `requests`).

## Issue data format

Managed rows are `| mark | computer | drive | used | size (type) | <!-- calculate-storage#<computer_name>#<drive> -->`.

- The marker's `drive` is what is passed to `psutil.disk_usage()`; it can differ from the displayed drive column.
- Rows without a marker are kept as is. Marker rows that fail parsing (not 7 `|`-separated parts, or an invalid size column) are not loaded or updated, and are kept unchanged when the body is rewritten. Keep parsing and regeneration consistent when changing `row_regex` or `size_regex`.
- `update_issue_body()` re-fetches the body just before the `PATCH` to avoid overwriting concurrent updates from other hosts.

## Conventions

- Python files use 2-space indentation, LF, UTF-8, and a final newline (`.editorconfig`). Classes are PascalCase, functions and variables snake_case, constants UPPER_SNAKE_CASE.
- The GitHub token is read from `data/github_token.txt` (not an environment variable). `data/` and `results/` are git-ignored; never commit them, and never log tokens or Issue contents.
- OS-specific code branches on `os.name`.
- Tests mock external dependencies (GitHub API, psutil) with `unittest.mock`. Add or update tests when changing parsing, GitHub API logic, disk info retrieval, error handling, or OS-specific code.
- Commits follow [Conventional Commits](https://www.conventionalcommits.org/) and branches follow [Conventional Branch](https://conventional-branch.github.io) (`feat/...`, `fix/...`).
- Do not commit to Renovate PRs.
- Keep `README.md` in sync when behavior, environment variables, or the Issue format change.
