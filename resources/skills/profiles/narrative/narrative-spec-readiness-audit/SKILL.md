---
name: narrative-spec-readiness-audit
description: 物語、分岐、状態管理、意思決定フロー、ゲーム設計、シナリオ資料、条件DSL化前の仕様が実装可能な粒度か監査する時に使う。route、ending、state、fact、条件、UI表示、ID、未決定事項を点検し、実装前にmust-fixと保留可能点を分ける。
---

# Narrative Spec Readiness Audit

物語や分岐仕様を、実装前に「まだ曖昧な文章」から「実装できる契約」へ近づけるための監査 workflow。

## 使う場面

- ユーザーが「まだ編集せず仕様を見て」「実装前に穴を探して」「分岐条件を確認して」と言った時。
- シナリオ、route、ending、quest、decision flow、state machine などが docs にあり、実装前に曖昧さを潰したい時。
- 物語上の制約、既知情報と取得情報の境界、UI に出す情報と内部状態の境界が壊れると product の意味が変わる時。

## 使わない場面

- 既にコードが中心で、責務分担や変更容易性を見たい時は `clarity-review` を使う。
- 表示文言だけを整える時は、表示ラベル、保存値、分岐ID、外部契約を分けて扱う。
- 外部providerやscheduled jobの運用境界が主題なら、それぞれの専用 skill を使う。

## 手順

1. 読み取り範囲と編集可否を確認する。
   - ユーザーが編集禁止を指定しているなら、file は触らず audit だけ行う。
   - docs、design note、route表、user guide、既存 data schema を列挙する。
2. 仕様を実装契約へ分解する。
   - 目的、世界観やdomain制約、分岐条件、ending条件、状態遷移、ID体系、UI surface、失敗や詰み条件を見る。
   - リポジトリ固有名詞をそのまま共通ルールへ持ち込まず、「どの種類の制約か」に言い換える。
3. readiness gap を分類する。
   - 実装前に必ず決めるもの。
   - 最小縦 slice では仮置きできるもの。
   - リポジトリ固有の物語判断として toolkit へ昇格しないもの。
4. 判定を出す。
   - `No-Go`: 実装すると分岐、状態、情報境界が壊れる可能性が高い。
   - `Conditional Go`: 最小実装は可能だが、明示した未決事項を残す。
   - `Go`: 実装に必要な契約が十分あり、残りは通常の実装判断で扱える。
5. 次の作業に渡す。
   - 必要なら `assets/spec-audit-report.md` の形で監査結果を出す。
   - 条件の書き方で迷う時は `references/branching-condition-patterns.md` を読む。
   - 詳細チェックは `references/spec-readiness-checklist.md` を必要箇所だけ参照する。
   - 条件 schema の開始形が必要なら `assets/branching-schema-starter.yaml` を使う。
   - 監査結果を実装 slice へ渡す時は `references/implementation-bridge.md` を読む。
   - ユーザーが明示的に並列 review を求めた時だけ、`references/optional-subagent-lanes.md` を使う。

## 出力

- 対象にした資料
- readiness 判定
- Must fix before implementation
- Can defer
- リポジトリ固有として残す
- Suggested implementation slice
- Open questions

## 原則

- 物語固有の判断を、無理に global rule へ一般化しない。
- 分岐条件は「自然文として分かる」ではなく「実装者が条件式に落とせる」かで見る。
- ID、状態、UI表示、情報取得の境界は、後から直すと data migration やsave互換へ響くため先に見る。
- standalone な workflow 棚は増やさず、この skill の references / assets から辿れる形にする。
