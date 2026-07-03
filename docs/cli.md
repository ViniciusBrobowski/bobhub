# BobHub CLI

## Overview

The BobHub CLI is a command-line interface used to operate common tasks in the BobHub lab.

It centralizes scripts related to Git, Observability and Health checks, making day-to-day operations easier and more consistent.

The CLI is not intended to replace the individual scripts. Instead, it acts as a single entrypoint to access them through menus.

---

## Usage

From the repository root:

```bash
./cli/bobhub.sh
```

From any subdirectory, use the full path:

```bash
/path/to/bobhub/cli/bobhub.sh
```

Example:

```bash
~/git/bobhub/cli/bobhub.sh
```

---

## Main Menu

The initial version of the CLI includes the following menus:

```text
1) Git
2) Observability
3) Health
0) Exit
```

---

## Git Menu

The Git menu provides basic Git operations for the project.

Available options:

```text
1) Git status
2) Commit and push
3) Git log
0) Back
```

### Commit and push

The CLI uses the Git helper script:

```text
scripts/git/git-commit-push.sh
```

This script adds all changes, creates a commit and pushes to the remote repository.

It also supports closing a GitHub issue automatically when an issue number is provided.

Example:

```bash
./scripts/git/git-commit-push.sh "Update CLI documentation" 4
```

This generates a commit message with:

```text
Closes #4
```

After the push, GitHub closes the issue automatically and moves the related Project card to Done.

---

## Observability Menu

The Observability menu centralizes operations related to the monitoring stack.

Available options:

```text
1) Start stack
2) Stop stack
3) Restart stack
4) Validate Prometheus
5) Health check
0) Back
```

These options call scripts from:

```text
scripts/observability/
```

Current scripts:

```text
start-observability.sh
stop-observability.sh
restart-observability.sh
validate-prometheus.sh
health-check.sh
```

---

## Health Menu

The Health menu provides validation options for the current observability environment.

Available options:

```text
1) Observability health check
2) Validate Prometheus
0) Back
```

The goal is to quickly check whether the monitoring stack is healthy and whether Prometheus configuration files are valid.

---

## Related Scripts

Current operational scripts used by the CLI:

```text
scripts/
├── git/
│   └── git-commit-push.sh
│
└── observability/
    ├── health-check.sh
    ├── restart-observability.sh
    ├── start-observability.sh
    ├── stop-observability.sh
    └── validate-prometheus.sh
```

---

## Recommended Workflow

The recommended BobHub workflow is:

```text
Create Issue
    ↓
Move card to In Progress
    ↓
Implement changes
    ↓
Validate
    ↓
Commit with issue reference
    ↓
Push
    ↓
GitHub closes the issue automatically
    ↓
Project card moves to Done
```

Example:

```bash
./scripts/git/git-commit-push.sh "Document BobHub CLI usage" 4
```

---

## Notes

The CLI is currently in its first version.

Future improvements may include:

* GitHub issue importer
* GitHub Project helpers
* Alertmanager operations
* Docker management menu
* Backup menu
* BobHub doctor command
* Integration with AI-assisted planning
