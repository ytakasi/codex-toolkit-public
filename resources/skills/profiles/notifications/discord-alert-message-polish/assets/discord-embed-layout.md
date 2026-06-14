# Discord Embed Layout

Discord通知を見やすくするための叩き台。

## Alert

- `content`
  - 1行目: alert種別と対象
  - 2行目: 結論または一番重要な状態
  - 3行目: 必要ならURL。自動previewを出したくない場合は置かない。
- `embed.title`
  - 対象名、短い状態、主要価格など。
- `embed.description`
  - 1〜3行の要約。長い説明は入れない。
- `inline fields`
  - 価格
  - 24h件数
  - 24h volume
  - owner / buyer / seller など短いKPI
- `full-width fields`
  - 判断理由
  - 警告
  - 除外理由
  - 長い内訳
- `components`
  - 監視する
  - ミュート
  - 詳細を見る

## Job Summary

- 上段は件数KPIだけにする。
  - 取得総数
  - 試行件数
  - 成功件数
  - skip件数
- 理由内訳は全幅fieldへ移す。
- 失敗がゼロなら短く、ゼロでない時だけ原因分類を出す。

## URL Preview

- 画像や外部カードを見せたい: 本文にURLを置く。
- 通知本文をコンパクトにしたい: embed title URL または button にする。
- previewが不安定で困る: embed image へ明示的に画像URLを入れる。

## Avoid

- 長い箇条書きをinline fieldへ入れる。
- 生ログをそのまま貼る。
- 同じ内容をcontentとembedへ重複させる。
- URL previewとembed imageを意図なく両方主役にする。
