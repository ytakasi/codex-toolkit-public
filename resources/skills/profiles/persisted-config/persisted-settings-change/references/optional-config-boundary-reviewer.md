# Optional Config Boundary Reviewer

ユーザーが明示的に サブエージェント / 並列レビューを求めた時だけ使う read-only lane 候補。通常は親エージェントが `persisted-settings-change` と `config-surface-audit.md` を使う。

## いつ使うか

- ENV、Secrets、DB、local file、UI、docs にまたがる大量設定がある。
- secret 本体、secret lookup key、public config、generated state の境界が混ざりそう。
- 親エージェントが実装を進める横で、分類表と境界リスクだけを独立に作りたい。

## 親エージェントが渡すもの

- 現行設定 model、設定ファイル例、env / secret 一覧。
- DB schema、管理 UI、workflow、fallback 方針の草案。
- 変更してよい範囲と read-only 範囲。

## 成果物

- 設定分類表。
- secret 混入リスク。
- DB へ移す候補、fallback 禁止条件。
- 保存 identity と migration 順序のリスク。
- リポジトリ固有に残すべき設定名や domain 判断。
