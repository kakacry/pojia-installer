# POJIA bootstrap (ASCII head, no BOM)
# ============================================================
#  破甲插件 · 一条命令在线安装
# ============================================================
#  在 PowerShell 里执行：
#    irm https://pojia-install.app.workbuddy.host/install.ps1 | iex
#
#  流程：选一个能通的下载源 -> 拉取安装核心与插件包 -> 自动安装
# ============================================================

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"

$BRAND = "https://pojia-install.app.workbuddy.host"

$MIRRORS = @(
    $BRAND,
    "https://cdn.jsdelivr.net/gh/kakacry/pojia-installer@main",
    "https://raw.githubusercontent.com/kakacry/pojia-installer/main",
    "https://ghproxy.net/https://raw.githubusercontent.com/kakacry/pojia-installer/main"
)

# 插件包在服务器上的候选名（部分 CDN/WAF 会拦 .zip，逐个回退）
$ZIP_NAMES = @("pojia.pkg", "pojia.bin", "files/pojia.zip", "pojia.zip")

function Say($m, $c = "Gray") { Write-Host $m -ForegroundColor $c }

Say ""
Say "  ==========================================" "Cyan"
Say "     POJIA  online installer" "Cyan"
Say "  ==========================================" "Cyan"
Say ""

# ---------- 1/3 选源 ----------
Say "[1/3] picking a reachable mirror" "Cyan"
$Base = $null
foreach ($m in $MIRRORS) {
    try {
        $r = Invoke-WebRequest -Uri "$m/VERSION" -TimeoutSec 12 -UseBasicParsing -ErrorAction Stop
        if ($r.StatusCode -eq 200) { $Base = $m; Say "      OK  $m" "Green"; break }
    } catch {
        Say "      --  $m" "DarkGray"
    }
}
if (-not $Base) {
    Say ""
    Say "  All mirrors unreachable." "Red"
    exit 1
}

# ---------- 2/3 下载 ----------
$Work = Join-Path $env:TEMP "pojia-setup"
if (Test-Path $Work) { Remove-Item $Work -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Path $Work -Force | Out-Null

Say "[2/3] downloading" "Cyan"
$core = Join-Path $Work "install-core.ps1"
$zip  = Join-Path $Work "pojia.zip"

Invoke-WebRequest -Uri "$Base/install-core.ps1" -OutFile $core -UseBasicParsing -TimeoutSec 60
Say ("      install-core.ps1     " + (Get-Item $core).Length + " B") "Green"

$got = $false
foreach ($n in $ZIP_NAMES) {
    try {
        Invoke-WebRequest -Uri "$Base/$n" -OutFile $zip -UseBasicParsing -TimeoutSec 300 -ErrorAction Stop
        $sz = (Get-Item $zip).Length
        if ($sz -gt 100000) {
            Say ("      pojia.zip            " + $sz + " B   (via $n)") "Green"
            $got = $true
            break
        }
    } catch {
        Say "      --  $n" "DarkGray"
    }
}
if (-not $got) {
    Say "  Package download failed. Check network." "Red"
    exit 1
}

# ---------- 3/3 安装 ----------
Say "[3/3] installing" "Cyan"
Say ""

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force -ErrorAction SilentlyContinue
& $core -Zip "$zip"
