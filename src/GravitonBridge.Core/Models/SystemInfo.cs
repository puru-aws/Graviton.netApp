namespace GravitonBridge.Core.Models;

public class SystemInfo
{
    public string Architecture { get; set; } = string.Empty;
    public string OperatingSystem { get; set; } = string.Empty;
    public string RuntimeVersion { get; set; } = string.Empty;
    public string ProcessorCount { get; set; } = string.Empty;
    public string MachineName { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public long TotalMemory { get; set; }
    public long AvailableMemory { get; set; }
    public DateTime Timestamp { get; set; }
}
