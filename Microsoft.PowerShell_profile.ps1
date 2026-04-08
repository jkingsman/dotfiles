# ============================================================
# PowerShell Profile
# Familiar environment ported from bash dotfiles
#
# Install: copy or symlink to $PROFILE path, e.g.
#   Copy-Item .\Microsoft.PowerShell_profile.ps1 $PROFILE
# ============================================================

$ESC = [char]27

# ------------------------------------------------------------------
# Editor
# ------------------------------------------------------------------
$env:EDITOR = if (Get-Command code -ErrorAction SilentlyContinue) { 'code' } else { 'notepad' }
$env:VISUAL = $env:EDITOR

# ------------------------------------------------------------------
# PSReadLine — match bash readline feel
# ------------------------------------------------------------------
if (Get-Module PSReadLine -ListAvailable -ErrorAction SilentlyContinue) {
    Set-PSReadLineOption -BellStyle Visual
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# ------------------------------------------------------------------
# Directory Navigation
# ------------------------------------------------------------------
function .. { Set-Location .. }
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }
function dotfiles { Set-Location ~/dotfiles }

function godev {
    foreach ($p in @('D:\Projects\Development', "$HOME\Projects")) {
        if (Test-Path $p) { Set-Location $p; return }
    }
}

function dl {
    foreach ($p in @('D:\Downloads', "$HOME\Downloads")) {
        if (Test-Path $p) { Set-Location $p; return }
    }
}

function dt {
    foreach ($p in @('D:\Desktop', "$HOME\Desktop")) {
        if (Test-Path $p) { Set-Location $p; return }
    }
}

function db {
    foreach ($p in @('D:\Dropbox', "$HOME\Dropbox", "$HOME\Library\CloudStorage\Dropbox")) {
        if (Test-Path $p) { Set-Location $p; return }
    }
}

function e. { explorer . }

function mkcd {
    param([Parameter(Mandatory)][string]$Path)
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
    Set-Location $Path
}

# ------------------------------------------------------------------
# ls
# ------------------------------------------------------------------
function lsl { Get-ChildItem -Force @args | Sort-Object LastWriteTime -Descending | Format-Table Mode, LastWriteTime, @{N='Size';E={$_.Length};A='Right'}, Name -AutoSize }

# ------------------------------------------------------------------
# Git shell aliases
# ------------------------------------------------------------------
function gs { git status @args }
function gl { git log --oneline --all --graph --decorate @args }
function ga { git add --all . }
function gp { git push @args }
function gd { git diff @args }
function gsa { git stash @args }
function gsp { git stash pop }
function gsd { git stash drop }

function gco {
    git fetch
    git stash
    git checkout @args
    git unfuck
    git pull
}

function gcp {
    $msg = $args -join ' '
    git commit -am $msg
    git push
}

function gcpa {
    git add .
    git commit --amend --no-edit
    git push --force
}

function master {
    git stash
    git unfuck 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host 'unfuck failed; continuing' }
    git checkout master
    git pull
}

function main {
    git stash
    git unfuck 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host 'unfuck failed; continuing' }
    git checkout main
    git pull
}

function buildkick {
    git commit --allow-empty -m 'Kick the build'
    git push
}

function gchp { git cherry-pick @args }
function gchpc { git add .; git cherry-pick --continue }

# ------------------------------------------------------------------
# Terraform
# ------------------------------------------------------------------
function tf { terraform @args }
function tfs { terraform state @args }

# ------------------------------------------------------------------
# Quick HTTP server
# ------------------------------------------------------------------
function srv {
    param([int]$Port = 8000)
    python -m http.server $Port
}

# ------------------------------------------------------------------
# Docker
# ------------------------------------------------------------------
function drun {
    if ($args.Count -gt 1) {
        docker run -it $args[0] $args[1..($args.Count - 1)]
    } else {
        docker run -it $args[0] cmd
    }
}

function dockerkill {
    $ids = @(docker ps -q)
    if ($ids) { docker kill @ids }
}

function dockerstop { dockerkill }

function dockerclean {
    $ids = @(docker ps -q 2>$null)
    if ($ids) { docker kill @ids }
    docker system prune -f
    docker image prune -af
    docker buildx prune -f
    docker volume prune -f
    docker network prune -f
}

function dockerdel { docker rmi -f @args }

# ------------------------------------------------------------------
# YouTube downloading
# ------------------------------------------------------------------
function yta { yt-dlp -x --audio-format mp3 --audio-quality 0 @args }
function ytd { yt-dlp -f 'bestvideo+bestaudio' -ciw --add-metadata --embed-subs --all-subs -v @args }

