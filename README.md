# Codex Toolkit

※本リポジトリのドキュメントやスキル本文には、生成AIの支援で作成・整理した内容を含みます。公開前に人間がレビューし、現時点の実装と整合することを確認しています。

Codex Toolkit は、Codex の運用ルール、スキル、フックをリポジトリごとに配備し、補助テンプレートを提供するための Windows / PowerShell 用ツールキット。
共通で使用するスキルやフックを対象リポジトリへ同期する。

中心になるのは `codex-kit` CLI。
用途別のプロファイルを選んで対象リポジトリへ同期できる作りになっている。

## なぜ作ったか

リポジトリ横断で使う Codex のルール、スキル、フックをグローバル設定に常駐させて運用していたが、そのリポジトリでは使用しない知見や手順までAIが読み込んでしまい、ノイズになることがあった。
特に個人開発ではWebアプリ、スマホアプリ、クライアントアプリ、バッチ、ゲームなど、技術的に違うものをいろいろ開発することがあるため、スマホアプリの開発中に別フレームワークの知見などを参照してしまっても意味がない。
共通資産を一か所で管理しつつ、対象リポジトリでは必要なプロファイルだけを選んで育てていくようにしたかったので作った。

- 用途に依らない汎用的なスキルは `resources/skills/global` に置く。
- 用途や技術ごとのスキルは `resources/skills/profiles/<profile>` に置く。
- リポジトリ側で育てる上書きや固有フックはリポジトリ側で `agent-skills/repo` に置く。
- Codex が読む `.agents` は生成物として扱い、直接編集しない。

## 動作要件

Codex Toolkit は Windows 上の PowerShell 7 以降で動かす前提。
CLI、インストーラー、生成される hook dispatcher は `pwsh` から実行される。

Windows PowerShell 5.1 は動作対象外。

## クイックスタート

### 1. CLI をインストールする

本リポジトリで以下のコマンドを実行して `codex-kit` をインストールする。
まず `-DryRun` で変更内容を確認してからインストールする。

事前確認

```powershell
.\scripts\install-codex-kit.ps1 -DryRun
```

インストール

```powershell
.\scripts\install-codex-kit.ps1
```

インストール後、ターミナルを再起動する。
新しく開いたターミナルで以下を実行してヘルプが表示されればOK。

```powershell
codex-kit --help
```

### 2. 新規リポジトリに入れる

対象リポジトリのルートで実行する。

```powershell
codex-kit init
```

プロファイルの選択画面が表示されるので、用途に合わせて番号を入力する。
選択後、必要なスキルとフックの同期まで実行される。

```txt
作るもの・盛り込む機能に近い番号を選んでください。
複数ある時は、カンマかスペースで区切って入力できます。
迷ったら何も入力せず Enter で基本構成にします。
  1. 基本だけ / まだ未定
  2. 定期実行 / 巡回バッチ
  3. 署名付きwebhook受信 / bot
  4. Godot 4 / C#ゲーム
  5. ノベルゲーム / 分岐シナリオ
  6. codex-toolkit 自体
  7. Androidアプリ
  8. 外部API / Webページからデータ取得
  9. Discord / Slack / Teams / webhook 通知
 10. 設定画面 / 管理画面 / 設定ファイル / CLIオプション
 11. デプロイ / migration / IaC / DB権限変更
番号（例: 4 2 5）: 4 2 5
```

## init 後に触る場所

普段触る場所は多くない。

- `agent-skills/repo/skills/<skill-name>/SKILL.md`: 対象リポジトリ固有のスキル。
- `agent-skills/repo/hooks.d/<Event>/<name>.*`: 対象リポジトリ固有のフック。
- `.agents`: Codex が読む生成先。`codex-kit sync` で作り直されるため、直接編集しない。
- `.codex-kit/manifest.json`: 選んだプロファイルなどの記録。通常は手で編集しない。

同期の詳しい仕組み、生成物、フック振り分けは [TOOLKIT_DISTRIBUTION.md](docs/TOOLKIT_DISTRIBUTION.md) に置く。

## よく使うコマンド

| コマンド | 用途 |
|---|---|
| `codex-kit update` | Codex Toolkit 側の更新を取り込み、対象リポジトリへ同期する。 |
| `codex-kit status` | 対象リポジトリの選択プロファイルと同期状態を見る。 |
| `codex-kit doctor` | PATH、manifest、生成先などを点検する。 |
| `codex-kit list-profiles` | 選べるプロファイルと含まれるスキルを見る。 |

## スキルを追加する場所

`.agents` は生成物なので、スキルやフックの正本は別の場所に置く。

- 対象リポジトリだけで使うスキル: `agent-skills/repo/skills/<skill-name>/SKILL.md`
- 対象リポジトリだけで使うフック: `agent-skills/repo/hooks.d/<Event>/<name>.*`
- toolkit 全体に配るスキル: `resources/skills/global/<skill-name>/SKILL.md`
- 用途別プロファイルに入れるスキル: `resources/skills/profiles/<profile>/<skill-name>/SKILL.md`

新しくスキル、フックを作る時は `skill-authoring` スキルを使い、正本ルートと配布レイヤーを先に確認する。
これにより、AIが間違えることなく配置すべき場所にスキルやフックを作成できる。

## 公開版について

公開版では、実運用で育ったすべてのスキルは収録していない。
各プロファイルの考え方が分かる代表スキルだけを置き、プロファイル、プリセット、リポジトリ固有上書きの動きが分かる最小構成にしている。

## ドキュメント

| ファイル | 役割 |
|---|---|
| [TOOLKIT_DISTRIBUTION.md](docs/TOOLKIT_DISTRIBUTION.md) | toolkit / リポジトリレイヤー、生成物、フック、マニフェスト、同期仕様の詳細。 |
| [SKILL_LAYER_INVENTORY.md](docs/SKILL_LAYER_INVENTORY.md) | スキル、プロファイル、テンプレートの分類表。新しいスキルの置き場所を決める時に見る。 |
