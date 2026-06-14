# Config Surface Audit

永続設定を追加、移動、削除した時に、model、DB、seed、UI、docs、tests のどこが追随する必要があるかを見るための reference。

## 使う場面

- ENV / local config / DB-backed config / management UI のどれかに設定項目を足した。
- 設定の正本をファイルからDBへ移す、または逆にランタイム optionへ戻す。
- 「設定したのに効かない」「UIにはあるが実行時に読まない」事故を避けたい。

## Surface checklist

- ランタイム model / options / validation。
- DB schema / migration / repository / seed。
- config provider / loader / fallback。
- CLI args、env schema、example config、local override。
- 管理UI、form validation、save path、既存row identity。
- evaluator / runner / provider adapter など、実際に設定を使う場所。
- docs、README、setup、DEVELOPMENT_STORY、AGENTS。
- unit test、fixture test、integration smoke、manual verification。

## 判断

- secret本体は config DB や UI に移さず、secret lookup key だけにできるか。
- DB config empty、disabled only、DB read failure、schema mismatch を区別しているか。
- 旧設定との fallback を残すなら、いつ消すかを docs に残しているか。
- 互換用の旧fieldを残すなら、reader / writer / seed / UI のどこまで対応するか明確か。

## 出力

- 追随が必要なsurfaceと不要なsurface。
- 手作業の migration / seed / secret / docs 更新。
- 古い設定名や互換pathのcleanup候補。
- 検証コマンドと、未確認の実行経路。
