# Test if script syntax is valid
Write-Host "Testing DEPLOY-NOW.ps1 syntax..." -ForegroundColor Cyan

try {
    $errors = @()
    $null = [System.Management.Automation.PSParser]::Tokenize(
        (Get-Content "D:\Work\Outform\az-webapi-postgresql\DEPLOY-NOW.ps1" -Raw), 
        [ref]$errors
    )
    
    if ($errors.Count -gt 0) {
        Write-Host "? Syntax errors found:" -ForegroundColor Red
        $errors | ForEach-Object {
            Write-Host "  Line $($_.Token.StartLine): $($_.Message)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "? No syntax errors found" -ForegroundColor Green
    }
}
catch {
    Write-Host "? Error checking syntax: $_" -ForegroundColor Red
}
