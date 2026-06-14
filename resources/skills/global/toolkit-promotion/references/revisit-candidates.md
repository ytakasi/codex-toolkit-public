# 再判定候補

このファイルは保留箱であり、汎用知見の保存先そのものではない。
リポジトリ固有名詞を剥がしても意味が通り、次回以降の作業品質を上げるものは、既存 skill の `references/`、`assets/`、template、または global rule へ小さく昇格する。

ここに残すのは、名前、置き場所、責務境界、サブエージェントとしての使い方がまだ未確定なものに限る。
昇格した候補の履歴は、追加された skill / template / reference と git history に任せる。

## 残す再判定候補

### wpf-admin-tool-shell

CLI / batch の管理ツールを WPF で作る時の初期形候補。

再判定の焦点:

- WPF限定でよいか、WinUI / Avalonia / Web admin に広げるべきか。
- Core model 共有、secret masking、既存DB行ID維持保存、保存中ローディングが別リポジトリでも再発するか。
- 設定管理用の既存workflowと DB-backed config の reference で足りるか。

### decision-flow branching schema template

分岐型アプリやゲームで使う schema template 候補。
現時点では分岐仕様監査用profileの asset として置き、top-level template には出していない。

再判定の焦点:

- route / ending / state / fact / merge rule の初期形を、narrative 以外の decision-flow app でも使うか。
- `resources/templates/` に出すほど `codex-kit` 本体が直接読む初期形か。そうでなければ owning skill の `assets/` で足りるか。
- JSON schema や validator 雛形まで必要か。

### privacy-risk-first app bootstrap

AI連携、mobile app、health/location/personal activity data、external API proxy を含むリポジトリを立ち上げる時に、実装前へ置く初期docsセット候補。

発生元では、READMEを入口にし、project brief、roadmap、MVP scope、privacy model、decision log、risk register、technical feasibility、references、development story を初期commit前に整えた。
Android / mobile の実装前 risk burn-down は専用profileの範囲として扱うため、この候補では初期docsセットと privacy-first bootstrap の器だけを再判定する。

再判定の焦点:

- `repo-bootstrap` に reference/template として吸収するだけで足りるか、新skillが必要か。
- `PRIVACY_MODEL.md` / `DECISIONS.md` / `RISK_REGISTER.md` の初期雛形を、複数リポジトリでそのまま使うか。
- AI + personal data + external provider の組み合わせで、リポジトリ開始時に privacy/data boundary docs を先に固定する流れが再発するか。
- 実装後の ops 点検や外部providerの初回観測では遅すぎる、リポジトリ立ち上げ時専用の判断があるか。

## workflow / サブエージェント 再判定候補

サブエージェントは、ユーザーが明示的にサブエージェント / 並列探索 / 並列レビューを求めた時だけ使う候補として扱う。
通常作業では既存 skill を親エージェントが順に使う。

### optional scout / reviewer / auditor lane 群

現在は次の reference に optional lane と成果物形式がある。

- 外部source探索用の optional scout contract
- 運用差分確認用の optional scout contract
- 設定境界レビュー用の optional reviewer contract
- runtime state path 監査 contract

`source-scout` と `runtime-state-auditor` は reference 内に lane contract を持つ。まだ standalone skill / agent にはせず、ここには独立 サブエージェント 化を再判定する条件だけ残す。

再判定の焦点:

- read-only 探索、運用監査、設定分類、path matrix 作成を、親エージェントの本流作業から本当に並列化したいか。
- 既存 reference の成果物形式で足りるか。
- 複数リポジトリで同じ lane 名と入出力契約を共有するほど繰り返すか。

### content-review-lane

現在は文章修正 intake、gate review、QA report のテンプレートを組み合わせる。
ここには、domain 固有 editor / reviewer lane として切り出す条件だけ残す。

再判定の焦点:

- facilitator、domain reviewer、QA、integrator、scribe の流れが複数リポジトリで繰り返されるか。
- domain 固有の観点を剥がしても、workflow と成果物境界が残るか。
- top-level template で足りるか、skill 化して実行順まで持たせるべきか。
