---
name: toolkit-integrity-audit
description: `codex-toolkit` 自体のスキル、テンプレート、参考メモ、同梱資産、共通ルールテンプレート、インストーラー、検証スクリプト、README、配布モデルを変更した後の整合性確認に使う。メタデータ、参照切れ、重複、改行コード、生成先ランタイム / 正本の混同、公開入口を点検する。
---

# Toolkit Integrity Audit

`codex-toolkit` 自体を触った後に、追加した資産が次の session で迷わず使える状態か確認する手順。
単なるスクリプト実行ではなく、スキル、テンプレート、参考メモ、共通ルールの置き場所と入口が揃っているかを見る。

## 使う場面

- スキル、テンプレート、参考メモ、同梱資産、共通ルールを追加または移動した。
- `revisit-candidates.md` から候補を昇格した。
- インストーラー、検証スクリプト、README の入口を変えた。
- 既存資産へ吸収した結果、古い候補や重複説明が残っていないか確認したい。
- `codex-kit` CLI、hook 振り分け、管理側強制設定、`.agents` 生成のどれかを触った。

## 手順

1. リポジトリ状態を確認する。
   - `git status --short --branch`
   - `git diff --stat`
   - 既存の未コミット変更と今回触る差分を分ける。
2. リポジトリ内検証を実行する。
   - まず `.\scripts\validate-skills.ps1` を使う。
   - shell都合で失敗したら、サンドボックス / ツール環境由来か、toolkit の整合性失敗かを分ける。
3. スキルのメタデータを見る。
   - 各スキルに `SKILL.md` と `agents/openai.yaml` があるか。
   - `SKILL.md` frontmatter の `name` がディレクトリ名と一致しているか。
   - `agents/openai.yaml` の `default_prompt` が自然な文で `$skill-name` を含むか。
4. 参照と入口を確認する。
   - README や親スキルから新しい参考メモ / 同梱資産へ辿れるか。
   - 移動済み参考メモの旧パスが残っていないか。
   - スキルを `resources/skills/global` や `resources/skills/profiles/<profile>` へ移す時、スキルルート直下前提の直書きパスや、上位ディレクトリへ戻るテンプレート参照が残っていないか。
   - `codex-kit` 配布モデルでは、対象リポジトリ内の toolkit レイヤー `agent-skills/toolkit`、リポジトリ側の正本ルート `agent-skills/repo`、生成先ランタイムルート `.agents` を混同していないか。
   - スキルやランタイムメタデータを作るメタスキル / スクリプトが、sync で消える `.agents` ではなく正本ルートへ書く前提になっているか。
   - `.codex/hooks.json` をリポジトリ固有フックの編集場所にしていないか。フック本体は `hooks.d/<Event>` 側へ寄せているか。
   - `permissions.filesystem.deny_read` のような管理側強制設定を、リポジトリ配布 hook や `.codex/config.toml` に誤って寄せていないか。
   - 共通ルールを圧縮した場合、専門スキルの `description` が発火導線として十分か。
   - `revisit-candidates.md` に昇格済みの本文が残っていないか。
5. 重複を確認する。
   - テンプレートとスキル同梱資産に同じ実行知識を二重化していないか。
   - 単独のワークフロー / ガイダンス棚を増やしていないか。
   - 既存スキルの参考メモへ吸収できる内容を新スキルにしていないか。
6. テンプレートと公開入口を確認する。
   - テンプレートにリポジトリ固有の実値、絶対パス、secret名、provider名、ランタイムバージョンが固定値として混ざっていないか。
   - プレースホルダーは `REPLACE_ME_*`、安全な例、空値のどれにすべきか判断できる形になっているか。
   - README、共通ルール、スクリプト、テンプレート、検証から新しい資産へ辿れるか。
   - shell / OS 固定のコマンド例がローカル標準手順として残っていないか。
   - 人間向けのドキュメント、コメント、CLI 表示文言が日本語に寄っているか。コマンド名、オプション名、JSONキー、TOMLキーだけを識別子として英語に残しているか。
7. git hygiene を確認する。
   - `git diff --check`
   - 内容差分なしの改行コード変更や、意図しないファイルモード / 空白変更がないか。
   - 共通ルールテンプレート `resources/global/AGENTS.common-rules-template.md` は LF-only を維持する。
8. 必要なら配布の事前確認を行う。
   - リポジトリ配備や published skill の入口を変えた時は、`codex-kit update --dry-run` / `codex-kit sync --dry-run` で何が変わるか見る。
   - PATH 入口を変えた時は、`.\scripts\install-codex-kit.ps1 -DryRun` と process scope の起動確認を優先する。
9. `codex-kit` CLI を触った場合は command 境界を確認する。
   - CLI 実装や変更なら、CLI の責務境界、docs、検証、公開面が揃っているかを追加で見る。
   - 削除・再生成対象はリポジトリ内の解決済みパスだけか。
   - `sync` と `harden` の責務が混ざっていないか。
   - `.codex/hooks.json` は薄い振り分け入口で、hook 本体を直接埋め込んでいないか。

## 参考メモの読み分け

- テンプレートのプレースホルダーと実値混入が主題なら `references/template-placeholder-audit.md` を読む。
- README、共通ルール、setup、スクリプト、検証など外側の入口が主題なら `references/public-surface-review.md` を読む。
- `codex-kit` CLI の init / sync / update / harden 実装が主題なら、CLI 実装用の詳細手順が配備されているか確認する。

## 出力

- 実行した検証 / diff check
- メタデータ / 参考メモ / テンプレート / 共通ルールの確認結果
- `revisit-candidates.md` から削除または縮約した候補
- 残した未解決論点
- 配布反映や手作業が必要ならその内容

## 原則

- 正本は追加されたスキル / テンプレート / 参考メモと git history に置く。`revisit-candidates.md` は保留箱としてだけ使う。
- 新しい棚を増やす前に、既存スキルの `references/` や `assets/` へ小さく吸収できないか見る。
- 検証スクリプトで検出できることはスクリプトに任せ、スキルでは置き場所や重複の判断を補う。
