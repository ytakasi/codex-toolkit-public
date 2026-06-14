---
name: repo-bootstrap
description: 新規リポジトリ、空リポジトリ、初回commit前、既存リポジトリの初期セットアップ不足を埋める時に使う。README、AGENTS.md、docs/DEVELOPMENT_STORY.md、既定branch、正本docs、初期保存、リポジトリ初期化の骨格を整え、最初の実装へ入れる状態を作る。
---

# リポジトリ初期化

## 手順

1. リポジトリの目的と公開範囲を確認する。
   - private / public の意図、README に書くべき最小スコープ、最初に決めるべき運用条件を把握する。
   - 作業ディレクトリが空、または `README.md` / `AGENTS.md` / `docs/DEVELOPMENT_STORY.md` が未整備なら、初回実装前でも bootstrap 対象として扱う。
   - ユーザーが実装を急いでいる場合でも、最低限の初期骨格を同時に置けるか判断し、明示的に見送る場合は理由を残す。
2. 初期骨格を置く。
   - `README.md`
   - `AGENTS.md` は `assets/AGENTS.md` を叩き台にし、リポジトリ固有差分だけを書く。
   - `docs/DEVELOPMENT_STORY.md` は `assets/DEVELOPMENT_STORY.md` を叩き台にして必ず置く。
   - 複数agent laneや常設workflow索引が必要なら `assets/AGENT_WORKFLOWS.md` を使う。
3. 先に決めるべきことを明文化する。
   - 実行環境
   - 秘密情報の置き場
   - ランタイム / migration / provisioning credential の分離方針
   - CI から stateful IaC を実行する場合の remote backend / state 管理
   - ドキュメントの正本
   - 生成物や直接編集しないファイル
   - branch / worktree の基本方針
   - 人間判断を残す範囲
   - Codex project config を置く場合は、リポジトリ全員に効いてよい policy だけに絞る。個人の approval、絶対path、connector tool 承認は user config へ寄せる。
4. setup surface を整える。
   - README は最初の入口に留め、詳細な環境構築やdeploy手順は必要なら `docs/setup.md` を正本にする。
   - `docs/setup.md` の初期形が必要なら `assets/setup.md` を使う。
   - Node系の安全な setup helper が必要なら `assets/setup-helper-node/` を叩き台にする。
   - 自動化する場合は、依存関係install、build、test、`.env` 雛形作成など local-safe な処理から始める。
   - DB migration、cloud secret、deploy、外部provider設定のような mutation は setup script が勝手に実行しない。必要なら doctor / checklist で未完了事項として表示する。
5. 必要なら初期保存まで進める。
   - 既定 branch は、特別な理由がなければ `main`
   - `.gitignore` を確認する。
   - 初期 commit と remote / push が必要か確認する。
6. 持ち越しが発生する時だけ、`docs/NEXT_SESSION.md` を追加する。

## 原則

- リポジトリの `AGENTS.md` へ global 方針を重複させず、そのリポジトリだけの差分を書く。
- issue や task tracker を使うリポジトリでは、issue body は実行契約、issue comment は時系列、長期 docs / handoff は正本として使い分ける。
- `README.md` はリポジトリの目的、起動方法、現在のスコープを示す入口に留め、実行手順や常設方針の正本を重複させない。
- issue や task tracker を使うリポジトリでは、詳細な役割分担は `references/issue-workflow-core.md` を叩き台にする。
- 長期の開発記録は、複数セッション化を待たず最初から置く。
- 空リポジトリへの最初の実装は、実装作業であると同時にリポジトリ運用の初期化でもある。
- setup helper は「安全に自動化するもの」と「人間が外部surfaceで行うもの」を分ける。便利さのために secret 登録やdeployを暗黙実行しない。
- 最初から完璧な運用を作るより、後で判断を追える最小の骨組みを先に置く。
- bootstrap 中に汎用的な資産が生まれたら、`toolkit-promotion` skill で昇格候補か判定する。

## 出力

- 追加または更新した初期ファイル
- まだ決めていない運用論点
- 初期 commit / push まで進めたか
- 次に着手すべき最初の1手
