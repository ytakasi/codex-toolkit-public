---
name: scheduled-batch-hardening
description: GitHub Actions、外部scheduler、cron、one-shot batch、watcher、monitor、定期監視ジョブ、Discord通知付きバッチ、Neon/Postgresなど外部DBを使う巡回処理を作る・レビューする時に使う。concurrency、timeout、Secrets/Variables、失敗通知、Webhook retry、migration/seed、通知履歴登録順を固める。
---

# Scheduled Batch Hardening

## 使う場面

- GitHub Actions `schedule` / `workflow_dispatch` でCLIやscriptを1回実行して終了する。
- Discord、Slack、メールなど外部通知と重複排除履歴を持つ。
- Neon/Postgresなど外部DBを使い、migrationやseedの扱いを決めたい。
- 既存リポジトリのscheduled workflowを、運用事故が起きにくい形へ見直したい。

## 手順

1. 実行単位を確認する。
   - 常駐ではなくone-shotか。
   - schedule遅延や再実行が許容される用途か。
   - 1回の上限時間、API rate limit、途中停止時の扱いを確認する。
2. workflowの外枠を固める。
   - `workflow_dispatch` を必ず残す。
   - `timeout-minutes` を設定する。
   - 同一jobの多重起動を避けるため `concurrency` を入れる。
   - 実行時のSecretsと調整用Variablesを分ける。
3. DB操作を分ける。
   - migrationはschedule前に毎回確認するか、release/manualへ分けるかをリポジトリごとに決める。
   - seedや初期投入は、通常scheduleから自動実行しない方をまず検討する。
   - DB設定が0件ならfallbackしてよいか、DB読取失敗もfallbackしてよいかを分けて決める。
4. 外部通知を堅くする。
   - 429/5xx/timeoutなど一時失敗はbounded retryにする。
   - `Retry-After` があれば優先し、なければ短いexponential backoffを使う。
   - retry待ちは最大秒数でcapする。
   - 通知本文は長さ制限に収め、secretや生payloadを出さない。
   - `allowed_mentions` 相当がある通知先では不用意なmentionを抑止する。
5. 通知履歴と観測結果の順序を決める。
   - 通知履歴やdedupe markerは、外部通知が成功した後にだけ保存する。
   - 通知前に観測結果を保存する場合は、通知済み扱いと混同しない。
   - 通知しなかった対象も後から確認したい場合は、観測結果、非通知理由、最終観測時刻を通知履歴とは別の state として保存する。
   - 同じ外部itemを再通知する条件は、値下げ、状態変更、構成変更などに分け、dedupe key と混同しない。
   - 部分失敗を正常終了にするなら、summaryへerror countやstop reasonを残す。
6. 失敗時通知を入れる。
   - 通常通知とは別のSecret/Webhookを使う。
   - app名、job名、repository、run number、attempt、ref、commit、actor、run URLを含める。
   - matrixやshardがある場合は、失敗した軸が通知だけで分かるfieldを足す。
   - Secret未設定時はwarningに留め、元のworkflow失敗状態を隠さない。
   - 雛形が必要なら `assets/github-actions-failure-notify-step.yml` を使う。
7. 検証する。
   - unit testでretry、dedupe順、fallback条件を確認する。
   - workflow YAMLは差分レビューでSecret露出や自動seed混入を確認する。
   - build/test/lintやリポジトリ標準の確認を実行し、開発記録へ残す。

## 原則

- scheduleは厳密な時刻保証ではなく、遅延や再実行があり得る前提で設計する。
- 環境依存値やsecretはENV/Secretsに置き、DBやリポジトリにはsecret本体を置かない。
- 「DBに設定がない」と「DBに接続できない」を同じfallbackにしない。
- seedは便利だが、通常実行に混ぜると意図しない再有効化や設定上書きにつながりやすい。
- 外部通知は成功して初めて外部世界へ出たものとして扱う。
- 共通化するのは運用の型まで。domainの閾値、通知文面、DB schemaはリポジトリ側に残す。

## 出力

- workflowで追加または確認したhardening項目
- Secrets / Variables の一覧
- migration / seed / fallback の扱い
- 外部通知retryと失敗通知の仕様
- 通知履歴登録順の確認結果
- 実行した検証コマンド

## 参照

- DB-backed config rolloutや設定編集UIの保存観点は `references/db-backed-config-rollout.md` を読む。
- .NET one-shot CLI を GitHub Actions schedule へ載せる時は `references/dotnet-scheduled-cli-notes.md` を読む。
- 通知、観測結果、価格履歴、dedupe marker の保存順を確認する時は `references/stateful-observation-history.md` を読む。
- Playwright / Selenium など browser-backed source を scheduled job へ載せる時は `references/browser-backed-source-budget.md` を読む。
- Windows Task Scheduler で one-shot CLI を動かす時は `references/windows-task-scheduler-runner.md` を読む。
- GitHub Actions の失敗通知fieldやmulti-job配置で迷う時は `references/github-actions-failure-notify.md` を読む。
- GitHub Actions の失敗通知stepが必要な時は `assets/github-actions-failure-notify-step.yml` を使う。
- 通知が多すぎる、少なすぎる、届かない時の切り分けは `references/notification-incident-triage.md` を読む。
- 通知履歴、dedupe marker、cursor、checkpoint を触って再実行確認する時は `references/stateful-replay-check.md` を読む。
- 表示名変更で重複通知や履歴断絶が起きそうな時は `references/stable-identity-and-dedupe.md` を読む。
- .NET one-shot CLI を GitHub Actions schedule へ載せる初期形が必要なら `assets/github-actions/dotnet-scheduled-job.yml` を使う。
- Node CLI を GitHub Actions schedule へ載せる初期形が必要なら `assets/github-actions/node-scheduled-job.yml` を使う。
- .NET one-shot CLI の最小コード雛形が必要なら `assets/dotnet-one-shot-worker/` を使う。