# ------------------------------------------------------------------
# Python venvs
# ------------------------------------------------------------------
function vmake { python -m venv venv }
function va {
    $activate = Join-Path (Get-Location) 'venv\Scripts\Activate.ps1'
    if (Test-Path $activate) { & $activate }
    else { Write-Host "No venv found in current directory" }
}

# ------------------------------------------------------------------
# Utilities
# ------------------------------------------------------------------

# Reload profile
function reload { . $PROFILE }

# Print PATH entries one per line
function path { $env:PATH -split ';' | Where-Object { $_ } }

# Random password
function gen_passwd {
    param([int]$Length = 32)
    $chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
    -join (1..$Length | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

# Run a command N times: ntimes 5 { curl example.com }
function ntimes {
    param(
        [Parameter(Mandatory, Position = 0)][int]$Count,
        [Parameter(Mandatory, Position = 1)][scriptblock]$Command
    )
    for ($i = 1; $i -le $Count; $i++) {
        Write-Host "Run #$i"
        & $Command
    }
}

# Extract archives (uses tar, Expand-Archive, or 7z as available)
function extract {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) {
        Write-Host "'$Path' is not a valid file"; return
    }
    switch -Regex ($Path) {
        '\.zip$'               { Expand-Archive -Path $Path -DestinationPath . }
        '\.tar\.gz$|\.tgz$'   { tar -xzf $Path }
        '\.tar\.bz2$|\.tbz2$' { tar -xjf $Path }
        '\.tar\.xz$'          { tar -xJf $Path }
        '\.tar$'               { tar -xf $Path }
        '\.7z$'                { 7z x $Path }
        '\.rar$'               { 7z x $Path }
        '\.gz$'                { 7z x $Path }
        '\.bz2$'               { 7z x $Path }
        default                { Write-Host "'$Path' cannot be extracted via extract" }
    }
}

# YAML dump (resolve anchors)
function yamldump {
    param([Parameter(Mandatory)][string]$Path)
    python -c "import yaml, json; print(yaml.safe_dump(json.loads(json.dumps(yaml.safe_load(open('$Path'))))))"
}

# ------------------------------------------------------------------
# Time zone conversion: PT <-> UTC
# Accepts: YYYY-MM-DD HH:MM, MM/DD HH:MM, HH:MM, HHMM
# ------------------------------------------------------------------
function pt2utc {
    param([Parameter(ValueFromRemainingArguments)][string[]]$InputTime)
    $timeStr = ($InputTime -join ' ').Trim()
    $tz = [TimeZoneInfo]::FindSystemTimeZoneById('Pacific Standard Time')
    $now = [TimeZoneInfo]::ConvertTimeFromUtc([DateTime]::UtcNow, $tz)
    $parsed = $null
    $timeOnly = $false

    if ($timeStr -match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$') {
        $parsed = [DateTime]::ParseExact($timeStr, 'yyyy-MM-dd HH:mm', $null)
    } elseif ($timeStr -match '^\d{2}/\d{2} \d{2}:\d{2}$') {
        $parsed = [DateTime]::ParseExact("$($now.Year)/$timeStr", 'yyyy/MM/dd HH:mm', $null)
    } elseif ($timeStr -match '^\d{2}:\d{2}$') {
        $parsed = [DateTime]::ParseExact("$($now.ToString('yyyy-MM-dd')) $timeStr", 'yyyy-MM-dd HH:mm', $null)
        $timeOnly = $true
    } elseif ($timeStr -match '^\d{4}$') {
        $parsed = [DateTime]::ParseExact("$($now.ToString('yyyy-MM-dd')) $($timeStr.Substring(0,2)):$($timeStr.Substring(2,2))", 'yyyy-MM-dd HH:mm', $null)
        $timeOnly = $true
    } else {
        Write-Host 'Error: Use YYYY-MM-DD HH:MM, MM/DD HH:MM, HH:MM, or HHMM'; return
    }

    $utc = [TimeZoneInfo]::ConvertTimeToUtc($parsed, $tz)
    if ($timeOnly) {
        $dayDiff = ($utc.Date - $parsed.Date).Days
        $suffix = switch ($dayDiff) { 0 { '(same day)' } { $_ -gt 0 } { '(next day)' } default { '(previous day)' } }
        Write-Host "$($utc.ToString('HH:mm')) $suffix"
    } else {
        Write-Host "$($utc.ToString('yyyy-MM-dd HH:mm')) UTC"
    }
}

function utc2pt {
    param([Parameter(ValueFromRemainingArguments)][string[]]$InputTime)
    $timeStr = ($InputTime -join ' ').Trim()
    $tz = [TimeZoneInfo]::FindSystemTimeZoneById('Pacific Standard Time')
    $nowUtc = [DateTime]::UtcNow
    $parsed = $null
    $timeOnly = $false

    if ($timeStr -match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$') {
        $parsed = [DateTime]::ParseExact($timeStr, 'yyyy-MM-dd HH:mm', $null)
    } elseif ($timeStr -match '^\d{2}/\d{2} \d{2}:\d{2}$') {
        $parsed = [DateTime]::ParseExact("$($nowUtc.Year)/$timeStr", 'yyyy/MM/dd HH:mm', $null)
    } elseif ($timeStr -match '^\d{2}:\d{2}$') {
        $parsed = [DateTime]::ParseExact("$($nowUtc.ToString('yyyy-MM-dd')) $timeStr", 'yyyy-MM-dd HH:mm', $null)
        $timeOnly = $true
    } elseif ($timeStr -match '^\d{4}$') {
        $parsed = [DateTime]::ParseExact("$($nowUtc.ToString('yyyy-MM-dd')) $($timeStr.Substring(0,2)):$($timeStr.Substring(2,2))", 'yyyy-MM-dd HH:mm', $null)
        $timeOnly = $true
    } else {
        Write-Host 'Error: Use YYYY-MM-DD HH:MM, MM/DD HH:MM, HH:MM, or HHMM'; return
    }

    $parsed = [DateTime]::SpecifyKind($parsed, [DateTimeKind]::Utc)
    $pt = [TimeZoneInfo]::ConvertTimeFromUtc($parsed, $tz)
    if ($timeOnly) {
        $dayDiff = ($pt.Date - $parsed.Date).Days
        $suffix = switch ($dayDiff) { 0 { '(same day)' } { $_ -gt 0 } { '(next day)' } default { '(previous day)' } }
        Write-Host "$($pt.ToString('HH:mm')) $suffix"
    } else {
        Write-Host "$($pt.ToString('yyyy-MM-dd HH:mm')) PT"
    }
}

# ------------------------------------------------------------------
# Prompt: [time] user@host in path on branch [*]
# With command timing and exit code display
# ------------------------------------------------------------------

function prompt {
    # Snapshot exit code before any commands overwrite it
    $exitCode = $LASTEXITCODE

    # -- Command timing & exit code from previous command --
    $lastCmd = Get-History -Count 1 -ErrorAction SilentlyContinue
    $width = 80
    try { $width = $Host.UI.RawUI.WindowSize.Width } catch {}

    $showExtra = $false

    if ($lastCmd -and $lastCmd.Duration.TotalSeconds -gt 1 -and $lastCmd.Duration.TotalSeconds -lt 86400) {
        $dur = $lastCmd.Duration
        $tStr = if ($dur.TotalMinutes -ge 1) { "t=$([math]::Floor($dur.TotalMinutes))m$($dur.Seconds)s" } else { "t=$([math]::Floor($dur.TotalSeconds))s" }
        Write-Host ("$ESC[3;90m" + $tStr.PadLeft($width) + "$ESC[0m")
        $showExtra = $true
    }

    if ($exitCode -and $exitCode -ne 0) {
        Write-Host ("$ESC[3;31m" + "exit $exitCode".PadLeft($width) + "$ESC[0m")
        $showExtra = $true
    }

    # -- Time block --
    $localTime = Get-Date -Format 'HH:mm:ss'
    $utcTime = (Get-Date).ToUniversalTime().ToString('HH:mm')
    $timeBlock = if ($localTime.Substring(0,5) -eq $utcTime) {
        "$ESC[90m[${localTime}Z]$ESC[0m"
    } else {
        "$ESC[90m[${localTime}L][${utcTime}Z]$ESC[0m"
    }

    # -- User @ Host --
    $user = $env:USERNAME
    $hostname = $env:COMPUTERNAME

    # -- Path --
    $shortPath = (Get-Location).Path

    # -- Git --
    $gitInfo = ''
    $branch = git symbolic-ref --quiet --short HEAD 2>$null
    if (-not $branch) { $branch = git rev-parse --short HEAD 2>$null }
    if ($branch) {
        $dirty = git status --porcelain 2>$null
        $mark = if ($dirty) { "$ESC[34m *" } else { '' }
        $gitInfo = " $ESC[0mon $ESC[1;35m$branch$mark$ESC[0m"
    }

    # -- Assemble --
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    $userColor = if ($isAdmin) { '31' } else { '33' } # red if admin, orange/yellow otherwise

    Write-Host ""
    Write-Host "$timeBlock $ESC[1;${userColor}m$user$ESC[0m at $ESC[1;33m$hostname$ESC[0m in $ESC[1;32m$shortPath$ESC[0m$gitInfo"

    # Reset LASTEXITCODE so stale codes don't persist across prompts
    $global:LASTEXITCODE = 0

    return "$([char]0x0394) "
}
