[CmdletBinding()]
param(
    [switch]$NonInteractive
)

$ErrorActionPreference = "Stop"

$TerraformAutoApprove = @()

if ($NonInteractive) {
    $TerraformAutoApprove = @("-auto-approve")
}

function Get-RequiredValue {
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

    return Read-Host $Label
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

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$OciTerraformDir = Join-Path $RepoRoot "terraform\multicloud\oci-dr"
$AzureTerraformDir = Join-Path $RepoRoot "terraform\multicloud\azure-data"
$AnsibleDir = Join-Path $RepoRoot "ansible"
$InventoryFile = Join-Path $AnsibleDir "inventory\oci.ini"

$PostgresPassword = $null
$AppDbPassword = $null
$PostgresAdminUser = $null
$OciNatPublicIp = $null
$AzureAccount = $null
$TunnelProcess = $null
$BastionSessionId = $null
$ApplicationPrivateIp = $null
$OriginalWslenv = $env:WSLENV

try {
    Write-Step "Validating required tools"

    Assert-Command "terraform"
    Assert-Command "az"
    Assert-Command "oci"
    Assert-Command "ssh"
    Assert-Command "wsl"

    Write-Host "Terraform, Azure CLI, OCI CLI, SSH and WSL found."

    Write-Step "Validating Azure authentication"

    $AzureAccount = az account show --output json 2>$null | ConvertFrom-Json

    if (-not $AzureAccount) {
        throw "Azure CLI is not authenticated. Run 'az login' before starting the lab."
    }

    $env:ARM_SUBSCRIPTION_ID = $AzureAccount.id

    Write-Host "Azure subscription:"
    Write-Host "  Name: $($AzureAccount.name)"
    Write-Host "  ID:   $($AzureAccount.id)"

    Write-Step "Provisioning OCI infrastructure"

    terraform "-chdir=$OciTerraformDir" init

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform init failed for OCI."
    }

    terraform "-chdir=$OciTerraformDir" validate

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform validate failed for OCI."
    }

    terraform "-chdir=$OciTerraformDir" apply @TerraformAutoApprove

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed for OCI."
    }

    Write-Step "Retrieving OCI NAT Gateway public IP"

    $OciNatPublicIp = terraform "-chdir=$OciTerraformDir" output -raw nat_gateway_public_ip

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($OciNatPublicIp)) {
        throw "Failed to retrieve OCI NAT Gateway public IP."
    }

    $OciNatPublicIp = $OciNatPublicIp.Trim()

    $env:TF_VAR_oci_nat_public_ip = $OciNatPublicIp

    Write-Host "OCI NAT public IP:"
    Write-Host "  $OciNatPublicIp"

    Write-Step "Loading Azure PostgreSQL credentials"

    $PostgresAdminUser = Get-RequiredValue `
        -Label "PostgreSQL admin username" `
        -EnvironmentVariable "BOBHUB_DB_ADMIN_USER"

    if ([string]::IsNullOrWhiteSpace($PostgresAdminUser)) {
        throw "PostgreSQL admin username cannot be empty."
    }

    $PostgresPassword = Get-RequiredSecret `
        -Label "PostgreSQL admin password" `
        -EnvironmentVariable "TF_VAR_postgresql_admin_password"

    if ([string]::IsNullOrWhiteSpace($PostgresPassword)) {
        throw "PostgreSQL admin password cannot be empty."
    }

    Write-Step "Loading BobHub application database password"

    $AppDbPassword = Get-RequiredSecret `
        -Label "BobHub application DB password" `
        -EnvironmentVariable "BOBHUB_DB_PASSWORD"

    if ([string]::IsNullOrWhiteSpace($AppDbPassword)) {
        throw "BobHub application database password cannot be empty."
    }

    $env:TF_VAR_postgresql_admin_password = $PostgresPassword

    Write-Step "Provisioning Azure data layer"

    terraform "-chdir=$AzureTerraformDir" init

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform init failed for Azure."
    }

    terraform "-chdir=$AzureTerraformDir" validate

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform validate failed for Azure."
    }

    terraform "-chdir=$AzureTerraformDir" apply @TerraformAutoApprove

    if ($LASTEXITCODE -ne 0) {
        throw "Terraform apply failed for Azure."
    }

    Write-Step "Phase 1 completed"

    Write-Host ""
    Write-Host "OCI:"
    Write-Host "  Terraform root: $OciTerraformDir"
    Write-Host "  NAT public IP:  $OciNatPublicIp"
    Write-Host ""
    Write-Host "Azure:"
    Write-Host "  Terraform root: $AzureTerraformDir"
    Write-Host "  Subscription:   $($AzureAccount.name)"

    Write-Step "Preparing OCI Bastion port forwarding session"

    $ApplicationPrivateIp = terraform "-chdir=$OciTerraformDir" output -raw application_instance_private_ip

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($ApplicationPrivateIp)) {
        throw "Failed to retrieve OCI application private IP."
    }

    $BastionId = terraform "-chdir=$OciTerraformDir" output -raw bastion_id

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($BastionId)) {
        throw "Failed to retrieve OCI Bastion ID."
    }

    $OciConfigFile = Join-Path $env:USERPROFILE ".oci\config"
    $SshPrivateKey = Join-Path $env:USERPROFILE ".ssh\bobhub-oci"
    $SshPublicKey = Join-Path $env:USERPROFILE ".ssh\bobhub-oci.pub"

    if (-not (Test-Path $OciConfigFile)) {
        throw "OCI config file not found: $OciConfigFile"
    }

    if (-not (Test-Path $SshPrivateKey)) {
        throw "SSH private key not found: $SshPrivateKey"
    }

    if (-not (Test-Path $SshPublicKey)) {
        throw "SSH public key not found: $SshPublicKey"
    }

    Write-Host "Application private IP: $ApplicationPrivateIp"
    Write-Host "Bastion ID: $BastionId"

    Write-Step "Retrieving Bastion session TTL"

    $BastionInfo = oci bastion bastion get `
        --bastion-id $BastionId `
        --config-file $OciConfigFile `
        --output json | ConvertFrom-Json

    if (-not $BastionInfo) {
        throw "Failed to retrieve OCI Bastion information."
    }

    $BastionSessionTtl = $BastionInfo.data.'max-session-ttl-in-seconds'

    if (-not $BastionSessionTtl) {
        throw "Could not determine Bastion maximum session TTL."
    }

    Write-Host "Bastion session TTL: $BastionSessionTtl seconds"

    Write-Step "Creating OCI Bastion port forwarding session"

    $PortForwardResult = oci bastion session create-port-forwarding `
        --bastion-id $BastionId `
        --ssh-public-key-file $SshPublicKey `
        --target-private-ip $ApplicationPrivateIp `
        --target-port 22 `
        --session-ttl $BastionSessionTtl `
        --display-name "bobhub-v03-port-forward" `
        --wait-for-state SUCCEEDED `
        --config-file $OciConfigFile `
        --output json | ConvertFrom-Json

    if (-not $PortForwardResult) {
        throw "Failed to create OCI Bastion port forwarding work request."
    }

    Write-Step "Retrieving active Bastion session"

    $Sessions = oci bastion session list `
        --bastion-id $BastionId `
        --config-file $OciConfigFile `
        --all `
        --output json | ConvertFrom-Json

    $Session = $Sessions.data |
        Where-Object {
            $_.'display-name' -eq "bobhub-v03-port-forward" -and
            $_.'lifecycle-state' -eq "ACTIVE" -and
            $_.'target-resource-details'.'target-resource-private-ip-address' -eq $ApplicationPrivateIp
        } |
        Sort-Object 'time-created' -Descending |
        Select-Object -First 1

    if (-not $Session) {
        throw "Active OCI Bastion port forwarding session could not be found."
    }

    $BastionSessionId = $Session.id

    Write-Host "Bastion session ID:"
    Write-Host "  $BastionSessionId"

    Write-Step "Waiting for Bastion session SSH authentication"

    Start-Sleep -Seconds 10

    Write-Step "Cleaning stale SSH tunnel"

    $ExistingTunnel = Get-NetTCPConnection `
        -LocalPort 2222 `
        -State Listen `
        -ErrorAction SilentlyContinue

    if ($ExistingTunnel) {
        $ExistingPid = $ExistingTunnel |
            Select-Object -First 1 -ExpandProperty OwningProcess

        $ExistingProcess = Get-Process `
            -Id $ExistingPid `
            -ErrorAction SilentlyContinue

        if ($ExistingProcess -and $ExistingProcess.ProcessName -eq "ssh") {
            Write-Host "Stopping stale SSH tunnel process PID $ExistingPid..."
            Stop-Process -Id $ExistingPid -Force
            Start-Sleep -Seconds 2
        }
        else {
            throw "Port 2222 is already in use by a non-SSH process."
        }
    }

    Write-Step "Starting SSH tunnel on Windows port 2222"

    $BastionHost = "host.bastion.sa-vinhedo-1.oci.oraclecloud.com"

    $SshArguments = @(
        "-N",
        "-L", "0.0.0.0:2222:$ApplicationPrivateIp`:22",
        "-i", $SshPrivateKey,
        "-o", "ExitOnForwardFailure=yes",
        "-o", "ServerAliveInterval=30",
        "-o", "ServerAliveCountMax=3",
        "-p", "22",
        "$BastionSessionId@$BastionHost"
    )

    $TunnelStdOut = Join-Path $env:TEMP "bobhub-ssh-tunnel.out.log"
    $TunnelStdErr = Join-Path $env:TEMP "bobhub-ssh-tunnel.err.log"

    $TunnelStarted = $false

    for ($Attempt = 1; $Attempt -le 3; $Attempt++) {
        Write-Host "Starting SSH tunnel attempt $Attempt of 3..."

        Remove-Item $TunnelStdOut -Force -ErrorAction SilentlyContinue
        Remove-Item $TunnelStdErr -Force -ErrorAction SilentlyContinue

        $TunnelProcess = Start-Process `
            -FilePath "ssh" `
            -ArgumentList $SshArguments `
            -PassThru `
            -WindowStyle Hidden `
            -RedirectStandardOutput $TunnelStdOut `
            -RedirectStandardError $TunnelStdErr

        Start-Sleep -Seconds 5

        if (-not $TunnelProcess.HasExited) {
            $TunnelStarted = $true
            break
        }

        $TunnelError = ""

        if (Test-Path $TunnelStdErr) {
            $TunnelError = Get-Content $TunnelStdErr -Raw
        }

        Write-Host "SSH tunnel attempt failed:"
        Write-Host $TunnelError

        if ($Attempt -lt 3) {
            Write-Host "Waiting before retry..."
            Start-Sleep -Seconds 10
        }
    }

    if (-not $TunnelStarted) {
        throw "SSH tunnel could not be established after 3 attempts."
    }

    Write-Step "Validating local SSH tunnel"

    $TunnelReady = $false

    for ($Attempt = 1; $Attempt -le 10; $Attempt++) {
        $TcpTest = Test-NetConnection 127.0.0.1 -Port 2222 -WarningAction SilentlyContinue

        if ($TcpTest.TcpTestSucceeded) {
            $TunnelReady = $true
            break
        }

        Start-Sleep -Seconds 3
    }

    if (-not $TunnelReady) {
        Stop-Process -Id $TunnelProcess.Id -Force -ErrorAction SilentlyContinue
        throw "SSH tunnel on Windows port 2222 could not be validated."
    }

    Write-Host "SSH tunnel is ready."
    Write-Host "Tunnel PID: $($TunnelProcess.Id)"

    Write-Step "Preparing Ansible access through WSL"

    if (-not (Test-Path $InventoryFile)) {
        throw "Ansible inventory not found: $InventoryFile"
    }

    Write-Step "Detecting Windows host IP from WSL"

    $WslRoute = (
        wsl sh -c "ip route | grep '^default '"
    ).Trim()

    if ([string]::IsNullOrWhiteSpace($WslRoute)) {
        throw "Could not determine default WSL route."
    }

    $WslRouteParts = $WslRoute -split '\s+'
    $ViaIndex = [Array]::IndexOf($WslRouteParts, "via")

    if ($ViaIndex -lt 0 -or ($ViaIndex + 1) -ge $WslRouteParts.Count) {
        throw "Could not extract Windows host IP from WSL route: $WslRoute"
    }

    $WslWindowsIp = $WslRouteParts[$ViaIndex + 1]

    Write-Host "Windows host IP visible from WSL:"
    Write-Host "  $WslWindowsIp"

    Write-Step "Validating SSH tunnel from WSL"

    wsl sh -c "nc -z -w 5 $WslWindowsIp 2222"

    if ($LASTEXITCODE -ne 0) {
        throw "WSL cannot reach the SSH tunnel at ${WslWindowsIp}:2222."
    }

    Write-Host "WSL can reach SSH tunnel at ${WslWindowsIp}:2222"

    Write-Step "Updating Ansible inventory"

    $InventoryContent = @"
