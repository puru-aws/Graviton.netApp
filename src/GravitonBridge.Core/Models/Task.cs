namespace GravitonBridge.Core.Models;

public class Task
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public TaskStatus Status { get; set; }
    public TaskPriority Priority { get; set; }
    public int ExpectedDurationMinutes { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}

public enum TaskStatus
{
    Pending,
    Running,
    Completed,
    Failed
}

public enum TaskPriority
{
    Low,
    Medium,
    High,
    Critical
}
