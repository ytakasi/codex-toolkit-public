# Windows Task Scheduler Runner

Windows Task Scheduler で one-shot CLI / watcher / batch を動かす時の reference。
GitHub Actions と違い、実行ユーザー、working directory、publish先、window表示、state path がズレやすいので先に確認する。

## 登録前に確認すること

- executable path と arguments が publish 先を向いているか。
- working directory が config / relative state path の前提と一致しているか。
- 実行ユーザーが必要な secret、certificate、network、DB接続へアクセスできるか。
- window を出したくない運用では hidden / no-window 実行にしているか。
- local run と scheduler run が同じ config / state DB / cache / log を見ているか。
- 手動実行、last run result、next run time、exit code、log の確認手順があるか。

## 登録scriptに欲しいもの

- `-WhatIf` / dry-run で、登録される task name、trigger、user、executable、arguments、working directory を表示する。
- 既存taskを更新する時、何を上書きするか summary を出す。
- destructive な削除や再作成は明示的な確認を要求する。
- task登録後に、手動runと状態確認コマンドを案内する。

## 出力

- task name / trigger / user
- executable / arguments / working directory
- config / state / log path
- manual test command
- last run result の確認方法
