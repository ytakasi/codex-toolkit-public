# Web source 初回観測チェックリスト

外部Webページを provider / source として取り込む時の初回観測チェックリスト。
API docs や typed SDK がある provider では通常の `provider-dry-run` を優先し、HTML、検索ページ、browser-rendered DOM を読む必要がある時だけこの補助を使う。

## まず static HTML

- まず通常HTTPで初期HTMLを取得し、欲しい item data が含まれるか確認する。
- 初期HTMLが skeleton、app shell、hydration marker だけなら、その事実を観測結果として残す。
- 旧記事や過去実装の selector を正本にせず、現行HTMLに同じ構造があるか見る。
- login、cookie、geo、bot protection が必要そうなら、この段階で無理に回避せず未検証点にする。

## Rendered DOM

- JavaScript実行後にだけ item data が出る場合は、browser rendering が必要な理由を短く残す。
- DOM観測では class 名より、data属性、semantic link、role、安定した親子構造を優先する。
- item card、title、price、url、thumbnail、pagination、sold / unavailable 表示の取得可否を分ける。
- 画面に見えるがDOM上では埋め込みJSONやshadow DOMなど別経路にある値がないか見る。

## field の充足

- 欲しい field を、取れる、取れない、推定できる、危険なので使わない、に分ける。
- 取れない値は `unknown`、safe default、excluded のどれで扱うかを決める。
- safe default を使う場合は、なぜ安全側なのかを decision reason や docs に残す。
- 推定値を実測値として扱わず、名前や flags で区別する。

## 正本 mapping

- item名、型番、カテゴリなどから一意に決まる値があるなら、自由な文字列抽出や近傍テキスト推定より正本mappingを優先する。
- mapping hit、inferred、unknown を同じ値として扱わず、後段のscore、通知理由、readback surfaceで由来が分かるようにする。
- mappingに存在しない時だけ conservative な推定へ進み、危ない近傍値や別fieldの値を強い根拠として使わない。
- 運用で増えるmappingは、リポジトリの設定、DB、reference tableなど、追加しやすくreviewしやすい場所に置く。

## 検索とページング

- 検索URLで category、status、price range、sort、page / offset を絞れるか確認する。
- 1 run で読む page / item の上限を決める。
- 次ページリンクがDOMにあるか、URL template で展開できるか、infinite scroll かを分ける。
- 重い経路になりそうなら、scheduled job へ載せる前に `scheduled-batch-hardening` でランタイム予算を見る。

## Fixture と境界

- unit test では実サイトや実ブラウザを直接必須にせず、保存済みHTML / DOM fixture を使う。
- browser rendering が必要な場合も、parser test は renderer seam の後ろのHTML / DOMで確認する。
- fake fetcher / fake renderer で URL 展開、page 上限、field 欠損時の扱いをテストする。
- 生HTML全文や個人情報をログや公開fixtureへ入れない。

## 出力

- static HTML で足りるか、rendered DOM が必要か。
- 安定 selector / mapping 候補。
- 取れる field、取れない field、safe default。
- page / item 上限とランタイムリスク。
- fixture 化するサンプルと、まだ未検証の現実パターン。
