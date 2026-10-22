$ErrorActionPreference = "Stop"

param(
  [string]$DeviceId = "",
  [string]$ApiBaseUrl = "http://192.168.0.6:3001/api/v1"
)

Write-Host "== Laundry Customer App (USB / LAN) ==" -ForegroundColor Cyan
Write-Host "API_BASE_URL: $ApiBaseUrl"
Write-Host "Same Wi-Fi API: http://192.168.0.6:3001/api/v1"

if ($DeviceId -ne "") {
  Write-Host "Device: $DeviceId"
}

Write-Host ""
Write-Host "1) adb reverse tcp:3001 tcp:3001 (optional for USB localhost)" -ForegroundColor Yellow
if ($DeviceId -ne "") {
  adb -s $DeviceId reverse tcp:3001 tcp:3001
} else {
  adb reverse tcp:3001 tcp:3001
}

Write-Host ""
Write-Host "2) flutter run" -ForegroundColor Yellow
$flutterArgs = @("run", "--dart-define=API_BASE_URL=$ApiBaseUrl")
if ($DeviceId -ne "") {
  $flutterArgs += @("-d", $DeviceId)
}

flutter @flutterArgs
