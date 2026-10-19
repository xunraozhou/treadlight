param([Parameter(Mandatory=$true)][string]$Godot)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$importOutput = & $Godot --headless --path $projectRoot --import 2>&1 | Out-String
Write-Output $importOutput
if ($LASTEXITCODE -ne 0 -or $importOutput -match 'ERROR:') { throw 'Godot import failed' }
$testOutput = & $Godot --headless --path $projectRoot --script res://tests/run_tests.gd --fixed-fps 60 2>&1 | Out-String
Write-Output $testOutput
if ($LASTEXITCODE -ne 0 -or $testOutput -match 'ERROR:' -or $testOutput -notmatch '0 failures') { throw 'Gameplay checks failed' }
