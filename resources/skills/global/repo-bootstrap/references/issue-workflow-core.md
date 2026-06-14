# Issue Workflow Core

Use this reference when a repository uses issues or task tracker items as execution entry points.

## Roles

- Issue body: current execution contract, scope, acceptance criteria, and verification expectations.
- Issue comments: chronological progress, handoff notes, branch / commit / PR links, and final result.
- Long-lived docs or handoff files: durable source of truth for design decisions, operational rules, and reusable context.
- Pull request: review surface for the concrete diff and verification summary.

## Core Rules

- If issue body and durable docs conflict, treat the durable docs or explicit handoff as source of truth and update the issue with a pointer.
- Do not turn the issue body into a running log. Keep logs and progress notes in comments.
- Include a branch name, commit, PR URL, verification summary, and remaining work in the final issue comment when those surfaces exist.
- Use one issue for one reviewable purpose. Split independent follow-up work instead of mixing unrelated acceptance criteria.
- When creating issues programmatically, prefer a body file or API call over interactive issue creation for long Markdown bodies.

## Issue Body Template

task issue body を手作業または CLI / API で作る時は、`work-mode-triage/assets/implementation-issue.md` を正本の初期形にする。
この reference には最低限の役割と運用境界だけを置き、issue body の欄定義は owning skill の asset へ寄せる。

## Final Comment Template

final comment を投稿する時は、対象リポジトリの既存コメント雛形や、実行した検証結果の箇条書きを初期形にする。

## Templates

- task issue body の欄定義は `work-mode-triage/assets/implementation-issue.md` を正本にする。
- 長い Markdown body は、interactive editor に頼らず body file を作って tracker command / API へ渡す。
- Project ID、field ID、label、milestone、automation 固有値はリポジトリ固有 guidance に置く。

## Repository Adapter

Project ID、field ID、label 名、branch prefix、tracker automation などの固有値は、各リポジトリの guidance に置く。この reference は持ち回れる内容に留める。
