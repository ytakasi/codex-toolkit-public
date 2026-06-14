using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace ReplaceMe;

/// <summary>
/// scheduler から起動され、1回だけ処理して終了する実行単位。
/// </summary>
internal sealed class OneShotRunner(
    IOptions<WorkerOptions> options,
    ILogger<OneShotRunner> logger)
{
    private readonly WorkerOptions workerOptions = options.Value;

    /// <summary>
    /// コマンドライン引数を反映して処理を1回実行する。
    /// </summary>
    public async Task RunAsync(string[] args)
    {
        var dryRun = this.workerOptions.DryRun || args.Contains("--dry-run", StringComparer.OrdinalIgnoreCase);

        using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(this.workerOptions.MaxRunSeconds));

        if (dryRun)
        {
            logger.LogInformation("dry-run として実行します。外部副作用は行いません。");
        }

        await this.RunCoreAsync(dryRun, cts.Token);
    }

    private Task RunCoreAsync(bool dryRun, CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();

        logger.LogInformation("ここに1回実行の本体を実装します。DryRun={DryRun}", dryRun);
        return Task.CompletedTask;
    }
}
