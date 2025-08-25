using Microsoft.AspNetCore.Mvc;
using GravitonBridge.Services;
using GravitonBridge.Data;
using GravitonBridge.Web.Models;
using System.Diagnostics;

namespace GravitonBridge.Web.Controllers;

public class HomeController : Controller
{
    private readonly ILogger<HomeController> _logger;
    private readonly ISystemInfoService _systemInfoService;
    private readonly IBenchmarkService _benchmarkService;
    private readonly ApplicationDbContext _context;

    public HomeController(
        ILogger<HomeController> logger,
        ISystemInfoService systemInfoService,
        IBenchmarkService benchmarkService,
        ApplicationDbContext context)
    {
        _logger = logger;
        _systemInfoService = systemInfoService;
        _benchmarkService = benchmarkService;
        _context = context;
    }

    public async Task<IActionResult> Index()
    {
        var systemInfo = await _systemInfoService.GetSystemInfoAsync();
        var recentBenchmarks = _context.BenchmarkResults
            .OrderByDescending(b => b.Timestamp)
            .Take(5)
            .ToList();

        var viewModel = new DashboardViewModel
        {
            SystemInfo = systemInfo,
            RecentBenchmarks = recentBenchmarks,
            TaskCount = _context.Tasks.Count(),
            CompletedTaskCount = _context.Tasks.Count(t => t.Status == GravitonBridge.Core.Models.TaskStatus.Completed)
        };

        return View(viewModel);
    }

    public IActionResult Privacy()
    {
        return View();
    }

    [HttpPost]
    public async Task<IActionResult> RunBenchmark(string type)
    {
        try
        {
            var result = type.ToLower() switch
            {
                "cpu" => await _benchmarkService.RunCpuBenchmarkAsync(),
                "memory" => await _benchmarkService.RunMemoryBenchmarkAsync(),
                "fileio" => await _benchmarkService.RunFileIoBenchmarkAsync(),
                _ => throw new ArgumentException("Invalid benchmark type")
            };

            // Save to database
            _context.BenchmarkResults.Add(result);
            await _context.SaveChangesAsync();

            return Json(new { success = true, result });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error running benchmark: {Type}", type);
            return Json(new { success = false, error = ex.Message });
        }
    }

    [HttpPost]
    public async Task<IActionResult> RefreshSystemInfo()
    {
        try
        {
            var systemInfo = await _systemInfoService.GetSystemInfoAsync();
            return Json(new { success = true, systemInfo });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error refreshing system info");
            return Json(new { success = false, error = ex.Message });
        }
    }

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
    {
        return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
    }
}
