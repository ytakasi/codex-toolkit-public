# Scoring Semantics Review

しきい値、スコア、bonus、ranking、alert rule が混ざる実装で、設定名と実際の挙動がズレていないかを見るための reference。

## 使う場面

- `notify_under_*` や `max_*` のような名前なのに、実際は soft score の一部として使っている。
- hard threshold と soft score / bonus が同じ設定画面に並んでいる。
- ユーザーが「なぜ通知されたのか」「なぜ落ちたのか」を確認している。
- 通知理由、ログ、管理画面、README の説明が実装とズレそう。

## 分けるもの

- Hard threshold: 条件を満たさないと必ず除外する。
- Soft score: 条件に近いほど加点するが、満たさなくても他の要素で採用され得る。
- Bonus / penalty: 特定条件の重み付け。
- Tie-breaker: 同点時だけ効く順序。
- Explanation: 人間に見せる理由。内部 score 式そのものとは別に整える。

## チェック

- 設定名が hard condition に見えるのに soft score として使われていないか。
- threshold を超えた item が、他の score / bonus によって採用される可能性があるか。
- UI label、README、通知理由で hard / soft の違いが分かるか。
- score breakdown を log / dry-run / readback surface で見られるか。
- null / unknown / estimated value が hard condition に使われる時、安全側の挙動が明記されているか。
- 既存ユーザーが設定値を変えた時、互換性や期待が壊れないか。

## 改善方向

- hard threshold なら名前に `required`、`max_allowed`、`exclude_if` などを使う。
- soft score なら名前に `preferred`、`target`、`score_weight` などを使う。
- 通知理由には「条件を満たした」だけでなく、score / bonus / warning を分けて出す。
- 設定UIでは hard filter と scoring weights を別groupにする。
- 既存の保存値や外部契約を壊す場合は、表示ラベルだけを変えるか migration を用意する。

## 出力

- hard threshold と soft score の分類
- 誤解されやすい設定名
- UI / docs / notification reason の修正案
- score breakdown の追加候補
