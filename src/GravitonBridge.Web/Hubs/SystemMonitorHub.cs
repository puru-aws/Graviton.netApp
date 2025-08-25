using Microsoft.AspNetCore.SignalR;
using GravitonBridge.Services;

namespace GravitonBridge.Web.Hubs;

public class SystemMonitorHub : Hub
{
    private readonly ISystemInfoService _systemInfoService;
    private readonly IBenchmarkService _benchmarkService;

    public SystemMonitorHub(ISystemInfoService systemInfoService, IBenchmarkService benchmarkService)
    {
        _systemInfoService = systemInfoService;
        _benchmarkService = benchmarkService;
    }

    public async Task JoinGroup(string groupName)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, groupName);
    }

    public async Task LeaveGroup(string groupName)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, groupName);
    }

    public async Task GetSystemInfo()
    {
        var systemInfo = await _systemInfoService.GetSystemInfoAsync();
        await Clients.Caller.SendAsync("SystemInfoUpdate", systemInfo);
    }

    public async Task RunBenchmark(string benchmarkType)
    {
        await Clients.Caller.SendAsync("BenchmarkStarted", benchmarkType);
        
        try
        {
            var result = benchmarkType.ToLower() switch
            {
                "cpu" => await _benchmarkService.RunCpuBenchmarkAsync(),
                "memory" => await _benchmarkService.RunMemoryBenchmarkAsync(),
                "fileio" => await _benchmarkService.RunFileIoBenchmarkAsync(),
                _ => throw new ArgumentException("Invalid benchmark type")
            };

            await Clients.Caller.SendAsync("BenchmarkCompleted", result);
        }
        catch (Exception ex)
        {
            await Clients.Caller.SendAsync("BenchmarkError", ex.Message);
        }
    }
}
