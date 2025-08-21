param(
  [string]$RepoPath  = "C:\Repos\sondas-repo",  # repositorio clonado
  [string]$SourceDir = "C:\SONDAS\data",        # carpeta de origen
  [string]$DestRel   = "data",                  # carpeta dentro del repo
  [string]$Branch    = "main"                   # rama destino
)

$ErrorActionPreference = "Stop"
$ts  = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$log = Join-Path $RepoPath "auto-push.log"
function Log($m){ "[$ts] $m" | Out-File -FilePath $log -Append }

try {
  Set-Location $RepoPath

  # 1) Asegura carpeta destino en el repo
  $destPath = Join-Path $RepoPath $DestRel
  if (!(Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath -Force | Out-Null }

  # 2) Copia SOLO CSV, solo si son más nuevos (tus 3 archivos están ahí)
  robocopy $SourceDir $destPath *.csv /XO /R:1 /W:1 | Out-Null
  # (Si quieres espejar exacto y borrar lo viejo del repo: usa /MIR en lugar de /XO)

  # 3) Commit / push solo si hay cambios
  git add -A
  $changes = git status --porcelain
  if (-not [string]::IsNullOrWhiteSpace($changes)) {
    git commit -m "Auto backup CSV $ts"
    git push origin $Branch
    Log "Cambios detectados y enviados."
  } else {
    Log "Sin cambios."
  }
}
catch {
  Log "ERROR: $($_.Exception.Message)"
  exit 1
}
