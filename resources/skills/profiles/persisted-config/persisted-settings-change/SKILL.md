---
name: persisted-settings-change
description: 設定画面、管理画面、設定ファイル、CLI option、feature flag などの設定管理機能を追加・変更する時に使う。保存値、表示名、secret境界、migration、seed、validation、既存データ互換、外部API契約の抜けを点検する。
---

# Persisted Settings Change

設定管理機能を追加または変更する時に、model、DB、UI、CLI、docs、tests のどこかだけ更新して事故るのを防ぐ workflow。
scheduled batch だけに限らず、通知先、監視条件、連携先、feature flag などをコード変更なしで変える機能を作るなら使える。

## 使う場面

- 設定画面、管理画面、typed config file、CLI option のどれかに設定項目を追加する。
- 既存設定を ENV / JSON / DB / UI へ移す。
- 表示名、保存key、外部API契約、secret lookup key が混ざりそう。
- nullable、default、backfill、seed、validation の扱いが曖昧。

## 手順

1. 設定の性質を分類する。
   - secret
   - ランタイム option
   - mutable config
   - generated state / history / cache
   - display label
   - external contract value
2. surface を列挙する。
   - domain model / DTO
   - DB schema / migration
   - repository / store / loader
   - seed / example config
   - CLI option / validation
   - admin UI / form / grid
   - docs / setup / README
   - tests / fixtures
3. 保存値と表示名を分ける。
   - 機械可読なキーは安定させる。
   - UI label や表示名を dedupe key、foreign key、secret lookup key にしない。
   - 既存行IDを維持し、表示順やラベル変更だけで別entity扱いにしない。
4. migration / default / seed を確認する。
   - 既存行の backfill が必要か。
   - nullable と `0` / empty string を混同していないか。
   - seed が既存設定や disabled 行を上書きしないか。
   - DB read failure と config empty を同じ fallback にしていないか。
5. UI / docs / tests を揃える。
   - boolean は checkbox、enum は select / combo、numeric は nullable 表現を持つ。
   - 保存中の二重保存を防ぐ。
   - docs に古い env var、旧config section、旧command が残っていないか見る。
   - repository-level test や validation test を置く価値を判断する。

## 参照

- 設定追加・移動・削除で追随surfaceを棚卸しする時は `references/config-surface-audit.md` を読む。
- scheduled batch / watcher の DB-backed config 移行や設定編集UIは `scheduled-batch-hardening` の `references/db-backed-config-rollout.md` を読む。
- 大量設定や secret 境界だけを親エージェントの本流作業と並列レビューしたい時は `references/optional-config-boundary-reviewer.md` を読む。
- 実装後は env、DB、docs drift、manual step が残っていないか確認する。
- ユーザー向け表示文言と機械可読な識別子を分け、保存値や外部契約を表示ラベルの変更に巻き込まない。

## 出力

- 設定分類表
- 変更が必要な surface
- migration / default / seed / validation の判断
- secret と public config の境界
- UI / docs / tests の追随状況
- リポジトリ固有に残すべき設定名やdomain判断
