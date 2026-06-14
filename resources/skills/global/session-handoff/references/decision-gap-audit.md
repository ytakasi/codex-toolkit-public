# Decision Gap Audit

Milestone 完了前、長期開発記録を更新した後、またはユーザーが「判断理由が残っているか」と聞いた時に使う reference。
親エージェントは文脈を知りすぎているため、後から読む人が迷う点を明示的に探す。

## 入力

- `DEVELOPMENT_STORY.md`、README、ROADMAP などの正本 docs。
- 今回の変更概要。
- 重要な未決事項、検証結果、採用しなかった案。

## チェック

- 後で読んだ人が「なぜこの案にしたのか」を追えるか。
- 未解決論点が、会話だけでなく docs / issue / NEXT_SESSION のどれかへ残っているか。
- リポジトリ固有に残すべき理由と、toolkit へ昇格できる一般知見が分かれているか。
- 実装済みの内容が handoff や revisit box に重複して残っていないか。

## 出力

- 不足している判断理由。
- docs へ追記する候補。
- follow-up issue / task に回す候補。
- common template / skill へ吸えそうな観点。