[oci_app]
bobhub-oci ansible_host=$WslWindowsIp ansible_port=2222 ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/bobhub-oci ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'
"@

    Set-Content `
        -Path $InventoryFile `
        -Value $InventoryContent `
        -Encoding ascii

    wsl sh -c "ssh-keygen -f ~/.ssh/known_hosts -R '[$WslWindowsIp]:2222' >/dev/null 2>&1 || true"

    Write-Step "Testing Ansible connectivity"

    $WslAnsibleDir = $AnsibleDir `
        -replace '^C:', '/mnt/c' `
        -replace '\\', '/'

    $AnsiblePingResult = wsl sh -c "cd '$WslAnsibleDir' && ansible -i inventory/oci.ini oci_app -m ping 2>&1"
    $AnsibleExitCode = $LASTEXITCODE

    $AnsiblePingResult | ForEach-Object {
        Write-Host $_
    }

    $AnsibleOutput = $AnsiblePingResult -join "`n"

    if (
        $AnsibleExitCode -ne 0 -or
        $AnsibleOutput -notmatch '"ping":\s*"pong"'
    ) {
        throw "Ansible connectivity test failed."
    }

    Write-Host "Ansible connectivity validated successfully."

    Write-Step "Preparing BobHub database configuration"

    $PostgresFqdn = terraform `
        "-chdir=$AzureTerraformDir" `
        output `
        -raw `
        postgresql_fqdn

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($PostgresFqdn)) {
        throw "Could not retrieve PostgreSQL FQDN."
    }

    $PostgresDatabase = terraform `
        "-chdir=$AzureTerraformDir" `
        output `
        -raw `
        postgresql_database_name

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($PostgresDatabase)) {
        throw "Could not retrieve PostgreSQL database name."
    }

    $env:BOBHUB_DB_HOST = $PostgresFqdn
    $env:BOBHUB_DB_NAME = $PostgresDatabase
    $env:BOBHUB_DB_USER = "bobhub_app"
    $env:BOBHUB_DB_PASSWORD = $AppDbPassword
    $env:BOBHUB_DB_ADMIN_USER = $PostgresAdminUser
    $env:BOBHUB_DB_ADMIN_PASSWORD = $PostgresPassword

    $BobHubWslEnvNames = @(
        "BOBHUB_DB_HOST",
        "BOBHUB_DB_NAME",
        "BOBHUB_DB_USER",
        "BOBHUB_DB_PASSWORD",
        "BOBHUB_DB_ADMIN_USER",
        "BOBHUB_DB_ADMIN_PASSWORD"
    )

    $ExistingWslEnvNames = @()

    if (-not [string]::IsNullOrWhiteSpace($OriginalWslenv)) {
        $ExistingWslEnvNames = $OriginalWslenv -split ':'
    }

    $env:WSLENV = (
        @($ExistingWslEnvNames) + $BobHubWslEnvNames |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Select-Object -Unique
    ) -join ':'

    Write-Step "Deploying BobHub application with Ansible"

    wsl sh -c "cd '$WslAnsibleDir' && ansible-playbook -i inventory/oci.ini playbooks/oci-application.yml"

    if ($LASTEXITCODE -ne 0) {
        throw "Ansible application deployment failed."
    }

    Write-Step "BobHub v0.3 startup completed"

    Write-Host ""
    Write-Host "OCI:"
    Write-Host "  Application private IP: $ApplicationPrivateIp"
    Write-Host "  NAT public IP:          $OciNatPublicIp"
    Write-Host ""
    Write-Host "Azure:"
    Write-Host "  PostgreSQL:             $PostgresFqdn"
    Write-Host "  Database:               $PostgresDatabase"
    Write-Host ""
    Write-Host "Bastion:"
    Write-Host "  Session ID:             $BastionSessionId"
    Write-Host "  Windows tunnel PID:     $($TunnelProcess.Id)"
    Write-Host "  WSL endpoint:           ${WslWindowsIp}:2222"
}
finally {
    Write-Step "Cleaning temporary environment variables"

    Remove-Item Env:TF_VAR_postgresql_admin_password -ErrorAction SilentlyContinue
    Remove-Item Env:TF_VAR_oci_nat_public_ip -ErrorAction SilentlyContinue

    Remove-Item Env:BOBHUB_DB_HOST -ErrorAction SilentlyContinue
    Remove-Item Env:BOBHUB_DB_NAME -ErrorAction SilentlyContinue
    Remove-Item Env:BOBHUB_DB_USER -ErrorAction SilentlyContinue
    Remove-Item Env:BOBHUB_DB_PASSWORD -ErrorAction SilentlyContinue
    Remove-Item Env:BOBHUB_DB_ADMIN_USER -ErrorAction SilentlyContinue
    Remove-Item Env:BOBHUB_DB_ADMIN_PASSWORD -ErrorAction SilentlyContinue

    if ($null -eq $OriginalWslenv) {
        Remove-Item Env:WSLENV -ErrorAction SilentlyContinue
    }
    else {
        $env:WSLENV = $OriginalWslenv
    }

    $PostgresPassword = $null
    $AppDbPassword = $null
}
