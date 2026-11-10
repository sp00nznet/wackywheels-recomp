# One-click setup for the Wacky Wheels static recompilation. Run it by
# double-clicking Setup.cmd in the repo folder; the README's "Step by step" is
# the same thing by hand, command for command.
#
# It checks the tools, unpacks the game from your CD's installer archives into
# game\, writes a silent WACKY.CFG, lifts WW.EXE to C, builds
# build\wackywheels.exe and leaves a shortcut to it in this folder. Each step is
# skipped when its output already exists (-Force redoes them), so a rerun after
# a failure resumes. Everything it does goes to setup.log. Nothing of the game
# is downloaded: it comes from your CD (or an image or copy of it).
#
#   -GameDir <drive, folder, .iso or .cue>   skip the question (-Game works too)
#   -Yes                               answer yes to every install question
#
# The toolkit is ..\pcrecomp (PCRECOMP overrides it). Under recomp-launcher
# (RECOMP_LAUNCHER=1) it never waits for Enter, and exit code 0 means the
# shortcut is there.
param([switch]$Force, [switch]$Yes, [Alias('Game')][string]$GameDir = "")
$Game = $GameDir

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Toolkit = $env:PCRECOMP
if (-not $Toolkit) { $Toolkit = Join-Path (Split-Path -Parent $Root) 'pcrecomp' }
$env:PCRECOMP = $Toolkit -replace "\\", "/"   # run_lift.py and build.cmd (CMake wants /) read it
$Log = Join-Path $Root 'setup.log'
Set-Location $Root
function Log($t) { Add-Content -Path $Log -Value $t -Encoding UTF8 }
Log "==== setup $(Get-Date -Format s)"

function Say($t, $c = 'Gray') { Write-Host $t -ForegroundColor $c; Log $t }
function Step($n, $t) { Write-Host ""; Say "[$n/5] $t" 'Cyan' }
function Pause-End { if (-not $Yes -and $env:RECOMP_LAUNCHER -ne '1') { Read-Host "Press Enter to close" | Out-Null } }
function Fail($t) {
  Say ""; Say "Setup stopped: $t" 'Red'
  Say "The details are in $Log. Fix that and run Setup.cmd again; finished steps are skipped." 'Yellow'
  Pause-End; exit 1
}
trap { Fail "$_" }
function Ask($q) { if ($Yes) { Say "$q yes"; return $true }; $a = Read-Host "$q [Y/n]"; return -not ($a -match '^[nN]') }
function Refresh-Path {
  $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
}
# Run a program with its output in the log. Windows PowerShell turns a native
# program's stderr into errors, so 'Stop' is off while it runs.
function Exec([string[]]$cmd) {
  $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
  $rest = @($cmd | Select-Object -Skip 1)
  & $cmd[0] @rest 2>&1 | ForEach-Object { Log "$_" }
  $code = $LASTEXITCODE
  $ErrorActionPreference = $old
  return $code
}
function Run($what, [string[]]$cmd) {
  Say "  $what..."
  $code = Exec $cmd
  if ($code -ne 0) { Fail "$what failed (exit code $code)." }
}

if ($env:RECOMP_LAUNCHER -ne '1') { Clear-Host }
Say "Wacky Wheels: static recompilation setup" 'White'
Say "You need your own copy of the game (the CD rerelease, an .iso of it, or a folder copy of it) and about 1 GB free."

