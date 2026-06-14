---
name: discord-alert-message-polish
description: Discord通知、Webhook通知、botメッセージ、監視alert、定期job summary、当選通知、操作付き通知が長文で読みにくい時に使う。embed、field、button、URL preview、画像表示、重要度、判断に必要な情報を整理し、受け手がすぐ判断できる通知へ再設計する。
---

# Discord Alert Message Polish

## 手順

1. 通知の目的を1つ決める。
   - 受信者が今すぐ判断するalertなのか、定期jobの状態確認なのか、操作導線なのかを分ける。
   - 先頭本文は、通知種別、対象、結論が分かる短い要約にする。
2. 情報の階層を作る。
   - 重要なKPIは短いfieldへ置く。
   - 可変長の理由、警告、内訳は全幅fieldへ置く。
   - 長い箇条書きや生ログをinline fieldへ詰めない。
3. Discordの表示特性に合わせる。
   - 本文に生URLを置くと自動previewが大きく出る。previewを見せたい時だけ本文に置く。
   - previewを抑えたい時はembed titleのURLやbuttonへ寄せる。
   - 画像を安定表示したい時は、可能ならembed imageへ明示的に入れる。
4. 操作導線を分ける。
   - 判断に必要な情報と、押すbuttonを近くに置く。
   - button付き通知はWebhookで送れるか、Bot APIが必要かを仕様と実環境で確認する。
   - destructive または状態変更系buttonは、権限、監査ログ、冪等性を合わせて見る。
5. 数値と欠損を整える。
   - 桁が長い数値は通知用に丸めるか指数表記にする。
   - `n/a` や欠損は、理由が分かる場合だけ補足する。
   - score、confidence、valuation、provider completeness のような別軸を1つの品質表示に潰さない。
6. fixture / payload test で守る。
   - 期待するcontent、embed fields、components、URL、imageをテストする。
   - 実際のDiscord表示で崩れやすい可変長fieldは、長い値のケースも確認する。

## 原則

- Discord通知は「全文を読む場所」ではなく「判断を始める場所」として設計する。
- 短い数字は横並び、長い説明は縦に流す。
- URL previewは便利だが主役にしない。必要な時だけ使う。
- 通知payloadの都合でdomain modelを汚さず、message builderやadapterで吸収する。

## 出力

- 通知の目的と主な判断ポイント
- content / embed / field / component の配置
- URL preview と画像表示の方針
- 操作buttonがある場合の送信経路と権限方針
- 更新したpayload test

## 参照

- レイアウトの叩き台は `assets/discord-embed-layout.md` を使う。
