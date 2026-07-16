# Builds the Fire TV / Android TV launcher banner (rectangular) from the
# existing square app icon, so the TV artwork stays consistent with the phone
# icon: play logo on the left, app name on the right, on the icon's own black.
Add-Type -AssemblyName System.Drawing

$root = "C:\Users\aless\Documents\Claude\broken_iptv"
$src = [System.Drawing.Bitmap]::FromFile("$root\assets\icon\app_icon.png")

# --- Find the white play square inside the icon, so we can crop just that
# (drawing the whole icon would leave the logo tiny inside its own padding).
$rect = New-Object System.Drawing.Rectangle 0, 0, $src.Width, $src.Height
$data = $src.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$bytes = New-Object byte[] ($data.Stride * $src.Height)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
$src.UnlockBits($data)

$minX = $src.Width; $minY = $src.Height; $maxX = 0; $maxY = 0
for ($y = 0; $y -lt $src.Height; $y += 2) {
  $row = $y * $data.Stride
  for ($x = 0; $x -lt $src.Width; $x += 2) {
    $i = $row + $x * 4
    # Format32bppArgb byte order is B,G,R,A
    if ($bytes[$i] -gt 200 -and $bytes[$i + 1] -gt 200 -and $bytes[$i + 2] -gt 200 -and $bytes[$i + 3] -gt 128) {
      if ($x -lt $minX) { $minX = $x }
      if ($x -gt $maxX) { $maxX = $x }
      if ($y -lt $minY) { $minY = $y }
      if ($y -gt $maxY) { $maxY = $y }
    }
  }
}
$logoW = $maxX - $minX + 1
$logoH = $maxY - $minY + 1
Write-Output "logo bbox: x=$minX y=$minY w=$logoW h=$logoH"

# Background = the icon's own black, sampled from inside its rounded square,
# so the cropped logo sits on the banner with no visible seam.
$bg = $src.GetPixel(60, 60)
Write-Output ("bg: R={0} G={1} B={2} A={3}" -f $bg.R, $bg.G, $bg.B, $bg.A)
if ($bg.A -lt 250) { $bg = [System.Drawing.Color]::FromArgb(255, 10, 10, 10) }

function New-Banner {
  param([int]$W, [int]$H, [string]$OutPath)

  $scale = $W / 320.0
  $bmp = New-Object System.Drawing.Bitmap $W, $H
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $g.Clear($bg)

  # App name, two lines so it stays big and readable across a TV room.
  $fontSize = 30 * $scale
  $font = New-Object System.Drawing.Font "Segoe UI", $fontSize, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
  $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)

  $l1 = "Broken"
  $l2 = "IPTV"
  $s1 = $g.MeasureString($l1, $font)
  $s2 = $g.MeasureString($l2, $font)
  $textW = [Math]::Max($s1.Width, $s2.Width)

  # Centre logo + text as one group, so the banner isn't left-heavy.
  $logoSize = [int](116 * $scale)
  $gap = [int](18 * $scale)
  $groupW = $logoSize + $gap + $textW
  $startX = ($W - $groupW) / 2

  $logoY = [int](($H - $logoSize) / 2)
  $destRect = New-Object System.Drawing.Rectangle ([int]$startX), $logoY, $logoSize, $logoSize
  $srcRect = New-Object System.Drawing.Rectangle $minX, $minY, $logoW, $logoH
  $g.DrawImage($src, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)

  $textX = $startX + $logoSize + $gap
  $lineH = [Math]::Max($s1.Height, $s2.Height)
  $textY = ($H - $lineH * 2) / 2

  $g.DrawString($l1, $font, $brush, $textX, $textY)
  $g.DrawString($l2, $font, $brush, $textX, $textY + $lineH)
  Write-Output ("{0}x{1}: group={2} left={3} right={4}" -f $W, $H, $groupW, $startX, ($startX + $groupW))

  $dir = Split-Path $OutPath -Parent
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force $dir | Out-Null }
  $bmp.Save($OutPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose(); $font.Dispose(); $brush.Dispose()
  Write-Output "wrote $OutPath"
}

# 320x180 @xhdpi is the documented Fire TV / Android TV banner size; the
# xxhdpi copy keeps it crisp on 4K sticks.
New-Banner -W 320 -H 180 -OutPath "$root\android\app\src\main\res\drawable-xhdpi\tv_banner.png"
New-Banner -W 480 -H 270 -OutPath "$root\android\app\src\main\res\drawable-xxhdpi\tv_banner.png"
$src.Dispose()
