Add-Type -AssemblyName System.Drawing

$srcPath = "f:\NotePro\assets\app_logo.png"
if (-not (Test-Path $srcPath)) {
    Write-Error "Source image f:\NotePro\assets\app_logo.png not found"
    exit 1
}

$srcBmp = New-Object System.Drawing.Bitmap($srcPath)

# Create Windows multi-res ICO format from the user's PNG
$sizes = @(16, 24, 32, 48, 64, 128, 256)
$pngBytesList = @()

foreach ($s in $sizes) {
    $subBmp = New-Object System.Drawing.Bitmap($s, $s, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gSub = [System.Drawing.Graphics]::FromImage($subBmp)
    $gSub.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gSub.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $gSub.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $gSub.Clear([System.Drawing.Color]::Transparent)
    $gSub.DrawImage($srcBmp, 0, 0, $s, $s)
    $gSub.Dispose()
    
    $ms = New-Object System.IO.MemoryStream
    $subBmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytesList += ,$ms.ToArray()
    $ms.Dispose()
    $subBmp.Dispose()
}

$icoFs = New-Object System.IO.FileStream("f:\NotePro\windows\runner\resources\app_icon.ico", [System.IO.FileMode]::Create)
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
    $bw.Write([Byte]0) # Colors
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

$srcBmp.Dispose()

Write-Output "Converted user's new logo to app_icon.ico successfully!"