# ---------------------------------------------------------------- tools
Step 1 "Checking the tools"
# A Python that answers "Python 3.x". The Store's placeholder "python" answers
# nothing, so asking is the reliable test.
function Find-Python {
  $user = @(Get-ChildItem "$env:LOCALAPPDATA\Programs\Python\Python3*\python.exe" -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | ForEach-Object { ,@($_.FullName) })
  foreach ($c in (@(@('py', '-3'), @('python'), @('python3')) + $user)) {
    if (-not (Get-Command $c[0] -ErrorAction SilentlyContinue)) { continue }
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $rest = @($c | Select-Object -Skip 1)
    $v = (& $c[0] @rest --version 2>&1 | Out-String).Trim()
    $ErrorActionPreference = $old
    if ($v -match '^Python 3\.(\d+)' -and [int]$Matches[1] -ge 10) { return ,$c }
  }
  return $null
}
$pyargs = Find-Python
if (-not $pyargs) {
  Say "  Python 3.10 or newer is not installed."
  if (-not (Ask "  Install Python 3.12 now (winget, for your user only, about 30 MB)?")) { Fail "Python 3 is required." }
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Fail "winget is missing. Install 'App Installer' from the Microsoft Store, or install Python yourself." }
  Exec @('winget', 'install', '-e', '--id', 'Python.Python.3.12', '--scope', 'user', '--accept-package-agreements', '--accept-source-agreements') | Out-Null
  Refresh-Path
  $pyargs = Find-Python
  if (-not $pyargs) { Fail "Python installed, but it can't be found. Install Python 3.12 from python.org yourself." }
}
Say "  Python: $($pyargs -join ' ')"

if ((Exec ($pyargs + @('-c', 'import pefile, capstone'))) -ne 0) {
  Say "  The Python packages pefile and capstone are missing (about 20 MB)."
  if (-not (Ask "  Install them now (pip, for your user only)?")) { Fail "pefile and capstone are required." }
  Run "Installing pefile and capstone" ($pyargs + @('-m', 'pip', 'install', '--user', 'pefile', 'capstone'))
}

if (-not (Test-Path (Join-Path $Toolkit 'tools\lift\lift32.py'))) {
  Say "  The pcrecomp toolkit is not beside this folder ($Toolkit)."
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    if (-not (Ask "  git is needed to fetch it. Install Git for Windows now (winget, about 60 MB)?")) { Fail "git is needed to fetch pcrecomp." }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Fail "winget is missing. Install Git for Windows yourself." }
    Exec @('winget', 'install', '-e', '--id', 'Git.Git', '--accept-package-agreements', '--accept-source-agreements') | Out-Null
    Refresh-Path
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Fail "Git did not install. Install Git for Windows yourself." }
  }
  if (-not (Ask "  Download it now (git, about 20 MB)?")) { Fail "pcrecomp is required at $Toolkit." }
  Run "Cloning pcrecomp" @('git', 'clone', '--depth', '1', 'https://github.com/sp00nznet/pcrecomp', $Toolkit)
}
Say "  pcrecomp: $Toolkit"

# Visual Studio 2022 or its Build Tools with the C++ x64 tools and clang-cl;
# CMake and Ninja ship inside that workload, so build.cmd needs nothing else.
function Find-VS {
  $p = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
  if (Test-Path $p) { return (& $p -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath) }
  return $null
}
function Have-Clang($vs) { (Test-Path "$env:ProgramFiles\LLVM\bin\clang-cl.exe") -or ($vs -and (Test-Path "$vs\VC\Tools\Llvm\x64\bin\clang-cl.exe")) }
$vs = Find-VS
if (-not $vs -or -not (Have-Clang $vs)) {
  Say "  Visual Studio 2022 with the C++ tools and clang-cl is not installed. The recompiled game is C, and clang-cl compiles it."
  if (-not (Ask "  Install the Visual Studio 2022 Build Tools with the C++ workload and clang-cl now (about 4 GB)?")) { Fail "a C compiler (Visual Studio 2022 C++ with clang-cl) is required." }
  if ($vs) {
    # Visual Studio is there without clang-cl: add it with the Visual Studio Installer.
    Exec @("${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\setup.exe", 'modify', '--installPath', $vs, '--quiet', '--norestart',
           '--add', 'Microsoft.VisualStudio.Component.VC.Llvm.Clang') | Out-Null
  } else {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Fail "winget is missing. Install Visual Studio 2022 Build Tools with 'Desktop development with C++' and 'C++ Clang tools for Windows' yourself." }
    Exec @('winget', 'install', '-e', '--id', 'Microsoft.VisualStudio.2022.BuildTools', '--accept-package-agreements', '--accept-source-agreements',
           '--override', '--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Llvm.Clang --includeRecommended') | Out-Null
  }
  $vs = Find-VS
  if (-not $vs -or -not (Have-Clang $vs)) { Fail "the Build Tools did not install. Install Visual Studio 2022 with 'Desktop development with C++' and 'C++ Clang tools for Windows' yourself." }
}
Say "  C compiler: $vs (clang-cl)"

