# スキルレイヤー棚卸し

※本ドキュメントは、生成AIの支援を受けて作成・整理した内容を含みます。公開前に人間がレビューし、現時点の実装と整合することを確認しています。

この文書は、公開版 `codex-toolkit` に含めるスキルとプロファイルの構成を説明する。
公開版は、実運用で育ったすべてのスキルを収録するのではなく、プロファイル、プリセット、リポジトリ固有上書きの動きが分かる代表スキルだけを置く。

## 分類軸

- `resources/skills/global`: どのリポジトリでも入っていて困らない基礎作業能力。
- `resources/skills/profiles/<profile>`: 作るもの、使う技術、外部境界に応じて `init` が追加する能力。
- `resources/templates/`: `codex-kit` 本体が直接読む CLI 所有の初期形。スキル固有の雛形は置かず、各スキルの `assets/` に同梱する。
- リポジトリ固有の語彙、設計、実装パスを前提にするものは、配布せず対象リポジトリの `agent-skills/repo` に残す。

```txt
resources/
|-- skills/
|   |-- global/
|   |   `-- <global skill>/
|   `-- profiles/
|       |-- android-mobile/<representative skill>/
|       |-- deploy-infra/<representative skill>/
|       |-- godot-csharp/<representative skill>/
|       |-- narrative/<representative skill>/
|       |-- notifications/<representative skill>/
|       |-- persisted-config/<representative skill>/
|       |-- provider-integration/<representative skill>/
|       |-- scheduled-batch/<representative skill>/
|       |-- toolkit-maintenance/<representative skill>/
|       `-- webhook-worker/<representative skill>/
|-- hooks/
|   `-- global/hooks.d/<Event>/
`-- templates/
    |-- repo/
    |-- codex-kit/
    `-- codex-requirements/

<repo>/
`-- agent-skills/
    `-- repo/
        |-- skills/<repo-specific skill>/
        |-- agents/
        `-- hooks.d/<Event>/
```

新しくスキル、エージェントメタデータ、フックを作る時は、先に `skill-authoring` を使って正本ルートと配布レイヤーを判定する。

## 公開v1のプロファイル

| プロファイル | 用途 | 代表スキル | プロファイルで扱うこと |
|---|---|---|---|
| `global` | 基本作業用 | `work-mode-triage`, `repo-bootstrap`, `project-preflight`, `clarity-review`, `codex-config-doctor`, `local-toolchain-diagnostics`, `session-handoff`, `project-retrospective`, `toolkit-promotion`, `skill-authoring` | どのリポジトリでも起きる初期化、レビュー、環境診断、引き継ぎ、共通知見化。 |
| `android-mobile` | Androidアプリ用 | `android-mobile-risk-burndown` | Androidアプリの権限管理、実機確認、センシティブなデータの扱い、Android API 利用時の注意点。 |
| `scheduled-batch` | 定期実行 / 巡回バッチ用 | `scheduled-batch-hardening` | 定期実行、巡回処理、定期ジョブの実行制御、失敗時対応、履歴管理。 |
| `notifications` | 通知送信用 | `discord-alert-message-polish` | Discord や webhook などで送る通知の文面、重要度、判断材料の整理。 |
| `deploy-infra` | デプロイ / インフラ変更用 | `ci-infra-safety-review` | デプロイ、migration、IaC、DB権限変更など、外部環境を変える作業。 |
| `provider-integration` | 外部データ取り込み用 | `provider-dry-run` | 外部APIやWebページからの取得、正規化、欠損、失敗分類、運用化前の事前確認。 |
| `persisted-config` | 設定管理機能用 | `persisted-settings-change` | 通知先、監視条件、連携先、feature flag などを後から変えられる設定管理機能。 |
| `webhook-worker` | 署名付きwebhook受信用 | `signed-webhook-worker` | 外部サービスから呼ばれる署名付き webhook の受信処理。 |
| `godot-csharp` | Godot 4 / C#ゲーム用 | `godot-smoke-test` | Godot 4 / C# プロジェクトのビルド、起動、scene の最小動作確認。 |
| `narrative` | ノベルゲーム / 分岐シナリオ用 | `narrative-spec-readiness-audit` | ノベルゲーム、会話シナリオ、分岐ストーリーの仕様整理と実装前準備。 |
| `toolkit-maintenance` | toolkit保守用 | `toolkit-integrity-audit` | `codex-toolkit` 自体の公開面、テンプレート、スキル配置、CLI 配布モデル。 |

## init 選択肢からの組み立て

`codex-kit init` は、番号入力からプロファイルを足す。
ユーザーにプロファイル名を覚えさせない。

| 選択肢 | 足すプロファイル |
|---|---|
| 基本だけ / まだ未定 | `global` |
| 定期実行 / 巡回バッチ | `scheduled-batch` |
| 署名付きwebhook受信 / bot | `webhook-worker` |
| Godot 4 / C#ゲーム | `godot-csharp` |
| ノベルゲーム / 分岐シナリオ | `narrative` |
| `codex-toolkit` 自体 | `toolkit-maintenance` と全プロファイル |
| Androidアプリ | `android-mobile` |
| 外部API / Webページからデータ取得 | `provider-integration` |
| Discord / Slack / Teams / webhook 通知 | `notifications` |
| 設定画面 / 管理画面 / 設定ファイル / CLIオプション | `persisted-config` |
| デプロイ / migration / IaC / DB権限変更 | `deploy-infra` |

## 公開v1に含めないもの

次のようなスキルは、公開初回では主題が散るため含めない。

- provider 本番 job 化の細かい hardening
- prose 改稿の実運用スキル
- `codex-toolkit` CLI 実装専用スキル
- GitHub issue 操作や worktree cleanup など、個人運用に寄りやすいスキル
- 詳細 ops 監査や、特定の開発履歴に強く依存するスキル

## プリセット

非対話や急ぎの初期化では、プリセットを使って質問を省略してよい。
プリセットは内部的に複数プロファイルを選ぶだけのショートカットとして扱う。

| プリセット | プロファイル |
|---|---|
| `basic` | `global` |
| `android-mobile` | `global`, `android-mobile` |
| `scheduled-batch` | `global`, `scheduled-batch` |
| `webhook-service` | `global`, `webhook-worker` |
| `godot-csharp` | `global`, `godot-csharp` |
| `narrative` | `global`, `narrative` |
| `codex-toolkit` | `global`, 全プロファイル, `toolkit-maintenance` |

## テンプレート

| 置き場所 | 扱い |
|---|---|
| `resources/templates/repo` | `codex-kit init` が使うリポジトリ初期化テンプレート。 |
| `resources/templates/codex-kit` | `codex-kit sync` が生成する hook dispatcher の正本。 |
| `resources/templates/codex-requirements` | Codex の管理側強制設定用の雛形。 |
| `resources/skills/global/repo-bootstrap/assets` | 新規リポジトリの `AGENTS.md`、開発記録、setup docs、Node setup helper の叩き台。 |
| `resources/skills/global/work-mode-triage/assets` | issue body と作業モード切り替え checklist の初期形。 |
| `resources/skills/global/report-artifact-writing/assets` | PR、QA、review、handoff、content revision、gate review の成果物テンプレート。 |
| `resources/skills/profiles/scheduled-batch/scheduled-batch-hardening/assets` | 定期ジョブ用 GitHub Actions workflow と .NET one-shot worker の初期形。 |
| `resources/skills/profiles/deploy-infra/ci-infra-safety-review/assets` | CI/CD から deploy する workflow の初期形。 |
