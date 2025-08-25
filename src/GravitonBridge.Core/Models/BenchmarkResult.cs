namespace GravitonBridge.Core.Models;

public class BenchmarkResult
{
    public int Id { get; set; }
    public string TestName { get; set; } = string.Empty;
    public string Architecture { get; set; } = string.Empty;
    public double ExecutionTimeMs { get; set; }
    public long MemoryUsedBytes { get; set; }
    public double CpuUsagePercent { get; set; }
    public int OperationsPerSecond { get; set; }
    public DateTime Timestamp { get; set; }
    public string AdditionalMetrics { get; set; } = string.Empty; // JSON string for flexible metrics
}
