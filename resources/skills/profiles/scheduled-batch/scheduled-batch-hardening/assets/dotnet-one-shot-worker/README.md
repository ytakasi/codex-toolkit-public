# .NET One-shot Worker Template

`Host.CreateApplicationBuilder`、DI、Options、`ILogger<T>` を使い、1回実行して終了する CLI / scheduled batch の初期形。

## 使い方

1. `Program.cs`、`WorkerOptions.cs`、`OneShotRunner.cs` を対象プロジェクトへコピーする。
2. 新規プロジェクトから始める場合は `ReplaceMe.csproj` も叩き台にする。
3. `ReplaceMe` namespace、target framework、package version、オプション名をリポジトリに合わせて変える。
4. `OneShotRunner.RunAsync()` に実処理を入れる。
5. `dotnet run -- --dry-run` と通常実行の両方を確認する。

## 方針

- 常駐workerではなく、schedulerから起動されて1回処理して終了する。
- 起動時に設定を検証し、secretや生設定値をそのまま例外やlogへ出さない。
- `--dry-run` は外部副作用を行わず、取得件数や対象件数のsummaryだけ出す。
- 未処理例外はtop-level `try/catch` で受け、終了コードを明確にする。
