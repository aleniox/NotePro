Add-Type -AssemblyName System.Drawing

$srcPath = "C:\Users\PC\.gemini\antigravity\brain\862289f0-6e0e-492e-9f10-d428a404bb14\notepro_app_logo_1788264319637.jpg"
if (-not (Test-Path $srcPath)) {
    Write-Error "Source image not found"
    exit 1
}

$srcBmp = New-Object System.Drawing.Bitmap($srcPath)
$w = $srcBmp.Width
$h = $srcBmp.Height

# Crop the squircle icon area (approx padding 10% on each side) and make background transparent
# The icon is centered, roughly spanning from (0.15*w, 0.15*h) to (0.85*w, 0.85*h)
$cropX = [int]($w * 0.18)
$cropY = [int]($h * 0.18)
$cropW = [int]($w * 0.64)
$cropH = [int]($h * 0.64)

$cropBmp = New-Object System.Drawing.Bitmap($cropW, $cropH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gCrop = [System.Drawing.Graphics]::FromImage($cropBmp)
$gCrop.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gCrop.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$gCrop.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

$gCrop.DrawImage($srcBmp, (New-Object System.Drawing.Rectangle(0, 0, $cropW, $cropH)), (New-Object System.Drawing.Rectangle($cropX, $cropY, $cropW, $cropH)), [System.Drawing.GraphicsUnit]::Pixel)
$gCrop.Dispose()

# Create a transparent rounded squircle mask for the icon
$size = 256
$finalBmp = New-Object System.Drawing.Bitmap($size, $size, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$gFinal = [System.Drawing.Graphics]::FromImage($finalBmp)
$gFinal.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$gFinal.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$gFinal.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$gFinal.Clear([System.Drawing.Color]::Transparent)

# Create rounded path
$radius = 56
$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$dim = $size - 8
$rect = New-Object System.Drawing.Rectangle(4, 4, $dim, $dim)
$d = $radius * 2

$path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
$path.AddArc($rect.Right - $d, $rect.Y, $d, $d, 270, 90)
$path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
$path.AddArc($rect.X, $rect.Bottom - $d, $d, $d, 90, 90)
$path.CloseFigure()

$gFinal.SetClip($path)
$gFinal.DrawImage($cropBmp, 0, 0, $size, $size)
$gFinal.ResetClip()
$gFinal.Dispose()

# Save transparent PNG
$outPng = Join-Path $PSScriptRoot "assets\app_logo.png"
$finalBmp.Save($outPng, [System.Drawing.Imaging.ImageFormat]::Png)

# Create Windows multi-res ICO format
# Write ICO header & directory entries for PNG-compressed ICO (standard Windows Vista/7/10/11 format)
$sizes = @(16, 24, 32, 48, 64, 128, 256)
$pngBytesList = @()

foreach ($s in $sizes) {
    $subBmp = New-Object System.Drawing.Bitmap($s, $s, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gSub = [System.Drawing.Graphics]::FromImage($subBmp)
    $gSub.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gSub.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $gSub.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $gSub.Clear([System.Drawing.Color]::Transparent)
    $gSub.DrawImage($finalBmp, 0, 0, $s, $s)
    $gSub.Dispose()
    
    $ms = New-Object System.IO.MemoryStream
    $subBmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytesList += ,$ms.ToArray()
    $ms.Dispose()
    $subBmp.Dispose()
}

$outIco = Join-Path $PSScriptRoot "windows\runner\resources\app_icon.ico"
$icoFs = New-Object System.IO.FileStream($outIco, [System.IO.FileMode]::Create)
$bw = New-Object System.IO.BinaryWriter($icoFs)

# ICONDIR Header
$bw.Write([UInt16]0) # Reserved
$bw.Write([UInt16]1) # Type (1 = Icon)
$bw.Write([UInt16]$sizes.Count) # Count of images

$offset = 6 + (16 * $sizes.Count)

for ($i = 0; $i -lt $sizes.Count; $i++) {
    $s = $sizes[$i]
    $bytes = $pngBytesList[$i]
    
    $bw.Write([Byte]($s % 256)) # Width (0 = 256)
    $bw.Write([Byte]($s % 256)) # Height (0 = 256)
    $bw.Write([Byte]0) # Colors (0 if >= 8bpp)
    $bw.Write([Byte]0) # Reserved
    $bw.Write([UInt16]1) # Color planes
    $bw.Write([UInt16]32) # Bits per pixel
    $bw.Write([UInt32]$bytes.Length) # Image size in bytes
    $bw.Write([UInt32]$offset) # Offset
    
    $offset += $bytes.Length
}

foreach ($bytes in $pngBytesList) {
    $bw.Write($bytes)
}

$bw.Close()
$icoFs.Close()

$finalBmp.Dispose()
$cropBmp.Dispose()
$srcBmp.Dispose()

Write-Output "Generated crystal-clear transparent ICO and PNG!"
