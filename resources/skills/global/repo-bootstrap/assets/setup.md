# Setup

このドキュメントを、このリポジトリの環境構築手順の正本にする。
README は概要と quick start、ここは **初回構築 / deploy / 更新時の作業順** を扱う。

## まず全体像

| Surface | 役割 | 主な実行場所 |
| --- | --- | --- |
| REPLACE_ME app/job | REPLACE_ME | local / CI / production |
| REPLACE_ME worker | REPLACE_ME | provider / edge / server |

最初に最低限動かす surface と、本番で必要な surface を分けて書く。

## 0. 初回に叩くコマンド

```bash
REPLACE_ME setup command
REPLACE_ME doctor command
```

setup command がやること:

- `.env` がなければ `.env.example` から作る
- install
- build
- test

setup command が **やらない** こと:

- DB migration
- cloud / provider secret 登録
- deploy
- external provider registration

外部環境へ触る処理は、明示的な deploy / migration 手順へ分ける。

## 1. Local development

### 必須 env

```env
DATABASE_URL=
REPLACE_ME_API_KEY=
RUN_MODE=dry-run
```

### migration

`DATABASE_URL` を確認してから実行する。

```bash
REPLACE_ME migrate command
```

### local 実行

```bash
REPLACE_ME dev command
```

## 2. Production bootstrap

### 2-1. Database

| 接続文字列 | 用途 |
| --- | --- |
| `MIGRATION_DATABASE_URL` | migration 用。schema 変更できる権限を持つ |
| `DATABASE_URL` | ランタイム用。アプリ / worker が使う |

低権限のランタイム用 user を使う場合は、surface ごとに必要 table / sequence 権限を書く。

### 2-2. CI / scheduled jobs

#### Repository secrets

| Name | 用途 |
| --- | --- |
| `REPLACE_ME` | REPLACE_ME |

#### Repository variables

| Name | 備考 |
| --- | --- |
| `REPLACE_ME` | 任意 |

### 2-3. Worker / service deploy

#### ランタイム用 secrets

```bash
REPLACE_ME secret put command
```

#### deploy

```bash
REPLACE_ME deploy command
```

### 2-4. Provider registration

slash command、webhook、callback URL、endpoint registration などがある場合に書く。

```bash
REPLACE_ME register command
```

## 3. 既存環境を更新する時

| 変更 | 必要な作業 |
| --- | --- |
| migration が増えた | migrate |
| ランタイム用 env / secret が増えた | secret / variable 更新 |
| worker / deploy config を変えた | deploy |
| command / webhook 定義を変えた | provider registration 再実行 |
| docs / setup を変えた | smoke test 手順を確認 |

## 4. Smoke test

### local

```bash
REPLACE_ME doctor command
REPLACE_ME build command
REPLACE_ME test command
```

### production / provider

1. REPLACE_ME
2. REPLACE_ME
3. REPLACE_ME

## 5. よくある詰まりどころ

| 症状 | まず見る場所 |
| --- | --- |
| command が出ない | provider registration を再実行したか |
| DB error | migration 未適用、またはランタイム用 user 権限不足 |
| pending job が進まない | worker / cron / schedule が deploy 済みか |
| auth error | public key / secret / endpoint URL |
| local env error | doctor command の error 行 |

## 6. 補足

リポジトリ固有の補足、採用しなかった IaC、手動運用に残す判断を書く。
