# deploy.ps1 - Deploy statico su VPS con Nginx
# Richiede: plink.exe e pscp.exe (PuTTY) oppure OpenSSH (Windows 10+)

$VPS_HOST = "144.91.90.41"
$VPS_USER = "root"
$VPS_PASS = "VibeCoding2026"
$NGINX_SITES = "/etc/nginx/sites-available"
$NGINX_ENABLED = "/etc/nginx/sites-enabled"
$WWW_ROOT = "/var/www"

# ─── Colori helper ───────────────────────────────────────────────────────────
function Write-Step  { param($msg) Write-Host "`n[>] $msg" -ForegroundColor Cyan }
function Write-OK    { param($msg) Write-Host "    [OK] $msg" -ForegroundColor Green }
function Write-Fail  { param($msg) Write-Host "    [!!] $msg" -ForegroundColor Red; exit 1 }
function Write-Info  { param($msg) Write-Host "    [i]  $msg" -ForegroundColor Yellow }

# ─── Banner ──────────────────────────────────────────────────────────────────
Clear-Host
Write-Host @"
╔══════════════════════════════════════════╗
║        VPS Deploy Script v1.0            ║
║  Host : $VPS_HOST              ║
╚══════════════════════════════════════════╝
"@ -ForegroundColor Magenta

# ─── 1. Nome progetto ─────────────────────────────────────────────────────────
Write-Step "Configurazione progetto"
do {
    $PROJECT = Read-Host "  Nome del progetto (es. mio-sito)"
    $PROJECT = $PROJECT.Trim().ToLower() -replace '\s+', '-'
} while ($PROJECT -eq "")

$REMOTE_DIR = "$WWW_ROOT/$PROJECT"
Write-OK "Progetto : $PROJECT"
Write-OK "Percorso : $REMOTE_DIR"

# ─── 2. Verifica tool SSH disponibili ────────────────────────────────────────
Write-Step "Verifica strumenti SSH"

$USE_OPENSSH = $false
$USE_PUTTY   = $false

if (Get-Command ssh -ErrorAction SilentlyContinue) {
    $USE_OPENSSH = $true
    Write-OK "OpenSSH trovato"
} elseif ((Test-Path "$env:ProgramFiles\PuTTY\plink.exe") -or (Get-Command plink -ErrorAction SilentlyContinue)) {
    $USE_PUTTY = $true
    Write-OK "PuTTY (plink/pscp) trovato"
} else {
    Write-Fail "Nessun client SSH trovato. Installa OpenSSH (Windows 10+) oppure PuTTY."
}

