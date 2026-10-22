[CmdletBinding()]

param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

$TerraformAutoApprove = @()

if ($NonInteractive) {
    $TerraformAutoApprove = @("-auto-approve")
}

function Get-RequiredSecret {
    param(
        [Parameter(Mandatory)]
        [string]$Label,

        [Parameter(Mandatory)]
        [string]$EnvironmentVariable
    )

    $value = [Environment]::GetEnvironmentVariable($EnvironmentVariable)

    if (-not [string]::IsNullOrWhiteSpace($value)) {
        return $value
    }

    if ($NonInteractive) {
        throw "$Label was not provided. Set $EnvironmentVariable before running in non-interactive mode."
    }

    $secure = Read-Host $Label -AsSecureString

    return [System.Net.NetworkCredential]::new("", $secure).Password
}

function Write-Step {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Host ""
    Write-Host "==> $Message"
}

function Assert-Command {
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found in PATH."
    }
}

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")

$OciTerraformDir = Join-Path $RepoRoot "terraform\multicloud\oci-dr"
$AzureTerraformDir = Join-Path $RepoRoot "terraform\multicloud\azure-data"

$PostgresPassword = $null
$OciNatPublicIp = $null
$AzureAccount = $null

try {

    Write-Step "Validating required tools"

    Assert-Command "terraform"
    Assert-Command "az"

    Write-Host "Terraform and Azure CLI found."

    Write-Step "Stopping local SSH tunnel"

    $TunnelConnections = Get-NetTCPConnection `
        -LocalPort 2222 `
        -State Listen `
        -ErrorAction SilentlyContinue

    if ($TunnelConnections) {

        $TunnelProcessIds = $TunnelConnections |
            Select-Object -ExpandProperty OwningProcess -Unique

        foreach ($TunnelProcessId in $TunnelProcessIds) {

            $TunnelProcess = Get-Process `
                -Id $TunnelProcessId `
                -ErrorAction SilentlyContinue

            if ($TunnelProcess -and $TunnelProcess.ProcessName -eq "ssh") {

                Write-Host "Stopping SSH tunnel process PID $TunnelProcessId..."

                Stop-Process `
                    -Id $TunnelProcessId `
                    -Force
            }
            elseif ($TunnelProcess) {

                Write-Host "Port 2222 is being used by process '$($TunnelProcess.ProcessName)' PID $TunnelProcessId."
                Write-Host "The process will not be stopped automatically."
            }
        }
    }
    else {
        Write-Host "No SSH tunnel found on port 2222."
    }

    Write-Step "Validating Azure authentication"

    $AzureAccount = az account show --output json 2>$null | ConvertFrom-Json

    if (-not $AzureAccount) {
        throw "Azure CLI is not authenticated. Run 'az login' before stopping the lab."
    }

    $env:ARM_SUBSCRIPTION_ID = $AzureAccount.id

    Write-Host "Azure subscription:"
    Write-Host "  Name: $($AzureAccount.name)"
    Write-Host "  ID:   $($AzureAccount.id)"

    Write-Step "Retrieving OCI NAT Gateway public IP"

    $OciNatPublicIp = $env:TF_VAR_oci_nat_public_ip

    if ([string]::IsNullOrWhiteSpace($OciNatPublicIp)) {
        $OciNatPublicIp = terraform `
            "-chdir=$OciTerraformDir" `
            output `
            -raw `
            nat_gateway_public_ip 2>$null
    }

    if ([string]::IsNullOrWhiteSpace($OciNatPublicIp)) {
        throw "OCI NAT Gateway public IP could not be determined. Set TF_VAR_oci_nat_public_ip or keep the OCI state available."
    }

    $OciNatPublicIp = $OciNatPublicIp.Trim()

    $env:TF_VAR_oci_nat_public_ip = $OciNatPublicIp

    Write-Host "OCI NAT public IP:"
    Write-Host "  $OciNatPublicIp"

    Write-Step "Loading Azure PostgreSQL admin password"

    $PostgresPassword = Get-RequiredSecret `
        -Label "PostgreSQL admin password" `
        -EnvironmentVariable "TF_VAR_postgresql_admin_password"

    if ([string]::IsNullOrWhiteSpace($PostgresPassword)) {
        throw "PostgreSQL admin password cannot be empty."
    }

    $env:TF_VAR_postgresql_admin_password = $PostgresPassword

    Write-Step "Destroying Azure data layer"

    terraform `
        "-chdir=$AzureTerraformDir" `
        destroy `
        @TerraformAutoApprove

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform destroy failed for Azure."
    }

    Write-Step "Destroying OCI infrastructure"

    terraform `
        "-chdir=$OciTerraformDir" `
        destroy `
        @TerraformAutoApprove

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform destroy failed for OCI."
    }

    Write-Step "BobHub v0.3 shutdown completed"

    Write-Host ""
    Write-Host "Azure data layer destroyed."
    Write-Host "OCI infrastructure destroyed."
    Write-Host "Local SSH tunnel stopped."
}
finally {

    Write-Step "Cleaning temporary environment variables"

    Remove-Item `
        Env:TF_VAR_postgresql_admin_password `
        -ErrorAction SilentlyContinue

    Remove-Item `
        Env:TF_VAR_oci_nat_public_ip `
        -ErrorAction SilentlyContinue

    Remove-Item `
        Env:ARM_SUBSCRIPTION_ID `
        -ErrorAction SilentlyContinue

    $PostgresPassword = $null
    $SecurePostgresPassword = $null
}