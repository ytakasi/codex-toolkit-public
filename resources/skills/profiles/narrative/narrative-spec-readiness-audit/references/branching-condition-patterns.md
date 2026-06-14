# 分岐条件パターン

物語や意思決定フローの自然文条件を、実装しやすい形へ言い換えるための reference。

## 基本形

### allOf

すべて満たす必要がある条件。

```yaml
allOf:
  - flag: knows_core_fact
  - state: case.resolved
  - countAtLeast:
      tag: trust
      value: 3
```

向いているもの:

- 必須証拠が揃った時だけ進む route。
- 複数の問題を解決した時だけ解放される ending。

### anyOf

どれか1つを満たせばよい条件。

```yaml
anyOf:
  - flag: helped_neighbor
  - flag: restored_archive
```

向いているもの:

- 複数の解決策がある task。
- 代替可能な情報源。

### not

条件を満たしていないことを要求する。

```yaml
not:
  flag: revealed_secret_too_early
```

向いているもの:

- 早期開示を避けた route。
- 失敗flagが立っていない時だけ進む ending。

### count / threshold

一定数以上、一定値以上を要求する。

```yaml
countAtLeast:
  tag: repaired_relationship
  value: 2
```

向いているもの:

- 信頼、評判、調査達成数。
- 全件必須ではないが十分量を要求する分岐。

### priority

複数条件が同時成立した時の優先順位。

```yaml
priority:
  - ending: ending_truth
    when:
      flag: reached_hidden_truth
  - ending: ending_repair
    when:
      countAtLeast:
        tag: repaired_relationship
        value: 3
```

向いているもの:

- ending の同時成立。
- route の排他。

### fallback

どの条件にも当たらない時の扱い。

```yaml
fallback:
  ending: ending_incomplete
```

向いているもの:

- 未達、時間切れ、通常失敗。
- 条件漏れで ランタイムエラーにしないための保険。

## 点検ポイント

- 条件は表示名ではなく、安定した ID / flag / state を参照しているか。
- 同時成立した時の priority があるか。
- 条件未達時の fallback があるか。
- 条件式に落とせない情緒的な説明は、testable な proxy へ分けられるか。
- 物語上「知らないはず」の情報を条件式が参照していないか。
- UI に見せる条件と内部で判定する条件が混ざっていないか。
