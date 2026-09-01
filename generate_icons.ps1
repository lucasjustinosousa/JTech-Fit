Add-Type -AssemblyName System.Drawing

# 1. Gerar ícone 512x512
$bmp512 = New-Object System.Drawing.Bitmap(512, 512)
$g = [System.Drawing.Graphics]::FromImage($bmp512)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# Fundo escuro com cantos arredondados
$rect = New-Object System.Drawing.Rectangle(0, 0, 512, 512)
$bgBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 13, 13, 13))
$g.FillRectangle($bgBrush, $rect)

# Círculo Azul TitanNova
$blueBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 30, 136, 229))
$g.FillEllipse($blueBrush, 56, 56, 400, 400)

# Anel Cyan Brilhante
$cyanPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 0, 210, 255), 14)
$g.DrawEllipse($cyanPen, 56, 56, 400, 400)

# Texto TITANNOVA FIT
$fontTitle = New-Object System.Drawing.Font('Arial', 40, [System.Drawing.FontStyle]::Bold)
$fontSub = New-Object System.Drawing.Font('Arial', 32, [System.Drawing.FontStyle]::Bold)
$whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$cyanBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255, 0, 210, 255))

$g.DrawString("TITANNOVA", $fontTitle, $whiteBrush, 170, 190)
$g.DrawString("FIT 🏋️‍♂️", $fontSub, $cyanBrush, 190, 260)

# Salvar PNGs
$bmp512.Save("c:\Users\TI\Desktop\Foco\assets\icons\icon-512.png", [System.Drawing.Imaging.ImageFormat]::Png)

$bmp192 = New-Object System.Drawing.Bitmap($bmp512, 192, 192)
$bmp192.Save("c:\Users\TI\Desktop\Foco\assets\icons\icon-192.png", [System.Drawing.Imaging.ImageFormat]::Png)

$bmp64 = New-Object System.Drawing.Bitmap($bmp512, 64, 64)
$bmp64.Save("c:\Users\TI\Desktop\Foco\assets\icons\favicon.png", [System.Drawing.Imaging.ImageFormat]::Png)

Write-Host "Ícones PNG gerados com sucesso!"
