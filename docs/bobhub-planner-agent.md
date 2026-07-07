# BobHub Planner Agent

## Overview

The BobHub Planner Agent is an AI-assisted planning workflow designed to transform raw project ideas into structured GitHub issues.

Instead of manually writing every issue, the Planner Agent helps create consistent, well-defined backlog items that follow the BobHub standards.

The first version is intended to be **manual/semi-automated**, using ChatGPT (or another LLM) together with the existing BobHub scripts.

---

# Purpose

The Planner Agent should:

- Transform project ideas into structured GitHub Issues.
- Standardize issue quality.
- Reduce manual planning effort.
- Ensure every issue contains enough context for implementation.
- Keep the GitHub Project organized.

---

# Current Workflow

```text
Project Idea
      │
      ▼
Planner Agent
      │
      ▼
Structured Issue Draft
      │
      ▼
Review
      │
      ▼
templates/issues.yaml
      │
      ▼
import-issues.sh
      │
      ▼
GitHub Issue
      │
      ▼
GitHub Project
```

---

# Required Project Context

The Planner Agent should use the following project files as context:

- `README.md`
- `docs/devops-drd-roadmap.md`
- `docs/bobhub-cli.md`
- `templates/issues.yaml`
- Existing GitHub Issues
- Existing GitHub Labels
- GitHub Project structure

These files provide enough context for the agent to avoid duplicate work and generate issues that follow the project's standards.

---

# Input Format

The first version accepts a simple natural language description.

Example:

```text
Create a script that generates infrastructure inventory documentation automatically.
It should collect Linux, Docker and network information and save the result as Markdown.
```

---

# Expected Issue Structure

Every generated issue should contain:

```md
## Context

Explain why the feature is needed.

## Tasks

- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

## Acceptance Criteria

- Requirement 1
- Requirement 2
- Requirement 3

## Labels

- bobhub
- automation

## Dependencies

- None
```

---

# Labels Strategy

| Label | Purpose |
|--------|---------|
| bobhub | General BobHub work |
| automation | Scripts and automation |
| github | GitHub integrations |
| devops | DevOps practices |
| documentation | Documentation tasks |
| infrastructure | Infrastructure related work |
| observability | Monitoring and metrics |
| security | Security improvements |

---

# Milestones Strategy

Suggested milestones:

| Milestone | Purpose |
|------------|---------|
| v0.1 Foundation | Core project setup |
| v0.2 Automation | GitHub automation |
| v0.3 Observability | Monitoring stack |
| v0.4 Infrastructure | Infrastructure documentation |

---

# GitHub CLI Integration

The Planner Agent should integrate with the existing issue importer.

Current flow:

```text
Planner Agent
        │
        ▼
templates/issues.yaml
        │
        ▼
scripts/git/import-issues.sh
        │
        ▼
GitHub Issues
```

Future versions may generate issues directly using GitHub CLI.

Example:

```bash
gh issue create \
  --title "Issue Title" \
  --body "Issue Description" \
  --label "bobhub"
```

---

# First Version

The initial implementation will be **manual/semi-automated**.

Reasons:

- Simple to validate.
- No API complexity.
- Easy to improve over time.
- Fits the current BobHub maturity.

Workflow:

```text
Idea
 │
 ▼
Planner Agent
 │
 ▼
Issue Draft
 │
 ▼
Review
 │
 ▼
templates/issues.yaml
 │
 ▼
Import Script
 │
 ▼
GitHub Issue
```

---

# Example Input

```text
Create a helper script to generate GitHub Releases automatically from the latest commits.
```

---

# Example Output

```md
## Context

Automate the release creation process for BobHub.

## Tasks

- [ ] Create release helper script
- [ ] Read latest Git commits
- [ ] Generate release notes
- [ ] Publish release using GitHub CLI

## Acceptance Criteria

- Release helper exists
- GitHub Release is created automatically
- Documentation updated

## Labels

- bobhub
- automation
- github

## Dependencies

- GitHub CLI
```

---

# Proposed Workflow

1. Describe the project idea.
2. Planner Agent generates a structured issue.
3. Review the generated issue.
4. Save it to `templates/issues.yaml`.
5. Run the issue importer.
6. Add the issue to the GitHub Project.
7. Track implementation using the project board.

---

# Future Improvements

- Automatic dependency detection.
- Duplicate issue detection.
- Automatic milestone selection.
- Automatic label suggestion.
- Direct GitHub Project integration.
- AI-generated implementation checklist.
- Automatic DRD roadmap mapping.

---

# Conclusion

The BobHub Planner Agent establishes a standardized planning process that transforms ideas into actionable GitHub Issues. Starting with a manual/semi-automated workflow allows validation of the planning model before introducing deeper integrations with the GitHub API and other automation tools.