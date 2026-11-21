# crear_vm.ps1 - Crea la maquina virtual Ubuntu 24.04 LTS en VMware Workstation Pro
# a partir de la imagen oficial de nube de Canonical (OVA), sin instalador.
# cloud-init lee el usuario, la llave SSH y el nombre de la maquina de las
# variables guestinfo del .vmx (fuente de datos VMware de cloud-init).
#
# Uso (PowerShell 7):
#   pwsh -File crear_vm.ps1 -Ova C:\VMs\descargas\ubuntu\ubuntu-24.04-server-cloudimg-amd64.ova `
#        -Destino C:\VMs\biobot-sky130 -LlavePublica C:\VMs\biobot-sky130\ssh\id_ed25519.pub `
#        -HashContrasena '<salida de: openssl passwd -6>'
param(
    [Parameter(Mandatory)] [string] $Ova,
    [Parameter(Mandatory)] [string] $Destino,
    [Parameter(Mandatory)] [string] $LlavePublica,
    [Parameter(Mandatory)] [string] $HashContrasena,
    [string] $Nombre = 'biobot-sky130',
    [int] $MemoriaMB = 6144,
    [int] $Cpus = 8,
    [int] $DiscoGB = 80
)
$ErrorActionPreference = 'Stop'

# Herramientas de VMware Workstation (la ruta cambia entre versiones)
$base = @('C:\Program Files (x86)\VMware\VMware Workstation', 'C:\Program Files\VMware\VMware Workstation') |
    Where-Object { Test-Path (Join-Path $_ 'vmrun.exe') } | Select-Object -First 1
if (-not $base) { throw 'No encuentro VMware Workstation (vmrun.exe).' }
$ovftool = Join-Path $base 'OVFTool\ovftool.exe'
$vdisk   = Join-Path $base 'vmware-vdiskmanager.exe'
$vmrun   = Join-Path $base 'vmrun.exe'

$vmx = Join-Path $Destino "$Nombre.vmx"
if (Test-Path $vmx) { throw "Ya existe $vmx; no la sobrescribo." }
New-Item -ItemType Directory -Force $Destino | Out-Null

# 1. OVA -> .vmx + disco
& $ovftool --acceptAllEulas --allowExtraConfig --name=$Nombre $Ova $Destino
if ($LASTEXITCODE -ne 0) { throw "ovftool fallo ($LASTEXITCODE)" }
$carpeta = Join-Path $Destino $Nombre
if (Test-Path (Join-Path $carpeta "$Nombre.vmx")) {
    Get-ChildItem $carpeta | Move-Item -Destination $Destino
    Remove-Item $carpeta
}

# 2. Agrandar el disco (la imagen trae ~3.5 GB; cloud-init crece la particion al arrancar)
$disco = Get-ChildItem $Destino -Filter *.vmdk | Select-Object -First 1
& $vdisk -x "${DiscoGB}GB" $disco.FullName
if ($LASTEXITCODE -ne 0) { throw "vmware-vdiskmanager fallo ($LASTEXITCODE)" }

# 3. cloud-init: usuario adam con la llave SSH
$pub = (Get-Content $LlavePublica -Raw).Trim()
$userData = @"
#cloud-config
hostname: $Nombre
timezone: America/Mexico_City
users:
  - name: adam
    gecos: BioBot SKY130
    groups: [sudo, adm]
    shell: /bin/bash
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    lock_passwd: false
    passwd: "$HashContrasena"
    ssh_authorized_keys:
      - $pub
ssh_pwauth: false
growpart:
  mode: auto
  devices: ["/"]
"@
$metaData = "instance-id: $Nombre-01`nlocal-hostname: $Nombre`n"
$b64 = { param($t) [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($t -replace "`r", ''))) }

# 4. Ajustes del .vmx
$lineas = Get-Content $vmx | Where-Object { $_ -notmatch '^(memsize|numvcpus|cpuid\.coresPerSocket|displayName|guestinfo\.|ethernet0\.connectionType|vhv\.enable)\s*=' }
$lineas += @(
    "displayName = `"BioBot SKY130 (Ubuntu 24.04)`"",
    "memsize = `"$MemoriaMB`"",
    "numvcpus = `"$Cpus`"",
    "cpuid.coresPerSocket = `"$Cpus`"",
    "vhv.enable = `"FALSE`"",
    "ethernet0.connectionType = `"nat`"",
    "guestinfo.metadata = `"$(& $b64 $metaData)`"",
    "guestinfo.metadata.encoding = `"base64`"",
    "guestinfo.userdata = `"$(& $b64 $userData)`"",
    "guestinfo.userdata.encoding = `"base64`""
)
Set-Content -Path $vmx -Value $lineas -Encoding ascii

# 5. Arrancar y esperar la IP (open-vm-tools viene en la imagen)
& $vmrun -T ws start $vmx nogui
if ($LASTEXITCODE -ne 0) { throw "vmrun start fallo ($LASTEXITCODE)" }
$ip = & $vmrun -T ws getGuestIPAddress $vmx -wait
"VM lista: $vmx"
"IP: $ip"
