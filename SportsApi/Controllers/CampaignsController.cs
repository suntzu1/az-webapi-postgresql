using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SportsApi.Data;
using SportsApi.DTOs;
using SportsApi.Models;

namespace SportsApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CampaignsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<CampaignsController> _logger;

    public CampaignsController(ApplicationDbContext context, ILogger<CampaignsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<CampaignDto>>> GetCampaigns()
    {
        var campaigns = await _context.Campaigns
            .Include(c => c.Client)
            .Select(c => new CampaignDto
            {
                Id = c.Id,
                Name = c.Name,
                Description = c.Description,
                StartDate = c.StartDate,
                EndDate = c.EndDate,
                TargetAudience = c.TargetAudience,
                Budget = c.Budget,
                ClientId = c.ClientId,
                ClientName = c.Client.Name,
                CreatedAt = c.CreatedAt,
                UpdatedAt = c.UpdatedAt
            })
            .ToListAsync();

        return Ok(campaigns);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<CampaignDto>> GetCampaign(int id)
    {
        var campaign = await _context.Campaigns
            .Include(c => c.Client)
            .Where(c => c.Id == id)
            .Select(c => new CampaignDto
            {
                Id = c.Id,
                Name = c.Name,
                Description = c.Description,
                StartDate = c.StartDate,
                EndDate = c.EndDate,
                TargetAudience = c.TargetAudience,
                Budget = c.Budget,
                ClientId = c.ClientId,
                ClientName = c.Client.Name,
                CreatedAt = c.CreatedAt,
                UpdatedAt = c.UpdatedAt
            })
            .FirstOrDefaultAsync();

        if (campaign == null)
        {
            return NotFound();
        }

        return Ok(campaign);
    }

    [HttpPost]
    public async Task<ActionResult<CampaignDto>> CreateCampaign(CreateCampaignDto dto)
    {
        if (!await _context.Clients.AnyAsync(c => c.Id == dto.ClientId))
        {
            return BadRequest("Client not found");
        }

        var campaign = new Campaign
        {
            Name = dto.Name,
            Description = dto.Description,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            TargetAudience = dto.TargetAudience,
            Budget = dto.Budget,
            ClientId = dto.ClientId,
            CreatedAt = DateTime.UtcNow
        };

        _context.Campaigns.Add(campaign);
        await _context.SaveChangesAsync();

        var campaignDto = await _context.Campaigns
            .Include(c => c.Client)
            .Where(c => c.Id == campaign.Id)
            .Select(c => new CampaignDto
            {
                Id = c.Id,
                Name = c.Name,
                Description = c.Description,
                StartDate = c.StartDate,
                EndDate = c.EndDate,
                TargetAudience = c.TargetAudience,
                Budget = c.Budget,
                ClientId = c.ClientId,
                ClientName = c.Client.Name,
                CreatedAt = c.CreatedAt,
                UpdatedAt = c.UpdatedAt
            })
            .FirstAsync();

        return CreatedAtAction(nameof(GetCampaign), new { id = campaign.Id }, campaignDto);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateCampaign(int id, UpdateCampaignDto dto)
    {
        var campaign = await _context.Campaigns.FindAsync(id);

        if (campaign == null)
        {
            return NotFound();
        }

        if (!string.IsNullOrWhiteSpace(dto.Name))
        {
            campaign.Name = dto.Name;
        }

        if (dto.Description != null)
        {
            campaign.Description = dto.Description;
        }

        if (dto.StartDate.HasValue)
        {
            campaign.StartDate = dto.StartDate.Value;
        }

        if (dto.EndDate.HasValue)
        {
            campaign.EndDate = dto.EndDate.Value;
        }

        if (dto.TargetAudience != null)
        {
            campaign.TargetAudience = dto.TargetAudience;
        }

        if (dto.Budget.HasValue)
        {
            campaign.Budget = dto.Budget.Value;
        }

        campaign.UpdatedAt = DateTime.UtcNow;

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            if (!await CampaignExists(id))
            {
                return NotFound();
            }
            throw;
        }

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteCampaign(int id)
    {
        var campaign = await _context.Campaigns.FindAsync(id);
        if (campaign == null)
        {
            return NotFound();
        }

        _context.Campaigns.Remove(campaign);
        await _context.SaveChangesAsync();

        return NoContent();
    }

    private async Task<bool> CampaignExists(int id)
    {
        return await _context.Campaigns.AnyAsync(e => e.Id == id);
    }
}
