# Template Placeholder Audit

Template を追加または更新した時に、リポジトリ固有の実値や、一見そのまま使えそうな固定値が混ざっていないか確認する reference。

## 見るもの

- product 名、リポジトリ名、owner 名、project path、URL。
- secret 名、env var 名、account ID、token 名。
- target framework、ランタイムバージョン、runner OS、cron、port、region。
- example と placeholder の境界。
- `REPLACE_ME_*` にすべき値が、実値のように残っていないか。

## 判断

- 複製先で必ず変える値は placeholder にする。
- どのリポジトリでも同じでよい値だけを実値として残す。
- 安全な空値、example value、必須 placeholder を混ぜない。
- 手順書に出す command は shell 解釈で誤実行されない形にする。

## 出力

- template に残してよい固定値。
- placeholder 化する値。
- README や setup docs へ説明が必要な値。
- 既に公開済み template の cleanup 候補。
