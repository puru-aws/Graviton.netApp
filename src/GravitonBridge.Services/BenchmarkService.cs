using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Text.Json;
using GravitonBridge.Core.Models;

namespace GravitonBridge.Services;

public interface IBenchmarkService
{
    System.Threading.Tasks.Task<BenchmarkResult> RunCpuBenchmarkAsync();
    System.Threading.Tasks.Task<BenchmarkResult> RunMemoryBenchmarkAsync();
    System.Threading.Tasks.Task<BenchmarkResult> RunFileIoBenchmarkAsync();
    System.Threading.Tasks.Task<List<BenchmarkResult>> RunAllBenchmarksAsync();
}

public class BenchmarkService : IBenchmarkService
{
    public async System.Threading.Tasks.Task<BenchmarkResult> RunCpuBenchmarkAsync()
    {
        var stopwatch = Stopwatch.StartNew();
        var startMemory = GC.GetTotalMemory(false);
        
        // CPU intensive task - calculate prime numbers
        var primeCount = await System.Threading.Tasks.Task.Run(() => CountPrimesUpTo(100000));
        
        stopwatch.Stop();
        var endMemory = GC.GetTotalMemory(false);
        
        var additionalMetrics = new
        {
            PrimesFound = primeCount,
            TestType = "CPU_INTENSIVE"
        };

        return new BenchmarkResult
        {
            TestName = "CPU Benchmark",
            Architecture = RuntimeInformation.ProcessArchitecture.ToString(),
            ExecutionTimeMs = stopwatch.Elapsed.TotalMilliseconds,
            MemoryUsedBytes = endMemory - startMemory,
            CpuUsagePercent = 0, // Would need platform-specific code for accurate CPU usage
            OperationsPerSecond = (int)(primeCount / stopwatch.Elapsed.TotalSeconds),
            Timestamp = DateTime.UtcNow,
            AdditionalMetrics = JsonSerializer.Serialize(additionalMetrics)
        };
    }

    public async System.Threading.Tasks.Task<BenchmarkResult> RunMemoryBenchmarkAsync()
    {
        var stopwatch = Stopwatch.StartNew();
        var startMemory = GC.GetTotalMemory(false);
        
        // Memory intensive task - create and manipulate large arrays
        var operations = await System.Threading.Tasks.Task.Run(() => MemoryIntensiveOperations());
        
        stopwatch.Stop();
        var endMemory = GC.GetTotalMemory(false);
        
        var additionalMetrics = new
        {
            ArrayOperations = operations,
            TestType = "MEMORY_INTENSIVE"
        };

        return new BenchmarkResult
        {
            TestName = "Memory Benchmark",
            Architecture = RuntimeInformation.ProcessArchitecture.ToString(),
            ExecutionTimeMs = stopwatch.Elapsed.TotalMilliseconds,
            MemoryUsedBytes = endMemory - startMemory,
            CpuUsagePercent = 0,
            OperationsPerSecond = (int)(operations / stopwatch.Elapsed.TotalSeconds),
            Timestamp = DateTime.UtcNow,
            AdditionalMetrics = JsonSerializer.Serialize(additionalMetrics)
        };
    }

    public async System.Threading.Tasks.Task<BenchmarkResult> RunFileIoBenchmarkAsync()
    {
        var stopwatch = Stopwatch.StartNew();
        var startMemory = GC.GetTotalMemory(false);
        
        // File I/O intensive task
        var operations = await FileIoOperations();
        
        stopwatch.Stop();
        var endMemory = GC.GetTotalMemory(false);
        
        var additionalMetrics = new
        {
            FileOperations = operations,
            TestType = "FILE_IO_INTENSIVE"
        };

        return new BenchmarkResult
        {
            TestName = "File I/O Benchmark",
            Architecture = RuntimeInformation.ProcessArchitecture.ToString(),
            ExecutionTimeMs = stopwatch.Elapsed.TotalMilliseconds,
            MemoryUsedBytes = endMemory - startMemory,
            CpuUsagePercent = 0,
            OperationsPerSecond = (int)(operations / stopwatch.Elapsed.TotalSeconds),
            Timestamp = DateTime.UtcNow,
            AdditionalMetrics = JsonSerializer.Serialize(additionalMetrics)
        };
    }

    public async System.Threading.Tasks.Task<List<BenchmarkResult>> RunAllBenchmarksAsync()
    {
        var results = new List<BenchmarkResult>();
        
        results.Add(await RunCpuBenchmarkAsync());
        results.Add(await RunMemoryBenchmarkAsync());
        results.Add(await RunFileIoBenchmarkAsync());
        
        return results;
    }

    private int CountPrimesUpTo(int limit)
    {
        var count = 0;
        for (int i = 2; i <= limit; i++)
        {
            if (IsPrime(i))
                count++;
        }
        return count;
    }

    private bool IsPrime(int number)
    {
        if (number < 2) return false;
        for (int i = 2; i <= Math.Sqrt(number); i++)
        {
            if (number % i == 0)
                return false;
        }
        return true;
    }

    private int MemoryIntensiveOperations()
    {
        var operations = 0;
        var arrays = new List<int[]>();
        
        // Create multiple large arrays and perform operations
        for (int i = 0; i < 100; i++)
        {
            var array = new int[10000];
            for (int j = 0; j < array.Length; j++)
            {
                array[j] = j * i;
                operations++;
            }
            arrays.Add(array);
        }
        
        // Perform some operations on the arrays
        foreach (var array in arrays)
        {
            Array.Sort(array);
            operations++;
        }
        
        return operations;
    }

    private async System.Threading.Tasks.Task<int> FileIoOperations()
    {
        var operations = 0;
        var tempDir = Path.GetTempPath();
        var testFiles = new List<string>();
        
        try
        {
            // Create multiple files
            for (int i = 0; i < 10; i++)
            {
                var fileName = Path.Combine(tempDir, $"benchmark_test_{i}_{Guid.NewGuid()}.txt");
                var content = string.Join("\n", Enumerable.Range(0, 1000).Select(x => $"Line {x} in file {i}"));
                
                await File.WriteAllTextAsync(fileName, content);
                testFiles.Add(fileName);
                operations++;
            }
            
            // Read files
            foreach (var file in testFiles)
            {
                var content = await File.ReadAllTextAsync(file);
                operations++;
            }
            
            // Copy files
            for (int i = 0; i < testFiles.Count; i++)
            {
                var copyName = Path.Combine(tempDir, $"copy_{i}_{Guid.NewGuid()}.txt");
                File.Copy(testFiles[i], copyName);
                testFiles.Add(copyName);
                operations++;
            }
        }
        finally
        {
            // Cleanup
            foreach (var file in testFiles)
            {
                try
                {
                    if (File.Exists(file))
                        File.Delete(file);
                }
                catch { /* Ignore cleanup errors */ }
            }
        }
        
        return operations;
    }
}
