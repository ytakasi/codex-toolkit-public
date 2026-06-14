# Stateful observation history

通知、観測結果、価格履歴、dedupe marker のような state を持つ scheduled batch / watcher の保存順メモ。
外部通知や外部副作用がある処理では、「何を保存したら外部世界で起きた扱いになるか」を最初に決める。

## 保存順の基本

- 外部通知の dedupe marker や通知履歴は、外部通知が成功した後にだけ保存する。
- 通知前に観測結果を保存する場合は、通知済み扱いと混同しない別テーブル / 別状態にする。
- 親子テーブルや履歴テーブルでは、親 row を insert / upsert してから子 row や履歴 row を保存する。
- 価格履歴や状態履歴は、前回値を読んで変化有無を判定し、親の最新状態を upsert した後に履歴を insert する。
- cleanup は transaction 内で実行する場合、今回追加する子 row の親を先に消さない条件になっているか確認する。

## Review checklist

- FK の親子関係が schema と保存順で一致しているか。
- 新規 item、既存 item、価格変更 item、削除対象 item の順序がそれぞれ通るか。
- dedupe marker、notification history、observation、price history の意味が分かれているか。
- partial failure を許容する場合、summary に error count / stop reason が残るか。
- retry 後の再実行で二重通知、履歴欠落、FK violation が起きないか。
- 実DB統合テストがない場合でも、repository-level test や小さな保存順テストを足せるか。

## よくある危険信号

- 子テーブルへ先に insert してから親テーブルを upsert している。
- 通知送信前に notified 扱いの row を保存している。
- `ON CONFLICT` で最新状態を更新するが、履歴追加条件が更新前の値を読めていない。
- cleanup と insert が同じ transaction にあり、cutoff 条件が広すぎる。
- DB read failure と「保存対象0件」を同じ正常終了にしている。
