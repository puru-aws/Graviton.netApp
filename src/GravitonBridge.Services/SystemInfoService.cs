using System.Runtime.InteropServices;
using GravitonBridge.Core.Models;

namespace GravitonBridge.Services;

public interface ISystemInfoService
{
    SystemInfo GetSystemInfo();
    System.Threading.Tasks.Task<SystemInfo> GetSystemInfoAsync();
}

public class SystemInfoService : ISystemInfoService
{
    public SystemInfo GetSystemInfo()
    {
        return new SystemInfo
        {
            Architecture = RuntimeInformation.ProcessArchitecture.ToString(),
            OperatingSystem = RuntimeInformation.OSDescription,
            RuntimeVersion = RuntimeInformation.FrameworkDescription,
            ProcessorCount = Environment.ProcessorCount.ToString(),
            MachineName = Environment.MachineName,
            UserName = Environment.UserName,
            TotalMemory = GC.GetTotalMemory(false),
            AvailableMemory = GetAvailableMemory(),
            Timestamp = DateTime.UtcNow
        };
    }

    public async System.Threading.Tasks.Task<SystemInfo> GetSystemInfoAsync()
    {
        return await System.Threading.Tasks.Task.FromResult(GetSystemInfo());
    }

    private long GetAvailableMemory()
    {
        try
        {
            // This is a simplified approach - in production you might want to use platform-specific APIs
            var workingSet = Environment.WorkingSet;
            return workingSet;
        }
        catch
        {
            return 0;
        }
    }
}