# ---------------------------------------------------------------- the game
Step 2 "Unpacking the game from your CD into game\"
if ((Test-Path 'game\WW.EXE') -and (Test-Path 'game\WACKY.DAT') -and -not $Force) {
  Say "  Already there (skipping)."
} else {
  $Game = $Game.Trim('"', ' ')
  if (-not $Game) {
    foreach ($d in (Get-PSDrive -PSProvider FileSystem)) {
      if (Test-Path (Join-Path $d.Root 'WW_REGUP._1')) { $Game = $d.Root; Say "  Found the CD in $Game"; break }
    }
  }
  if (-not $Game -and $Yes) { Fail "The CD wasn't found. Give its drive, folder, .iso or .cue with -GameDir." }
  while (-not $Game) {
    $Game = (Read-Host "  Where is the CD? Its drive (E:\), a folder holding WW_REGUP._1 and ._2, an .iso or a .cue").Trim('"', ' ')
  }
  # A .cue/.bin image becomes an .iso (its data track), which Windows mounts.
  if ($Game -match '\.cue$') {
    New-Item -ItemType Directory -Force 'work' | Out-Null
    if (-not (Test-Path 'work\disc.iso') -or $Force) { Run "Converting $(Split-Path -Leaf $Game) to work\disc.iso" ($pyargs + @('tools\cue2iso.py', $Game, 'work\disc.iso')) }
    $Game = Join-Path $Root 'work\disc.iso'
  }
  $img = $null
  if ($Game -match '\.iso$') {
    Say "  Mounting $Game"
    $iso = (Resolve-Path $Game).Path
    $img = Get-DiskImage -ImagePath $iso
    if (-not $img.Attached) { $img = Mount-DiskImage -ImagePath $iso -PassThru }
    $Game = (Get-Volume -DiskImage $img).DriveLetter + ':\'
  }
  $arc = Get-ChildItem $Game -Recurse -Depth 2 -Filter 'WW_REGUP._1' -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $arc) { Fail "WW_REGUP._1 is not in $Game. It is on the Wacky Wheels CD rerelease, next to WW_REGUP._2." }
  Run "Unpacking WW_REGUP._1 and ._2" ($pyargs + @('tools\unpack_regup.py', $arc.DirectoryName, 'game'))
  if ($img) { Dismount-DiskImage -ImagePath $img.ImagePath | Out-Null }
}
if (-not (Test-Path 'game\WACKY.CFG') -or $Force) { Run "Writing WACKY.CFG (no music, no effects)" ($pyargs + @('tools\make_cfg.py')) }

# ---------------------------------------------------------------- lift
Step 3 "Recompiling WW.EXE to C (a minute or two the first time)"
if ((Test-Path 'src\recomp\gen\recomp_dispatch.c') -and -not $Force) { Say "  Already done (skipping)." }
else { Run "Lifting" ($pyargs + @('run_lift.py')) }

# ---------------------------------------------------------------- build
Step 4 "Building build\wackywheels.exe (a few minutes)"
if ((Test-Path 'build\wackywheels.exe') -and -not $Force) { Say "  Already built (skipping)." }
else { Run "Compiling" @('cmd', '/d', '/c', "`"$Root\build.cmd`"") }

# ---------------------------------------------------------------- shortcut
Step 5 "Making the shortcut"
$lnk = Join-Path $Root 'Wacky Wheels.lnk'
$s = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$s.TargetPath = Join-Path $Root 'build\wackywheels.exe'
$s.WorkingDirectory = $Root
$s.Save()
if (-not (Test-Path $lnk)) { Fail "the shortcut was not made." }
Say "  $lnk"
Write-Host ""
Say "Done. Double-click 'Wacky Wheels' in this folder to run it. It boots to the menus, but the screen is not right yet (README, Status)." 'Green'
Pause-End
exit 0
