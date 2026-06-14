using System.ComponentModel.DataAnnotations;

namespace ReplaceMe;

/// <summary>
/// 1回実行の worker が起動時に読む設定。
/// </summary>
internal sealed class WorkerOptions
{
    /// <summary>
    /// 外部副作用を行わず、取得や判定のsummaryだけ確認するか。
    /// </summary>
    public bool DryRun { get; init; }

    /// <summary>
    /// 1回の実行で使える最大秒数。
    /// </summary>
    [Range(1, 3600)]
    public int MaxRunSeconds { get; init; } = 300;
}
