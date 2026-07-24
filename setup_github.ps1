# ============================================================
#  SETUP GITHUB PAGES — ONE-CLICK DEPLOYER
#  Run this once to create your live trading dashboard.
#
#  What it does:
#    1. Asks for your GitHub username, token, and repo name
#    2. Creates the GitHub repo via API
#    3. Pushes all website files
#    4. Enables GitHub Pages (gh-pages branch)
#    5. Writes github_config.json for publisher.py
#    6. Prints your live URL
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  ====================================================" -ForegroundColor Cyan
Write-Host "   AI Trading Bot — GitHub Pages Setup" -ForegroundColor Cyan
Write-Host "  ====================================================" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Collect info ──
Write-Host "  You need a GitHub account and a Personal Access Token." -ForegroundColor Yellow
Write-Host "  If you don't have a token:" -ForegroundColor Yellow
Write-Host "    1. Go to: https://github.com/settings/tokens/new" -ForegroundColor White
Write-Host "    2. Note name: 'TradingBot', Expiration: No expiration" -ForegroundColor White
Write-Host "    3. Scopes: tick [repo] and [workflow]" -ForegroundColor White
Write-Host "    4. Click 'Generate token' and copy it" -ForegroundColor White
Write-Host ""

$GITHUB_USER  = Read-Host "  Enter your GitHub username"
$GITHUB_TOKEN = Read-Host "  Enter your GitHub Personal Access Token"
$REPO_NAME    = Read-Host "  Enter repo name (press Enter for 'ai-trading-live')"
if (-not $REPO_NAME) { $REPO_NAME = "ai-trading-live" }

$WEBSITE_DIR = $PSScriptRoot
$BOT_DIR     = "C:\TradingBot"

Write-Host ""
Write-Host "  Creating repo: $GITHUB_USER/$REPO_NAME" -ForegroundColor Cyan

# ── Step 2: Create GitHub repo ──
$headers = @{
    "Authorization" = "Bearer $GITHUB_TOKEN"
    "Accept"        = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

$body = @{
    name        = $REPO_NAME
    description = "AI Trading Bot — Live Performance Dashboard"
    private     = $false
    auto_init   = $false
} | ConvertTo-Json

try {
    $resp = Invoke-RestMethod -Uri "https://api.github.com/user/repos" `
        -Method POST -Headers $headers `
        -Body $body -ContentType "application/json"
    Write-Host "  Repo created: $($resp.html_url)" -ForegroundColor Green
} catch {
    $errBody = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($errBody.errors -and $errBody.errors[0].message -like "*already exists*") {
        Write-Host "  Repo already exists — continuing." -ForegroundColor Yellow
    } else {
        Write-Host "  ERROR creating repo: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Check your token has 'repo' scope." -ForegroundColor Red
        exit 1
    }
}

# ── Step 3: Init git in website folder and push ──
Write-Host ""
Write-Host "  Pushing website files to GitHub..." -ForegroundColor Cyan

Set-Location $WEBSITE_DIR

# Configure git remote
$REMOTE_URL = "https://$GITHUB_TOKEN@github.com/$GITHUB_USER/$REPO_NAME.git"

if (-not (Test-Path ".git")) {
    git init
    git checkout -b main
}

git config user.email "singhthaparkunwarpreet@gmail.com"
git config user.name  "Kunwarpreet Singh Thapar"

# Remove old remote if exists
git remote remove origin 2>$null

git remote add origin $REMOTE_URL
git add -A
git commit -m "Deploy trading dashboard" 2>$null; if (-not $?) {
    git commit --allow-empty -m "Deploy trading dashboard"
}
git branch -M main
git push -u origin main --force

Write-Host "  Website files pushed." -ForegroundColor Green

# ── Step 4: Enable GitHub Pages ──
Write-Host ""
Write-Host "  Enabling GitHub Pages..." -ForegroundColor Cyan

$pagesBody = @{
    source = @{
        branch = "main"
        path   = "/"
    }
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "https://api.github.com/repos/$GITHUB_USER/$REPO_NAME/pages" `
        -Method POST -Headers $headers `
        -Body $pagesBody -ContentType "application/json" | Out-Null
    Write-Host "  GitHub Pages enabled." -ForegroundColor Green
} catch {
    $errBody = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue
    if ($errBody.message -like "*already enabled*" -or $errBody.message -like "*already exists*") {
        Write-Host "  GitHub Pages already enabled." -ForegroundColor Yellow
    } else {
        Write-Host "  NOTE: Pages may need manual enable at:" -ForegroundColor Yellow
        Write-Host "  https://github.com/$GITHUB_USER/$REPO_NAME/settings/pages" -ForegroundColor White
    }
}

# ── Step 5: Write github_config.json for publisher.py ──
Write-Host ""
Write-Host "  Writing publisher config to C:\TradingBot\github_config.json..." -ForegroundColor Cyan

$pubConfig = @{
    token            = $GITHUB_TOKEN
    owner            = $GITHUB_USER
    repo             = $REPO_NAME
    local_stats_path = "C:/TradingBot/data/live_stats.json"
    repo_stats_path  = "data/live_stats.json"
    interval         = 120
} | ConvertTo-Json -Depth 3

$pubConfig | Out-File -FilePath "$BOT_DIR\github_config.json" -Encoding UTF8
Write-Host "  Config written." -ForegroundColor Green

# ── Done ──
$LIVE_URL = "https://$GITHUB_USER.github.io/$REPO_NAME/"
Write-Host ""
Write-Host "  ====================================================" -ForegroundColor Green
Write-Host "   SETUP COMPLETE!" -ForegroundColor Green
Write-Host "  ====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Your live dashboard: $LIVE_URL" -ForegroundColor Cyan
Write-Host "  (GitHub Pages takes 1-3 minutes to go live)" -ForegroundColor Yellow
Write-Host ""
Write-Host "  TO KEEP THE SITE UPDATED:" -ForegroundColor White
Write-Host "  Open a new terminal and run:" -ForegroundColor White
Write-Host "    cd C:\TradingBot" -ForegroundColor Green
Write-Host "    python publisher.py" -ForegroundColor Green
Write-Host ""
Write-Host "  The publisher pushes fresh data every 2 minutes." -ForegroundColor Yellow
Write-Host "  The website auto-refreshes every 60 seconds." -ForegroundColor Yellow
Write-Host ""
