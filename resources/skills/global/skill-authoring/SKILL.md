---
name: skill-authoring
description: スキル、エージェント、フック、agents/openai.yaml、skill metadata を新規作成・更新する時に使う。`codex-kit` 管理リポジトリで `.agents` へ直接作らず、`agent-skills/repo`、`resources/skills/global`、`resources/skills/profiles`、`resources/hooks`、`resources/templates` などの正本ルートと配布レイヤーを判定し、作成後の validate まで行う。
---

# スキル作成

## 目的

新しいスキル、エージェントメタデータ、フックを作る前に、どの正本ルートへ置くかを決める。
Codex が読む `.agents` は生成先ランタイムであり、`codex-kit` 管理下では直接編集しない。

## 手順

1. 作りたい資産を分類する。
   - 実行手順なら skill。
   - UI metadata なら `agents/openai.yaml`。
   - Codex 標準 hook の本体なら hook。
   - `codex-kit` 本体が直接読む初期形なら toolkit template。
   - 背景、判断基準、詳細手順なら skill 配下の `references/`。
   - skill から使う雛形や出力テンプレートなら skill 配下の `assets/`。

2. 配布レイヤーを決める。
   - どのリポジトリでも自然に起きる作業は `resources/skills/global/<skill-name>/`。
   - 技術、外部境界、作るものに依存する作業は `resources/skills/profiles/<profile>/<skill-name>/`。
   - `codex-toolkit` 自体の保守に閉じる作業は `resources/skills/profiles/toolkit-maintenance/<skill-name>/`。
   - 対象リポジトリ固有の語彙、設計、運用、パスに依存する作業は `agent-skills/repo/skills/<skill-name>/`。
   - 配布判断に迷う時は `docs/SKILL_LAYER_INVENTORY.md` と `docs/TOOLKIT_DISTRIBUTION.md` を見る。

3. 正本ルートを選ぶ。
   - リポジトリ固有 skill: `agent-skills/repo/skills/<skill-name>/SKILL.md`
   - リポジトリ固有 agent metadata: `agent-skills/repo/agents/`
   - リポジトリ固有 hook: `agent-skills/repo/hooks.d/<Event>/<name>.*`
   - toolkit 共通 skill: `resources/skills/global/<skill-name>/SKILL.md`
   - toolkit profile skill: `resources/skills/profiles/<profile>/<skill-name>/SKILL.md`
   - toolkit global hook: `resources/hooks/global/hooks.d/<Event>/<name>.*`
   - toolkit template: `resources/templates/<kind>/...`
   - toolkit global skill asset: `resources/skills/global/<skill-name>/assets/...`
   - toolkit profile skill asset: `resources/skills/profiles/<profile>/<skill-name>/assets/...`

4. skill を作る時は最小構成にする。
   - 必須は `SKILL.md`。
   - `agents/openai.yaml` も用意し、`display_name`、`short_description`、`default_prompt` を skill 本文に合わせる。
   - `default_prompt` には `$skill-name` を含める。
   - `scripts/`、`references/`、`assets/` は実際に使う時だけ作る。
   - `README.md`、`CHANGELOG.md`、長い導入ガイドは skill 配下へ増やさない。

5. frontmatter を整える。
   - `name` はディレクトリ名と一致させる。
   - `description` には「何をする skill か」と「いつ使うか」を書く。
   - 発火条件は本文ではなく `description` に入れる。
   - skill 名は lowercase letters、digits、hyphens のみで 64 文字以内にする。

6. 本文は Codex が実行するための手順だけに絞る。
   - 既知の一般論を長く説明しない。
   - 判断順、禁止事項、正本ファイル、検証コマンドを優先する。
   - 詳細が長くなる場合は `references/` に分け、本文から読む条件を明示する。

7. 生成先ランタイムを直接触らない。
   - `.agents/skills/...` に新規 skill を作らない。
   - `agent-skills/toolkit` を手で編集しない。
   - `.codex/hooks.json` に hook 本体を埋め込まない。
   - 必要な変更を正本ルートへ置き、`codex-kit sync` で生成先へ反映する。

8. 作成後に検証する。
   - toolkit 側の変更なら `.\scripts\validate-skills.ps1` を実行する。
   - CLI や同期挙動に影響するなら `.\scripts\test-codex-kit.ps1` も実行する。
   - 対象リポジトリ側の skill なら `codex-kit sync --dry-run`、`codex-kit sync`、`codex-kit status` で反映を確認する。
   - 検証結果は実行したコマンドと実際の結果だけを書く。

## 判断チェック

- その資産は対象リポジトリ固有か、複数リポジトリで再利用できるか。
- global 常駐させても未知のリポジトリでノイズにならないか。
- profile に置く場合、どの preset / init 質問から自然に入るか。
- `.agents`、`agent-skills/toolkit`、`.codex/hooks.json` を正本と誤読させていないか。
- UI metadata と skill description がズレていないか。
- 新しい docs を増やさず、既存 README / inventory / distribution docs から辿れるか。
- skill 固有の雛形を `resources/templates/` へ置いていないか。

## 出力

- 作成または更新する資産の種類。
- 選んだ正本ルートと理由。
- 作成または更新したファイル。
- 実行した検証コマンドと結果。
- 迷った配布レイヤーや、後で `toolkit-promotion` へ回す候補。
