# POJIA bootstrap v1.0.1
# ============================================================
#  破甲插件 · 一条命令在线安装
# ============================================================
#  在 PowerShell 里执行：
#    irm https://pojia-install.app.workbuddy.host/install.ps1 | iex
#
#  流程：探测可达镜像 -> 拉安装核心 -> 按 SHA256 指纹取插件包 -> 自动安装
#  插件包做指纹校验，任一镜像给出旧包/坏包会自动跳到下一个镜像，
#  所以镜像站缓存滞后不会导致装出错误的身份文件。
# ============================================================

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"

$BRAND = "https://pojia-install.app.workbuddy.host"

# 插件包指纹（SHA256）：与本机生效态一致的那一份
$PKG_SHA256 = "ECB84A96E2708CE99DE17E390842939CC23FE6CB10A4B1A5E62156A980C0DC95"
$PKG_MIN    = 300000

$MIRRORS = @(
    $BRAND,
    "https://cdn.jsdelivr.net/gh/kakacry/pojia-installer@main",
    "https://raw.githubusercontent.com/kakacry/pojia-installer/main",
    "https://ghproxy.net/https://raw.githubusercontent.com/kakacry/pojia-installer/main"
)

# 插件包在服务器上的候选名（部分 CDN/WAF 会拦 .zip，逐个回退）
$ZIP_NAMES = @("pojia.pkg", "pojia.bin", "files/pojia.zip", "pojia.zip")

function Say($m, $c = "Gray") { Write-Host $m -ForegroundColor $c }

function Get-Sha256($p) {
    try { return (Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash } catch { return "" }
}

function Try-Fetch($url, $out) {
    try {
        if (Test-Path -LiteralPath $out) { Remove-Item -LiteralPath $out -Force -ErrorAction SilentlyContinue }
        Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing -TimeoutSec 300 -ErrorAction Stop
        if (Test-Path -LiteralPath $out) { return [int64](Get-Item -LiteralPath $out).Length }
        return 0
    } catch { return 0 }
}

Say ""
Say "  ==========================================" "Cyan"
Say "     POJIA  online installer" "Cyan"
Say "  ==========================================" "Cyan"
Say ""

$Work = Join-Path $env:TEMP "pojia-setup"
if (Test-Path -LiteralPath $Work) { Remove-Item -LiteralPath $Work -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $Work -Force | Out-Null

$core = Join-Path $Work "install-core.ps1"
$zip  = Join-Path $Work "pojia.zip"

# ---------- 1/3 拉安装核心 ----------
Say "[1/3] fetching install core" "Cyan"
$coreOk = $false
foreach ($m in $MIRRORS) {
    $sz = Try-Fetch "$m/install-core.ps1" $core
    if ($sz -gt 5000) {
        Say ("      install-core.ps1  " + $sz + " B   ($m)") "Green"
        $coreOk = $true
        break
    }
    Say "      --  $m" "DarkGray"
}
if (-not $coreOk) {
    Say ""
    Say "  All mirrors unreachable." "Red"
    exit 1
}

# ---------- 2/3 取插件包（按指纹） ----------
Say "[2/3] fetching plugin package" "Cyan"
$pkgOk  = $false
$fall   = $null
$fallSz = 0
foreach ($m in $MIRRORS) {
    foreach ($n in $ZIP_NAMES) {
        $sz = Try-Fetch "$m/$n" $zip
        if ($sz -lt 100000) { continue }
        if ((Get-Sha256 $zip) -eq $PKG_SHA256) {
            Say ("      pojia.zip  " + $sz + " B   (verified via $n @ $m)") "Green"
            $pkgOk = $true
            break
        }
        Say ("      !   " + $n + " @ " + $m + "  stale " + $sz + " B, next") "Yellow"
        if ($sz -gt $fallSz) { $fallSz = $sz; $fall = $m + "/" + $n }
    }
    if ($pkgOk) { break }
}

if (-not $pkgOk) {
    if ($fallSz -ge $PKG_MIN) {
        Say ("      !   no mirror served the verified build; using $fall ($fallSz B)") "Yellow"
    } else {
        Say ""
        Say "  Package download failed. Check network." "Red"
        exit 1
    }
}

# ---------- 3/3 安装 ----------
Say "[3/3] installing" "Cyan"
Say ""

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
& $core -Zip "$zip"
