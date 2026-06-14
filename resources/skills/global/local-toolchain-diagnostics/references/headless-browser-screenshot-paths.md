# Headless Browser Screenshot Paths

Windows で Chrome / Edge の headless screenshot を撮る時の path 問題を、UI の表示崩れや app 側の不具合と混同しないためのメモ。

## 症状

- `--screenshot=artifacts\preview.png` のような相対path指定で、browser は起動するが screenshot file の書き込みに失敗する。
- exit code だけでは成功に見えることがある。
- `artifacts/` directory が存在していても、browser process 側の path 解決や working directory の違いで失敗する。

## 対応

1. screenshot 保存先 directory を事前に作る。
2. `--screenshot` には絶対pathを渡す。
3. 実行後に file size と更新時刻を見る。
4. screenshot は generated artifact として扱い、必要がなければ commit しない。

PowerShell 例:

```powershell
$shot = Join-Path (Get-Location) 'artifacts\preview.png'
& 'C:\Program Files\Google\Chrome\Application\chrome.exe' --headless=new --disable-gpu --window-size=1440,1100 --screenshot=$shot http://127.0.0.1:5173
```

## 報告に分けて書くこと

- app 側の build / ランタイム結果
- browser CLI の起動可否
- screenshot file の生成可否
- 相対path失敗から絶対pathへ切り替えた場合は、tooling fallback として扱う
