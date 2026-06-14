# GitHub Actions failure notification notes

GitHub Actions の job 末尾に失敗通知を足す時の補足。
基本の YAML は `../assets/github-actions-failure-notify-step.yml` を使い、この reference ではリポジトリごとに迷いやすい field と配置だけを決める。

## 最低限入れる情報

- app / service 名
- job 名、または人間が分かる実行単位
- repository
- run number と attempt
- ref
- short commit SHA
- actor
- Actions run URL

通知本文だけでも発生元が分かるよう、`[app-name]` のような prefix を置く。
Discord では `allowed_mentions.parse` を空にして、失敗通知から意図しない mention を飛ばさない。

## Matrix / shard の field

matrix job では、失敗した軸を field に足す。

例:

- `Category Group`
- `Target`
- `Shard`
- `Region`
- `Provider`

`APP_NAME` と `JOB_NAME` だけでは原因を追いにくい場合に追加する。
domain の具体名は asset 側へ入れず、リポジトリの workflow で env と field を足す。

## Multi-job workflow での配置

- 各 job の失敗を別々に知りたいなら、各 job の末尾へ通知 step を置く。
- migrate / build / deploy / watch など失敗時の対応者や原因範囲が違う job は、job ごとの通知が分かりやすい。
- workflow 全体で1回だけ通知したい場合は、集約 job を作る必要があるが、個別 job の context が薄くなる。

まずは失敗時に人が次の調査へ進みやすい単位へ置く。

## `continue-on-error: true` の意味

通知 step 自体の失敗で、元の workflow failure を別の失敗へ見せかけないために使う。
Webhook secret 未設定時も warning だけ出して終了し、元の job failure を隠さない。

## Docs に残すこと

- 必要な secret 名
- secret 未設定時の挙動
- 通知に含む run URL と発生元情報
- 通常の業務通知とは別 channel / webhook にする理由
