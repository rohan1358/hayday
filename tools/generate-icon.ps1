Add-Type -AssemblyName System.Drawing

$out = Join-Path $PSScriptRoot '..\assets\icon.png'
$bmp = [System.Drawing.Bitmap]::new(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

function Brush([string] $hex) {
    return [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml($hex))
}

function Polygon([int[]] $coords, [string] $color) {
    $pts = [System.Drawing.Point[]]::new($coords.Length / 2)
    for ($i = 0; $i -lt $pts.Length; $i++) {
        $pts[$i] = [System.Drawing.Point]::new($coords[$i * 2], $coords[$i * 2 + 1])
    }
    $brush = Brush $color
    $g.FillPolygon($brush, $pts)
    $brush.Dispose()
}

$g.Clear([System.Drawing.ColorTranslator]::FromHtml('#f8e5a6'))
$brush = Brush '#5ba965'
$g.FillEllipse($brush, 13, 13, 486, 486)
$brush.Dispose()
$brush = Brush '#83c96f'
$g.FillEllipse($brush, 45, 38, 422, 420)
$brush.Dispose()

# Land, barn silhouette, golden roof and white side beams.
Polygon @(66,361,256,268,451,361,256,470) '#e5b86a'
Polygon @(108,216,258,126,406,219,406,378,108,378) '#cb5c4a'
Polygon @(82,220,258,94,435,221,408,239,258,135,107,242) '#f1a266'
Polygon @(126,242,257,161,388,241,388,361,126,361) '#e87c59'
Polygon @(215,273,297,273,297,376,215,376) '#8c573d'
Polygon @(225,285,287,285,287,371,225,371) '#c78a55'
Polygon @(225,300,287,352,287,362,225,309) '#f2c68d'
Polygon @(287,300,225,352,225,362,287,309) '#f2c68d'

# Wheat frame on top of the roof.
$stalk = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml('#e8ce70'), 8)
$g.DrawLine($stalk, 257, 97, 257, 40)
$stalk.Dispose()
$seed = Brush '#f8d65a'
foreach ($pos in @(@(242, 55), @(263, 46), @(240, 75), @(265, 67), @(250, 27))) {
    $g.FillEllipse($seed, $pos[0], $pos[1], 19, 28)
}
$seed.Dispose()

# App icon remains fully opaque on Android launcher.
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose()
$bmp.Dispose()
Write-Output "Generated $out"
