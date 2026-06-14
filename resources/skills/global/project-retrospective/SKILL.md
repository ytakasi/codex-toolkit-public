---
name: project-retrospective
description: 作業の区切りで、今回得た再利用可能な学びをリポジトリ固有 skill、AGENTS、docs、revisit、toolkit候補へ仕分ける時に使う。ユーザーが「振り返り」「レトロ」「今回の知見を残す」「スキル化」「次も使えるように」「この流れを再現」などと言い、単なる次セッション引き継ぎやPR/QA報告だけでは足りない時に使う。handoff作成だけなら session-handoff、toolkit昇格判定だけなら toolkit-promotion を優先し、文章成果物だけなら観測事実と未検証事項を分けて短くまとめる。
---

# プロジェクト振り返り

作業から得た再利用可能な知見を、会話ログだけに閉じ込めず、リポジトリの正本へ仕分けるための skill。
リポジトリ固有の流れはリポジトリ側へ残し、横断化できる粒だけ `toolkit-promotion` へつなぐ。
handoff、PR本文、QA報告、toolkit昇格の実行そのものは主責務にしない。この skill は「何をどこへ残すか」を決める入口として使う。

## 手順

1. 区切りを特定する。
   - ユーザーが「振り返り」「レトロ」「スキル化」「次も使えるように」「この流れ」などと言った。
   - 実装、検証、commit、push、docs更新、dev server確認、次タスク移行、最終報告の前後で、再利用できる判断順や失敗回避が見えた。
   - 同じ説明、同じ失敗、同じ確認手順が次セッションでも必要になりそう。
   - 次セッションの再開点だけを残せば足りるなら `session-handoff` を使い、この skill では長い仕分けをしない。
   - PR本文、review、QA結果、issue comment 草案など文章成果物だけなら、この skill では長い仕分けをせず、観測事実、未検証事項、tool由来情報を分けて短くまとめる。
   - 既に toolkit へ昇格する候補が明確なら `toolkit-promotion` を直接使う。
   - 何も残す必要がなければ、長い追記をせず「追記なし」と短く報告する。
2. リポジトリの正本を確認する。
   - まず `AGENTS.md`、README、既存 docs、既存リポジトリ固有 skill を見る。
   - codex-kit 管理リポジトリなら、リポジトリ固有 skill の正本は `agent-skills/repo/skills`、ランタイム生成先は `.agents/skills` として扱う。
   - 未移行リポジトリや既存運用では `.agents/skills`、`.codex/skills`、`.github/skills` などに skill が残っている場合がある。既存の置き場を読んでから増やす。
   - 既に振り返り用リポジトリ固有 skill があるなら、まずそれを更新する。似た skill を増やさない。
3. 学びを分類する。

| 分類 | 残す場所 |
| --- | --- |
| リポジトリ固有の繰り返し作業 | リポジトリ固有 skill |
| リポジトリ固有の常設ルール | `AGENTS.md` |
| 採用済みの設計判断 | `docs/DECISIONS.md` など、そのリポジトリの判断正本 |
| リスクや検証状態 | `docs/RISK_REGISTER.md` など |
| 長期の作業記録と判断理由 | `docs/DEVELOPMENT_STORY.md` など |
| 次セッションへの短期引き継ぎ | `session-handoff` と `NEXT_SESSION` 系 docs |
| 未確定だが忘れると困る候補 | `REVISIT_CANDIDATES` 系 docs |
| リポジトリ横断の workflow / template / reference 候補 | `toolkit-promotion` 経由で `codex-toolkit` |
| 一回限りの観測 | 最終報告だけ。必要なら長期記録へ短く残す |

4. リポジトリ固有 skill 化を判断する。
   - 入口の言葉や状況、2手以上の手順、判断分岐、更新する成果物、完了条件が見えるなら skill 候補にする。
   - 一回便利だっただけの手順は、まず長期記録や再判定候補でよい。
   - ただし、忘却、skill選択ミス、再説明コスト、同じtoolchain失敗の二度踏みが起きた流れは、リポジトリ固有 skill 化を前向きに判断する。
   - skill 本文、運用メモ、表示文言は、リポジトリのルールに反しない限り日本語中心にする。
5. 既存 skill へ接続する。
   - 持ち越し、中断、再開点を残すなら、この skill では要否だけ決め、実際の引き継ぎ作成は `session-handoff` を使う。
   - リポジトリ横断で使えそうなら、この skill では候補として分け、昇格可否と置き場所の判定は `toolkit-promotion` へ渡す。
   - review / QA / PR本文 / handoff など後で判断材料になる文章は、この skill で本文を書き切らず、観測事実、未検証事項、tool由来情報を分ける。
   - PATH 上のコマンド起動失敗、bundled ランタイム不足、sandbox由来の失敗などは、product failure と混ぜず、必要なら `local-toolchain-diagnostics` へ流す。
6. docs 肥大化を仕分ける。
   - 手順そのものは skill、常設制約は `AGENTS.md`、採用済み判断は decisions、短期再開点は handoff、長期の時系列は development story、揺れている論点は revisit に寄せる。
   - README や setup docs は入口に留め、長い運用手順を重複させない。
   - 採用済みの内容を revisit に残し続けない。未確定の再判定事項だけに縮める。
7. 検証と報告を残す。
   - skill を追加または更新したら、そのリポジトリの skill validation を実行する。実行できない場合は理由を書く。
   - 実装や運用手順に影響したら、可能な範囲で build、test、dry-run、smoke を行い、実行コマンドと結果だけを書く。
   - sandbox / tooling 起因の失敗と product 起因の失敗を分ける。

## toolkit 昇格の判断

次を満たすものだけ `toolkit-promotion` へ進める。

- リポジトリ名、固有パス、固有サービス名、秘密情報、世界観、実装構造を剥がしても意味が通る。
- 他のリポジトリでも同じ迷い、失敗、作業順の抜けを防げる。
- 既存の global skill、profile skill、template、reference に吸収できるか確認済み。
- 「複数リポジトリで起きたか」だけで判断しない。1リポジトリ発でも、リポジトリ固有文脈への依存が薄ければ候補にする。

昇格する時は、元リポジトリの文章を丸ごとコピーせず、共通部分だけを薄く抜く。

## 出力

短く次を報告する。

- 残したもの: リポジトリ固有 skill、`AGENTS.md`、docs、handoff、revisit、toolkit候補。
- 見送ったもの: 一回限り、リポジトリ固有すぎる、既存 skill で足りる、未確定などの理由。
- 変更したファイル。
- 検証: 実行したコマンドと結果、未実行または失敗した理由。
- 次に見るべきファイルや、次セッション開始時の入口。
