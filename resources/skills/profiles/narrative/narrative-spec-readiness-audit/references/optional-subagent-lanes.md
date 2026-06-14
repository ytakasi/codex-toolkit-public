# Optional Subagent Lanes

ユーザーが明示的に サブエージェント / 並列レビューを求めた時だけ使う候補。
通常の監査は親エージェントが `narrative-spec-readiness-audit` を使えば足りる。

## Spec Auditor

いつ使うか:

- 大量の仕様 docs があり、実装前に矛盾、未定義、曖昧条件だけを独立に洗いたい時。
- 親エージェントが実装計画やデータ設計を進める横で、read-only の仕様監査を並列化したい時。

親エージェントが渡すもの:

- doc 一覧
- 監査範囲
- 編集禁止かどうか
- 優先したい実装 surface

成果物:

- `Must fix`
- `Can defer`
- `Open questions`
- 矛盾している仕様箇所

既存skillで足りない理由:

- skill 自体は親エージェントでも使えるが、大量 docs の独立読み取りは並列 lane として切る価値がある。

## Schema Drafter

いつ使うか:

- 自然文の route / ending / state 条件を JSON / YAML schema の初稿へ落としたい時。
- audit 結果はあるが、実装者が条件 DSL の初期形を起こす時間を分けたい時。

親エージェントが渡すもの:

- 採用済みの route / ending / state docs
- 希望する出力形式
- ID 命名規約
- リポジトリで使う validator や data loader の前提

成果物:

- schema draft
- 未表現の条件一覧
- validator 観点
- 後で人間判断が必要な箇所

既存skillで足りない理由:

- schema 下書きは監査と別作業で、読み取り結果が固まった後に並列化しやすい。

## Narrative Constraint

いつ使うか:

- キャラ、世界観、開示順、NG 表現の制約が実装や UI 文言で壊れそうな時。
- 仕様の意味論が product の価値を左右する時。

親エージェントが渡すもの:

- narrative bible
- 制約一覧
- 対象 UI / event / route の候補
- 触ってよい docs と触らない docs

成果物:

- 制約違反候補
- 危険な実装解釈
- テスト観点
- リポジトリ固有に残すべき判断

既存skillで足りない理由:

- `clarity-review` は責務分担を見るが、物語上の意味論までは主責務にしない。

## UX Surface

いつ使うか:

- user guide や game loop から、画面に必要な表示項目、操作、状態ラベルを逆算したい時。
- 実装前に UI surface と内部状態の境界を独立に棚卸ししたい時。

親エージェントが渡すもの:

- user guide
- 主要 loop
- 対象画面
- 技術 stack
- UI に出してよい情報と隠す情報

成果物:

- 画面別の表示項目
- 操作
- empty / error / locked / hidden 状態
- 受け入れ条件

既存skillで足りない理由:

- frontend 実装前の UI surface 棚卸しに特化しており、通常の design review より仕様読解の比重が高い。
