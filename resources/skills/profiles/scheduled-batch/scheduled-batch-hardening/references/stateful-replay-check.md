# Stateful replay check

通知、dedupe marker、cursor、checkpoint、cache などの状態を持つ scheduled batch / watcher を、本番確認や再通知確認のために安全に再実行する時の補助メモ。
目的は、外部副作用を再発火させるために必要な最小状態だけを触り、観測履歴や監査ログまで壊さないこと。

## 使う場面

- 外部通知や webhook をもう一度発火させて本番確認したい。
- dedupe marker、notification history、cursor、checkpoint が再実行を止めている。
- local run と scheduled / production run で見ている state store が違う疑いがある。
- 「全部消す」ではなく、1件または1カテゴリだけ再処理したい。

## 手順

1. 実行経路を確認する。
   - local、published binary、scheduler、CI、admin tool のどれで再実行するか。
   - working directory、env、config、DB connection、cache path がその経路でどう解決されるか。
   - path 差分が主題なら、runtime state、cache、export、log、dedupe marker のパスを matrix にして確認する。
2. 状態の種類を分ける。
   - 外部副作用を止める dedupe / notification marker。
   - 次回取得位置を決める cursor / checkpoint。
   - 観測履歴、監査ログ、価格履歴、debug cache など、消すと調査材料が失われるもの。
3. 削除対象を最小化する。
   - 目的の item、provider、category、run window だけに絞る。
   - 表示名ではなく stable key、provider ID、normalized URL、DB ID で指定する。
   - observation / audit history と dedupe marker を混同しない。
4. backup と復元手順を用意する。
   - file DB なら copy、server DB なら transaction、export、対象行の控えなどを使う。
   - 削除前件数、削除対象key、削除後件数を残す。
   - 復元できない操作なら、その理由と代替の安全策を明記する。
5. 再実行と確認を分ける。
   - dry-run で同じ候補が見えるなら先に確認する。
   - 外部通知や外部writeを行う run では、送信成功と state 登録順を確認する。
   - 再実行後、通知数、skip数、dedupe再登録、error数を summary で見る。

## 出力

- 実効 state store と実行経路。
- 触る state と触らない history / audit の分類。
- backup / restore 方法。
- 削除した最小keyと件数。
- 再実行結果と、次に戻すべき設定や状態。
