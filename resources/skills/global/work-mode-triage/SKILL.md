---
name: work-mode-triage
description: ユーザー依頼、issue、handoff、作業メモの完了境界、source of truth、編集してよいか、外部writeまで行うかが曖昧な時に使う。Explore / Draft / Apply / Tracking-only を判定し、必要な intake、完了条件、確認事項、次アクションを揃える。
---

# Work Mode Triage

依頼、issue、handoff の完了境界や source of truth が曖昧な時に、いきなり実装や反映へ進まず、今回の作業モードを短く判定するための workflow。
特に、tracking issue と execution issue が混ざっている時、または「レビュー」「確認」「直して」が正本反映まで含むか曖昧な時に使う。

## モード

- `Explore`: 比較、相談、診断、方針整理。リポジトリ編集、外部 write、commit、PR は行わない。
- `Draft`: 対象 artifact はあるが、出力は草案、局所 patch、提案に留める。正本反映や durable tracking 更新はまだしない。
- `Apply`: source of truth を更新し、必要な生成、検証、commit、push、PR、issue comment まで完了境界に含める。
- `Tracking-only`: umbrella issue、Project item、進捗整理、親 issue 更新など、作業管理 artifact だけを更新する。実装や正本反映は子 issue / 別作業に分ける。

## 判定手順

1. 入力 artifact を分ける。
   - ユーザー依頼、issue body、既存 docs、handoff、PR、Project field を混ぜずに見る。
   - source of truth と tracking artifact がどれかを先に名前で出す。
2. 完了境界を読む。
   - build、test、validator、generated refresh、commit、push、PR、close が書かれていれば `Apply` 寄り。
   - 状況確認、棚卸し、親 issue 更新、lane assignment だけなら `Tracking-only` 寄り。
   - 受け入れ条件が草案レビューや提案作成で止まるなら `Draft` 寄り。
3. 反映対象を確認する。
   - source of truth を直接変えるなら `Apply`。
   - source of truth 候補を提示するだけなら `Draft`。
   - source of truth が未選定なら `Explore`。
4. 実行 lane や agent 指定を確認する。
   - 明示された agent / lane がある場合、親エージェントが勝手に代替実装しない。
   - timeout、応答なし、途中終了は完了扱いにせず、待機、再指示、fallback確認、未完了報告へ切り替える。
5. mixed issue を分割する。
   - 親 issue が tracking と execution を兼ねているなら、親は `Tracking-only`、実作業は子 issue または明示した execution scope へ分ける。
   - ひとつの issue で進める場合も、本文内で `tracking` と `execution` の完了条件を分けて書く。

## issue 化する時

- 実作業の入口には `assets/implementation-issue.md` を使う。
- 親 issue、umbrella issue、lane tracking は、対象リポジトリの tracking 用テンプレートや既存 issue body の型に合わせる。
- モード判定だけを手元で行う時は `assets/work-mode-switch-checklist.md` を使う。

## 出力

- 選んだモード
- 判断理由
- 必要な intake
- 完了境界
- `Apply` へ進む前に必要な不足情報
- tracking と execution を分ける必要があるか
