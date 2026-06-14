# Agent Asset Boundaries

agent / instructions / prompt / template / metadata の責務を分け、同じ運用ルールが複数箇所で drift するのを防ぐための基準。

## 使う場面

- リポジトリに カスタムエージェント、prompt、template、skill、metadata を置く時。
- 既存 agent 定義が長くなり、どこが正本か分からなくなってきた時。
- Codex / Copilot / GitHub 側など複数の読込経路へ同じルールを書きたくなった時。

## 境界

- `agent`: 役割、担当範囲、必読先、絶対に外せない禁止事項だけを書く。
- `instructions`: 実行手順、品質基準、差し戻し条件、例外処理、出力項目の正本にする。
- `prompt`: 入口導線、モード選択、今回の優先工程に絞る。
- `template`: 出力欄の器にし、長い品質基準や運用ルールを持たせない。
- `skill`: 繰り返す判断や実行手順をまとめる。
- `metadata`: UI 表示、呼び出し補助、必読宣言に留め、本文ルールを重複させない。

## 判断ルール

- 新しい品質ルールは、まず `instructions` または `skill` に置く。
- agent が長くなったら、役割契約だけ残して詳細を正本へ寄せる。
- template に禁止事項が増え始めたら、instructions / skill へ戻す。
- 読み漏れが怖い時は、本文を複製する前に metadata や必読リストを見直す。
- リポジトリ固有名詞を消しても意味が通るルールは、`toolkit-promotion` で共通化を検討する。

## 避けること

- 同じ実行手順を agent、instructions、prompt、template へ丸ごと重複させる。
- template を品質基準の正本にする。
- metadata に長い運用本文を持たせる。
- provider や UI の都合だけで、正本を複数作る。
