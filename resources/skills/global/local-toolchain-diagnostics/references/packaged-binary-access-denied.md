# Packaged Binary Access Denied

Windows Store app、Electron app bundle、sandbox-managed directory など、アプリ管理配下の binary が PATH 上に見えるのに起動できない時の判断メモ。

## 典型例

- `Get-Command` や `where.exe` では実行ファイルが見つかる。
- `--version` や `--help` だけで `Access denied` / `アクセスが拒否されました` になる。
- 同じ binary を user-controlled path に置くと起動できる。

## 切り分け

1. 解決先を確認する。
   - `Get-Command <name>`
   - `where.exe <name>`
2. 副作用のない実行確認をする。
   - `<command> --version`
   - `<command> --help`
3. path class を見る。
   - `Program Files\WindowsApps`
   - app bundle / packaged resources
   - sandbox temp directory
   - user profile 配下の通常 install
4. 必要なら event log を見る。
   - AppLocker
   - CodeIntegrity
   - Windows Security protection history

## 対処の優先順位

1. 通常 installer / package manager / standalone binary で user-controlled path に置く。
2. PATH で user-controlled path を app-managed path より前に置く。
3. リポジトリdocs では app-managed path を正本にしない。
4. ACL / owner 変更は最終手段にし、まず避ける。

## 記録すること

- PATH で見つかった path。
- 起動確認の結果。
- 同じ binary または通常 install で起動できたか。
- 採用した fallback。
- ACL を変更しなかった理由、または変更が必要な場合の承認理由。
