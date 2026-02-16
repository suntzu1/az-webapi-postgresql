# ========================================
# Azure Database Management Commands
# Start/Stop PostgreSQL to Save Costs
# ========================================

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('start','stop','status','cost')]
    [string]$Action = 'status'
)

$resourceGroup = "rg-campaign-manager"

# Get the database server name
Write-Host "?? Finding PostgreSQL server..." -ForegroundColor Cyan
$servers = az postgres flexible-server list --resource-group $resourceGroup 2>&1 | ConvertFrom-Json
if ($servers.Count -eq 0) {
    Write-Host "? No PostgreSQL servers found in resource group: $resourceGroup" -ForegroundColor Red
    exit 1
}

$dbServerName = $servers[0].name

switch ($Action) {
    'stop' {
        Write-Host "?? Stopping PostgreSQL server: $dbServerName" -ForegroundColor Yellow
        Write-Host "   This will reduce costs to ~`$4/month (storage only)" -ForegroundColor Green
        az postgres flexible-server stop --resource-group $resourceGroup --name $dbServerName
        Write-Host "? Server stopped! You're now only paying for storage." -ForegroundColor Green
    }
    
    'start' {
        Write-Host "?? Starting PostgreSQL server: $dbServerName" -ForegroundColor Yellow
        Write-Host "   This will take 1-2 minutes..." -ForegroundColor Cyan
        az postgres flexible-server start --resource-group $resourceGroup --name $dbServerName
        Write-Host "? Server started! You're now paying full price (~`$12-16/month)" -ForegroundColor Yellow
    }
    
    'status' {
        Write-Host "?? Checking server status..." -ForegroundColor Cyan
        $server = az postgres flexible-server show --resource-group $resourceGroup --name $dbServerName | ConvertFrom-Json
        $state = $server.state
        
        Write-Host "`nServer Name: $dbServerName" -ForegroundColor White
        Write-Host "Status: $state" -ForegroundColor $(if ($state -eq 'Ready') { 'Green' } else { 'Yellow' })
        Write-Host "Location: $($server.location)" -ForegroundColor White
        
        if ($state -eq 'Ready') {
            Write-Host "`n?? Current Cost: ~`$12-16/month (running)" -ForegroundColor Yellow
            Write-Host "?? Run: .\manage-database.ps1 -Action stop" -ForegroundColor Cyan
            Write-Host "   to reduce cost to ~`$4/month (storage only)" -ForegroundColor Green
        } else {
            Write-Host "`n?? Current Cost: ~`$4/month (storage only)" -ForegroundColor Green
            Write-Host "?? Run: .\manage-database.ps1 -Action start" -ForegroundColor Cyan
            Write-Host "   to use the database (costs ~`$12-16/month)" -ForegroundColor Yellow
        }
    }
    
    'cost' {
        Write-Host "?? COST BREAKDOWN - Pay As You Go" -ForegroundColor Cyan
        Write-Host "???????????????????????????????????????????" -ForegroundColor DarkGray
        Write-Host "When STOPPED (storage only):" -ForegroundColor Yellow
        Write-Host "  • PostgreSQL Storage:     ~`$4/month" -ForegroundColor Green
        Write-Host "  • App Service:            `$0 (F1 Free)" -ForegroundColor Green
        Write-Host "  • Static Web App:         `$0 (Free)" -ForegroundColor Green
        Write-Host "  • TOTAL:                  ~`$4/month" -ForegroundColor Green
        Write-Host "" -ForegroundColor White
        Write-Host "When RUNNING (active use):" -ForegroundColor Yellow
        Write-Host "  • PostgreSQL Compute:     ~`$12/month" -ForegroundColor Yellow
        Write-Host "  • PostgreSQL Storage:     ~`$4/month" -ForegroundColor Yellow
        Write-Host "  • App Service:            `$0 (F1 Free)" -ForegroundColor Green
        Write-Host "  • Static Web App:         `$0 (Free)" -ForegroundColor Green
        Write-Host "  • TOTAL:                  ~`$16/month" -ForegroundColor Yellow
        Write-Host "???????????????????????????????????????????" -ForegroundColor DarkGray
        Write-Host "`n?? BEST PRACTICE:" -ForegroundColor Cyan
        Write-Host "Stop database when done working, start when needed!" -ForegroundColor White
        Write-Host "Average cost for occasional use: ~`$5-8/month" -ForegroundColor Green
    }
}

Write-Host "`n?? Quick Commands:" -ForegroundColor Cyan
Write-Host "  Stop:    .\manage-database.ps1 -Action stop" -ForegroundColor White
Write-Host "  Start:   .\manage-database.ps1 -Action start" -ForegroundColor White
Write-Host "  Status:  .\manage-database.ps1 -Action status" -ForegroundColor White
Write-Host "  Costs:   .\manage-database.ps1 -Action cost" -ForegroundColor White
