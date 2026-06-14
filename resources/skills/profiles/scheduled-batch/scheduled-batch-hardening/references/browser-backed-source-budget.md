# Browser-backed source budget

Playwright、Selenium、browserless など、ブラウザ描画を必要とする source を scheduled job / watcher / monitor へ載せる時の判断メモ。
まず静的HTTPや公式APIで足りるかを観測し、browser は必要性が分かった時だけ採用する。

## Before adding a browser

- 初期HTMLに必要な item data がないことを確認したか。
- API endpoint、埋め込みJSON、軽いHTML route で代替できないか見たか。
- browser rendering が必要な field と、不要な field を分けたか。
- browser が必要な理由を開発記録や source docs に短く残したか。

## ランタイム予算

- 1 run あたりの page / item 上限を決める。
- infinite scroll や pagination は、明示的な上限で止める。
- browser install、cache restore、page load、wait、parse のおおよその時間を分けて見る。
- `timeout-minutes` やアプリ側 time budget へ収まるか確認する。
- provider rate limit やサイト負荷を考え、parallelism を上げすぎない。
- screenshot や trace は通常 run で常時保存せず、調査時だけにする。

## Same job or separate job

既存jobに入れる方がよい場合:

- 低頻度で、対象page数が少ない。
- 失敗しても同じカテゴリや同じ通知先の範囲で扱える。
- cache込みで既存 timeout に収まる。
- job分割により secret、dedupe、summary、docs が複雑になる方が重い。

別jobに分ける方がよい場合:

- browser install / run time が他の軽量sourceを圧迫する。
- browser特有の失敗率が高く、他sourceの結果まで巻き込みたくない。
- runner OS、依存browser、cache key、timeout が明確に違う。
- 通知summaryやfailure通知を別に見たい。

## CI / scheduled workflow

- browser binary の install 手順を build / run の前提に合わせる。
- cache key は browser package version、OS、lockfile に合わせる。
- browser が必要な job だけ install / cache する。
- headless 実行を前提にし、visible window が必要な手順を scheduled run に混ぜない。
- failure notification には job名、run URL、attempt、ref を含める。

## Verification

- unit test は fake renderer と保存済みHTML / DOM fixture を優先する。
- 実browser dry-run は代表URL、少数page、短いtimeoutで確認する。
- browser が取得したHTML全文をログへ出さない。
- 実行時間が伸びたら、page上限、検索条件、別job化の順で見直す。
