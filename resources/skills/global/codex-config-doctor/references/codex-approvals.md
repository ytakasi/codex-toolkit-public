# Codex 承認と設定の境界

Codex の承認や tool 設定で迷う時の境界メモ。
この文書は正本ではなく、公式ドキュメントへ行くための案内とローカル観測メモとして扱う。
正確なキー名、読み込み場所、継承挙動、フックイベント は作業のたびに公式ドキュメントを確認する。
公式情報の引き方は `openai-docs` skill に従い、この reference では検索手順を持たない。

## 公式ドキュメントで再確認する場所

- `https://developers.openai.com/codex/config-reference#configtoml`
- `https://developers.openai.com/codex/skills`
- `https://developers.openai.com/codex/hooks#where-codex-looks-for-hooks`
- `https://developers.openai.com/codex/subagents#custom-agents`
- `https://developers.openai.com/codex/subagents#approvals-and-sandbox-controls`
- `https://developers.openai.com/codex/agent-approvals-security#sandbox-and-approvals`
- `https://developers.openai.com/codex/enterprise/managed-configuration#locations-and-precedence`

## 境界

- project-scoped `.codex/config.toml` は trusted project でだけ読まれる。
- カスタムエージェントファイルは設定レイヤーであり、別の `allowed_tools` manifest ではない。
- カスタムエージェントファイルには `name`、`description`、`developer_instructions` が必要。
- カスタムエージェントファイルには `sandbox_mode`、`mcp_servers`、`skills.config` など、対応済みの config key を書ける。
- Subagent は現在の sandbox policy を引き継ぎ、親 session の実行時 override が子の起動時に再適用されることがある。
- App / connector tool は `[apps.<id>]` と `[apps.<id>.tools.<tool>]` で設定する。
- MCP tool は `[mcp_servers.<id>]` の `enabled_tools` / `disabled_tools` で設定する。
- `permissions.filesystem.deny_read` は管理側強制設定の項目。リポジトリ固有 hook や `.codex/config.toml` の代わりに、system `requirements.toml` など管理側へ置く。
- Skill 本体の基本形は、skill folder / `SKILL.md` / 任意の `agents/openai.yaml`。
- リポジトリ固有 skill の実行時探索先は、まず公式ドキュメントと現行実装の両方で探索対象になる `.agents/skills` を優先する。
- `codex-kit` 管理リポジトリでは `.agents` は Codex が読む生成先ランタイムルートとして扱い、skill 探索先は `.agents/skills`、リポジトリ固有に育てる資産の正本ルートは `agent-skills/repo` に置く。
- Codex 標準 hook の読み込み口は `.codex/hooks.json` / `.codex/config.toml` なので、`codex-kit` 管理リポジトリでは `.codex/hooks.json` を振り分け入口、`agent-skills/repo/hooks.d/<Event>` をリポジトリ固有 hook の正本として分ける。
- 機密ファイルの読み取り防止は `resources/templates/codex-requirements/requirements.secret-read-deny.toml` を元に管理側強制設定へ寄せ、リポジトリ配布の hook は変更・コピー・stage の補助に絞る。
- 現行 `openai/codex` 実装は project config の隣にある `skills/` もリポジトリ側 skill ルートとして扱うため、`.codex/config.toml` があるリポジトリでは `.codex/skills` が読まれる可能性がある。ただし docs 上の第一説明は `.agents/skills` なので、bootstrapでは `.agents/skills` を既定にする。
- `$CODEX_HOME/skills` は user skill root として後方互換扱い。user横断で使うものは `$HOME/.agents/skills` も確認する。
- `[[skills.config]]` は主に skill の有効 / 無効を上書きする設定として扱い、リポジトリ固有 skill を置いたり発見させたりする主手段と混同しない。project-local `skills.config` はランタイムバージョンにより、モデルから見える skill へ効かない報告があるため、`codex debug prompt-input` などで実測する。
- shell command の承認は approval policy / rules の領域であり、app tool approval ではない。

## 診断順

1. 設定ファイルが実際に読み込まれているか。
2. app / MCP / skill の id が、実行時に見えている対象と一致しているか。
3. TOML 上で引用符が必要な tool key を正しく書いているか。
4. user config、project config、カスタムエージェントファイル、管理側強制設定のどこに置くべき設定か。
5. 親 session の override が子 agent の既定値を隠していないか。
6. その変更はリポジトリに置くべき方針か、個人環境 / 管理環境に置くべき安全設定か。

## Plugin metadata の扱い

同梱 plugin metadata や cache ファイルは、公開 UI に出ない内部 tool 名を確認する最後の観測材料にはなる。ただし安定した公開契約として扱わない。toolkit template を cache パス前提にしない。
