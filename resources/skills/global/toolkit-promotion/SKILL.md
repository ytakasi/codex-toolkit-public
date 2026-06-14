---
name: toolkit-promotion
description: 個別リポジトリの作業中に複数リポジトリで再利用できそうな skill、template、reference、運用ガイダンス、workflow、サブエージェント候補が生まれた時に使う。`codex-toolkit` へ昇格すべきか、既存資産へ吸収すべきか、リポジトリ固有 に残すべきか、global / profile / template のどこに置くかを判定する。
---

# ツールキット昇格

## 手順

1. 候補資産と発生元の文脈を確認する。
   - 何度使ったか、どの失敗や迷いを防ぐか、リポジトリ固有の事情がどこまで混ざっているかを見る。
   - template や共通ガイダンスへ昇格させる時、複数の実運用例は強い根拠だが必須条件ではない。現在のリポジトリの振り返りでは、リポジトリ固有文脈への依存度で判断する。
2. 必要なら `references/promotion-guide.md` を読み、昇格可否と置き場所を判定する。既存 session を振り返る時は `assets/session-retrospective-prompt.md` を叩き台にする。
   - agent / instructions / prompt / template / metadata の境界が論点なら `references/agent-asset-boundaries.md` を読む。
3. `codex-toolkit` に近い既存資産がないか確認する。
   - 既存 skill、template、global guidance、reference と役割が重ならないかを見る。
   - 個々の部品が既存skillで足りても、複数skill / docs / risk / decisionをまたぐ「順番そのもの」に再現価値がないか見る。
   - ユーザーが「この流れを再現したい」「当初想定より色々やった」と言った場合は、入口skill / orchestration skill候補として扱う。
   - 新規skill候補だけで終わらせず、既存 skill / reference / asset へ入れられる知見を実際に反映する。
4. 昇格させるなら、リポジトリ固有名詞、秘密情報、環境固有パス、一時しのぎを剥がす。
5. 役割に合う最小の形で追加する。
   - 常設方針なら共通ルールテンプレート `resources/global/AGENTS.common-rules-template.md`
   - 繰り返す手順なら skill。ただし toolkit への昇格可否と global 常駐可否は別に判定する。
   - 新規作成の初期形なら template
   - skill に従属する雛形や開始文なら skill 配下の `assets/`
   - 詳細な背景や判断基準なら skill 配下の `references/`
   - 配備レイヤーに迷う時は `docs/TOOLKIT_DISTRIBUTION.md` を見る。
6. skill を追加または更新した場合は、UI metadata も確認する。
   - `agents/openai.yaml` は UI metadata であり、skill発火の正本は `SKILL.md` frontmatter の `name` と `description`。
   - `agents/openai.yaml` を作る場合は、`display_name`、`short_description`、`default_prompt` を skill 本文と一致させる。
   - `default_prompt` は自然な文で `$skill-name` を含める。
7. 入口を更新する。
   - README から大まかな置き場所へ辿れるか
   - 必要なら setup や template から使えるか
   - 元リポジトリ側へ共通化済みであることを反映すべきか
8. 昇格元が `references/revisit-candidates.md` にある場合は、候補メモを整理する。
   - 完全に昇格した候補は削除する。
   - 一部だけ昇格した候補は、未昇格の再判定事項だけに縮める。
   - `昇格済み` の一覧や作業ログは残さない。正本は追加された skill / template / reference と git history に任せる。
9. 昇格後の重複を軽く監査する。
   - 元リポジトリや関連リポジトリの `AGENTS.md`、README、docs に、昇格済みの共通ルールや手順が古いコピーとして残っていないか検索する。
   - 見つけた場合は即座に広範囲へ手を入れず、リポジトリ固有差分として残すべきものと cleanup 候補を分ける。
   - cleanup する場合は、リポジトリ固有の意味が残る最小表現に縮め、共通ルール本文は `codex-toolkit` 側を正本にする。
10. 昇格しない判断なら、なぜまだ早いのかを短く説明する。
   - ただし次回以降に再判定したい候補は、会話に閉じ込めず `references/revisit-candidates.md` へ残す。

## 判断の原則

- **常設の気づき**は global guidance に寄せる。
- **実行のしかた**は skill に寄せる。
- **人が手で複製する初期形**は template に寄せる。
- **1リポジトリ発の知見でも、リポジトリ固有文脈を剥がして意味が通るもの**は昇格候補にする。見送る理由は「1リポジトリだから」ではなく、domain 依存、責務未確定、置き場所未確定、再利用場面が不明のいずれかにする。
- **一般化できること**と**全リポジトリへ global 常駐させてよいこと**は分けて判断する。
- **机上の一般化だけで雛形を作らず**、使われている実例から共通部分を抜く。
- **標準化判断では1つの情報源だけに寄らず**、公式ドキュメント、現行実装、bundled assets、実環境の観測が割れていないか確認する。
- **同じ実行知識を複数の場所へ複製せず**、別文書を残すのは独立した背景説明や詳細 reference として価値がある時だけにする。
- **既存資産へ吸収できるもの**を、新しい棚として増やさない。
- **流れ全体に再現価値があるもの**は、部品が既存資産に分解できても入口skill候補として見る。
- **実装対象が明確なCLIや運用tool**で、複数 docs / safety rule / validation を毎回同じ順番で踏むなら、実装用 orchestration skill として切り出す。
- **standalone な補助棚を増やさず**、詳細 reference は関連 skill から辿れる場所へ置く。
- **skill-curator 的な振り返り**は、汎用化候補が実際にある時だけ行う。毎回「新規なし」を残すためだけに新しい skill や候補メモを増やさない。

## 配備レイヤー判定

昇格できる資産でも、既定で global skill に置くとは限らない。
詳細な配布モデルは `docs/TOOLKIT_DISTRIBUTION.md` を正本にし、この skill では判断の入口だけを扱う。

- 未知のリポジトリで発火しても困らないものだけを global 候補にする。
- 技術領域や project type に偏るものは profile 候補にする。
- 新規リポジトリの初期形として価値があるものは template 候補にする。
- そのリポジトリの設計、用語、運用、ディレクトリ構成を前提にするものはリポジトリ固有として対象リポジトリ側へ残す。
- リポジトリ側で育てたランタイム資産は `agent-skills/repo` を正本ルートにし、skill は `agent-skills/repo/skills` に置く。Codex が実際に読む `.agents` は sync 後の生成先ランタイムルートとして考える。
- skill や ランタイムメタデータを作る / 更新する meta skill や script は正本ルートを触る前提にし、`.agents` に直接作らない。

## 出力

- 昇格可否
- 置き場所の理由
- 追加または変更したファイル
- まだ昇格しない場合は、その理由と再判定の目安
- 昇格済み内容の重複や、リポジトリ側で cleanup すべき候補

## 参照

- 境界判断に迷う時は `references/promotion-guide.md` を読む。
- global / profile / リポジトリ固有 の配布判断に迷う時は `docs/TOOLKIT_DISTRIBUTION.md` を読む。
- `codex-toolkit` 正本リポジトリで実際に変更する場合だけ、保守用profileや同リポジトリ内の検証スクリプトで整合性を確認する。配備先リポジトリでは、この skill は昇格可否と置き場所の判断までに留める。
- 既存 session の振り返りを始める時は `assets/session-retrospective-prompt.md` を使う。
- 昇格しなかったが忘れたくない候補は `references/revisit-candidates.md` を見る。
- agent / prompt / template / metadata の置き場所を迷う時は `references/agent-asset-boundaries.md` を見る。
