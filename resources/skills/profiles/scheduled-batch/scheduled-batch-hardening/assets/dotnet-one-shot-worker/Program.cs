using System;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Options;

namespace ReplaceMe;

internal static class Program
{
    public static async Task<int> Main(string[] args)
    {
        try
        {
            var builder = Host.CreateApplicationBuilder(args);

            builder.Services
                .AddOptions<WorkerOptions>()
                .Bind(builder.Configuration.GetSection("Worker"))
                .ValidateDataAnnotations()
                .ValidateOnStart();

            builder.Services.AddSingleton<OneShotRunner>();

            using var host = builder.Build();
            await host.Services.GetRequiredService<OneShotRunner>().RunAsync(args);
            return 0;
        }
        catch (OptionsValidationException ex)
        {
            Console.Error.WriteLine("設定が正しくないため起動できません。");

            foreach (var failure in ex.Failures)
            {
                Console.Error.WriteLine($"- {failure}");
            }

            return 2;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine("実行中にエラーが発生しました。");
            Console.Error.WriteLine(ex.Message);
            return 1;
        }
    }
}
