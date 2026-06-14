# Session Retrospective Prompt

既存 session を振り返って、複数リポジトリで再利用できる知見を掘り起こす時の開始プロンプト。

```text
この session 全体を振り返って、複数リポジトリで再利用できそうな知見を洗い出して。

以下に分類して。

1. すぐ codex-toolkit に昇格すべきもの
   - skill
   - template
   - global rule / 運用ガイダンス
   - skill 配下の reference / asset
2. 既存資産へ吸収すべきもの
   - 既存 skill の references / assets
   - 既存 template
   - 既存 global rule
3. まだ リポジトリ固有に留めるべきもの
4. 今すぐ昇格するには早いが、次回以降に再判定したいもの
   - 名前、置き場所、責務境界がまだ未確定なもの
5. workflow / サブエージェントとして再判定したいもの
   - 専用 workflow 候補
   - サブエージェント 候補

再判定候補は会話ログに閉じ込めず、codex-toolkit の `toolkit-promotion` skill 配下にある `references/revisit-candidates.md` に残す前提で整理して。
ただし、汎用化できて既存 skill の reference / asset / template へ小さく吸収できるものは、保留せず昇格候補として扱って。
`revisit-candidates.md` は保留箱であり、汎用知見の保存先ではない。昇格済みや吸収済みの候補は残さず、未解決論点だけに縮める。
ユーザーが実作業まで求めている場合は、候補を列挙するだけで終わらせず、新規 skill 化と既存 skill / reference / asset への吸収を行う。

判断時は、既存の codex-toolkit に近い skill / template / reference / workflow / サブエージェント 候補がないか確認し、重複する新規 skill や専用 agent を増やさず、既存資産へ吸収できるものは吸収候補として出して。

特に見てほしい観点:
- 同じ失敗や迷いを複数リポジトリで防げそうか
- リポジトリ固有名詞を消しても意味が通るか
- 実行手順なら skill、初期形なら template、詳細補足なら関連 skill の references に置けるか
- 並列探索・独立レビュー・繰り返し調査として切り出す価値があるなら サブエージェント 候補にする
- サブエージェント 候補は「いつ使うか」「親エージェントが何を渡すか」「成果物は何か」「既存skillで足りない理由」まで書く
- standalone な workflow / guidance 棚を増やさず、関連 skill から辿れる形にできるか
- agents/openai.yaml が必要な skill 候補なら、UI metadata も含めて考える
```

## 短縮版

```text
この session を振り返って、複数リポジトリで再利用できる skill / template / 運用ガイダンス / reference / workflow / サブエージェント 候補を洗い出して。

すぐ codex-toolkit に昇格するもの、既存資産へ吸収するもの、リポジトリ固有に留めるもの、まだ早いが再判定したいもの、workflow / サブエージェントとして再判定したいものに分けて。
再判定候補は会話に閉じ込めず、`toolkit-promotion` skill 配下の `references/revisit-candidates.md` に残す前提で整理して。
ただし、既存 skill の reference / asset / template へ小さく吸収できる汎用知見は、保留せず昇格候補として扱って。
`revisit-candidates.md` には昇格済みの作業ログを残さず、未解決論点だけを残して。
既存の codex-toolkit 資産や既存候補と重複しないかも確認して。
実作業まで求められている時は、新規 skill 化だけでなく既存資産への吸収も行って。
```
