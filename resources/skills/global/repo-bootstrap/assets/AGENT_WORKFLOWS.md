# Agent Workflows

このリポジトリで複数の agent lane、workflow、review path を使う時の索引。
リポジトリ固有の役割名だけをここへ書き、全リポジトリ共通のルールは `codex-toolkit` 側を正本にする。

| Workflow | 使う場面 | 入力 | 出力 | 検証 | Handoff |
|---|---|---|---|---|---|
| `<workflow-name>` | `<trigger>` | `<files / issue / PR / docs>` | `<artifact / patch / review>` | `<commands / checks>` | `<handoff target>` |

## Subagent 方針

- サブエージェントはユーザーが明示的にサブエージェント、並列探索、並列レビューを求めた時だけ使う。
- 親エージェントは本流作業を担当し、サブエージェントには独立して読める範囲と成果物形式を渡す。
- サブエージェントの報告は、親エージェントが観測した事実と混ぜずに統合する。
