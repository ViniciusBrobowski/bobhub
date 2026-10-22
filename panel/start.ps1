[CmdletBinding()]
param(
    [int]$Port = 8090,

    [switch]$NoBrowser,

    [switch]$Rebuild
)

$ErrorActionPreference = "Stop"

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}
catch {
    # The panel still works when the host does not expose a console.
}

$PanelDir = $PSScriptRoot
$BinDir = Join-Path $PanelDir "bin"
$Exe = Join-Path $BinDir "bobhub-panel.exe"

if (-not (Get-Command go -ErrorAction SilentlyContinue)) {
    throw "Go não encontrado no PATH. Instale o Go 1.22+ e abra um novo terminal."
}

Push-Location $PanelDir

try {
    $NeedBuild = $Rebuild -or -not (Test-Path $Exe)

    if (-not $NeedBuild) {
        $NewestSource = Get-ChildItem `
            -Path $PanelDir `
            -Recurse `
            -File `
            -Include *.go, *.html, *.css, *.js, *.svg, go.mod |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1

        if ($NewestSource -and $NewestSource.LastWriteTime -gt (Get-Item $Exe).LastWriteTime) {
            $NeedBuild = $true
        }
    }

    if ($NeedBuild) {
        New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

        Write-Host "Compilando o BobHub Control Panel..."

        go build -trimpath -ldflags "-s -w" -o $Exe .

        if ($LASTEXITCODE -ne 0) {
            throw "Falha ao compilar o painel."
        }
    }

    $Arguments = @("--port", "$Port")

    if ($NoBrowser) {
        $Arguments += "--no-browser"
    }

    & $Exe @Arguments
}
finally {
    Pop-Location
}
