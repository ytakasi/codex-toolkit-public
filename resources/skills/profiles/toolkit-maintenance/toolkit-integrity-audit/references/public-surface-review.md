# Public Surface Review

Skill、template、reference を整理した後に、外側から見える入口が揃っているか確認する reference。

## 見る surface

- README。
- 共通ルールテンプレート `resources/global/AGENTS.common-rules-template.md`。
- skill frontmatter と `agents/openai.yaml`。
- template。
- setup / validation script。
- reference へのリンク。
- `revisit-candidates.md`。

## チェック

- README に詳細一覧を持ちすぎて drift しないか。
- global rules が全リポジトリ常設に値する内容だけになっているか。
- skill 本文から必要な reference / asset へ辿れるか。
- template と skill asset に同じ実行知識を重複して置いていないか。
- setup や validation が新しい配置に追随しているか。
- 昇格済みの候補が `revisit-candidates.md` に本文として残っていないか。

## 出力

- 入口として不足している surface。
- 重複している説明。
- cleanup 候補。
- あえてリポジトリ固有に残す説明。
