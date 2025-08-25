using Microsoft.EntityFrameworkCore;
using GravitonBridge.Core.Models;

namespace GravitonBridge.Data;

public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options)
    {
    }

    public DbSet<GravitonBridge.Core.Models.Task> Tasks { get; set; }
    public DbSet<BenchmarkResult> BenchmarkResults { get; set; }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<GravitonBridge.Core.Models.Task>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Description).HasMaxLength(1000);
            entity.Property(e => e.Status).HasConversion<string>();
            entity.Property(e => e.Priority).HasConversion<string>();
        });

        modelBuilder.Entity<BenchmarkResult>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.TestName).IsRequired().HasMaxLength(100);
            entity.Property(e => e.Architecture).IsRequired().HasMaxLength(50);
            entity.Property(e => e.AdditionalMetrics);
        });
    }
}
