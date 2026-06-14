# DB-backed config rollout notes

scheduled batch / watcher で、ENVやローカルファイルに置いていた監視対象や判定設定をDB正本へ移す時の判断メモ。

これはまだ汎用templateではなく、複数リポジトリで見えてきた共通の注意点を残す reference として扱う。

## 設定分類

DBへ移す前に、設定や状態を次のように分類する。

| 種類 | 主な置き場 | 注意 |
|---|---|---|
| Secret本体 | Secret store / CI secrets / local secret file | DB、リポジトリ、ログ、UIに出さない。 |
| Secret lookup key | DB-backed config / typed config | 表示名と分け、UI文言変更で解決が壊れないようにする。 |
| 実行環境値 | ENV / ランタイム options | runner、region、mode、dry-runなど、運用経路ごとに変わるもの。 |
| 人が変える業務設定 | DB-backed config / typed config file | 管理UIやseedの対象。emptyとread failureを分ける。 |
| 取得で増える状態 | DB / object storage | notification history、dedupe、cursor、checkpoint、observationなど。 |
| derived / cache | cache / temp / artifact | 消えても再生成できるか、runner依存でよいか確認する。 |

本命DBへ移す予定が明確なら、仮DBや一時file実装を先に厚く作るより、設定取得interfaceやrepository境界だけ先に切って移行の二度手間を抑える。

## 段階移行の型

- まずDBへ移す対象を絞る。
  - 例: 監視対象だけ、通知チャンネル対応だけ、しきい値だけ。
  - いきなり全設定をDB化しない。
- 実行時secretとmutable configを分ける。
  - secret本体はSecrets/ENVに置く。
  - DBにはsecretを引くためのkeyや、非secretの運用設定だけを置く。
- DB優先とfallbackの意味を分ける。
  - DBにenabled設定が0件なら、移行期間としてENV fallbackしてよい場合がある。
  - DB読取失敗、権限不足、schema不一致はfallbackで隠さない方がよい。
- seedは明示コマンドにする。
  - schedule本体から自動seedしない。
  - 既存行やdisabled行を勝手に上書きしない。
  - seed結果は件数summaryを出す。
- 古い設定の廃止は観測後にする。
  - dry-runや管理画面でDB側の実データを確認する。
  - fallbackを消すのは運用が安定してからにする。

## チェックポイント

- DB schema変更が必要か、既存tableを使えるか。
- migrationを通常scheduleで毎回走らせるか、release/manualへ分けるか。
- seed commandがsecret不要なら、通常app env loaderとは分けるか。
- DBの設定0件とDB接続失敗をログ上で区別できるか。
- 通知先URLなどsecret本体がDBやログに入っていないか。
- 既存のdedupe / notification history と設定移行が干渉しないか。

## 安定IDと表示名

表示名変更や再seedで別entity扱いになりそうなら `stable-identity-and-dedupe.md` を読む。
DB-backed config では、secret lookup key、dedupe key、history key、表示名を分け、管理UI保存時に既存行IDを維持する。

## DB-backed 設定編集UIの保存チェック

DBを設定の正本にした後、管理画面やローカル編集UIを足す時は、移行そのものとは別に保存経路を軽く点検する。

- 既存行IDを維持して更新し、保存のたびに delete / insert で identity を振り直さない。
- 親子テーブルでは親IDを安定させ、子行だけ現在のUI内容へ同期する。
- 保存中は保存ボタン、タブ移動、閉じる操作などを止め、二重保存を防ぐ。
- 初回load / migrate / seed と、通常の save hot path を分ける。
- 保存のたびに重い DDL / migration 確認を走らせず、既存schema前提の軽い保存経路を持つ。
- secret本体はUIやDBへ出さず、secretを引くためのkeyや非secret設定だけを編集対象にする。
- nullable numeric を `0` と混同せず、未設定表示と保存値を明確に分ける。
- boolean は checkbox、enum / 選択肢は select / combo box に寄せ、自由入力は必要な箇所だけにする。
- 複数カテゴリや複数機能へ効く共有設定は、UIでも共有設定として見える場所へ置くか、model側にscopeを明示する。
- 設定0件、disabledのみ、DB read failure、schema mismatch を同じ「空」として扱わない。
- seedは既存設定を勝手に上書きせず、差分の件数summaryを出す。

## 設定surface audit

設定項目を足す、移す、消す時は `persisted-settings-change` の `references/config-surface-audit.md` を読む。
DB-backed config だけでなく、CLI、admin UI、seed、docs、tests まで追随するかをそこで確認する。

## まだtemplate化しない理由

- リポジトリごとにDB schema、ORM、管理画面、seed方法が大きく違う。
- `watch_targets`、カテゴリ別設定、通知チャンネルkeyなどはdomain名が混ざりやすい。
- まずはこのreferenceを見ながら、各リポジトリの現行設計に沿って最小移行する。
