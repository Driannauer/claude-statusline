#requires -Version 5.1
# Claude Code statusline (Windows PowerShell 5.1 / PowerShell 7+)
# Line 1: model | version | effort | total tokens | 7d usage   (each field its own color)
# Line 2: ctx bar | usage bar + reset countdown   (two bars; reset = time left in 5h window)

$ErrorActionPreference = 'SilentlyContinue'
$Culture = [System.Globalization.CultureInfo]::InvariantCulture

$raw = [Console]::In.ReadToEnd()
$json = $raw | ConvertFrom-Json

$esc = [char]27
$DIM = "$esc[2m"
$RESET = "$esc[0m"

$MODEL_C  = 39   # blue
$VERSION_C = 16  # true black (256-color 16 / ANSI 0)
$EFFORT_C = 135  # purple
$TOKENS_C = 28   # green
$WEEK_C   = 166  # orange
$CTX_C    = 30   # teal
$USAGE_C  = 125  # magenta/pink
$RESET_TIME_C = 178  # gold (5h usage-window reset countdown)

$barLen = 16

function Color([int]$code, [string]$text) {
    return "$esc[38;5;${code}m$text$RESET"
}

function Fmt1([double]$v) {
    return $v.ToString('0.0', $Culture)
}

function Fmt0([double]$v) {
    return [math]::Round($v, 0).ToString('0', $Culture)
}

function HumanTokens([double]$n) {
    if ($n -ge 1000000) {
        return "$(Fmt1 ($n / 1000000))M"
    } elseif ($n -ge 1000) {
        return "$(Fmt1 ($n / 1000))k"
    } else {
        return "$([math]::Round($n, 0))"
    }
}

function MakeBar($pct, [int]$len) {
    $filled = 0
    if ($null -ne $pct) {
        $filled = [int][math]::Round(([double]$pct) * $len / 100)
        if ($filled -gt $len) { $filled = $len }
        if ($filled -lt 0) { $filled = 0 }
    }
    $empty = $len - $filled
    return ('█' * $filled) + ('░' * $empty)
}

# Format a duration in seconds as a compact countdown: 3d1h / 2h13m / 47m / 0m
function HumanDur($sec) {
    if ($null -eq $sec) { return '--' }
    $s = [int64]$sec
    if ($s -le 0) { return '0m' }
    $d = [int][math]::Floor($s / 86400)
    $h = [int][math]::Floor(($s % 86400) / 3600)
    $m = [int][math]::Floor(($s % 3600) / 60)
    if ($d -gt 0) { return "${d}d${h}h" }
    elseif ($h -gt 0) { return "${h}h${m}m" }
    else { return "${m}m" }
}

$model = $json.model.display_name
if (-not $model) { $model = 'Claude' }
$version = $json.version
$effort = $json.effort.level

$inTok = [double]($json.context_window.total_input_tokens)
$outTok = [double]($json.context_window.total_output_tokens)
$totalTok = $inTok + $outTok

$weekPct = $json.rate_limits.seven_day.used_percentage
if ($null -ne $weekPct) { $weekStr = "$(Fmt0 $weekPct)%" } else { $weekStr = '--' }

$usedPct = $json.context_window.used_percentage
$ctxSize = [double]($json.context_window.context_window_size)
$usedTok = $inTok

$fivePct = $json.rate_limits.five_hour.used_percentage
$fiveReset = $json.rate_limits.five_hour.resets_at

$usedH = HumanTokens $usedTok
$totalH = HumanTokens $ctxSize
$totalTokH = HumanTokens $totalTok

$ctxBar = MakeBar $usedPct $barLen
$usageBar = MakeBar $fivePct $barLen

if ($null -ne $usedPct) { $ctxStr = "$(Fmt0 $usedPct)%" } else { $ctxStr = '?%' }
if ($null -ne $fivePct) { $usageStr = "$(Fmt0 $fivePct)%" } else { $usageStr = '?%' }

# Remaining time until the 5-hour usage window resets
if ($null -ne $fiveReset) {
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $resetStr = HumanDur ([int64]$fiveReset - $now)
} else {
    $resetStr = '--'
}

$sep = "$DIM | $RESET"

$line1 = Color $MODEL_C $model
if ($version) { $line1 += "$sep$(Color $VERSION_C "v$version")" }
if ($effort)  { $line1 += "$sep$(Color $EFFORT_C "effort:$effort")" }
$line1 += "$sep$(Color $TOKENS_C "total tokens:$totalTokH")$sep$(Color $WEEK_C "7d:$weekStr")"

$ctxPart = Color $CTX_C "ctx:$ctxStr [$ctxBar] $usedH/$totalH"
$usagePart = "$(Color $USAGE_C "usage:$usageStr [$usageBar]") $(Color $RESET_TIME_C "reset:$resetStr")"
$line2 = "   $ctxPart$sep$usagePart"

Write-Output $line1
Write-Output $line2
