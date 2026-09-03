Add-Type -AssemblyName System.Drawing

$srcPath = "C:\Users\PC\.gemini\antigravity\brain\862289f0-6e0e-492e-9f10-d428a404bb14\notepro_app_logo_1788264319637.jpg"
$img = [System.Drawing.Image]::FromFile($srcPath)

$assetsDir = "f:\NotePro\assets"
if (-not (Test-Path $assetsDir)) {
    New-Item -ItemType Directory -Path $assetsDir -Force | Out-Null
}

$bmp256 = New-Object System.Drawing.Bitmap(256, 256)
$g = [System.Drawing.Graphics]::FromImage($bmp256)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.DrawImage($img, 0, 0, 256, 256)

$bmp256.Save("f:\NotePro\assets\app_logo.png", [System.Drawing.Imaging.ImageFormat]::Png)

$icoH = $bmp256.GetHicon()
$ico = [System.Drawing.Icon]::FromHandle($icoH)
$fs = New-Object System.IO.FileStream("f:\NotePro\windows\runner\resources\app_icon.ico", [System.IO.FileMode]::Create)
$ico.Save($fs)
$fs.Close()

$g.Dispose()
$bmp256.Dispose()
$img.Dispose()

Write-Output "App icon and assets created successfully!"
