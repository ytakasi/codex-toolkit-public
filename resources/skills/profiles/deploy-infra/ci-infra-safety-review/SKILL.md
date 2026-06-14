---
name: ci-infra-safety-review
description: GitHub Actions、CI/CD、deploy、migration、Terraform apply、Cloudflare、DB権限など外部環境を変える前の安全レビューに使う。本番反映前、workflow変更、IaC変更、secretやstateの扱い、破壊的操作、再実行性が気になる時に、credential境界とrollback観点を点検する。
---

# CI / Infra Safety Review

## 手順

1. 変更対象を棚卸しする。
   - workflow、deploy script、IaC、migration、provider CLI、secret / variable を見る。
   - 何が read-only で、何が外部状態を変更するかを分ける。
2. state管理を確認する。
   - Terraform / Pulumi / provider state / generated config など、外部状態を追跡するものを探す。
   - ephemeral runner から apply する場合は remote backend / state保存先が必須。
   - local state のままCIで apply する構成は止めるか、plan-onlyに落とす。
3. credential境界を確認する。
   - ランタイム用、migration用、provisioning用、deploy用、notification用を分ける。
   - ランタイム用 credential に DDL / owner / account-wide admin 権限を持たせない。
   - secret がログ、artifact、Terraform state、workflow output に出ないかを見る。
4. migrationの実行条件を確認する。
   - migration は owner credential が設定されている時だけ実行するなど、明示条件を置く。
   - ランタイム用 credentialしかない時に migration step が失敗して本番jobを止めない設計を検討する。
5. 冪等性と再実行性を確認する。
   - workflow rerun、partial failure、deploy後hook失敗、provider timeout で壊れないかを見る。
   - command登録やendpoint設定のようなpost-deploy hookは、再実行しても同じ状態へ収束するか確認する。
6. 破壊的操作を確認する。
   - delete / recreate / reset / force / overwrite / bulk apply を探す。
   - destructive な処理は明示的な手動承認、dry-run、対象確認を要求する。
7. 通知と観測性を確認する。
   - 失敗時に人間が気づける通知があるか。
   - partial skip や migration skip のような正常系の注意も log / notice に残るか。

## 原則

- CI runner は消えるものとして扱う。外部stateをrunnerのlocal fileだけに置かない。
- credential は「通るか」ではなく「漏れた時・誤用した時の被害」で分ける。
- deploy workflow は成功パスだけでなく、rerun と途中失敗から考える。
- stateやsecretを含み得る出力を、PRコメント、Actions output、artifactへ気軽に出さない。
- IaCを採用しない判断も、安全な判断なら明記する。

## assets

- Cloudflare Worker deploy workflow の初期形が必要なら `assets/github-actions/cloudflare-worker-deploy.yml` を使う。

## 出力

- 外部状態を変更するstep一覧
- state backend / remote state の有無
- credential分離の評価
- migration / provisioning の実行条件
- destructive risk
- rerun / partial failure の懸念
- 必須修正、推奨修正、リポジトリ固有に残す判断
