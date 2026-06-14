# OpenAI Model Availability Triage

OpenAI の model 発表、API docs、Codex UI、Codex CLI、local config の見え方が食い違う時に使う切り分け reference。

## 先に見る情報源

- 公式 OpenAI docs または公式発表を先に確認し、対象 surface が API、ChatGPT、Codex app、Codex CLI、organization / project admin のどれかを記録する。
- local cache、bundled plugin metadata、UI 表示は観測値であり、正本として扱わない。
- ユーザーが「今日」「latest」「default」「rollout」を参照している時は、具体的な日付を入れて報告する。

## product surface を分ける

- API モデル利用可否: 現在の organization / project で model id を API から使えるか。
- ChatGPT availability: signed-in account と plan で ChatGPT UI から選べるか。
- Codex app / CLI availability: 現在の Codex session で選択または default 化されているか。
- Local config: `~/.codex/config.toml` や project `.codex/config.toml` が model を pin していないか。
- 認証方式: Codex が ChatGPT sign-in なのか API-key auth なのか。API availability があるだけで Codex app default availability があるとは扱わない。

## local check

redacted fact だけを見る。token、API key、refresh token、account identifier は表示しない。

- `~/.codex/auth.json`: ChatGPT sign-in / API key auth など auth mode だけ。
- `~/.codex/config.toml`: 明示的な `model = "..."`、reasoning effort、app / MCP / tool policy、project trust 関連設定。
- project `.codex/config.toml`: trusted project で読まれる リポジトリ固有 model / ランタイム override。
- `~/.codex/models_cache.json`: 現在の cache 観測値。ここに無いことは stale cache や rollout lag でも起きるため、model 不存在の証拠にしない。
- Codex UI / CLI model picker: 現在の session で実際に選べる model list。

## fix flow

1. 公式ドキュメントでは利用可能なのに Codex が古い model を使う時は、rollout 不具合と決める前に local `model = "..."` pin を見る。
2. app default に追随したいだけなら、model pin だけを外すか緩める。reasoning effort や tool policy など無関係な設定は触らない。
3. API では使えるが Codex UI に出ない場合は、公式 Codex docs が別の説明をしていない限り、product surface 差または rollout 差として報告する。
4. API連携を移行する時は、コード、テスト、prompt 前提、migration note の model id を更新する。local Codex app config 変更を API migration の代わりにしない。
5. config を変えた後は、必要なら fresh session や model picker refresh で確認し、即時 rollout を約束せず観測結果として報告する。

## 報告に含めるもの

- 確認した公式情報源と観測日。
- 比較した product surface。
- redacted local config observation。
- 実施した config 変更、特に model pin の削除。
- 残る不確実性: account rollout、organization permission、stale cache、UI refresh など。
