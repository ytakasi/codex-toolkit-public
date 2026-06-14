# Notification Incident Triage

scheduled job / watcher / monitor の通知が多すぎる、少なすぎる、失敗している時の切り分け reference。

## まず分ける件数

- fetched / observed。
- notify candidate。
- skipped / excluded。
- already notified。
- attempted send。
- successful send。
- failed send。
- dedupe marker inserted。

候補数、送信数、履歴登録数を1つの「通知数」に潰さない。

## 原因分類

- provider / parser 由来: 欠損、誤読、partial result、重複。
- evaluation 由来: threshold、score、mute、category、disabled。
- state 由来: dedupe marker、notification history、cursor、checkpoint。
- config 由来: secret未設定、channel違い、DB設定0件、fallback。
- external send 由来: 429、5xx、timeout、invalid webhook。
- workflow 由来: job failure、matrix失敗、runner差分、env未設定。

## 手順

1. 直近run summary、exit code、workflow result、app logを見る。
2. 候補数と実送信数を分ける。
3. 外部送信成功前に dedupe marker が保存されていないか見る。
4. DBやstate pathが想定と同じか見る。
5. 設定変更で直るか、state修復や再実行が必要か分ける。
6. 再実行する場合は `stateful-replay-check.md` を使う。

## 出力

- もっとも可能性が高い原因。
- 件数の内訳。
- 手動修復が必要な状態。
- 再実行してよい条件。
- 追加すべきログ / summary / test。
