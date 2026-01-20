$ErrorActionPreference = "Stop"

param(
  [string]$DeviceId = "",
  [string]$ApiBaseUrl = "http://13.232.71.139:4000/api/v1"
)

Write-Host "== Laundry Customer App (USB) ==" -ForegroundColor Cyan
Write-Host "API_BASE_URL: $ApiBaseUrl"

if ($DeviceId -ne "") {
  Write-Host "Device: $DeviceId"
}

Write-Host ""
Write-Host "1) adb reverse tcp:3000 tcp:3000" -ForegroundColor Yellow
if ($DeviceId -ne "") {
  adb -s $DeviceId reverse tcp:3000 tcp:3000
} else {
  adb reverse tcp:3000 tcp:3000
}

Write-Host ""
Write-Host "2) flutter run" -ForegroundColor Yellow
$flutterArgs = @("run", "--dart-define=API_BASE_URL=$ApiBaseUrl")
if ($DeviceId -ne "") {
  $flutterArgs += @("-d", $DeviceId)
}

flutter @flutterArgs


