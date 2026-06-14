---
name: signed-webhook-worker
description: Discord Interactions、GitHub/Stripe webhook、独自HMAC webhook、署名付きHTTP endpointを Cloudflare Worker / Serverless / Edge ランタイムで実装・レビューする時に使う。raw body署名検証、ACK制約、ランタイム検証、secret境界、監査ログ、replay対策、テストを揃える。
---

# Signed Webhook / Interaction Worker

## 手順

1. 公式仕様と受信surfaceを確認する。
   - 署名対象のmessage、header名、timestamp / nonce、replay防止要件、レスポンス期限、再送仕様を確認する。
   - webhook / interaction / bot API / management API のどこに token が必要かを分ける。
2. secret境界を決める。
   - ランタイム endpointに必要なsecretだけを置く。
   - command登録、application設定、provisioning、migration用tokenはランタイムへ混ぜない。
   - mutating action がある場合は user / role / org / account allowlist を先に決める。
3. raw bodyを最初に読む。
   - JSON parse、schema validation、logging の前に署名検証する。
   - 検証失敗、header欠落、不正hex/base64、不正timestampは `401` またはprovider仕様の失敗応答にする。
4. payloadは `unknown` として扱う。
   - 署名が通っても shape が正しいとは限らない。
   - type guard / schema validation で、必要fieldが揃った payload だけをdomain処理へ渡す。
5. ACK制約を守る。
   - providerが短い初期応答期限を持つ場合は、即時ACK / deferred ACK を返し、重い処理は background / queue / waitUntil に逃がす。
   - user-visible response は mention 抑止や ephemeral / private response を既定にする。
6. mutationを閉じる。
   - mutation前に allowlist を確認する。
   - 成功した変更だけ監査ログへ送る。
   - 同じ操作が再送されても壊れないよう、DB unique key / upsert / idempotency key を検討する。
7. provider APIへ返すmessageを安全にする。
   - `allowed_mentions` や同等のmention抑止を付ける。
   - 外部入力をそのまま markdown / mention / HTML として返さない。
8. deploy前にprotocol testを置く。
   - valid signature
   - invalid signature
   - missing header
   - malformed encoding
   - raw body verification before JSON parse
   - ACK response shape
   - authorization allow / deny
   - idempotent duplicate handling

## 原則

- 署名検証は「入口のドア」であり、business validation の代わりではない。
- ランタイム用 secret は少ないほどよい。登録・設定・運用tokenは別scriptやCI stepへ逃がす。
- provider仕様の時間制約はコード構造に影響するため、後付けではなく最初に設計へ入れる。
- webhookが外部副作用を起こす場合、成功ログより先に idempotency を設計する。
- 仕様が曖昧な時は、実運用へ出す前に最小の dry-run / provider sandbox / test request で観測する。

## 出力

- 署名検証方式と参照した公式仕様
- ランタイム / management / provisioning secret の分離
- endpointのACK方針
- mutation allowlist と監査ログ方針
- idempotency方針
- 追加したprotocol tests
- deploy後に手動確認するprovider設定
