# Build and package NoteCards Pro into a Windows installer

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host " [0/3] Dong bo Icon tu assets/app_logo.png..." -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

if (Test-Path ".\convert_user_logo.ps1") {
    & ".\convert_user_logo.ps1"
}

Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host " [1/3] Bien dich Flutter Windows (Release)..." -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Loi khi bien dich Flutter Windows! Vui long kiem tra lai." -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host " [2/3] Kiem tra Inno Setup Compiler (ISCC)..." -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

$isccPath = $null
$possiblePaths = @(
    "ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe",
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
)

foreach ($path in $possiblePaths) {
    if (Get-Command $path -ErrorAction SilentlyContinue) {
        $isccPath = (Get-Command $path).Source
        break
    } elseif (Test-Path $path) {
        $isccPath = $path
        break
    }
}

if (-not $isccPath) {
    Write-Host "Chua tim thay Inno Setup tren may!" -ForegroundColor Yellow
    Write-Host "Ban co the cai nhanh bang lenh (PowerShell Admin hoac User):" -ForegroundColor Yellow
    Write-Host "  winget install JRSoftware.InnoSetup" -ForegroundColor Green
    Write-Host "Hoac tai tai: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
    Write-Host "`nSau khi cai xong, hay chay lai script nay hoac click chuot phai vao windows_installer.iss -> Compile!" -ForegroundColor Cyan
    exit 0
}

Write-Host "Tim thay Inno Setup tai: $isccPath" -ForegroundColor Green

Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host " [3/3] Dong goi file cai dat (Setup.exe)..." -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

& "$isccPath" "windows_installer.iss"
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n>>> THANH CONG! <<<" -ForegroundColor Green
    Write-Host "File cai dat da duoc tao tai: NoteCards_Pro_Setup.exe" -ForegroundColor Green
} else {
    Write-Host "`nLoi khi dong goi bang Inno Setup!" -ForegroundColor Red
}
