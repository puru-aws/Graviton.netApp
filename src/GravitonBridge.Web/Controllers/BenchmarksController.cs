using Microsoft.AspNetCore.Mvc;
using GravitonBridge.Data;
using GravitonBridge.Services;
using Microsoft.EntityFrameworkCore;

namespace GravitonBridge.Web.Controllers;

public class BenchmarksController : Controller
{
    private readonly ILogger<BenchmarksController> _logger;
    private readonly ApplicationDbContext _context;
    private readonly IBenchmarkService _benchmarkService;

    public BenchmarksController(
        ILogger<BenchmarksController> logger, 
        ApplicationDbContext context,
        IBenchmarkService benchmarkService)
    {
        _logger = logger;
        _context = context;
        _benchmarkService = benchmarkService;
    }

    public async Task<IActionResult> Index()
    {
        var benchmarks = await _context.BenchmarkResults
            .OrderByDescending(b => b.Timestamp)
            .ToListAsync();

        return View(benchmarks);
    }

    [HttpPost]
    public async Task<IActionResult> RunAll()
    {
        try
        {
            // Run all three benchmarks
            var cpuResult = await _benchmarkService.RunCpuBenchmarkAsync();
            var memoryResult = await _benchmarkService.RunMemoryBenchmarkAsync();
            var fileIoResult = await _benchmarkService.RunFileIoBenchmarkAsync();

            // Save all results
            _context.BenchmarkResults.AddRange(cpuResult, memoryResult, fileIoResult);
            await _context.SaveChangesAsync();

            TempData["Success"] = "All benchmarks completed successfully!";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error running all benchmarks");
            TempData["Error"] = "Error running benchmarks: " + ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> ClearAll()
    {
        try
        {
            var allBenchmarks = await _context.BenchmarkResults.ToListAsync();
            _context.BenchmarkResults.RemoveRange(allBenchmarks);
            await _context.SaveChangesAsync();

            TempData["Success"] = "All benchmark results cleared successfully!";
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error clearing benchmark results");
            TempData["Error"] = "Error clearing results: " + ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            var benchmark = await _context.BenchmarkResults.FindAsync(id);
            if (benchmark != null)
            {
                _context.BenchmarkResults.Remove(benchmark);
                await _context.SaveChangesAsync();
                TempData["Success"] = "Benchmark result deleted successfully!";
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting benchmark result");
            TempData["Error"] = "Error deleting result: " + ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }

    public async Task<IActionResult> Details(int? id)
    {
        if (id == null)
        {
            return NotFound();
        }

        var benchmark = await _context.BenchmarkResults
            .FirstOrDefaultAsync(m => m.Id == id);
        
        if (benchmark == null)
        {
            return NotFound();
        }

        return View(benchmark);
    }

    public async Task<IActionResult> Compare()
    {
        var benchmarks = await _context.BenchmarkResults
            .OrderByDescending(b => b.Timestamp)
            .Take(10)
            .ToListAsync();

        return View(benchmarks);
    }
}
