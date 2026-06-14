# 任意の Source Scout

ユーザーが明示的にサブエージェント / 並列探索を求めた時だけ使う read-only lane 候補。通常は親エージェントが `provider-dry-run` と `web-source-intake.md` を使う。

## いつ使うか

- 複数 URL、複数 provider、複数 selector 候補がある。
- 親エージェントが adapter 設計や実装方針を進める横で、取得可否だけを独立に見たい。
- 認証や secret を使わず、安全な read-only 観測で足りる。

## 親エージェントが渡すもの

- 候補 URL / endpoint。
- 欲しい field 一覧。
- static fetch 優先か、browser rendering まで見てよいか。
- 上限ページ数、対象カテゴリ、避けたい副作用。

## Lane contract

サブエージェントへ渡す時は、次の形に縮める。親エージェントの推測や期待解は入れず、観測対象と制約だけを渡す。

```text
You are the read-only source-scout lane for this run.

Target:
- <URLs, endpoints, or provider pages to inspect>

Purpose:
- Determine whether the requested fields can be observed safely.

Inputs:
- Requested fields: <field list>
- Fetch mode: <static first / rendered DOM allowed>
- Limits: <max pages, categories, request budget>

Constraints:
- Do not modify files, accounts, provider state, or remote settings.
- Do not use secrets or authenticated flows unless the parent explicitly includes approved credentials handling.
- Do not implement the adapter or parser.
- Record uncertainty instead of inventing fields.

Output:
1. Source viability: <static/API/rendered DOM/blocked>
2. Field availability table
3. Selector or path candidates
4. Pagination and rate/ランタイムリスク
5. Fixture candidates
6. Open questions and blocked observations
```

Stop and report `blocked` if the source requires login, secret-bearing requests, CAPTCHA, destructive actions, or broad crawling beyond the supplied limits.

## 成果物

- static HTML / API / rendered DOM のどれで足りるか。
- 安定 selector 候補。
- 取れる field、取れない field、safe default。
- pagination、ランタイムリスク、fixture 化候補。
- 既存 source / parser で足りるか、専用実装が必要か。
