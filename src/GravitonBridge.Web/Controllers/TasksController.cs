using Microsoft.AspNetCore.Mvc;
using GravitonBridge.Data;
using GravitonBridge.Core.Models;
using Microsoft.EntityFrameworkCore;
using TaskModel = GravitonBridge.Core.Models.Task;
using TaskStatusEnum = GravitonBridge.Core.Models.TaskStatus;

namespace GravitonBridge.Web.Controllers;

public class TasksController : Controller
{
    private readonly ILogger<TasksController> _logger;
    private readonly ApplicationDbContext _context;

    public TasksController(ILogger<TasksController> logger, ApplicationDbContext context)
    {
        _logger = logger;
        _context = context;
    }

    public async System.Threading.Tasks.Task<IActionResult> Index()
    {
        var tasks = await _context.Tasks
            .OrderByDescending(t => t.CreatedAt)
            .ToListAsync();

        return View(tasks);
    }

    public IActionResult Create()
    {
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async System.Threading.Tasks.Task<IActionResult> Create(TaskModel task)
    {
        if (ModelState.IsValid)
        {
            task.Id = Guid.NewGuid();
            task.CreatedAt = DateTime.UtcNow;
            task.Status = TaskStatusEnum.Pending;

            _context.Tasks.Add(task);
            await _context.SaveChangesAsync();
            return RedirectToAction(nameof(Index));
        }
        return View(task);
    }

    public async System.Threading.Tasks.Task<IActionResult> Details(Guid? id)
    {
        if (id == null)
        {
            return NotFound();
        }

        var task = await _context.Tasks
            .FirstOrDefaultAsync(m => m.Id == id);
        if (task == null)
        {
            return NotFound();
        }

        return View(task);
    }

    [HttpPost]
    public async System.Threading.Tasks.Task<IActionResult> UpdateStatus(Guid id, TaskStatusEnum status)
    {
        var task = await _context.Tasks.FindAsync(id);
        if (task == null)
        {
            return NotFound();
        }

        task.Status = status;
        task.UpdatedAt = DateTime.UtcNow;
        
        if (status == TaskStatusEnum.Completed)
        {
            task.CompletedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    public async System.Threading.Tasks.Task<IActionResult> Delete(Guid id)
    {
        var task = await _context.Tasks.FindAsync(id);
        if (task != null)
        {
            _context.Tasks.Remove(task);
            await _context.SaveChangesAsync();
        }
        return RedirectToAction(nameof(Index));
    }
}
