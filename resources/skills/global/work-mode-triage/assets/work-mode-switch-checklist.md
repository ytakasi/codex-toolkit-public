# Work Mode Switch Checklist

Use this when a request may move from discussion into edits, verification, commits, PRs, or external tracking updates.

## Explore

- User wants comparison, brainstorming, or diagnosis:
- Source of truth is not selected:
- Target files or artifacts are not fixed:
- リポジトリ編集、外部 write、commit、PR が不要:

## Draft

- Target files or artifacts are known:
- Work can stay local and reversible:
- Output is a proposal, patch draft, or scoped content change:
- No durable tracking update is required yet:

## Apply

- Source of truth must be updated:
- Generated or derived artifacts must be refreshed:
- Build, test, validator, or smoke check is part of completion:
- Commit, push, PR, issue, ticket, or release note is part of completion:

## Tracking-only

- The artifact is an umbrella issue, parent ticket, Project item, or status thread:
- The next execution unit is a child issue, PR, branch, or named lane:
- Closing this item does not prove the underlying implementation is complete:
- Any source-of-truth edits are intentionally out of scope:

## Decision

- Selected mode:
- Switch reason:
- Required intake / handoff:
- Completion boundary:
