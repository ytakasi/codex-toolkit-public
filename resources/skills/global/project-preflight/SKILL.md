---
name: project-preflight
description: 新しいリポジトリ、新機能、外部provider接続、初回実装に入る前の preflight に使う。repo-bootstrap後または実装前に、目的、v0/MVP、やらないこと、privacy/secret境界、正本docs、risk register、toolchain/provider dry-run、依存配置、次アクションを揃える。
---

# Project Preflight

## 概要

初回実装へ入る前に、プロジェクトの滑走路を整える。目的は完璧な運用を作ることではなく、最初の実装で迷う点、危険な外部境界、後で忘れる判断を小さく固定すること。

`repo-bootstrap` はREADME/AGENTS/DEVELOPMENT_STORYなどの初期骨格を作る。このskillは、その骨格を使って「実装へ入ってよいか」を判定し、足りない前提を埋める。

## 手順

1. 開始モードを決める。
   - 空リポジトリ / 既存リポジトリ / 新機能 / 外部provider接続のどれか。
   - まだ骨格がない場合は先に `repo-bootstrap` を使う。
   - 依頼が曖昧なら `work-mode-triage` で Explore / Draft / Apply / Tracking-only を分ける。

2. 目的と非目的を固定する。
   - プロジェクト名または機能名。
   - v0 / MVP / 最初のPRで達成すること。
   - 今回やらないこと。
   - 成功条件と、実装前に潰すべき最大リスク。

3. 外部境界を先に決める。
   - secretをどこに置くか。client appやfixtureへ混ぜない。
   - 個人データ、顧客データ、位置情報、健康データ、決済情報などの送信可否。
   - 外部provider、DB、Cloud、Webhook、LLM、Notion/Slack/GitHubなどのwrite境界。
   - public/private、公開前に見直すもの。

4. 正本docsを揃える。
   - README: 入口、現在地、最初の一手だけ。
   - AGENTS.md: リポジトリ固有差分だけ。global方針を複製しない。
   - DEVELOPMENT_STORY: 観測事実、決定、検証結果、未解決、次アクション。
   - DECISIONS: 後で理由が消えそうな判断。
   - RISK_REGISTER: 最初に潰す順番。
   - 必要なら MVP / ROADMAP / PRIVACY_MODEL / SETUP / REFERENCES / CODEX_TASKS。

5. toolchain / provider readinessを小さく観測する。
   - PATHにあるかだけでなく、実際に `--version` / `--help` / dry-run が通るか見る。
   - mobile、cloud、DB、LLM、provider APIなど、実装前に詰まると大きいものを最小dry-runで見る。
   - 失敗は local toolchain、sandbox、network、provider、product bug に分ける。
   - 外部providerのreal-data観測が必要なら `provider-dry-run` を使う。
   - toolchain問題なら `local-toolchain-diagnostics` を使う。

6. 依存と生成物の置き場所を決める。
   - root dependencyか、subproject配下か。
   - app / worker / cli / tests / infra の責務境界。
   - lockfile、env example、generated artifact、fixture、secret、local cacheの扱い。
   - deployやsecret登録のような外部mutationを暗黙setupに入れない。

7. Codex作業ループを作る。
   - `codex-kit` 管理リポジトリでは、リポジトリ固有に育てる調査や振り返りは `agent-skills/repo` を正本ルートにし、skill は `agent-skills/repo/skills` に置く。Codex が読む実行時ツリーは sync 後の `.agents`、skill 探索先は `.agents/skills` として確認する。
   - `codex-kit` を使わないリポジトリでは、リポジトリ固有 skill の置き場と Codex が読む root が同じ `.agents/skills` になる。
   - リポジトリ横断化できるものだけ `toolkit-promotion` で判定する。
   - 実装後に更新すべきdocs、risk、decision、verificationの置き場所を決める。

8. 開始判定を出す。
   - `Ready`: 最初の実装に入ってよい。
   - `Ready with risks`: 実装に入れるが、並行して潰すリスクがある。
   - `Blocked`: 先にtoolchain、secret、provider、privacy、scopeのどれかを解く。

## 出力

- 現在の開始判定。
- 追加 / 更新したdocs、rules、skills。
- 残ったリスクと潰す順番。
- 実装前に必要な手作業。
- 最初の1PRまたは最初のspike。

## 判断チェック

- READMEに長い運用手順を抱え込ませない。
- AGENTS.mdにglobal方針を複製しない。
- docsを増やすだけで終わらず、次に使うskill / risk / decisionへ必要最小限を移す。
- toolchainは「インストール済み」と「起動確認済み」を分ける。
- rootに依存を置く前に、subproject配下で足りないか確認する。
- secretや外部writeを便利さのために自動実行しない。
