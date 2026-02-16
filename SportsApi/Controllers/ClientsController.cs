using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SportsApi.Data;
using SportsApi.DTOs;
using SportsApi.Models;

namespace SportsApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ClientsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<ClientsController> _logger;

    public ClientsController(ApplicationDbContext context, ILogger<ClientsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ClientDto>>> GetClients()
    {
        var clients = await _context.Clients
            .Include(c => c.Campaigns)
            .Include(c => c.Products)
            .Select(c => new ClientDto
            {
                Id = c.Id,
                Name = c.Name,
                Description = c.Description,
                CampaignCount = c.Campaigns.Count,
                ProductCount = c.Products.Count,
                CreatedAt = c.CreatedAt,
                UpdatedAt = c.UpdatedAt
            })
            .ToListAsync();

        return Ok(clients);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ClientDto>> GetClient(int id)
    {
        var client = await _context.Clients
            .Include(c => c.Campaigns)
            .Include(c => c.Products)
            .Where(c => c.Id == id)
            .Select(c => new ClientDto
            {
                Id = c.Id,
                Name = c.Name,
                Description = c.Description,
                CampaignCount = c.Campaigns.Count,
                ProductCount = c.Products.Count,
                CreatedAt = c.CreatedAt,
                UpdatedAt = c.UpdatedAt
            })
            .FirstOrDefaultAsync();

        if (client == null)
        {
            return NotFound();
        }

        return Ok(client);
    }

    [HttpPost]
    public async Task<ActionResult<ClientDto>> CreateClient(CreateClientDto dto)
    {
        var client = new Client
        {
            Name = dto.Name,
            Description = dto.Description,
            CreatedAt = DateTime.UtcNow
        };

        _context.Clients.Add(client);
        await _context.SaveChangesAsync();

        var clientDto = new ClientDto
        {
            Id = client.Id,
            Name = client.Name,
            Description = client.Description,
            CreatedAt = client.CreatedAt,
            UpdatedAt = client.UpdatedAt
        };

        return CreatedAtAction(nameof(GetClient), new { id = client.Id }, clientDto);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateClient(int id, UpdateClientDto dto)
    {
        var client = await _context.Clients.FindAsync(id);

        if (client == null)
        {
            return NotFound();
        }

        if (!string.IsNullOrWhiteSpace(dto.Name))
        {
            client.Name = dto.Name;
        }

        if (dto.Description != null)
        {
            client.Description = dto.Description;
        }

        client.UpdatedAt = DateTime.UtcNow;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await ClientExists(id))
            {
                return NotFound();
            }
            throw;
        }

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteClient(int id)
    {
        var client = await _context.Clients.FindAsync(id);
        if (client == null)
        {
            return NotFound();
        }

        _context.Clients.Remove(client);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    private async Task<bool> ClientExists(int id)
    {
        return await _context.Clients.AnyAsync(e => e.Id == id);
    }
}
