Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$output = Join-Path $root "assets"
New-Item -ItemType Directory -Force -Path $output | Out-Null

function New-Capsule {
    param([string]$Name, [int]$Width, [int]$Height, [int]$FontSize, [bool]$Vertical = $false)

    $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    $rect = New-Object System.Drawing.Rectangle 0, 0, $Width, $Height
    $background = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(5, 20, 34)), ([System.Drawing.Color]::FromArgb(21, 65, 78)), 35.0
    $graphics.FillRectangle($background, $rect)

    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(80, 112, 215, 232)), ([Math]::Max(2, $Width / 500))
    $nodeBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(112, 215, 232))
    for ($i = 0; $i -lt 12; $i++) {
        $x = ($i * 197 + 83) % $Width
        $y = ($i * 113 + 61) % $Height
        $x2 = ($x + $Width / 4) % $Width
        $y2 = ($y + $Height / 5) % $Height
        $graphics.DrawLine($pen, $x, $y, $x2, $y2)
        $radius = [Math]::Max(4, $Width / 180)
        $graphics.FillEllipse($nodeBrush, $x - $radius / 2, $y - $radius / 2, $radius, $radius)
    }

    $centerX = $Width * 0.5
    $baseY = $Height * 0.74
    $buildingW = $Width * 0.34
    $buildingH = $Height * 0.52
    $building = New-Object System.Drawing.PointF[] 6
    $building[0] = New-Object System.Drawing.PointF ($centerX - $buildingW / 2), $baseY
    $building[1] = New-Object System.Drawing.PointF ($centerX - $buildingW / 2), ($baseY - $buildingH * 0.78)
    $building[2] = New-Object System.Drawing.PointF $centerX, ($baseY - $buildingH)
    $building[3] = New-Object System.Drawing.PointF ($centerX + $buildingW / 2), ($baseY - $buildingH * 0.78)
    $building[4] = New-Object System.Drawing.PointF ($centerX + $buildingW / 2), $baseY
    $building[5] = New-Object System.Drawing.PointF ($centerX - $buildingW / 2), $baseY
    $buildingBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(160, 16, 43, 59))
    $outline = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(112, 215, 232)), ([Math]::Max(3, $Width / 250))
    $graphics.FillPolygon($buildingBrush, $building)
    $graphics.DrawPolygon($outline, $building)

    $crack = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(240, 199, 110)), ([Math]::Max(4, $Width / 160))
    $graphics.DrawLines($crack, @(
        (New-Object System.Drawing.PointF $centerX, ($baseY - $buildingH)),
        (New-Object System.Drawing.PointF ($centerX - $buildingW * 0.08), ($baseY - $buildingH * 0.65)),
        (New-Object System.Drawing.PointF ($centerX + $buildingW * 0.08), ($baseY - $buildingH * 0.48)),
        (New-Object System.Drawing.PointF ($centerX - $buildingW * 0.1), ($baseY - $buildingH * 0.25))
    ))

    $title = if ($Vertical) { "ARCHITECT`nOF FAILURE" } else { "ARCHITECT OF FAILURE" }
    $font = New-Object System.Drawing.Font "Arial", $FontSize, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    $textBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(225, 247, 248))
    $textRect = New-Object System.Drawing.RectangleF 0, ($Height * 0.08), $Width, ($Height * 0.42)
    $graphics.DrawString($title, $font, $textBrush, $textRect, $format)

    $bitmap.Save((Join-Path $output $Name), [System.Drawing.Imaging.ImageFormat]::Png)
    $textBrush.Dispose(); $format.Dispose(); $font.Dispose(); $crack.Dispose(); $outline.Dispose()
    $buildingBrush.Dispose(); $nodeBrush.Dispose(); $pen.Dispose(); $background.Dispose()
    $graphics.Dispose(); $bitmap.Dispose()
}

New-Capsule "header_capsule_920x430.png" 920 430 64
New-Capsule "small_capsule_462x174.png" 462 174 39
New-Capsule "main_capsule_1232x706.png" 1232 706 82
New-Capsule "vertical_capsule_748x896.png" 748 896 68 $true
New-Capsule "library_capsule_600x900.png" 600 900 57 $true
New-Capsule "library_hero_3840x1240.png" 3840 1240 190
New-Capsule "library_logo_1280x720.png" 1280 720 100 $true

Write-Host "Created Steam capsule drafts in $output"
