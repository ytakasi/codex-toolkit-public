# Stable identity and dedupe

通知履歴、観測履歴、DB-backed config を持つ batch / watcher で、表示名の変更が重複通知や履歴断絶を起こさないようにするための補助メモ。

## 原則

- 人間向け表示名、通知ラベル、provider表示名を永続keyにしない。
- dedupe key、notification history key、observed history key には、provider ID、normalized URL、DB ID、外部system ID、正規化した複合keyなど安定した値を使う。
- 表示順、表示名、カテゴリラベル、UI文言は、identity とは別の列や設定として扱う。
- secret lookup key と表示名も分ける。UI文言の変更で secret 解決が壊れないようにする。

## チェック

- 表示名やタイトルが変わった時、同じentityとして履歴に紐づくか。
- 再seedや管理UI保存で、同じlogical entityのDB IDが振り直されないか。
- URLにtracking queryやsort parameterが混ざる場合、正規化前後のkeyが意図通りか。
- provider側IDがない場合、どのfieldを組み合わせれば衝突と過剰分裂を避けられるか。
- dedupe keyと通知本文の表示名が別々にテストされているか。

## DB-backed config での注意

- 保存ごとに delete / insert でidentityを振り直さず、既存行を update する。
- child table は親IDを維持したまま同期する。
- display order は順序として扱い、identityの一部にしない。
- logical keyの変更が必要な場合は、migrationや明示的なrename操作として扱う。

## 出力

- 永続keyに使うfield。
- 表示名やラベルとしてだけ使うfield。
- 変更時に移行が必要なkey。
- dedupe / history / config save の回帰テスト観点。
