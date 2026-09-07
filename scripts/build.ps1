param([Parameter(Mandatory=$true)][string]$Godot)
$ErrorActionPreference = 'Stop'
$lelicsRoot = Split-Path $PSScriptRoot -Parent
$lelicsGame = Join-Path $lelicsRoot 'godot'
$lelicsOutput = Join-Path $lelicsRoot 'exports'
New-Item -ItemType Directory -Force (Join-Path $lelicsOutput 'web') | Out-Null
# Godotは構文エラーでも0を返す場合があるため、成功マーカーも確認する。
$lelicsTest = & $Godot --headless --path $lelicsGame --log-file (Join-Path $lelicsOutput 'build-tests.log') --script tests.gd 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $lelicsTest -notmatch 'LELICS_TESTS_PASS' -or $lelicsTest -match 'SCRIPT ERROR') { throw $lelicsTest }
foreach ($lelicsPreset in @('Windows','Web')) {
    $lelicsLog = & $Godot --headless --path $lelicsGame --log-file (Join-Path $lelicsOutput 'build-export.log') --export-release $lelicsPreset 2>&1 | Out-String
    $lelicsLog | Set-Content -Encoding utf8 (Join-Path $lelicsOutput ('build-'+$lelicsPreset+'.log'))
    if ($LASTEXITCODE -ne 0 -or $lelicsLog -match 'SCRIPT ERROR|Export failed|Failed to export') { throw $lelicsLog }
}
$lelicsHtmlPath = Join-Path $lelicsOutput 'web/index.html'
$lelicsHtml = Get-Content $lelicsHtmlPath -Raw
$lelicsHtml = $lelicsHtml.Replace('engine.startGame({', "engine.startGame({`n            'args': new URLSearchParams(location.search).has('verify') ? ['--','--verify'] : [],")
Set-Content -Encoding utf8 $lelicsHtmlPath $lelicsHtml
$lelicsExe = Join-Path $lelicsOutput 'Lelics-16bit.exe'
$lelicsNativeTest = & $lelicsExe --headless --log-file (Join-Path $lelicsOutput 'build-native-tests.log') -- --verify 2>&1 | Out-String
if ($LASTEXITCODE -ne 0 -or $lelicsNativeTest -notmatch 'LELICS_TESTS_PASS' -or $lelicsNativeTest -match 'SCRIPT ERROR') { throw $lelicsNativeTest }
Compress-Archive -Force -CompressionLevel Optimal -Path $lelicsExe,(Join-Path $lelicsOutput 'GODOT-LICENSES.txt'),(Join-Path $lelicsOutput 'OFL.txt') -DestinationPath (Join-Path $lelicsOutput 'Lelics-Windows.zip')
Write-Output 'Lelics source tests, Windows tests, and Windows/Web builds passed. Run the Web verification URL separately.'
