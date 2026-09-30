$ErrorActionPreference = 'Stop'

# Test the actual archive, outside the source tree and without MSYS2 on PATH.
$archives = @(Get-ChildItem -Path 'dist/mednafen-*.zip')
if ($archives.Count -ne 1) {
    throw 'Expected exactly one Windows archive'
}
$testDir = Join-Path $env:RUNNER_TEMP ('mednafen-smoke-' + [guid]::NewGuid())
Expand-Archive -LiteralPath $archives[0].FullName -DestinationPath $testDir
$executables = @(Get-ChildItem -Path $testDir -Filter 'mednafen.exe' -Recurse)
if ($executables.Count -ne 1) {
    throw 'Expected exactly one packaged executable'
}
$exe = $executables[0]

# Verify PE hardening bits independently of linker defaults and strip behavior.
$image = [System.IO.File]::ReadAllBytes($exe.FullName)
$peOffset = [BitConverter]::ToInt32($image, 0x3c)
$optionalHeader = $peOffset + 24
$dllCharacteristics = [BitConverter]::ToUInt16($image, $optionalHeader + 70)
$required = 0x0140 # DYNAMIC_BASE | NX_COMPAT
if ([BitConverter]::ToUInt16($image, $optionalHeader) -eq 0x020b) {
    $required = $required -bor 0x0020 # HIGH_ENTROPY_VA for PE32+
}
if (($dllCharacteristics -band $required) -ne $required) {
    throw 'Packaged executable is missing required ASLR/DEP flags'
}

$env:PATH = "$env:SystemRoot\System32;$env:SystemRoot"
$env:MEDNAFEN_HOME = Join-Path $testDir 'profile'
$env:MEDNAFEN_NOPOPUPS = '1'
$env:SDL_VIDEODRIVER = 'dummy'
$env:LC_ALL = 'C'
$process = [System.Diagnostics.Process]::new()
$process.StartInfo.FileName = $exe.FullName
$process.StartInfo.Arguments = '-help'
$process.StartInfo.WorkingDirectory = $exe.DirectoryName
$process.StartInfo.UseShellExecute = $false
$process.StartInfo.CreateNoWindow = $true
$process.StartInfo.RedirectStandardOutput = $true
$process.StartInfo.RedirectStandardError = $true
[void]$process.Start()
# Drain both streams concurrently so startup/help output cannot block the child.
$stdout = $process.StandardOutput.ReadToEndAsync()
$stderr = $process.StandardError.ReadToEndAsync()
if (-not $process.WaitForExit(60000)) {
    $process.Kill()
    throw 'Packaged executable did not finish its startup smoke test within 60 seconds'
}
$process.WaitForExit()
$output = $stdout.GetAwaiter().GetResult()
Write-Host $output
Write-Host ($stderr.GetAwaiter().GetResult())
# Mednafen intentionally returns -1 after displaying help. Require its final
# help text too, since initialization errors can return the same exit code.
if ($process.ExitCode -ne -1 -or $output -notmatch 'Settings specified in this manner') {
    throw "Packaged executable failed startup/help smoke test (exit $($process.ExitCode))"
}