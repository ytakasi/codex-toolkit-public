---
name: codex-config-doctor
description: Codex の設定詰まりを診断する時に使う。カスタムエージェント、承認、サンドボックス、app tool、MCP tool、skills.config、project trust、モデル利用可否 / 既定モデル、リポジトリ固有のスキル探索が効かない時に、公式仕様とローカル設定を照合し、最小の .codex/config.toml / rules / agent 変更へ整理する。
---

# Codex Config Doctor

Codex の設定詰まりを、エージェント定義の問題、project trust、承認ポリシー、サンドボックス、app / MCP tool、スキル有効化、モデル利用可否 / 既定モデルに分けて診断する手順。

## 手順

1. 症状を分類する。
   - app tool や MCP tool の承認が毎回出る。
   - カスタムエージェントに設定を書いたのにサブエージェントへ効かない。
   - project-local `.codex/config.toml`、`.codex/agents/*.toml`、rules、skills が読まれない。
   - サンドボックス / network / writable root の失敗が product bug に見える。
   - 公式発表、APIドキュメント、Codex UI / CLI、local config のモデル利用可否や既定モデルが食い違う。
2. 変わりやすい仕様は公式ドキュメントを先に確認する。
   - config key、フックイベント / フックJSON、カスタムエージェント、サブエージェントの継承、承認 / サンドボックス、管理側強制設定、スキル探索、モデル利用可否 / 既定モデルは毎回公式ドキュメントを確認する。
   - 公式情報の引き方は `openai-docs` スキルに委譲し、このスキルでは検索手順や fallback 手順を再定義しない。
   - `openai-docs` が使えない時だけ、OpenAI developer docs MCP または公式 OpenAI domain への fallback を行い、その fallback を報告する。
   - `references/` は正本ではなく、公式ドキュメントへ行くための案内メモとローカル観測メモとして扱う。
   - 公式ドキュメントとローカル観測が割れた場合は、どちらを見たか、観測日、まだ未確定の点を分けて報告する。
   - 公式確認ができない場合は、fallback として参考メモを使ったことを明示し、設定変更は狭くする。
3. 設定の置き場を確認する。
   - user config: `~/.codex/config.toml`
   - auth mode: `~/.codex/auth.json` の伏せた観測事実だけ。token や account identifier は出さない。
   - model cache: `~/.codex/models_cache.json` は観測値として扱い、正本にしない。
   - project config: `.codex/config.toml`
   - project custom agents: `.codex/agents/*.toml`
   - 管理側強制設定: クラウド管理の強制設定、MDM、system `requirements.toml`
   - rules / approval prefix: project rules と user rules
   - app / MCP / スキルのメタデータ: connector id、tool id、skill path
4. project trust を先に見る。
   - project-scoped `.codex/` レイヤーは trusted project でだけ読む前提。
   - trust 状態が疑わしい時は、設定値の正誤より先に「この project-local config が読み込まれているか」を確認する。
5. カスタムエージェントと承認 / サンドボックスの境界を分ける。
   - カスタムエージェントは通常の config key を持てるが、親セッションの実行時 override が子へ再適用されることがある。
   - `allowed_tools` のような専用 agent manifest を探す前に、app tool approval、MCP 許可リスト、rules、sandbox policy を確認する。
   - 詳細が必要なら `references/codex-approvals.md` を読む。
6. モデル利用可否と既定モデルを切り分ける。
   - API、ChatGPT、Codex app / CLI、organization / project permission を同じ利用可否として扱わない。
   - local `model = "..."` pin がある時は、app default が変わってもそのセッションが追随しない可能性を見る。
   - 詳細が必要なら `references/openai-model-availability-triage.md` を読む。
7. tool ごとの置き場所を選ぶ。
   - ChatGPT Apps / connectors: `[apps.<id>]` と `[apps.<id>.tools.<tool>]`
   - MCP server tools: `[mcp_servers.<id>]` の `enabled_tools` / `disabled_tools`
   - shell command approval: rules / approval prefix
   - filesystem read deny: 管理側強制設定の `permissions.filesystem.deny_read`
   - スキル探索: ランタイムが読むリポジトリ固有 `.agents/skills`、user `$CODEX_HOME/skills` / `$HOME/.agents/skills`、必要なら現行実装の project config 隣接 `skills/`
   - `codex-kit` 管理リポジトリでは、`.agents` は生成先ランタイムルート、スキル探索先は `.agents/skills`、リポジトリ固有資産を編集する正本ルートは `agent-skills/repo` として切り分ける。
   - Codex 標準フックは `.codex/hooks.json` を toolkit 管理の振り分け入口とし、リポジトリ固有フックの正本は `agent-skills/repo/hooks.d/<Event>` に置く。
   - スキルの有効 / 無効の上書き: `[[skills.config]]`
8. 変更は最小化する。
   - 個人の承認設定、絶対パス、connector id、tool id、model pin は template の既定値に焼かない。
   - `.env` や秘密鍵の読み取り防止はリポジトリ側 hook だけに寄せず、`requirements.toml` へ入れるべきか確認する。
   - リポジトリに置く場合は、リポジトリ全員に効いてよい policy だけに絞る。
   - 個人運用なら user config へ寄せ、リポジトリ側 config へ置くなら理由を残す。
9. 反映確認をする。
   - TOML を読み直し、引用符が必要な tool id を確認する。
   - 必要なら新しい session / thread で確認する。
   - 公式ドキュメントと実環境の表示が割れたら、公式ドキュメント、現行 config、UI / plugin metadata のどれを観測したかを分けて報告する。

## 参照

- `references/codex-approvals.md`: Codex config / カスタムエージェント / 承認 / サンドボックス / 管理側強制設定の境界の詳細。
- `references/openai-model-availability-triage.md`: OpenAI model announcement、API availability、Codex default、local model pin の切り分け。
- `assets/config-snippets.toml`: project config へ最小追加する時のプレースホルダー付き例。
