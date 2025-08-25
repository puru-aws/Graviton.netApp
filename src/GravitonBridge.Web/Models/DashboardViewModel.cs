using GravitonBridge.Core.Models;

namespace GravitonBridge.Web.Models;

public class DashboardViewModel
{
    public SystemInfo SystemInfo { get; set; } = new();
    public List<BenchmarkResult> RecentBenchmarks { get; set; } = new();
    public int TaskCount { get; set; }
    public int CompletedTaskCount { get; set; }
}
