# Hooks

Codex 標準の hook は `codex-kit` から配布する。
ただし Codex が直接読むのは、対象リポジトリに生成される `.codex/hooks.json` だけにする。

このディレクトリには、toolkit 側で管理する hook の正本を置く。
リポジトリ固有 hook は、対象リポジトリの `agent-skills/repo/hooks.d/<Event>` に置く。

機密ファイルの読み取り防止は、Codex の管理側強制設定に置く `permissions.filesystem.deny_read` を本命にする。
global hook は、リポジトリ配布で扱いやすい補助として、生成物の直編集や機密ファイルの変更・stage を止める。

`codex-kit sync` は、選択 profile の toolkit hook を `agent-skills/toolkit/hooks.d` へ反映し、`.codex/hooks.json` に薄い振り分け入口を生成する。
振り分けスクリプトは `agent-skills/toolkit/hooks.d/<Event>` と `agent-skills/repo/hooks.d/<Event>` を読み、同じ相対パスではリポジトリレイヤーを勝たせる。

各 hook は、ほかの hook との実行順に依存しないように作る。
`codex-kit` の振り分けスクリプトは実行結果を安定させるためにファイル名順で実行するが、順序制御を hook の前提にしない。

## global hook 一覧

| hook | 対象イベント | 役割 |
|---|---|---|
| `generated-layer-guard.ps1` | `PreToolUse` | `.agents`、`agent-skills/toolkit`、`.codex/hooks.json`、`.codex/hooks/codex-kit-dispatch.*` への直接変更を止める。変更は `agent-skills/repo` か `codex-kit sync/update` に寄せる。 |
| `secret-file-mutation-guard.ps1` | `PreToolUse` | `.env`、秘密鍵、認証情報や機密情報の JSON など、機密情報が入っていそうなファイルの変更、コピー、stage を止める。`.env.example` などの例や雛形は許可する。 |

`codex-toolkit` リポジトリ自体の検証注意は配布対象ではないため、このディレクトリには置かない。
このリポジトリの `.codex/hooks.json` と `.codex/hooks/toolkit-validation-reminder.ps1` で直接設定する。

PreToolUse で止める時は exit code `2` と stderr の理由で返す。
Stop の hook は `systemMessage` で注意だけを返し、作業は止めない。