# ─── Helper: esegui comando remoto ───────────────────────────────────────────
function Invoke-SSH {
    param([string]$Command)
    if ($USE_OPENSSH) {
        $env:SSHPASS = $VPS_PASS
        # Su Windows usiamo plink se disponibile, altrimenti ssh con StrictHostKeyChecking disabilitato
        $result = & ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 `
            "${VPS_USER}@${VPS_HOST}" $Command 2>&1
    } else {
        $result = & plink -ssh -pw $VPS_PASS -batch "${VPS_USER}@${VPS_HOST}" $Command 2>&1
    }
    return $result
}

# ─── Helper: copia file sul VPS ──────────────────────────────────────────────
function Copy-ToVPS {
    param([string]$LocalPath, [string]$RemotePath)
    if ($USE_OPENSSH) {
        & scp -o StrictHostKeyChecking=no -r $LocalPath "${VPS_USER}@${VPS_HOST}:${RemotePath}" 2>&1
    } else {
        & pscp -pw $VPS_PASS -r $LocalPath "${VPS_USER}@${VPS_HOST}:${RemotePath}" 2>&1
    }
}

# ─── 3. Raccolta file da caricare ────────────────────────────────────────────
Write-Step "Scansione file locali"

$extensions = @("*.html", "*.css", "*.js", "*.png", "*.jpg", "*.jpeg", "*.svg", "*.ico", "*.webp", "*.woff", "*.woff2")
$files = @()
foreach ($ext in $extensions) {
    $files += Get-ChildItem -Path . -Filter $ext -Recurse -File |
              Where-Object { $_.FullName -notmatch '\\node_modules\\' -and $_.Name -ne 'deploy.ps1' }
}

if ($files.Count -eq 0) {
    Write-Fail "Nessun file trovato nella cartella corrente."
}

Write-OK "$($files.Count) file trovati:"
$files | ForEach-Object { Write-Info $_.Name }

# ─── 4. Connessione e preparazione directory ─────────────────────────────────
Write-Step "Connessione al VPS"

$ping = Invoke-SSH "echo CONNECTED"
if ($ping -notmatch "CONNECTED") {
    Write-Fail "Impossibile connettersi al VPS. Verifica host/credenziali."
}
Write-OK "Connesso a $VPS_HOST"

Write-Step "Preparazione directory remota"
Invoke-SSH "mkdir -p $REMOTE_DIR" | Out-Null
Write-OK "Directory $REMOTE_DIR pronta"

# ─── 5. Upload file ──────────────────────────────────────────────────────────
Write-Step "Upload file sul VPS"

$localDir = (Get-Location).Path

foreach ($file in $files) {
    # Mantieni struttura sottocartelle
    $relativePath = $file.FullName.Substring($localDir.Length).TrimStart('\', '/')
    $relativePath = $relativePath -replace '\\', '/'
    $remoteFile   = "$REMOTE_DIR/$relativePath"
    $remoteSubdir = ($remoteFile -split '/' | Select-Object -SkipLast 1) -join '/'

    Invoke-SSH "mkdir -p $remoteSubdir" | Out-Null
    Copy-ToVPS $file.FullName $remoteFile | Out-Null
    Write-OK "Caricato: $relativePath"
}

# ─── 6. Template Nginx ───────────────────────────────────────────────────────
Write-Step "Configurazione Nginx"

$nginxConf = @"
server {
    listen 80;
    listen [::]:80;
    server_name _;

    root $REMOTE_DIR;
    index index.html index.htm;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/javascript image/svg+xml;
    gzip_min_length 256;

    # Cache per asset statici
    location ~* \.(css|js|png|jpg|jpeg|svg|ico|webp|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Sicurezza base
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";

    # Nasconde versione Nginx
    server_tokens off;
}
"@

# Scrivi config Nginx sul server
$escapedConf = $nginxConf -replace '"', '\"'
Invoke-SSH "cat > $NGINX_SITES/$PROJECT << 'NGINXEOF'`n$nginxConf`nNGINXEOF" | Out-Null
Write-OK "Config Nginx scritta in $NGINX_SITES/$PROJECT"

# Abilita il sito (symlink)
Invoke-SSH "ln -sf $NGINX_SITES/$PROJECT $NGINX_ENABLED/$PROJECT" | Out-Null
Write-OK "Sito abilitato in sites-enabled"

# ─── 7. Permessi ─────────────────────────────────────────────────────────────
Write-Step "Impostazione permessi"

Invoke-SSH "chown -R www-data:www-data $REMOTE_DIR" | Out-Null
Write-OK "Owner: www-data"

Invoke-SSH "find $REMOTE_DIR -type d -exec chmod 755 {} \;" | Out-Null
Write-OK "Directory: chmod 755"

Invoke-SSH "find $REMOTE_DIR -type f -exec chmod 644 {} \;" | Out-Null
Write-OK "File: chmod 644"

# ─── 8. Test config e riavvio Nginx ──────────────────────────────────────────
Write-Step "Test e riavvio Nginx"

$testResult = Invoke-SSH "nginx -t 2>&1"
if ($testResult -match "successful") {
    Write-OK "Config Nginx valida"
} else {
    Write-Info "Output nginx -t:"
    Write-Host $testResult -ForegroundColor Yellow
    Write-Fail "Errore nella configurazione Nginx. Riavvio annullato."
}

Invoke-SSH "systemctl restart nginx" | Out-Null
$nginxStatus = Invoke-SSH "systemctl is-active nginx"
if ($nginxStatus -match "active") {
    Write-OK "Nginx riavviato correttamente"
} else {
    Write-Fail "Nginx non si e' avviato. Controlla: journalctl -xe"
}

# ─── 9. Riepilogo ────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  Deploy completato con successo!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Progetto  : $PROJECT" -ForegroundColor White
Write-Host "  Directory : $REMOTE_DIR" -ForegroundColor White
Write-Host "  URL       : http://$VPS_HOST" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Per abilitare HTTPS:" -ForegroundColor Yellow
Write-Host "  certbot --nginx -d tuodominio.com" -ForegroundColor Gray
Write-Host ""
