Write-Host "👉 Bootstrap started"

# --- Check tools ---
Write-Host ""
Write-Host "👉 Checking cli tools"

# Scoop 
if (!(Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "    Installing Scoop..."
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
    iwr -useb get.scoop.sh | iex
} else {
    Write-Host "    ✔️ Scoop already installed"
}

# Age
if (!(Get-Command age -ErrorAction SilentlyContinue)) {
    Write-Host "    Installing Age..."
    scoop install age
} else {
    Write-Host "    ✔️ Age already installed"
}

# Bitwarden-Cli
if (!(Get-Command bw -ErrorAction SilentlyContinue)) {
    Write-Host "    Installing Bitwarden-Cli..."
    scoop install bitwarden-cli
} else {
    Write-Host "    ✔️ Bitwarden-Cli already installed"
}

# --- Bitwarden login ---
Write-Host ""
Write-Host "👉 Check Bitwarden status"

try {
    $bw_status = (bw status | ConvertFrom-Json).status
} catch {
    $bw_status = "unauthenticated"
}

if ($bw_status -eq "unauthenticated") {
    Write-Host ""
    Write-Host "👉 Logging into Bitwarden"
    bw login

    $bw_status = (bw status | ConvertFrom-Json).status
}

# --- Bitwarden Unlock ---
if ($bw_status -ne "unlocked") {
    Write-Host ""
    Write-Host "👉 Unlocking Bitwarden"
    $env:BW_SESSION = bw unlock --

    $bw_status = (bw status | ConvertFrom-Json).status
}

# --- Retrieve age private key ---
Write-Host ""
Write-Host "👉 Retrieving age key"

$keyPath = "$HOME\.config\chezmoi\age\key.txt"

# Ensure directory exists
New-Item -ItemType Directory -Force -Path (Split-Path $keyPath) | Out-Null

# Remove file if it exists (force reset)
if (Test-Path $keyPath) {
    try {
        Remove-Item $keyPath -Force -ErrorAction Stop
    } catch {
        icacls $keyPath /reset | Out-Null
        Remove-Item $keyPath -Force
    }
}

# Write fresh key
$key = bw get notes chezmoi-age-key 2>$null

if (-not $key) {
    Write-Host "    ❌ Failed to retrieve age key from Bitwarden" -ForegroundColor Red
    exit 1
}

$key | Set-Content -Encoding ascii $keyPath

# Secure permissions (best effort on Windows)
try {
    icacls $keyPath /inheritance:r /grant:r "$($env:USERNAME):(R)" | Out-Null
} catch {}

Write-Host "    ✔️ Age key recreated"

# --- Setup chezmoi config ---
Write-Host ""
Write-Host "👉 Setting up chezmoi config"

$chezmoiConfig = "$HOME\.config\chezmoi\chezmoi.toml"
$normalizedKeyPath = $keyPath -replace '\\', '/'
try {
    $pubkey = age-keygen -y $keyPath
} catch {
    Write-Host "    ❌ Invalid age key" -ForegroundColor Red
    exit 1
}

New-Item -ItemType Directory -Force -Path (Split-Path $chezmoiConfig) | Out-Null

Set-Content -Encoding ascii -Force $chezmoiConfig @"
encryption = "age"
[age]
    identity = "$normalizedKeyPath"
    recipients = ["$pubkey"]
"@

Write-Host "    ✔️ chezmoi config recreated"

# --- Apply chezmoi config ---
Write-Host ""
Write-Host "👉 Applying chezmoi config"

chezmoi apply

Write-Host "✅ Bootstrap complete"
