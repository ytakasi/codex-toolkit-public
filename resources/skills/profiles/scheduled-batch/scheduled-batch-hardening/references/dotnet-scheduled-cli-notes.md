# .NET scheduled CLI notes

.NET の one-shot CLI を GitHub Actions や外部 scheduler で動かす時の補足。
scheduled batch 一般の外枠は `scheduled-batch-hardening` を正本にし、この reference では .NET / solution 構成で迷いやすい点だけを扱う。

## Job の実行対象を先に決める

- CI の restore / build / test は、リポジトリ全体ではなく、その job が実際に実行する最小 project から考える。
- solution に Windows 専用 UI project と cross-platform CLI が混在する場合、Linux runner の scheduled job で solution 全体を restore しない。
- `dotnet run --project path/to/AppCli` で動かす job なら、restore も基本はその CLI project を対象にする。
- test job とランタイム用 job は対象が違うことがあるため、同じ restore 対象を使い回す前に project graph を確認する。
- ランタイム用 project だけを build した後に test project を `--no-build` で実行しない。test project を別に build するか、`dotnet test` 側で通常の build / restore を許す。

## Runner OS と target framework

- `net*-windows`、WPF、WinForms、Windows SDK 依存 project は Linux runner で restore / build に失敗し得る。
- Windows 専用 project を CI で確認したい場合は、ランタイム用 job から分けて `windows-latest` の別 job にする。
- Linux runner で本番 scheduled CLI を動かすなら、CLI とその参照 project は cross-platform target に保つ。

## NuGet cache と restore

- NuGet cache の key は lock file、project file、global.json など、実際の restore 対象に影響する file に合わせる。
- cache があっても restore 対象が広すぎると OS mismatch は防げない。
- `--no-restore` を使う run / build step は、直前の restore 対象と一致しているか確認する。

## Migration と ランタイム

- DB migration が必要な scheduled CLI では、migration credential とランタイム用 credential を分けるか検討する。
- migration を毎回 ランタイム用 job の前に走らせるか、manual / release job に分けるかを明示する。
- ランタイム用 credential しかない時に migration failure で本番監視が止まらないよう、実行条件を分ける。

## 最小 workflow 形

```yaml
- uses: actions/setup-dotnet@v4
  with:
    dotnet-version: "REPLACE_ME_DOTNET_VERSION"

- name: Restore
  run: dotnet restore path/to/AppCli/AppCli.csproj

- name: Run
  run: dotnet run --no-restore --project path/to/AppCli/AppCli.csproj --configuration Release
```

必要に応じて、`concurrency`、`timeout-minutes`、Secrets / Variables 分離、失敗通知、migration 分離を `scheduled-batch-hardening` の手順に沿って足す。
