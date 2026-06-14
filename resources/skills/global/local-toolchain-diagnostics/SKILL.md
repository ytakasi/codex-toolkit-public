---
name: local-toolchain-diagnostics
description: ローカル、Windows、sandbox、packaged app環境で command / toolchain が見つからない、PATH上にあるのに起動できない、access denied、標準コマンド未導入、version確認失敗が起きた時に使う。PATH検出と実起動、権限、cache/profile問題を切り分ける。
---

# Local Toolchain Diagnostics

ローカル環境、Codex sandbox、CI runner の toolchain 失敗を、project bug と混同しないための診断 workflow。

## 使う場面

- `Get-Command` / `where` / `which` では見つかるのに、実行すると access denied や起動失敗になる。
- リポジトリの標準手順が `make`、`python`、`godot`、`rg` などに依存しているが、実環境では通らない。
- bundled binary、Store app、Electron app、sandbox 配下の実行ファイルだけが失敗する。
- README、setup、CI、agent instructions の標準コマンドと、実際の開発環境がズレているか確認したい。

## 手順

1. 期待される platform と shell を確認する。
   - リポジトリの `AGENTS.md`、README、setup docs、CI runner OS を見る。
   - local 標準と CI-only 手順を分ける。
2. 対象コマンドを列挙する。
   - build / test / lint / format / compile / validator / smoke test。
   - docs や template に出てくる helper command。
3. 解決先を確認する。
   - Windows: `Get-Command <name>` と `where.exe <name>`。
   - macOS / Linux: `command -v <name>`。
4. 実行できるか確認する。
   - `--version`、`--help`、または副作用のない dry-run を使う。
   - 「PATH にある」と「起動できる」を別の結果として記録する。
5. 失敗 class を分ける。
   - not found
   - wrong binary / wrong version
   - access denied / packaged app path
   - sandbox / profile / cache permission
   - missing ランタイム / dependency
   - project command failure
6. fallback を決める。
   - project 標準コマンドへ戻せるなら、それを正本にする。
   - shell wrapper だけが無い場合は、wrapper ではなく実体コマンドを docs に併記する。
   - packaged app 配下の binary が拒否される場合は、まず user-controlled path への通常 install / PATH override を検討する。
   - headless browser の screenshot 保存だけが失敗する場合は、`references/headless-browser-screenshot-paths.md` を読み、相対pathと絶対pathの違いを切り分ける。
7. 結果を残す。
   - 必要なら `assets/toolchain-readiness-report.md` を使う。
   - packaged binary の access denied なら `references/packaged-binary-access-denied.md` を読む。

## 出力

- 対象 platform / shell
- 確認した command 一覧
- found path と runnable 判定
- 失敗 class
- fallback または install 方針
- リポジトリdocs / template / CI で直すべき stale command

## 原則

- コマンド存在確認と実行確認を混同しない。
- shell 都合の失敗を product bug と断定しない。
- OS や app が管理する directory の ACL / owner は、最初の解決策として変更しない。
- fallback は「通ったから採用」ではなく、リポジトリの標準環境で再現しやすいものを選ぶ。
