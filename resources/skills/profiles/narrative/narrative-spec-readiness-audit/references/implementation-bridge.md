# 実装への橋渡し

`narrative-spec-readiness-audit` の監査結果を、実装に渡せる作業単位へ変換するための reference。
standalone workflow にはせず、この skill の後続手順として使う。

## 使う場面

- `Conditional Go` 以上で、最小縦 slice を切りたい。
- 仕様資料はあるが、実装者が最初に作る data model / state / UI surface を決めきれていない。
- route、ending、state、fact、UI表示境界のどれかを後回しにすると、save互換や分岐判定へ響きそう。

## 手順

1. audit 結果を実装契約へ変換する。
   - `Must fix before implementation` は実装前の確認事項にする。
   - `Can defer` は最小縦 slice から外すか、明示的な仮契約にする。
   - `リポジトリ固有として残す` は共通 template へ持ち込まず、リポジトリ側の設計資料へ残す。
2. ID と表示名を分ける。
   - route、ending、event、fact、state は機械可読なIDを先に決める。
   - UI label や文言は後から変えられる場所に置く。
3. 状態遷移を固定する。
   - 状態一覧、許可遷移、禁止遷移、fallback を書く。
   - save / resume / migration に出る状態名は安易に変えない。
4. 分岐条件を形式化する。
   - `allOf`、`anyOf`、`not`、threshold、priority、fallback のどれに近いかへ落とす。
   - 条件式に落とせない感情や空気は、観測可能な proxy へ分ける。
5. UI surface を分ける。
   - ユーザーに見せる状態、隠す内部状態、まだ unknown として見せる状態を分ける。
   - locked / hidden / unknown / resolved / failed の表示を仕様に合わせる。
6. 最小縦 slice を切る。
   - 1 route、1 ending、代表状態遷移、代表 UI 表示、代表 save / resume を通す。
   - 未使用 route や高度な merge / compression は slice 外にしてよい。

## 出力

- 実装する最小縦 slice
- 先に固定する ID 一覧
- 状態遷移表
- route / ending 条件の初期形
- UI surface と内部状態の境界
- slice 外へ送る未決事項

## 注意

- 物語固有の正解を toolkit 側へ持ち込まない。
- 仕様の穴を「後で実装しながら決める」に逃がす時は、save互換や data migration へ響かない範囲に限る。
- 条件 schema の初期形が必要なら `assets/branching-schema-starter.yaml` をコピーして、リポジトリの data model に合わせて削る。
